#!/usr/bin/env bash
# =====================================================
# Configuration Loading - Toolkit Shared Library
# =====================================================

# Double-source guard
[[ -n "${_TOOLKIT_CONFIG_LOADED:-}" ]] && return 0
_TOOLKIT_CONFIG_LOADED=1

# Auto-detect SCRIPTS_DIR from this file's location
_CONFIG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "${_CONFIG_LIB_DIR}")}"

# Whitelisted config keys
_TOOLKIT_CONFIG_KEYS="SCRIPTS_DIR PROJECTS_DIR NOTES_DIR"

# Load config from a file (safe key=value parsing)
_load_config_file() {
    local config_file="$1"
    [[ -f "$config_file" ]] || return 1

    while IFS='=' read -r key value; do
        # Skip comments and blank lines
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Remove surrounding quotes
        value="${value#\"}" ; value="${value%\"}"
        value="${value#\'}" ; value="${value%\'}"

        # Expand ~ and $HOME
        value="${value/#\~/$HOME}"
        value="${value/\$HOME/$HOME}"

        # Only set whitelisted keys (and only if not already set in env)
        for allowed in $_TOOLKIT_CONFIG_KEYS; do
            if [[ "$key" == "$allowed" ]]; then
                # Environment takes precedence
                if [[ -z "${!key:-}" ]]; then
                    export "$key=$value"
                fi
                break
            fi
        done
    done < "$config_file"
}

# Config search order: $TOOLKIT_CONFIG > ~/.config/toolkit/config > config/toolkit.conf
if [[ -n "${TOOLKIT_CONFIG:-}" ]]; then
    _load_config_file "$TOOLKIT_CONFIG"
elif [[ -f "$HOME/.config/toolkit/config" ]]; then
    _load_config_file "$HOME/.config/toolkit/config"
elif [[ -f "${SCRIPTS_DIR}/config/toolkit.conf" ]]; then
    _load_config_file "${SCRIPTS_DIR}/config/toolkit.conf"
fi

# Ensure SCRIPTS_DIR is exported
export SCRIPTS_DIR
