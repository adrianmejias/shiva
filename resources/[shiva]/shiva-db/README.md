# shiva-db

`shiva-db` is Shiva's first-party database runtime.

## Goals

- no bundled UI
- no clone/fork baggage
- modern pooled MySQL/MariaDB access
- a small, Shiva-native public contract
- keep driver details out of modules and gameplay code

## Placement

This folder can incubate inside the repo during development, but at runtime `shiva-db` should be deployed as a **sibling resource** to `shiva-core` under `[shiva]/`, not inside the symlinked `libs/shiva/` foundation.

## Setup

1. Install dependencies:
   ```bash
   cd shiva-db
   npm install
   ```
2. Ensure the resource before `shiva-core` in `server.cfg`:
   ```cfg
   ensure shiva-db
   ensure shiva-core
   ```
3. Set the database connection string:
   ```cfg
   set mysql_connection_string "mysql://user:password@localhost:3306/shiva"
   ```

## Optional tuning

```cfg
set shiva_db_pool_limit "10"
set shiva_db_max_idle "10"
set shiva_db_idle_timeout "60000"
set shiva_db_connect_timeout "10000"
set shiva_db_slow_query_ms "500"
set shiva_db_debug "false"
```

## Primary export surface

- `ready`
- `health`
- `query` / `querySync`
- `one` / `oneSync`
- `scalar` / `scalarSync`
- `exec` / `execSync`
- `insert` / `insertSync`
- `transaction` / `transactionSync`

A few transition-friendly aliases still exist internally during migration, but the Shiva-native surface above is the intended contract.
