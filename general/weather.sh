#!/usr/bin/env bash
# =====================================================
# Weather - Terminal weather report via wttr.in
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command curl "Install with: sudo apt install curl" || exit 1

DEFAULT_CITY="Amsterdam"

# ── Current conditions ────────────────────────────────
current() {
    local city="${1:-$DEFAULT_CITY}"

    print_header "${NF_GLOBE} Weather: ${city}"
    echo

    print_loading "Fetching..."
    echo

    curl -s "wttr.in/${city}?format=3" 2>/dev/null
    echo
    curl -s "wttr.in/${city}?0QT" 2>/dev/null
    echo
}

# ── Full forecast ─────────────────────────────────────
forecast() {
    local city="${1:-$DEFAULT_CITY}"

    print_header "${NF_GLOBE} Forecast: ${city}"
    echo

    print_loading "Fetching 3-day forecast..."
    echo

    curl -s "wttr.in/${city}?QT" 2>/dev/null
    echo
}

# ── Compact one-liner ─────────────────────────────────
oneliner() {
    local city="${1:-$DEFAULT_CITY}"
    curl -s "wttr.in/${city}?format=%l:+%c+%t+%h+%w" 2>/dev/null
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_GLOBE} Weather"
    echo
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "now [city]"         "Current weather (default: ${DEFAULT_CITY})"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "forecast [city]"    "3-day forecast"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "brief [city]"       "Compact one-line output"
    echo
}

main() {
    local cmd="${1:-now}"
    shift || true

    case "$cmd" in
        now|current|c|today)    current "$@" ;;
        forecast|fc|f|week)     forecast "$@" ;;
        brief|one|1|oneliner)   oneliner "$@" ;;
        help|--help|-h)         show_help ;;
        *)
            # Treat unknown as city name
            current "$cmd" "$@"
            ;;
    esac
}

main "$@"
