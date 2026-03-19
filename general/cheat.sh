#!/usr/bin/env bash
# =====================================================
# Cheat - Quick command reference via cheat.sh
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command curl "Install with: sudo apt install curl" || exit 1

CHEAT_CACHE="$HOME/.cache/toolkit/cheat"
mkdir -p "$CHEAT_CACHE"

# ── Look up a command ─────────────────────────────────
lookup() {
    local query="$*"

    if [ -z "$query" ]; then
        print_error "Usage: cheat <command>"
        echo
        print_info "Examples: ${BOLD}cheat tar${RESET}${BRIGHT_CYAN}, ${BOLD}cheat rsync${RESET}${BRIGHT_CYAN}, ${BOLD}cheat find${RESET}"
        return 1
    fi

    # Sanitize query for filename
    local cache_key
    cache_key=$(echo "$query" | tr ' /' '_')
    local cache_file="${CHEAT_CACHE}/${cache_key}"

    # Use cache if fresh (< 24h)
    if [ -f "$cache_file" ] && [ "$(find "$cache_file" -mmin -1440 2>/dev/null)" ]; then
        cat "$cache_file"
        echo
        echo -e "  ${DIM}(cached — cheat clear to refresh)${RESET}"
        echo
        return
    fi

    print_loading "Looking up ${BOLD}$query${RESET}${BRIGHT_BLUE}..."

    local result
    result=$(curl -s "cheat.sh/${query}?style=rrt" 2>/dev/null)

    if [ -z "$result" ]; then
        print_error "No results for: $query"
        return 1
    fi

    echo "$result" > "$cache_file"
    echo
    echo "$result"
    echo
}

# ── Search cheat.sh ───────────────────────────────────
search() {
    local query="$*"

    if [ -z "$query" ]; then
        print_error "Usage: cheat search <keyword>"
        return 1
    fi

    print_header "${NF_SEARCH} Searching: ${query}"
    echo

    curl -s "cheat.sh/~${query}" 2>/dev/null | head -40
    echo
}

# ── Language-specific cheats ──────────────────────────
lang() {
    local lang="$1"
    local topic="$2"

    if [ -z "$lang" ] || [ -z "$topic" ]; then
        print_error "Usage: cheat lang <language> <topic>"
        echo
        print_info "Example: ${BOLD}cheat lang python list comprehension${RESET}"
        return 1
    fi

    shift
    local full_topic="$*"

    print_loading "Looking up ${BOLD}${lang}/${full_topic}${RESET}${BRIGHT_BLUE}..."

    local result
    result=$(curl -s "cheat.sh/${lang}/${full_topic// /+}" 2>/dev/null)

    echo
    echo "$result"
    echo
}

# ── Clear cache ───────────────────────────────────────
clear_cache() {
    local count
    count=$(find "$CHEAT_CACHE" -type f 2>/dev/null | wc -l)

    rm -rf "${CHEAT_CACHE:?}"/*
    print_success "Cleared $count cached cheatsheet(s)"
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_BOOK} Cheat"
    echo
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "<command>"                 "Look up a command (e.g., cheat tar)"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "search <keyword>"         "Search across all cheatsheets"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "lang <lang> <topic>"      "Language-specific (python, js, go...)"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "clear"                    "Clear local cache"
    echo
    echo -e "  ${DIM}Powered by cheat.sh — results cached for 24h${RESET}"
    echo
}

main() {
    local cmd="${1:---help}"
    shift || true

    case "$cmd" in
        search|find|s)      search "$@" ;;
        lang|l)             lang "$@" ;;
        clear|clean)        clear_cache ;;
        help|--help|-h)     show_help ;;
        *)                  lookup "$cmd" "$@" ;;
    esac
}

main "$@"
