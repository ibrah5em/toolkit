#!/usr/bin/env bash
# =====================================================
# Utility Functions - Toolkit Shared Library
# =====================================================

# Double-source guard
[[ -n "${_TOOLKIT_UTILS_LOADED:-}" ]] && return 0
_TOOLKIT_UTILS_LOADED=1

# Source UI (which sources colors)
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_LIB_DIR}/ui.sh"

# Check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if command exists, print install hint if not, return 1
require_command() {
    local cmd="$1"
    local hint="${2:-}"

    if command_exists "$cmd"; then
        return 0
    fi

    if [[ -n "$hint" ]]; then
        print_error "'$cmd' is not installed. $hint"
    else
        print_error "'$cmd' is not installed."
    fi
    return 1
}

# Validate a name (alphanumeric, hyphens, underscores, must start with letter)
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        print_error "Invalid name: '$name'. Use letters, numbers, hyphens, underscores (must start with a letter)."
        return 1
    fi
    return 0
}

# Prompt y/N before destructive operations
confirm_action() {
    local prompt="${1:-Are you sure?}"
    echo -ne "${BRIGHT_YELLOW}  ${prompt} ${RESET}${DIM}(y/N)${RESET} "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}
