#!/bin/env bash

# update-fivem.sh - Automatically update FIVEM_NUM in Dockerfile
# Usage: ./update-fivem.sh [new_fivem_num]
# If no argument provided, it will fetch the latest version from FiveM API

set -e

DOCKERFILE="Dockerfile"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_PATH="$SCRIPT_DIR/../runtimes/alpine-3/$DOCKERFILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate FIVEM_NUM format (should be numeric)
validate_fivem_num() {
    local num="$1"
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        print_error "Invalid FIVEM_NUM format: $num (should be numeric)"
        return 1
    fi
    return 0
}

# Function to get current FIVEM_NUM from Dockerfile
get_current_fivem_num() {
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        print_error "Dockerfile not found at: $DOCKERFILE_PATH"
        exit 1
    fi

    local current_num=$(grep "^ARG FIVEM_NUM=" "$DOCKERFILE_PATH" | cut -d'=' -f2)
    echo "$current_num"
}

# Function to fetch latest FiveM version and full version string from artifacts page
fetch_latest_fivem_info() {
    print_info "Fetching latest FiveM version from artifacts page..." >&2

    local artifacts_url="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
    local temp_file="/tmp/fivem_artifacts_$$.html"

    # Known latest version as fallback (update this periodically)
    local known_latest_num="17000"
    local known_latest_ver="17000-e0ef7490f76a24505b8bac7065df2b7075e610ba"

    # Download the artifacts page
    if command -v curl >/dev/null 2>&1; then
        print_info "Using curl to fetch artifacts page..." >&2
        if curl -s --max-time 10 --connect-timeout 5 "$artifacts_url" -o "$temp_file" 2>/dev/null; then
            # Check if file was actually downloaded and has content
            if [[ -f "$temp_file" ]] && [[ -s "$temp_file" ]]; then
                # Extract the latest version from href attribute
                # Look for pattern like href="./17000-e0ef7490f76a24505b8bac7065df2b7075e610ba/fx.tar.xz"
                local latest_ver=$(grep -oE 'href="\./([0-9]+-[a-f0-9]{40})/fx\.tar\.xz"' "$temp_file" | head -1 | sed 's/href="\.\///;s/\/fx\.tar\.xz"//')

                # Clean up temp file
                rm -f "$temp_file"

                if [[ -n "$latest_ver" ]] && [[ "$latest_ver" =~ ^[0-9]+-[a-f0-9]{40}$ ]]; then
                    local latest_num=$(echo "$latest_ver" | cut -d'-' -f1)
                    print_info "Latest FiveM version found: $latest_num" >&2
                    print_info "Latest FiveM version string: $latest_ver" >&2
                    echo "$latest_num|$latest_ver"
                    return 0
                fi
            fi
        fi
        rm -f "$temp_file"
    elif command -v wget >/dev/null 2>&1; then
        print_info "Using wget to fetch artifacts page..." >&2
        if wget -q --timeout=10 --tries=1 "$artifacts_url" -O "$temp_file" 2>/dev/null; then
            # Similar processing as curl
            if [[ -f "$temp_file" ]] && [[ -s "$temp_file" ]]; then
                local latest_ver=$(grep -oE 'href="\./([0-9]+-[a-f0-9]{40})/fx\.tar\.xz"' "$temp_file" | head -1 | sed 's/href="\.\///;s/\/fx\.tar\.xz"//')
                rm -f "$temp_file"

                if [[ -n "$latest_ver" ]] && [[ "$latest_ver" =~ ^[0-9]+-[a-f0-9]{40}$ ]]; then
                    local latest_num=$(echo "$latest_ver" | cut -d'-' -f1)
                    print_info "Latest FiveM version found: $latest_num" >&2
                    print_info "Latest FiveM version string: $latest_ver" >&2
                    echo "$latest_num|$latest_ver"
                    return 0
                fi
            fi
        fi
        rm -f "$temp_file"
    fi

    # Fallback to known latest version
    print_warning "Could not fetch latest version from artifacts page" >&2
    print_warning "Network issue, server unavailable, or parsing failed" >&2
    print_info "Using known latest version as fallback: $known_latest_num" >&2
    print_warning "Note: This may not be the absolute latest version" >&2
    print_warning "Check https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ for newest version" >&2

    echo "$known_latest_num|$known_latest_ver"
    return 0
}

# Function to fetch just the latest FiveM number (for backward compatibility)
fetch_latest_fivem_num() {
    local info=$(fetch_latest_fivem_info)
    echo "$info" | cut -d'|' -f1
}

# Function to update FIVEM_NUM in Dockerfile
update_fivem_num() {
    local new_num="$1"
    local current_num="$2"

    if [[ "$new_num" == "$current_num" ]]; then
        print_info "FIVEM_NUM is already set to $new_num. No update needed."
        return 0
    fi

    # Create backup
    local backup_file="${DOCKERFILE_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DOCKERFILE_PATH" "$backup_file"
    print_info "Created backup: $backup_file"

    # Update the FIVEM_NUM line
    if sed -i.tmp "s/^ARG FIVEM_NUM=.*/ARG FIVEM_NUM=$new_num/" "$DOCKERFILE_PATH"; then
        rm -f "${DOCKERFILE_PATH}.tmp" 2>/dev/null || true
        print_info "Successfully updated FIVEM_NUM from $current_num to $new_num"

        # Show the updated line
        echo ""
        print_info "Updated line in Dockerfile:"
        grep "^ARG FIVEM_NUM=" "$DOCKERFILE_PATH"
        echo ""

        return 0
    else
        print_error "Failed to update Dockerfile"
        # Restore from backup
        cp "$backup_file" "$DOCKERFILE_PATH"
        print_info "Restored from backup"
        return 1
    fi
}

