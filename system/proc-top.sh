#!/usr/bin/env bash
# =====================================================
# Proc Top - Top processes by CPU and memory
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# ── Color a percentage ────────────────────────────────
_color_pct() {
    local pct="$1"
    local num="${pct%.*}"
    [ -z "$num" ] && num=0
    if [ "$num" -ge 80 ]; then
        echo -e "${BRIGHT_RED}${pct}%${RESET}"
    elif [ "$num" -ge 40 ]; then
        echo -e "${BRIGHT_YELLOW}${pct}%${RESET}"
    else
        echo -e "${BRIGHT_GREEN}${pct}%${RESET}"
    fi
}

# ── Top by CPU ────────────────────────────────────────
top_cpu() {
    local n="${1:-10}"

    print_header "${NF_COG} Top ${n} Processes by CPU"
    echo

    printf "  ${BRIGHT_CYAN}%-8s %-7s %-7s %-10s %s${RESET}\n" \
        "PID" "CPU%" "MEM%" "User" "Command"
    print_single_line

    ps aux --sort=-%cpu 2>/dev/null | tail -n +2 | head -n "$n" | while read -r user pid cpu mem vsz rss tty stat start time cmd; do
        printf "  ${DIM}%-8s${RESET} %s  %s  ${BRIGHT_WHITE}%-10s${RESET} ${DIM}%.60s${RESET}\n" \
            "$pid" "$(_color_pct "$cpu")" "$(_color_pct "$mem")" "$user" "$cmd"
    done

    echo
}

# ── Top by memory ─────────────────────────────────────
top_mem() {
    local n="${1:-10}"

    print_header "${NF_CUBE} Top ${n} Processes by Memory"
    echo

    printf "  ${BRIGHT_CYAN}%-8s %-7s %-7s %-10s %-10s %s${RESET}\n" \
        "PID" "MEM%" "CPU%" "RSS" "User" "Command"
    print_single_line

    ps aux --sort=-%mem 2>/dev/null | tail -n +2 | head -n "$n" | while read -r user pid cpu mem vsz rss tty stat start time cmd; do
        local rss_h
        rss_h=$(numfmt --to=iec-i --suffix=B "$((rss * 1024))" 2>/dev/null || echo "${rss}K")
        printf "  ${DIM}%-8s${RESET} %s  %s  ${BRIGHT_YELLOW}%-10s${RESET} ${BRIGHT_WHITE}%-10s${RESET} ${DIM}%.50s${RESET}\n" \
            "$pid" "$(_color_pct "$mem")" "$(_color_pct "$cpu")" "$rss_h" "$user" "$cmd"
    done

    echo
}

# ── Docker container resource usage ───────────────────
docker_stats() {
    if ! command_exists docker; then
        print_warning "Docker not installed"
        return
    fi

    local containers
    containers=$(docker ps -q 2>/dev/null)
    if [ -z "$containers" ]; then
        print_info "No running Docker containers"
        return
    fi

    print_header "${NF_DOCKER} Container Resource Usage"
    echo

    printf "  ${BRIGHT_CYAN}%-25s %-10s %-10s %-12s %-12s${RESET}\n" \
        "Container" "CPU%" "MEM%" "MEM Usage" "Net I/O"
    print_single_line

    docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null \
        | while IFS=$'\t' read -r name cpu mem memusage netio; do
            printf "  ${BRIGHT_WHITE}%-25s${RESET} ${BRIGHT_YELLOW}%-10s${RESET} ${BRIGHT_YELLOW}%-10s${RESET} ${DIM}%-12s %-12s${RESET}\n" \
                "$name" "$cpu" "$mem" "$memusage" "$netio"
        done

    echo
}

# ── Summary ───────────────────────────────────────────
summary() {
    print_header "${NF_HEARTBEAT} Process Summary"
    echo

    local total_procs running sleeping
    total_procs=$(ps aux 2>/dev/null | tail -n +2 | wc -l)
    running=$(ps aux 2>/dev/null | awk '$8 ~ /R/ {count++} END {print count+0}')
    sleeping=$(ps aux 2>/dev/null | awk '$8 ~ /S/ {count++} END {print count+0}')

    local cpu_idle mem_total mem_used mem_pct load
    cpu_idle=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $8}' | tr -d '%,')
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    mem_pct=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    load=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}System Load${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Processes:${RESET}    ${BRIGHT_WHITE}$total_procs${RESET} total  ${BRIGHT_GREEN}$running running${RESET}  ${DIM}$sleeping sleeping${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Load avg:${RESET}     ${BRIGHT_WHITE}$load${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Memory:${RESET}       ${BRIGHT_WHITE}${mem_used}${RESET} / ${mem_total}  ($(_color_pct "$mem_pct"))"
    draw_box_bottom

    echo
    top_cpu 5
    top_mem 5

    if command_exists docker && [ -n "$(docker ps -q 2>/dev/null)" ]; then
        docker_stats
    fi
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_HEARTBEAT} Proc Top"
    echo
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "summary"            "Full overview (CPU + mem + docker)"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "cpu [n]"            "Top N processes by CPU (default: 10)"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "mem [n]"            "Top N processes by memory (default: 10)"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "docker"             "Docker container resource usage"
    echo
}

main() {
    local cmd="${1:-summary}"
    shift || true

    case "$cmd" in
        summary|all|s)          summary ;;
        cpu|c)                  top_cpu "$@" ;;
        mem|memory|m|ram)       top_mem "$@" ;;
        docker|containers|d)    docker_stats ;;
        help|--help|-h)         show_help ;;
        *)
            print_error "Unknown command: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
