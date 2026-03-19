#!/usr/bin/env bash
# =====================================================
# Service Status - Quick look at everything running
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# ── Check if a port responds ─────────────────────────
_port_ok() {
    local port="$1"
    (echo >/dev/tcp/localhost/"$port") 2>/dev/null
}

# ── Service check row ────────────────────────────────
_svc_row() {
    local name="$1" icon="$2" check_cmd="$3" url="$4"

    local status color
    if eval "$check_cmd" >/dev/null 2>&1; then
        status="${NF_CHECK} up"
        color="${BRIGHT_GREEN}"
    else
        status="${NF_CROSS} down"
        color="${BRIGHT_RED}"
    fi

    if [ -n "$url" ]; then
        printf "  ${color}%s${RESET}  ${BRIGHT_WHITE}%-20s${RESET}  ${DIM}%s${RESET}\n" \
            "$status" "${icon} ${name}" "$url"
    else
        printf "  ${color}%s${RESET}  ${BRIGHT_WHITE}%-20s${RESET}\n" \
            "$status" "${icon} ${name}"
    fi
}

# ── Main status board ─────────────────────────────────
show_status() {
    print_header "${NF_SERVER} Service Status"
    echo

    # ── Core services ──
    echo -e "  ${BRIGHT_MAGENTA}${BOLD}Core Services${RESET}"
    echo

    _svc_row "Ollama" "${NF_CUBE}" "pgrep -f 'ollama serve'" "http://localhost:11434"

    if command_exists docker && docker ps >/dev/null 2>&1; then
        _svc_row "Docker" "${NF_DOCKER}" "docker ps" ""

        # Check named containers
        local containers=("open-webui:3000" "pihole:80" "nginx:443")
        for entry in "${containers[@]}"; do
            local cname="${entry%%:*}"
            local cport="${entry##*:}"
            if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${cname}$"; then
                _svc_row "$cname" "${NF_DOCKER}" "true" "http://localhost:${cport}"
            fi
        done
    else
        _svc_row "Docker" "${NF_DOCKER}" "false" ""
    fi

    echo

    # ── Network services ──
    echo -e "  ${BRIGHT_MAGENTA}${BOLD}Ports${RESET}"
    echo

    local known_ports=(
        "22:SSH"
        "80:HTTP"
        "443:HTTPS"
        "3000:OpenWebUI"
        "5000:Dev Server"
        "8080:Alt HTTP"
        "11434:Ollama API"
    )

    for entry in "${known_ports[@]}"; do
        local port="${entry%%:*}"
        local label="${entry##*:}"

        if _port_ok "$port"; then
            printf "  ${BRIGHT_GREEN}${NF_CHECK}${RESET}  ${BRIGHT_WHITE}%-6s${RESET}  ${BRIGHT_CYAN}%s${RESET}\n" \
                ":$port" "$label"
        fi
    done

    local extra
    extra=$(ss -tlnp 2>/dev/null | tail -n +2 | awk '{print $4}' | grep -oP ':\K[0-9]+' | sort -un)
    local known_list
    known_list=$(printf '%s\n' "${known_ports[@]}" | cut -d: -f1)

    local extra_count=0
    while read -r port; do
        [ -z "$port" ] && continue
        echo "$known_list" | grep -qx "$port" && continue

        local proc
        proc=$(ss -tlnp "sport = :$port" 2>/dev/null | grep -oP 'users:\(\("\K[^"]+' | head -1)
        [ -z "$proc" ] && proc="unknown"

        printf "  ${BRIGHT_GREEN}${NF_CHECK}${RESET}  ${BRIGHT_WHITE}%-6s${RESET}  ${DIM}%s${RESET}\n" \
            ":$port" "$proc"
        ((extra_count++))
    done <<< "$extra"

    echo

    # ── System at a glance ──
    echo -e "  ${BRIGHT_MAGENTA}${BOLD}System${RESET}"
    echo

    local cpu_pct mem_pct disk_pct
    cpu_pct=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{printf "%.0f", 100 - $8}')
    mem_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    disk_pct=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    _gauge() {
        local label="$1" val="$2" icon="$3"
        local color="${BRIGHT_GREEN}"
        [ "$val" -ge 70 ] && color="${BRIGHT_YELLOW}"
        [ "$val" -ge 90 ] && color="${BRIGHT_RED}"

        local bar_len=$(( val / 5 ))
        [ "$bar_len" -gt 20 ] && bar_len=20
        local bar_filled=$(printf '█%.0s' $(seq 1 "$bar_len") 2>/dev/null)
        local bar_empty=$(printf '░%.0s' $(seq 1 $((20 - bar_len))) 2>/dev/null)

        printf "  ${BRIGHT_WHITE}%s  %-6s${RESET} ${color}%s${RESET}${DIM}%s${RESET} ${color}%3d%%${RESET}\n" \
            "$icon" "$label" "$bar_filled" "$bar_empty" "$val"
    }

    _gauge "CPU" "${cpu_pct:-0}" "${NF_COG}"
    _gauge "RAM" "${mem_pct:-0}" "${NF_CUBE}"
    _gauge "Disk" "${disk_pct:-0}" "${NF_FLOPPY}"

    echo
    echo -e "  ${DIM}Uptime: $(uptime -p | sed 's/up //')${RESET}"
    echo
}

# ── Watch mode (refresh every N seconds) ──────────────
watch_status() {
    local interval="${1:-5}"
    print_info "Refreshing every ${interval}s (Ctrl+C to stop)"
    sleep 1

    while true; do
        clear
        show_status
        echo -e "  ${DIM}Next refresh in ${interval}s...${RESET}"
        sleep "$interval"
    done
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_SERVER} Service Status"
    echo
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "status"             "Show all services, ports, and system stats"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "watch [seconds]"    "Auto-refresh dashboard (default: 5s)"
    echo
}

main() {
    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
        status|s|show)      show_status ;;
        watch|w|live)       watch_status "$@" ;;
        help|--help|-h)     show_help ;;
        *)
            print_error "Unknown command: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
