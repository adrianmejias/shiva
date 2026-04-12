#!/usr/bin/env bash

# setup.sh — One-time Shiva RP server configuration setup.
# Run this from the project root before starting Docker:
#   bash bin/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STUB="$ROOT_DIR/server.cfg.stub"
OUTPUT="$ROOT_DIR/fivem/server.cfg"
ENV_FILE="$ROOT_DIR/.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_section() { echo -e "\n${CYAN}[ $1 ]${NC}"; }

# Read a value from .env if it exists, otherwise return the default.
env_val() {
    local key="$1" default="$2"
    if [[ -f "$ENV_FILE" ]]; then
        local val
        val=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
        echo "${val:-$default}"
    else
        echo "$default"
    fi
}

# Prompt for a value. Uses env var as default if set, falls back to $default.
ask() {
    local label="$1" default="$2" secret="${3:-0}"
    local display="$default"
    [[ "$secret" == "1" && -n "$default" ]] && display="****"
    printf "  %s [%s]: " "$label" "$display" >&2
    local answer
    read -r answer
    echo "${answer:-$default}"
}

# Escape special sed replacement characters: / & \
escape_sed() {
    printf '%s' "$1" | sed 's/[\/&\\]/\\&/g'
}

# Generate a random alphanumeric string.
randstr() {
    LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "${1:-16}"
}

# ─── Intro ───────────────────────────────────────────────────────────────────

echo ""
echo "============================================"
echo "  Shiva RP — Server Configuration Setup"
echo "============================================"
echo ""
print_info "Press Enter to accept the default value shown in [brackets]."
if [[ -f "$ENV_FILE" ]]; then
    print_info "Existing .env found — using its values as defaults."
fi
echo ""

# ─── Load defaults from .env ─────────────────────────────────────────────────

DEFAULT_APP_NAME=$(env_val APP_NAME "Shiva RP")
DEFAULT_APP_DESCRIPTION=$(env_val APP_DESCRIPTION "A roleplay server for FiveM")
DEFAULT_APP_TAGS=$(env_val APP_TAGS "roleplay,fivem")
DEFAULT_MAX_PLAYERS=$(env_val MAX_PLAYERS "32")
DEFAULT_APP_ENV=$(env_val APP_ENV "development")
DEFAULT_APP_DEBUG=$(env_val APP_DEBUG "false")
DEFAULT_LICENSE_KEY=$(env_val LICENSE_KEY "")
DEFAULT_STEAM_KEY=$(env_val STEAM_KEY "")
DEFAULT_RCON_PASSWORD=$(env_val RCON_PASSWORD "$(randstr 16)")
DEFAULT_DB_USERNAME=$(env_val DB_USERNAME "root")
DEFAULT_DB_PASSWORD=$(env_val DB_PASSWORD "password")
DEFAULT_DB_HOST=$(env_val DB_HOST "host.docker.internal")
DEFAULT_DB_PORT=$(env_val DB_PORT "3306")
DEFAULT_DB_DATABASE=$(env_val DB_DATABASE "fivem")
DEFAULT_DB_CHARSET=$(env_val DB_CHARSET "utf8mb4")
DEFAULT_SHIVA_API_SECRET=$(env_val SHIVA_API_SECRET "$(randstr 32)")
DEFAULT_TXADMIN_PASSWORD=$(env_val TXADMIN_PASSWORD "$(randstr 16)")
DEFAULT_MYSQL_ROOT_PASSWORD=$(env_val MYSQL_ROOT_PASSWORD "password")
DEFAULT_MYSQL_USER=$(env_val MYSQL_USER "fivem")
DEFAULT_MYSQL_PASSWORD=$(env_val MYSQL_PASSWORD "password")
DEFAULT_MYSQL_DATABASE=$(env_val MYSQL_DATABASE "fivem")

# ─── Prompts ─────────────────────────────────────────────────────────────────

print_section "Server Identity"
APP_NAME=$(ask "Server name" "$DEFAULT_APP_NAME")
APP_DESCRIPTION=$(ask "Server description" "$DEFAULT_APP_DESCRIPTION")
APP_TAGS=$(ask "Server tags (comma-separated)" "$DEFAULT_APP_TAGS")
MAX_PLAYERS=$(ask "Max players" "$DEFAULT_MAX_PLAYERS")

print_section "Environment"
APP_ENV=$(ask "Environment (development/staging/production)" "$DEFAULT_APP_ENV")
APP_DEBUG=$(ask "Debug mode (true/false)" "$DEFAULT_APP_DEBUG")

print_section "Authentication"
echo "  (Get your license key at https://keymaster.fivem.net)"
LICENSE_KEY=$(ask "FiveM license key" "$DEFAULT_LICENSE_KEY" 1)
echo "  (Get your Steam API key at https://steamcommunity.com/dev/apikey)"
STEAM_KEY=$(ask "Steam Web API key" "$DEFAULT_STEAM_KEY" 1)
RCON_PASSWORD=$(ask "RCON password" "$DEFAULT_RCON_PASSWORD" 1)