# Function to update FIVEM_VER automatically
update_fivem_ver() {
    local new_ver="$1"

    if [[ -z "$new_ver" ]]; then
        print_warning "No FIVEM_VER provided, skipping FIVEM_VER update"
        return 0
    fi

    print_info "Updating FIVEM_VER..."

    # Get current FIVEM_VER
    local current_ver_line=$(grep "^ARG FIVEM_VER=" "$DOCKERFILE_PATH")
    local current_ver=$(echo "$current_ver_line" | cut -d'=' -f2)

    if [[ "$new_ver" == "$current_ver" ]]; then
        print_info "FIVEM_VER is already set to $new_ver. No update needed."
        return 0
    fi

    # Update the FIVEM_VER line
    if sed -i.tmp "s/^ARG FIVEM_VER=.*/ARG FIVEM_VER=$new_ver/" "$DOCKERFILE_PATH"; then
        rm -f "${DOCKERFILE_PATH}.tmp" 2>/dev/null || true
        print_info "Successfully updated FIVEM_VER from $current_ver to $new_ver"

        # Show the updated line
        echo ""
        print_info "Updated FIVEM_VER line in Dockerfile:"
        grep "^ARG FIVEM_VER=" "$DOCKERFILE_PATH"
        echo ""

        return 0
    else
        print_error "Failed to update FIVEM_VER in Dockerfile"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [FIVEM_NUM|--latest]"
    echo ""
    echo "Updates the FIVEM_NUM and FIVEM_VER in Dockerfile"
    echo ""
    echo "Arguments:"
    echo "  FIVEM_NUM    The new FiveM version number (numeric)"
    echo "  --latest     Automatically fetch and update to latest version"
    echo ""
    echo "Examples:"
    echo "  $0 12872      # Update to specific version (FIVEM_VER not updated)"
    echo "  $0 --latest   # Fetch and update both FIVEM_NUM and FIVEM_VER"
    echo "  $0            # Fetch and update both FIVEM_NUM and FIVEM_VER automatically"
    echo ""
    echo "The script will:"
    echo "  - Create a backup of the current Dockerfile"
    echo "  - Update the FIVEM_NUM value"
    echo "  - Update the FIVEM_VER value (when auto-fetching)"
    echo "  - Show a summary of changes"
}

# Main script logic
main() {
    print_info "FiveM Dockerfile Updater"
    echo ""

    # Check if Dockerfile exists
    if [[ ! -f "$DOCKERFILE_PATH" ]]; then
        print_error "Dockerfile not found at: $DOCKERFILE_PATH"
        exit 1
    fi

    # Get current FIVEM_NUM
    local current_num=$(get_current_fivem_num)
    print_info "Current FIVEM_NUM: $current_num"

    # Determine new FIVEM_NUM and FIVEM_VER
    local new_num=""
    local new_ver=""
    if [[ $# -eq 0 ]]; then
        # No arguments - fetch latest
        print_info "No version specified, attempting to fetch latest version..."
        local fivem_info
        if ! fivem_info=$(fetch_latest_fivem_info); then
            print_error "Auto-fetch failed. Please specify version manually."
            print_warning "Example: ./update-fivem.sh 19413"
            exit 1
        fi
        new_num=$(echo "$fivem_info" | cut -d'|' -f1)
        new_ver=$(echo "$fivem_info" | cut -d'|' -f2)
    elif [[ $# -eq 1 ]]; then
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            show_usage
            exit 0
        elif [[ "$1" == "--latest" ]]; then
            print_info "Fetching latest version explicitly..."
            local fivem_info
            if ! fivem_info=$(fetch_latest_fivem_info); then
                exit 1
            fi
            new_num=$(echo "$fivem_info" | cut -d'|' -f1)
            new_ver=$(echo "$fivem_info" | cut -d'|' -f2)
        else
            new_num="$1"
            # For manual version input, we don't have the hash, so skip FIVEM_VER update
            new_ver=""
        fi
    else
        print_error "Too many arguments"
        show_usage
        exit 1
    fi

    # Validate new FIVEM_NUM
    if ! validate_fivem_num "$new_num"; then
        exit 1
    fi

    print_info "New FIVEM_NUM: $new_num"
    if [[ -n "$new_ver" ]]; then
        print_info "New FIVEM_VER: $new_ver"
    fi
    echo ""

    # Update FIVEM_NUM
    if update_fivem_num "$new_num" "$current_num"; then
        # Update FIVEM_VER if we have the full version string
        if [[ -n "$new_ver" ]]; then
            update_fivem_ver "$new_ver"
        else
            print_warning "FIVEM_VER not updated (manual version specified)"
            print_warning "You may need to update FIVEM_VER manually with the correct hash"
            print_warning "Check https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ for the correct version string"
        fi
        print_info "Update completed successfully!"
    else
        print_error "Update failed!"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
