#!/usr/bin/env bash
# =====================================================
# QR - Generate QR codes in the terminal
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command curl "Install with: sudo apt install curl" || exit 1

# ── Display QR in terminal ────────────────────────────
generate() {
    local text="$*"

    if [ -z "$text" ]; then
        print_error "Usage: qr <text or url>"
        return 1
    fi

    print_header "${NF_NETWORK} QR Code"
    echo -e "  ${DIM}Content: ${text}${RESET}"
    echo

    curl -s "qrenco.de/${text}" 2>/dev/null
    echo
}

# ── Common shortcuts ──────────────────────────────────
wifi() {
    local ssid="$1"
    local pass="$2"
    local security="${3:-WPA}"

    if [ -z "$ssid" ] || [ -z "$pass" ]; then
        print_error "Usage: qr wifi <ssid> <password> [WPA|WEP|nopass]"
        return 1
    fi

    local wifi_string="WIFI:T:${security};S:${ssid};P:${pass};;"

    print_header "${NF_GLOBE} WiFi QR Code"
    echo -e "  ${DIM}SSID: ${ssid}  Security: ${security}${RESET}"
    echo

    curl -s "qrenco.de/${wifi_string}" 2>/dev/null
    echo
    print_info "Scan this to connect to ${BOLD}${ssid}${RESET}"
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_NETWORK} QR"
    echo
    printf "  ${BRIGHT_GREEN}%-30s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "<text or url>"              "Generate QR code for any text/URL"
    printf "  ${BRIGHT_GREEN}%-30s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "wifi <ssid> <pass> [type]"  "Generate WiFi QR (WPA/WEP/nopass)"
    echo
    echo -e "  ${DIM}Examples:${RESET}"
    echo -e "  ${DIM}  tool qr https://example.com${RESET}"
    echo -e "  ${DIM}  tool qr wifi MyNetwork secret123${RESET}"
    echo
}

main() {
    local cmd="${1:---help}"
    shift || true

    case "$cmd" in
        wifi|w)             wifi "$@" ;;
        help|--help|-h)     show_help ;;
        *)                  generate "$cmd" "$@" ;;
    esac
}

main "$@"