print_section "Database"
DB_USERNAME=$(ask "MySQL username" "$DEFAULT_DB_USERNAME")
DB_PASSWORD=$(ask "MySQL password" "$DEFAULT_DB_PASSWORD" 1)
DB_HOST=$(ask "MySQL host" "$DEFAULT_DB_HOST")
DB_PORT=$(ask "MySQL port" "$DEFAULT_DB_PORT")
DB_DATABASE=$(ask "MySQL database" "$DEFAULT_DB_DATABASE")
DB_CHARSET=$(ask "MySQL charset" "$DEFAULT_DB_CHARSET")
DB_CONNECTION="mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_DATABASE}?charset=${DB_CHARSET}"

print_section "Shiva Core"
SHIVA_API_SECRET=$(ask "Shiva API secret" "$DEFAULT_SHIVA_API_SECRET" 1)

print_section "Docker / Admin"
TXADMIN_PASSWORD=$(ask "txAdmin password" "$DEFAULT_TXADMIN_PASSWORD" 1)
MYSQL_ROOT_PASSWORD=$(ask "MySQL root password" "$DEFAULT_MYSQL_ROOT_PASSWORD" 1)
MYSQL_USER=$(ask "MySQL app user" "$DEFAULT_MYSQL_USER")
MYSQL_PASSWORD=$(ask "MySQL app password" "$DEFAULT_MYSQL_PASSWORD" 1)
MYSQL_DATABASE=$(ask "MySQL app database" "$DEFAULT_MYSQL_DATABASE")

# ─── Write .env ──────────────────────────────────────────────────────────────

echo ""
print_info "Writing .env..."

cat > "$ENV_FILE" <<EOF
APP_ENV=${APP_ENV}
APP_DEBUG=${APP_DEBUG}

APP_NAME="${APP_NAME}"
APP_DESCRIPTION="${APP_DESCRIPTION}"
APP_TAGS="${APP_TAGS}"

MAX_PLAYERS=${MAX_PLAYERS}

DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_CHARSET=${DB_CHARSET}
DB_CONNECTION="${DB_CONNECTION}"

LICENSE_KEY=${LICENSE_KEY}
STEAM_KEY=${STEAM_KEY}
RCON_PASSWORD=${RCON_PASSWORD}
SHIVA_API_SECRET=${SHIVA_API_SECRET}

TXADMIN_PASSWORD=${TXADMIN_PASSWORD}

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}

NO_DEFAULT_CONFIG=
NO_LICENSE_KEY=
NO_STEAM_KEY=
NO_ONESYNC=

FIVEM_ID=
DISCORD_ID=

FORWARD_FIVEM_PORT=30120
FORWARD_TXADMIN_PORT=40120
EOF

print_info ".env written."

# ─── Write fivem/server.cfg ───────────────────────────────────────────────────

print_info "Writing fivem/server.cfg from stub..."

if [[ ! -f "$STUB" ]]; then
    print_error "Stub not found at: $STUB"
    exit 1
fi

cp "$STUB" "$OUTPUT"

# Escape values before passing to sed
E_APP_NAME=$(escape_sed "$APP_NAME")
E_APP_DESCRIPTION=$(escape_sed "$APP_DESCRIPTION")
E_APP_TAGS=$(escape_sed "$APP_TAGS")
E_APP_ENV=$(escape_sed "$APP_ENV")
E_APP_DEBUG=$(escape_sed "$APP_DEBUG")
E_LICENSE_KEY=$(escape_sed "$LICENSE_KEY")
E_STEAM_KEY=$(escape_sed "$STEAM_KEY")
E_RCON_PASSWORD=$(escape_sed "$RCON_PASSWORD")
E_SHIVA_API_SECRET=$(escape_sed "$SHIVA_API_SECRET")
# DB_CONNECTION contains / so use | as sed delimiter (escape & and \\ only)
E_DB_CONNECTION=$(printf '%s' "$DB_CONNECTION" | sed 's/[&\\]/\\&/g')

sed -i.bak "s/{APP_NAME}/${E_APP_NAME}/g"                 "$OUTPUT"
sed -i.bak "s/{APP_DESCRIPTION}/${E_APP_DESCRIPTION}/g"   "$OUTPUT"
sed -i.bak "s/{APP_TAGS}/${E_APP_TAGS}/g"                 "$OUTPUT"
sed -i.bak "s/{MAX_PLAYERS}/${MAX_PLAYERS}/g"             "$OUTPUT"
sed -i.bak "s/{APP_ENV}/${E_APP_ENV}/g"                   "$OUTPUT"
sed -i.bak "s/{APP_DEBUG}/${E_APP_DEBUG}/g"               "$OUTPUT"
sed -i.bak "s/{LICENSE_KEY}/${E_LICENSE_KEY}/g"           "$OUTPUT"
sed -i.bak "s/{STEAM_KEY}/${E_STEAM_KEY}/g"               "$OUTPUT"
sed -i.bak "s/{RCON_PASSWORD}/${E_RCON_PASSWORD}/g"       "$OUTPUT"
sed -i.bak "s|{DB_CONNECTION}|${E_DB_CONNECTION}|g"       "$OUTPUT"
sed -i.bak "s/{SHIVA_API_SECRET}/${E_SHIVA_API_SECRET}/g" "$OUTPUT"
rm -f "${OUTPUT}.bak"

print_info "fivem/server.cfg written."
echo ""
print_info "Setup complete! Run: docker compose up -d"
echo ""
