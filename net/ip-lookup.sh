#!/usr/bin/env bash
# =====================================================
# IP Intel - Security Tool
# =====================================================

# Source shared libraries
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_SCRIPT_DIR}/../lib/utils.sh"

# Load secrets
[[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"

# ─── Usage ────────────────────────────────────────────
usage() {
    print_header "${NF_SHIELD} IP Intel"
    echo
    print_info  "Usage: ip-intel <ip_address>"
    echo
    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Sources${RESET}"
    draw_box_middle
    draw_box_line "  ${BRIGHT_CYAN}ipinfo.io${RESET}    ${DIM}Ownership, ASN, geolocation${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}whois${RESET}        ${DIM}Registry data${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}AbuseIPDB${RESET}    ${DIM}Reputation & abuse reports${RESET}"
    draw_box_bottom
    echo
    exit 0
}

# ─── Validate IP format ───────────────────────────────
validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if [[ ! "$ip" =~ $regex ]]; then
        print_error "Invalid IP address: $ip"
        exit 1
    fi
}

# ─── Section printer ─────────────────────────────────
print_section() {
    echo
    echo -e "${BRIGHT_MAGENTA}${BOLD}   $1${RESET}"
    print_single_line
}

# ─── ipinfo ───────────────────────────────────────────
fetch_ipinfo() {
    print_loading "Querying ipinfo.io..."

    local raw
    raw=$(curl -s --max-time 8 "https://ipinfo.io/${IP}/json")

    if [[ -z "$raw" ]]; then
        print_error "ipinfo.io: no response"
        return
    fi

    local hostname city region country org timezone
    hostname=$(echo "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hostname','-'))" 2>/dev/null)
    city=$(echo "$raw"     | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('city','-'))" 2>/dev/null)
    region=$(echo "$raw"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('region','-'))" 2>/dev/null)
    country=$(echo "$raw"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('country','-'))" 2>/dev/null)
    org=$(echo "$raw"      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('org','-'))" 2>/dev/null)
    timezone=$(echo "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('timezone','-'))" 2>/dev/null)

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}ipinfo.io${RESET}"
    draw_box_middle
    draw_box_line "  ${BRIGHT_CYAN}Hostname:${RESET}  ${BRIGHT_WHITE}$hostname${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Location:${RESET}  ${BRIGHT_WHITE}$city, $region, $country${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Org/ASN:${RESET}   ${BRIGHT_YELLOW}$org${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Timezone:${RESET}  ${DIM}$timezone${RESET}"
    draw_box_bottom
}

# ─── WHOIS ────────────────────────────────────────────
fetch_whois() {
    print_loading "Querying WHOIS..."

    require_command "whois" "Install with: sudo apt install whois" || return

    local raw
    raw=$(whois "$IP" 2>/dev/null)

    local netname org_name country descr route
    netname=$(echo  "$raw" | grep -Ei "^netname:"   | head -1 | awk -F: '{$1=""; print $0}' | xargs)
    org_name=$(echo "$raw" | grep -Ei "^org-name:|^OrgName:" | head -1 | awk -F: '{$1=""; print $0}' | xargs)
    country=$(echo  "$raw" | grep -Ei "^country:"   | head -1 | awk -F: '{$1=""; print $0}' | xargs)
    descr=$(echo    "$raw" | grep -Ei "^descr:"     | head -1 | awk -F: '{$1=""; print $0}' | xargs)
    route=$(echo    "$raw" | grep -Ei "^route:"     | head -1 | awk -F: '{$1=""; print $0}' | xargs)

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}WHOIS${RESET}"
    draw_box_middle
    [[ -n "$netname"  ]] && draw_box_line "  ${BRIGHT_CYAN}Netname:${RESET}  ${BRIGHT_WHITE}$netname${RESET}"
    [[ -n "$org_name" ]] && draw_box_line "  ${BRIGHT_CYAN}Org:${RESET}      ${BRIGHT_WHITE}$org_name${RESET}"
    [[ -n "$country"  ]] && draw_box_line "  ${BRIGHT_CYAN}Country:${RESET}  ${BRIGHT_WHITE}$country${RESET}"
    [[ -n "$descr"    ]] && draw_box_line "  ${BRIGHT_CYAN}Descr:${RESET}    ${DIM}$descr${RESET}"
    [[ -n "$route"    ]] && draw_box_line "  ${BRIGHT_CYAN}Route:${RESET}    ${DIM}$route${RESET}"
    draw_box_bottom
}

# ─── AbuseIPDB ────────────────────────────────────────
fetch_abuseipdb() {
    if [[ -z "${ABUSEIPDB_KEY:-}" ]]; then
        print_warning "ABUSEIPDB_KEY not set in ~/.secrets — skipping"
        return
    fi

    print_loading "Querying AbuseIPDB..."

    local raw
    raw=$(curl -s --max-time 8 -G "https://api.abuseipdb.com/api/v2/check" \
        --data-urlencode "ipAddress=${IP}" \
        -d "maxAgeInDays=90" \
        -H "Key: ${ABUSEIPDB_KEY}" \
        -H "Accept: application/json")

    if [[ -z "$raw" ]]; then
        print_error "AbuseIPDB: no response"
        return
    fi

    local score reports users isp last_seen is_tor usage_type
    score=$(echo      "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('abuseConfidenceScore','-'))" 2>/dev/null)
    reports=$(echo    "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('totalReports','-'))" 2>/dev/null)
    users=$(echo      "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('numDistinctUsers','-'))" 2>/dev/null)
    isp=$(echo        "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('isp','-'))" 2>/dev/null)
    usage_type=$(echo "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('usageType','-'))" 2>/dev/null)
    last_seen=$(echo  "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('lastReportedAt','-'))" 2>/dev/null)
    is_tor=$(echo     "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d.get('isTor',False))" 2>/dev/null)

    # Color score by severity
    local score_color
    if   [[ "$score" -ge 80 ]] 2>/dev/null; then score_color="${BRIGHT_RED}"
    elif [[ "$score" -ge 40 ]] 2>/dev/null; then score_color="${BRIGHT_YELLOW}"
    else score_color="${BRIGHT_GREEN}"; fi

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}AbuseIPDB${RESET}"
    draw_box_middle
    draw_box_line "  ${BRIGHT_CYAN}Abuse Score:${RESET}  ${score_color}${BOLD}${score}%${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Reports:${RESET}      ${BRIGHT_WHITE}$reports${RESET} ${DIM}from $users distinct users${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}ISP:${RESET}          ${BRIGHT_WHITE}$isp${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Usage Type:${RESET}   ${DIM}$usage_type${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Tor Exit:${RESET}     ${BRIGHT_WHITE}$is_tor${RESET}"
    draw_box_line "  ${BRIGHT_CYAN}Last Report:${RESET}  ${DIM}$last_seen${RESET}"
    draw_box_bottom
}

# ─── Main ─────────────────────────────────────────────
main() {
    [[ -z "$1" ]] && usage

    IP="$1"
    validate_ip "$IP"

    echo
    print_header "${NF_SHIELD} IP Intel — ${BRIGHT_YELLOW}$IP${RESET}"

    print_section "Geolocation & Ownership"
    fetch_ipinfo

    print_section "Registry"
    fetch_whois

    print_section "Reputation"
    fetch_abuseipdb

    echo
    print_success "Done"
    echo
}

main "$@"
