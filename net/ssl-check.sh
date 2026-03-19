#!/usr/bin/env bash
# =====================================================
# SSL Check - Certificate expiry & health for domains
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command openssl "Install with: sudo apt install openssl" || exit 1

# ── Default domains (your sites) ─────────────────────
DEFAULT_DOMAINS=(
    "example.com"
)

# ── Check a single domain ────────────────────────────
_check_domain() {
    local domain="$1"
    local port="${2:-443}"

    local cert_info
    cert_info=$(echo | openssl s_client -servername "$domain" -connect "${domain}:${port}" 2>/dev/null)

    if [ -z "$cert_info" ]; then
        printf "  ${BRIGHT_RED}${NF_CROSS}  %-35s${RESET} ${BRIGHT_RED}Connection failed${RESET}\n" "$domain"
        return 1
    fi

    local expiry issuer subject
    expiry=$(echo "$cert_info" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    issuer=$(echo "$cert_info" | openssl x509 -noout -issuer 2>/dev/null | sed 's/.*O = //' | cut -d, -f1)
    subject=$(echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null | sed 's/.*CN = //')

    if [ -z "$expiry" ]; then
        printf "  ${BRIGHT_RED}${NF_CROSS}  %-35s${RESET} ${BRIGHT_RED}No certificate found${RESET}\n" "$domain"
        return 1
    fi

    # Calculate days until expiry
    local expiry_epoch now_epoch days_left
    expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    # Color by urgency
    local color="${BRIGHT_GREEN}"
    local status="valid"
    if [ "$days_left" -le 0 ]; then
        color="${BRIGHT_RED}"; status="EXPIRED"
    elif [ "$days_left" -le 7 ]; then
        color="${BRIGHT_RED}"; status="critical"
    elif [ "$days_left" -le 30 ]; then
        color="${BRIGHT_YELLOW}"; status="warning"
    fi

    printf "  ${BRIGHT_GREEN}${NF_CHECK}  %-35s${RESET} ${color}%3d days${RESET}  ${DIM}%-20s  %s${RESET}\n" \
        "$domain" "$days_left" "$issuer" "$(date -d "$expiry" '+%Y-%m-%d')"
}

# ── Check all domains ────────────────────────────────
check_all() {
    local domains=("$@")
    [ ${#domains[@]} -eq 0 ] && domains=("${DEFAULT_DOMAINS[@]}")

    print_header "${NF_LOCK} SSL Certificate Check"
    echo

    printf "  ${BRIGHT_CYAN}   %-35s %-10s  %-20s  %s${RESET}\n" \
        "Domain" "Expiry" "Issuer" "Date"
    print_single_line

    local failed=0
    for domain in "${domains[@]}"; do
        _check_domain "$domain" || ((failed++))
    done

    echo

    if [ "$failed" -gt 0 ]; then
        print_warning "$failed domain(s) have issues"
    else
        print_success "All certificates healthy"
    fi
    echo
}

# ── Detailed info for one domain ─────────────────────
inspect() {
    local domain="$1"
    if [ -z "$domain" ]; then
        print_error "Usage: ssl-check inspect <domain>"
        exit 1
    fi

    print_header "${NF_SEARCH} SSL Details: ${domain}"
    echo

    print_loading "Connecting to ${domain}:443..."

    local cert_info
    cert_info=$(echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null)

    if [ -z "$cert_info" ]; then
        print_error "Could not connect to $domain"
        return 1
    fi

    local subject issuer serial expiry_date start_date san

    subject=$(echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
    issuer=$(echo "$cert_info" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
    serial=$(echo "$cert_info" | openssl x509 -noout -serial 2>/dev/null | cut -d= -f2)
    expiry_date=$(echo "$cert_info" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    start_date=$(echo "$cert_info" | openssl x509 -noout -startdate 2>/dev/null | cut -d= -f2)
    san=$(echo "$cert_info" | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oP 'DNS:[^ ,]+' | sed 's/DNS://g' | tr '\n' ', ' | sed 's/,$//')

    local expiry_epoch now_epoch days_left
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    echo
    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Certificate Details${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Subject:${RESET}    ${BRIGHT_WHITE}$subject${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Issuer:${RESET}     ${DIM}$issuer${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Serial:${RESET}     ${DIM}$serial${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Valid from:${RESET}  ${BRIGHT_WHITE}$start_date${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Expires:${RESET}    ${BRIGHT_YELLOW}$expiry_date${RESET} ${BOLD}(${days_left} days)${RESET}"
    [ -n "$san" ] && draw_box_line "${BRIGHT_CYAN}  SANs:${RESET}       ${DIM}$san${RESET}"
    draw_box_bottom
    echo

    # TLS version test
    echo -e "  ${BRIGHT_MAGENTA}${BOLD}Protocol Support${RESET}"
    echo
    for proto in tls1_2 tls1_3; do
        local label="${proto/tls1_/TLS 1.}"
        if echo | openssl s_client -"$proto" -connect "${domain}:443" 2>/dev/null | grep -q "Protocol.*TLSv"; then
            echo -e "  ${BRIGHT_GREEN}  ${NF_CHECK} $label${RESET}"
        else
            echo -e "  ${BRIGHT_RED}  ${NF_CROSS} $label${RESET}"
        fi
    done
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_LOCK} SSL Check"
    echo
    printf "  ${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "check [domain ...]"     "Check cert expiry (default: your sites)"
    printf "  ${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "inspect <domain>"       "Detailed cert info + TLS protocol test"
    echo
    echo -e "  ${DIM}Default domains: ${DEFAULT_DOMAINS[*]}${RESET}"
    echo
}

main() {
    local cmd="${1:-check}"
    shift || true

    case "$cmd" in
        check|c|list|ls)        check_all "$@" ;;
        inspect|info|i|detail)  inspect "$@" ;;
        help|--help|-h)         show_help ;;
        *)
            # Treat bare argument as a domain to check
            check_all "$cmd" "$@"
            ;;
    esac
}

main "$@"
