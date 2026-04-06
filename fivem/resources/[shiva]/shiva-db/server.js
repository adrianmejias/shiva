'use strict';

const mysql = require('mysql2/promise');

const resourceName = GetCurrentResourceName();
const registerExport = global.exports;

let pool = null;
let readyPromise = null;

function asBool(value, fallback = false) {
  if (typeof value !== 'string' || value.length === 0) return fallback;
  return /^(1|true|yes|on)$/i.test(value);
}

function asInt(value, fallback, min) {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) return fallback;
  return typeof min === 'number' ? Math.max(min, parsed) : parsed;
}

function parseKeyValueConnectionString(input) {
  const result = {};

  for (const segment of input.split(';')) {
    if (!segment) continue;

    const [rawKey, ...rawValue] = segment.split('=');
    const key = rawKey?.trim().toLowerCase();
    if (!key) continue;

    result[key] = rawValue.join('=').trim();
  }

  return result;
}

function parseConnectionString(input) {
  if (typeof input !== 'string' || input.trim().length === 0) {
    throw new Error('Missing `mysql_connection_string` convar for shiva-db');
  }

  const trimmed = input.trim();

  if (/^[a-z]+:\/\//i.test(trimmed)) {
    const url = new URL(trimmed);
    const database = decodeURIComponent(url.pathname.replace(/^\//, ''));

    if (!database) {
      throw new Error('Database name is missing from `mysql_connection_string`');
    }

    return {
      host: url.hostname || '127.0.0.1',
      port: asInt(url.port, 3306, 1),
      user: decodeURIComponent(url.username || ''),
      password: decodeURIComponent(url.password || ''),
      database,
    };
  }

  const pairs = parseKeyValueConnectionString(trimmed);
  const database = pairs.database || pairs.db || '';

  if (!database) {
    throw new Error('Database name is missing from `mysql_connection_string`');
  }

  return {
    host: pairs.host || pairs.server || '127.0.0.1',
    port: asInt(pairs.port, 3306, 1),
    user: pairs.user || pairs.username || '',
    password: pairs.password || '',
    database,
    charset: pairs.charset || undefined,
  };
}

function getConfig() {
  const connectionString = GetConvar('mysql_connection_string', '').trim();

  return {
    ...parseConnectionString(connectionString),
    connectionString,
    connectionLimit: asInt(GetConvar('shiva_db_pool_limit', '10'), 10, 1),
    maxIdle: asInt(GetConvar('shiva_db_max_idle', '10'), 10, 0),
    idleTimeout: asInt(GetConvar('shiva_db_idle_timeout', '60000'), 60000, 1000),
    connectTimeout: asInt(GetConvar('shiva_db_connect_timeout', '10000'), 10000, 1000),
    debug: asBool(GetConvar('shiva_db_debug', 'false')),
    slowQueryMs: asInt(GetConvar('shiva_db_slow_query_ms', '500'), 500, 1),
  };
}

function log(level, message, context) {
  const prefix = `[${resourceName}]`;
  const payload = context ? ` ${JSON.stringify(context)}` : '';
  const writer = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;

  writer(`${prefix} ${message}${payload}`);
}

function normalizeParams(params) {
  if (params == null) return [];
  if (Array.isArray(params)) return params;

  const valueType = typeof params;
  if (valueType !== 'object') return [params];

  const keys = Object.keys(params);
  if (keys.length === 0) return [];

  const numericKeys = keys.every((key) => /^\d+$/.test(key));
  if (numericKeys) {
    return keys
      .sort((left, right) => Number(left) - Number(right))
      .map((key) => params[key]);
  }

  return params;
}

function hasParams(params) {
  if (Array.isArray(params)) return params.length > 0;
  if (params && typeof params === 'object') return Object.keys(params).length > 0;
  return params != null;
}

function compactSql(sql) {
  return typeof sql === 'string' ? sql.replace(/\s+/g, ' ').trim().slice(0, 300) : '<invalid sql>';
}

function normalizeWriteResult(result) {
  return {
    affectedRows: typeof result?.affectedRows === 'number' ? result.affectedRows : 0,
    changedRows: typeof result?.changedRows === 'number' ? result.changedRows : 0,
    insertId: typeof result?.insertId === 'number' ? result.insertId : null,
    warningStatus: typeof result?.warningStatus === 'number' ? result.warningStatus : 0,
  };
}

async function ensurePool() {
  if (pool) return pool;
  if (readyPromise) return readyPromise;

  readyPromise = (async () => {
    const cfg = getConfig();

    const nextPool = mysql.createPool({
      host: cfg.host,
      port: cfg.port,
      user: cfg.user,
      password: cfg.password,
      database: cfg.database,
      charset: cfg.charset,
      waitForConnections: true,
      connectionLimit: cfg.connectionLimit,
      maxIdle: cfg.maxIdle,
      idleTimeout: cfg.idleTimeout,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0,
      namedPlaceholders: true,
      multipleStatements: false,
      supportBigNumbers: true,
      decimalNumbers: false,
      connectTimeout: cfg.connectTimeout,
      timezone: 'Z',
    });

    await nextPool.query('SELECT 1 AS ok');
    pool = nextPool;

    log('info', 'Database pool ready', {
      host: cfg.host,
      database: cfg.database,
      connectionLimit: cfg.connectionLimit,
      maxIdle: cfg.maxIdle,
    });

    return pool;
  })().catch((error) => {
    readyPromise = null;
    pool = null;
    log('error', 'Database pool initialization failed', { error: error.message });
    throw error;
  });

  return readyPromise;
}

async function withTiming(sql, task) {
  const cfg = getConfig();
  const startedAt = Date.now();

  try {
    const result = await task();
    const elapsed = Date.now() - startedAt;

    if (cfg.debug || elapsed >= cfg.slowQueryMs) {
      log(elapsed >= cfg.slowQueryMs ? 'warn' : 'info', 'Query complete', {
        elapsed,
        sql: compactSql(sql),
      });
    }

    return result;
  } catch (error) {
    log('error', 'Query failed', {
      sql: compactSql(sql),
      error: error.message,
      code: error.code || 'unknown',
    });
    throw error;
  }
}

async function runOn(executor, sql, params) {
  const normalized = normalizeParams(params);

  if (!hasParams(normalized)) {
    const [rows] = await executor.query(sql);
    return rows;
  }

  const [rows] = await executor.execute(sql, normalized);
  return rows;
}

async function queryInternal(sql, params, executor) {
  if (typeof sql !== 'string' || sql.trim().length === 0) {
    throw new Error('Query must be a non-empty string');
  }

  const db = executor || await ensurePool();
  return withTiming(sql, () => runOn(db, sql, params));
}

function firstRow(rows) {
  if (!Array.isArray(rows)) return rows ?? null;
  return rows[0] ?? null;
}

function firstValue(row) {
  if (row == null) return null;
  if (typeof row !== 'object') return row;

  const values = Object.values(row);
  return values.length > 0 ? values[0] : null;
}

function createExecutor(executor) {
  return {
    query: (sql, params) => queryInternal(sql, params, executor),
    one: async (sql, params) => firstRow(await queryInternal(sql, params, executor)),
    scalar: async (sql, params) => firstValue(firstRow(await queryInternal(sql, params, executor))),
    exec: async (sql, params) => normalizeWriteResult(await queryInternal(sql, params, executor)),
    insert: async (sql, params) => {
      const result = await queryInternal(sql, params, executor);
      return typeof result?.insertId === 'number' ? result.insertId : null;
    },
  };
}

async function transactionInternal(work) {
  const db = await ensurePool();
  const connection = await db.getConnection();
  const tx = createExecutor(connection);

  try {
    await connection.beginTransaction();

    let result;
    if (typeof work === 'function') {
      result = await work(tx);
    } else if (Array.isArray(work)) {
      const results = [];

      for (const step of work) {
        const sql = typeof step === 'string' ? step : step?.sql ?? step?.query;
        const params = typeof step === 'object' && step ? step.params ?? step.values ?? [] : [];

        if (typeof sql !== 'string' || sql.trim().length === 0) {
          throw new Error('Transaction step is missing a valid `sql` or `query` field');
        }

        results.push(await tx.query(sql, params));
      }

      result = results;
    } else {
      throw new Error('Transaction expects either a callback or an array of query steps');
    }

    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback().catch(() => {});
    throw error;
  } finally {
    connection.release();
  }
}

function withOptionalCallback(handler) {
  return async (firstArg, secondArg, thirdArg) => {
    let params = secondArg;
    let callback = thirdArg;

    if (typeof params === 'function') {
      callback = params;
      params = undefined;
    }

    const result = await handler(firstArg, params);

    if (typeof callback === 'function') {
      callback(result);
    }

    return result;
  };
}

on('onResourceStart', async (name) => {
  if (name !== resourceName) return;

  try {
    await ensurePool();
  } catch (error) {
    log('error', 'Startup connection check failed', { error: error.message });
  }
});

on('onResourceStop', async (name) => {
  if (name !== resourceName || !pool) return;

  await pool.end().catch(() => {});
  pool = null;
  readyPromise = null;
});

registerExport('driverName', () => 'shiva-db');
registerExport('ready', async () => {
  await ensurePool();
  return true;
});
registerExport('awaitConnection', async () => {
  await ensurePool();
  return true;
});
registerExport('health', async () => {
  const db = await ensurePool();
  const row = firstRow(await withTiming('SELECT 1 AS ok', () => runOn(db, 'SELECT 1 AS ok')));

  return {
    ok: row?.ok === 1,
    driver: 'shiva-db',
    ready: true,
  };
});

registerExport('query', withOptionalCallback(queryInternal));
registerExport('querySync', withOptionalCallback(queryInternal));
registerExport('one', withOptionalCallback(async (sql, params) => firstRow(await queryInternal(sql, params))));
registerExport('oneSync', withOptionalCallback(async (sql, params) => firstRow(await queryInternal(sql, params))));
registerExport('scalar', withOptionalCallback(async (sql, params) => firstValue(firstRow(await queryInternal(sql, params)))));
registerExport('scalarSync', withOptionalCallback(async (sql, params) => firstValue(firstRow(await queryInternal(sql, params)))));
registerExport('exec', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params))));
registerExport('execSync', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params))));
registerExport('insert', withOptionalCallback(async (sql, params) => {
  const result = await queryInternal(sql, params);
  return typeof result?.insertId === 'number' ? result.insertId : null;
}));
registerExport('insertSync', withOptionalCallback(async (sql, params) => {
  const result = await queryInternal(sql, params);
  return typeof result?.insertId === 'number' ? result.insertId : null;
}));
registerExport('transaction', withOptionalCallback(transactionInternal));
registerExport('transactionSync', withOptionalCallback(transactionInternal));

// Temporary transition aliases while shiva-core and modules migrate.
registerExport('fetch', withOptionalCallback(queryInternal));
registerExport('fetchSync', withOptionalCallback(queryInternal));
registerExport('single', withOptionalCallback(async (sql, params) => firstRow(await queryInternal(sql, params))));
registerExport('singleSync', withOptionalCallback(async (sql, params) => firstRow(await queryInternal(sql, params))));
registerExport('update', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params)).affectedRows));
registerExport('updateSync', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params)).affectedRows));
registerExport('execute', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params)).affectedRows));
registerExport('executeSync', withOptionalCallback(async (sql, params) => normalizeWriteResult(await queryInternal(sql, params)).affectedRows));
registerExport('prepare', withOptionalCallback(queryInternal));
registerExport('rawExecute', withOptionalCallback(queryInternal));
