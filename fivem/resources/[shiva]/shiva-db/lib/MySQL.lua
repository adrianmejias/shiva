local RESOURCE = 'shiva-db'

local function invoke(method, ...)
    return exports[RESOURCE][method](exports[RESOURCE], ...)
end

local function waitUntilReady(cb)
    while GetResourceState(RESOURCE) ~= 'started' do
        Wait(50)
    end

    local ok = invoke('ready')
    if cb then
        cb(ok)
    end

    return ok
end

local function makeMethod(name, syncName)
    syncName = syncName or (name .. 'Sync')
    return setmetatable({
        await = function(query, parameters)
            return invoke(syncName, query, parameters or {})
        end,
    }, {
        __call = function(_, query, parameters, cb)
            if type(parameters) == 'function' then
                cb = parameters
                parameters = nil
            end

            local result = invoke(name, query, parameters or {})
            if cb then
                cb(result)
            end

            return result
        end,
    })
end

local MySQL = rawget(_ENV, 'MySQL') or {}

MySQL.query       = makeMethod('query')
MySQL.one         = makeMethod('one')
MySQL.single      = MySQL.one
MySQL.scalar      = makeMethod('scalar')
MySQL.exec        = makeMethod('exec')
MySQL.execute     = makeMethod('execute')
MySQL.insert      = makeMethod('insert')
MySQL.transaction = makeMethod('transaction')
MySQL.prepare     = makeMethod('prepare')
MySQL.rawExecute  = makeMethod('rawExecute')

MySQL.Sync = {
    query       = MySQL.query.await,
    one         = MySQL.one.await,
    fetchAll    = MySQL.query.await,
    fetchSingle = MySQL.one.await,
    fetchScalar = MySQL.scalar.await,
    scalar      = MySQL.scalar.await,
    exec        = MySQL.exec.await,
    execute     = MySQL.execute.await,
    insert      = MySQL.insert.await,
    prepare     = MySQL.prepare.await,
    transaction = MySQL.transaction.await,
}

MySQL.Async = {
    query       = MySQL.query,
    one         = MySQL.one,
    fetchAll    = MySQL.query,
    fetchSingle = MySQL.one,
    fetchScalar = MySQL.scalar,
    scalar      = MySQL.scalar,
    exec        = MySQL.exec,
    execute     = MySQL.execute,
    insert      = MySQL.insert,
    prepare     = MySQL.prepare,
    transaction = MySQL.transaction,
}

MySQL.ready = setmetatable({
    await = function()
        return waitUntilReady()
    end,
}, {
    __call = function(_, cb)
        return waitUntilReady(cb)
    end,
})

_ENV.MySQL = MySQL
