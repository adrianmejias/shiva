#!/bin/sh

if [ -n "$DEBUG" ]; then
    set -x
fi

if [ ! -f /config/server.cfg ]; then
    printf >&2 'Error: /config/server.cfg not found.\n'
    printf >&2 'Run bin/setup.sh from the project root to generate it.\n'
    exit 1
fi

# OneSync
ONESYNC_ARGS=
if [ -z "$NO_ONESYNC" ]; then
    ONESYNC_ARGS="+set onesync on +set onesync_population true"
fi

CONFIG_ARGS=
if [ -z "$NO_DEFAULT_CONFIG" ]; then
    CONFIG_ARGS="$ONESYNC_ARGS +exec /config/server.cfg"
fi

if [ -z "$NO_LICENSE_KEY" ]; then
    if [ -z "$LICENSE_KEY" ] && [ -z "$NO_DEFAULT_CONFIG" ]; then
        printf >&2 'License key not set. Run bin/setup.sh or set LICENSE_KEY in .env.\n'
        exit 1
    fi
    [ -n "$LICENSE_KEY" ] && CONFIG_ARGS="$CONFIG_ARGS +set sv_licenseKey $LICENSE_KEY"
fi

if [ -z "$NO_STEAM_KEY" ] && [ -n "$STEAM_KEY" ]; then
    CONFIG_ARGS="$CONFIG_ARGS +set steam_webApiKey $STEAM_KEY"
fi

if [ "$APP_DEBUG" = "true" ] || [ "$APP_DEBUG" = "1" ]; then
    CONFIG_ARGS="$CONFIG_ARGS +set sv_verbose 1 +set sv_scriptDebug 1 +set sv_logFile 1"
fi

echo >&2 "Starting FiveM server..."

if [ -n "$CONFIG_ARGS" ]; then
    echo >&2 "----------------------------------------------"
    echo >&2 "Args: $CONFIG_ARGS"
    echo >&2 "----------------------------------------------"
fi

exec /opt/cfx-server/ld-musl-x86_64.so.1 \
    --library-path "/usr/lib/v8/:/lib/:/usr/lib/" \
    -- \
    /opt/cfx-server/FXServer \
    +set citizen_dir /opt/cfx-server/citizen/ \
    $CONFIG_ARGS \
    "$@"
