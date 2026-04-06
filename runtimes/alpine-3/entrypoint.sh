#!/bin/sh

if [ -n "$DEBUG" ]; then
    set -x
fi

if [ -z "$(ls -A)" ]; then
    echo >&2 "Creating default configs..."
    echo >&2 "----------------------------------------------"
    echo >&2 "Copying default configs to /config..."
    ls -A /opt/cfx-server-data
    echo >&2 "----------------------------------------------"
    cp -r /opt/cfx-server-data/* /config
    cp -r /opt/cfx-server-data/. /config
fi

if [ ! -f /config/server.cfg ]; then
    echo >&2 "Creating server.cfg..."
    echo >&2 "----------------------------------------------"
    cp /opt/cfx-server-data/server.cfg /config/server.cfg
    echo >&2 "----------------------------------------------"
fi

# RCON_PASSWORD
if [ -n "$(grep '{RCON_PASSWORD}' /config/server.cfg)" ]; then
    echo >&2 "RCON password not found in server.cfg"
    echo >&2 "----------------------------------------------"

    if [ -z "$RCON_PASSWORD" ]; then
        echo >&2 "Generating random RCON password..."
        RCON_PASSWORD="$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 16)"
    fi

    sed -i "s/{RCON_PASSWORD}/$RCON_PASSWORD/g" /config/server.cfg
    echo >&2 "RCON password is set to: $RCON_PASSWORD"
    echo >&2 "----------------------------------------------"
fi

# APP_ENV
if [ -n "$(grep '{APP_ENV}' /config/server.cfg)" ]; then
    sed -i "s/{APP_ENV}/$APP_ENV/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Environment is set to: $APP_ENV"
    echo >&2 "----------------------------------------------"
fi

# APP_DEBUG
if [ -n "$(grep '{APP_DEBUG}' /config/server.cfg)" ]; then
    sed -i "s/{APP_DEBUG}/$APP_DEBUG/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Debug mode is set to: $APP_DEBUG"
    echo >&2 "----------------------------------------------"
fi

# APP_NAME
if [ -n "$(grep '{APP_NAME}' /config/server.cfg)" ]; then
    sed -i "s/{APP_NAME}/$APP_NAME/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Hostname is set to: $APP_NAME"
    echo >&2 "----------------------------------------------"
fi

# APP_DESCRIPTION
if [ -n "$(grep '{APP_DESCRIPTION}' /config/server.cfg)" ]; then
    sed -i "s/{APP_DESCRIPTION}/$APP_DESCRIPTION/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Server description is set to: $APP_DESCRIPTION"
    echo >&2 "----------------------------------------------"
fi

# APP_TAGS
if [ -n "$(grep '{APP_TAGS}' /config/server.cfg)" ]; then
    sed -i "s/{APP_TAGS}/$APP_TAGS/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Server tags are set to: $APP_TAGS"
    echo >&2 "----------------------------------------------"
fi

# DB_CONNECTION
if [ -n "$(grep '{DB_CONNECTION}' /config/server.cfg)" ]; then
    sed -i "s|{DB_CONNECTION}|$DB_CONNECTION|g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Database connection string is set to: $DB_CONNECTION"
    echo >&2 "----------------------------------------------"
fi

# MAX_PLAYERS
if [ -n "$(grep '{MAX_PLAYERS}' /config/server.cfg)" ]; then
    sed -i "s/{MAX_PLAYERS}/$MAX_PLAYERS/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Max player slots is set to: $MAX_PLAYERS"
    echo >&2 "----------------------------------------------"
fi

# STEAM_KEY
if [ -n "$(grep '{STEAM_KEY}' /config/server.cfg)" ]; then
    sed -i "s/{STEAM_KEY}/$STEAM_KEY/g" /config/server.cfg
    echo >&2 "----------------------------------------------"
    echo >&2 "Steam key is set to: $STEAM_KEY"
    echo >&2 "----------------------------------------------"
fi

# ONESYNC
if [ -z "$NO_ONESYNC" ]; then
    ONESYNC_ARGS="+set onesync on +set onesync_population true"
fi

CONFIG_ARGS=

if [ -z "$NO_DEFAULT_CONFIG" ]; then
    CONFIG_ARGS="$CONFIG_ARGS $ONESYNC_ARGS +exec /config/server.cfg"
fi

# LICENSE_KEY
if [ -z "$NO_LICENSE_KEY" ]; then
    if [ -z "$LICENSE_KEY" ] && [ -n "$LICENSE_KEY" ]; then
        LICENSE_KEY="$LICENSE_KEY"
    fi

    if [ -z "$NO_DEFAULT_CONFIG"] && [ -z "$LICENSE_KEY" ]; then
        printf >&2 "License key not found in environment, please create one at https://keymaster.fivem.net!\n"
        exit 1
    fi

    if [ -z "$CONFIG_ARGS" ] && [ -n "$LICENSE_KEY" ] && [ -n "$NO_DEFAULT_CONFIG" ]; then
        printf >&2 "txadmin does not use the \$LICENSE_KEY environment variable.\nPlease remove it and set it through the txadmin web UI\n\n"
        exit 1
    fi

    CONFIG_ARGS="$CONFIG_ARGS +set sv_licenseKey $LICENSE_KEY"
fi

if [ -z "$NO_STEAM_KEY" ]; then
    if [ -z "$STEAM_KEY" ] && [ -n "$STEAM_KEY" ]; then
        STEAM_KEY="$STEAM_KEY"
    fi

    if [ -z "$NO_DEFAULT_CONFIG" ] && [ -n "$STEAM_KEY" ]; then
        printf >&2 "Steam key not found in environment, please create one at https://steamcommunity.com/dev/apikey\n"
        exit 1
    fi

    if [ -z "$CONFIG_ARGS" ] && [ -n "$STEAM_KEY" ] && [ -n "$NO_DEFAULT_CONFIG" ]; then
        printf >&2 "txadmin does not use the \$STEAM_KEY environment variable.\nPlease remove it and set it through the txadmin web UI\n\n"
        exit 1
    fi

    CONFIG_ARGS="$CONFIG_ARGS +set steam_webApiKey $STEAM_KEY"
fi

if [ "$APP_DEBUG" = "true" ] || [ "$APP_DEBUG" = "1" ]; then
    CONFIG_ARGS="$CONFIG_ARGS +set sv_verbose 1 +set sv_scriptDebug 1 +set sv_logFile 1"
fi

echo >&2 "Starting txAdmin..."

if [ ! -z "$CONFIG_ARGS" ]; then
    echo >&2 "----------------------------------------------"
    echo >&2 "Using the following arguments: $CONFIG_ARGS"
    echo >&2 "----------------------------------------------"
fi

exec /opt/cfx-server/ld-musl-x86_64.so.1 \
    --library-path "/usr/lib/v8/:/lib/:/usr/lib/" \
    -- \
    /opt/cfx-server/FXServer \
    +set citizen_dir /opt/cfx-server/citizen/ \
    $CONFIG_ARGS \
    $*
