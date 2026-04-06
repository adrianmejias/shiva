#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GITMODULES_FILE="${GITMODULES_FILE:-${ROOT_DIR}/.gitmodules}"
DEFAULT_SUBMODULE_BRANCH="${DEFAULT_SUBMODULE_BRANCH:-main}"
DEFAULT_SUBMODULE_UPDATE="${DEFAULT_SUBMODULE_UPDATE:-rebase}"

SHIVA_CORE_PATH="fivem/resources/[shiva]/shiva-core"
SHIVA_FW_PATH="fivem/resources/[shiva]/shiva-fw"
SHIVA_DB_PATH="fivem/resources/[shiva]/shiva-db"
SHIVA_BOOT_PATH="fivem/resources/[shiva]/shiva-boot"
SHIVA_MODULES_PATH="fivem/resources/[shiva-modules]"

SHIVA_CORE_URL="git@github.com:adrianmejias/shiva-core.git"
SHIVA_FW_URL="git@github.com:adrianmejias/shiva-fw.git"
SHIVA_DB_URL="git@github.com:adrianmejias/shiva-db.git"
SHIVA_BOOT_URL="git@github.com:adrianmejias/shiva-boot.git"
SHIVA_MODULES_URL="git@github.com:adrianmejias/shiva-modules.git"

print_usage() {
    cat <<'EOF'
Usage:
  submodules.sh status
  submodules.sh sync
  submodules.sh link-add <path> <url> [branch] [update]
  submodules.sh link-remove <path>
  submodules.sh links-add
  submodules.sh links-remove

Examples:
  submodules.sh link-add 'fivem/resources/[shiva]/shiva-core' 'git@github.com:owner/repo.git'
  submodules.sh link-remove 'fivem/resources/[shiva]/shiva-core'
EOF
}

ensure_git_is_available() {
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ git is required but was not found in PATH."
        exit 1
    fi
}

add_link() {
    local submodule_path="${1:-}"
    local submodule_url="${2:-}"
    local submodule_branch="${3:-$DEFAULT_SUBMODULE_BRANCH}"
    local submodule_update="${4:-$DEFAULT_SUBMODULE_UPDATE}"

    if [[ -z "$submodule_path" || -z "$submodule_url" ]]; then
        echo "Usage: submodules.sh link-add <path> <url> [branch] [update]"
        exit 1
    fi

    echo "🔗 Adding ${submodule_path} → ${submodule_url} to ${GITMODULES_FILE}..."
    git config -f "$GITMODULES_FILE" "submodule.${submodule_path}.path" "$submodule_path"
    git config -f "$GITMODULES_FILE" "submodule.${submodule_path}.url" "$submodule_url"
    git config -f "$GITMODULES_FILE" "submodule.${submodule_path}.branch" "$submodule_branch"
    git config -f "$GITMODULES_FILE" "submodule.${submodule_path}.update" "$submodule_update"
    echo "✅ Added ${submodule_path} to ${GITMODULES_FILE}."
}

remove_link() {
    local submodule_path="${1:-}"

    if [[ -z "$submodule_path" ]]; then
        echo "Usage: submodules.sh link-remove <path>"
        exit 1
    fi

    echo "🗑️  Removing ${submodule_path} from ${GITMODULES_FILE}..."
    git config -f "$GITMODULES_FILE" --unset-all "submodule.${submodule_path}.path" 2>/dev/null || true
    git config -f "$GITMODULES_FILE" --unset-all "submodule.${submodule_path}.url" 2>/dev/null || true
    git config -f "$GITMODULES_FILE" --unset-all "submodule.${submodule_path}.branch" 2>/dev/null || true
    git config -f "$GITMODULES_FILE" --unset-all "submodule.${submodule_path}.update" 2>/dev/null || true

    if [[ -f "$GITMODULES_FILE" && ! -s "$GITMODULES_FILE" ]]; then
        rm -f "$GITMODULES_FILE"
    elif [[ -f "$GITMODULES_FILE" ]] && ! grep -q '^\[submodule "' "$GITMODULES_FILE"; then
        rm -f "$GITMODULES_FILE"
    fi

    echo "✅ Removed ${submodule_path} from ${GITMODULES_FILE}."
}

status_cmd() {
    echo "📦 Current git submodule status..."
    git submodule status --recursive || true
}

sync_cmd() {
    echo "🔄 Syncing git submodules..."
    git submodule sync --recursive
    git submodule update --init --recursive
    echo "✅ Git submodules synced."
}

links_add_cmd() {
    echo "🔗 Adding default Shiva repo links to ${GITMODULES_FILE}..."
    add_link "$SHIVA_CORE_PATH" "$SHIVA_CORE_URL" "$DEFAULT_SUBMODULE_BRANCH" "$DEFAULT_SUBMODULE_UPDATE"
    add_link "$SHIVA_FW_PATH" "$SHIVA_FW_URL" "$DEFAULT_SUBMODULE_BRANCH" "$DEFAULT_SUBMODULE_UPDATE"
    add_link "$SHIVA_DB_PATH" "$SHIVA_DB_URL" "$DEFAULT_SUBMODULE_BRANCH" "$DEFAULT_SUBMODULE_UPDATE"
    add_link "$SHIVA_MODULES_PATH" "$SHIVA_MODULES_URL" "$DEFAULT_SUBMODULE_BRANCH" "$DEFAULT_SUBMODULE_UPDATE"
    add_link "$SHIVA_BOOT_PATH" "$SHIVA_BOOT_URL" "$DEFAULT_SUBMODULE_BRANCH" "$DEFAULT_SUBMODULE_UPDATE"
    echo "✅ Default Shiva repo links added."
}

links_remove_cmd() {
    echo "🗑️  Removing default Shiva repo links from ${GITMODULES_FILE}..."
    remove_link "$SHIVA_CORE_PATH"
    remove_link "$SHIVA_FW_PATH"
    remove_link "$SHIVA_DB_PATH"
    remove_link "$SHIVA_MODULES_PATH"
    remove_link "$SHIVA_BOOT_PATH"
    echo "✅ Default Shiva repo links removed."
}

main() {
    ensure_git_is_available

    local command="${1:-}"
    shift || true

    case "$command" in
        status)
            status_cmd "$@"
            ;;
        sync)
            sync_cmd "$@"
            ;;
        link-add)
            add_link "$@"
            ;;
        link-remove)
            remove_link "$@"
            ;;
        links-add)
            links_add_cmd "$@"
            ;;
        links-remove)
            links_remove_cmd "$@"
            ;;
        ""|-h|--help|help)
            print_usage
            ;;
        *)
            echo "❌ Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
