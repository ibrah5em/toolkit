#!/usr/bin/env bash
# =====================================================
# Port Manager - List, find, and kill by port
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# Internal: get PID listening on a port
_pid_on_port() {
    local port="$1"
    if command_exists lsof; then
        lsof -ti :"$port" 2>/dev/null | head -n 1
    elif command_exists ss; then
        ss -tlnp "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -n 1
    fi
}

# List all listening ports
list_ports() {
    print_header "${NF_PLUG} Listening Ports"
    echo

    if ! command_exists ss && ! command_exists netstat; then
        print_error "Neither 'ss' nor 'netstat' found. Install: sudo apt install iproute2"
        exit 1
    fi

    printf "  ${BRIGHT_CYAN}%-8s %-8s %-8s %s${RESET}\n" "Proto" "Port" "PID" "Process"
    print_single_line

    if command_exists ss; then
        ss -tlnp 2>/dev/null | tail -n +2 | while IFS= read -r line; do
            local addr port pid proc
            addr=$(echo "$line" | awk '{print $4}')
            port="${addr##*:}"
            pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | head -n 1)
            if [ -n "$pid" ]; then
                proc=$(ps -p "$pid" -o comm= 2>/dev/null || echo "?")
            else
                pid="-"; proc="-"
            fi
            printf "  ${BRIGHT_GREEN}%-8s${RESET} ${BRIGHT_WHITE}%-8s${RESET} ${DIM}%-8s${RESET} ${BRIGHT_YELLOW}%s${RESET}\n" \
                "tcp" "$port" "$pid" "$proc"
        done
    else
        netstat -tlnp 2>/dev/null | tail -n +3 | awk '{print "  " $1 "\t" $4 "\t" $7}' | \
            sed 's/.*://'
    fi

    echo
}

# Show what is using a specific port
find_port() {
    local port="$1"
    if [ -z "$port" ]; then
        print_error "Usage: port-manager find <port>"
        exit 1
    fi

    print_header "${NF_PLUG} Port ${port}"
    echo

    local pid
    pid=$(_pid_on_port "$port")

    if [ -z "$pid" ]; then
        print_info "Nothing is listening on port $port"
        echo
        return
    fi

    local proc cmd
    proc=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
    cmd=$(ps -p "$pid" -o args= 2>/dev/null | head -c 80 || echo "?")

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Process on port ${port}${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  PID:${RESET}     ${BRIGHT_GREEN}${pid}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Name:${RESET}    ${BRIGHT_YELLOW}${proc}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Command:${RESET} ${DIM}${cmd}${RESET}"
    draw_box_bottom
    echo
}

# Kill process listening on a port
kill_port() {
    local port="$1"
    if [ -z "$port" ]; then
        print_error "Usage: port-manager kill <port>"
        exit 1
    fi

    local pid
    pid=$(_pid_on_port "$port")

    if [ -z "$pid" ]; then
        print_info "Nothing found on port $port"
        return
    fi

    local proc
    proc=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")

    echo
    draw_box_top
    draw_box_line "${BRIGHT_RED}${BOLD}Kill Process${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Port:${RESET}    $port"
    draw_box_line "${BRIGHT_CYAN}  PID:${RESET}     $pid"
    draw_box_line "${BRIGHT_CYAN}  Process:${RESET} $proc"
    draw_box_bottom
    echo

    if confirm_action "Kill PID $pid ($proc)?"; then
        if kill "$pid" 2>/dev/null; then
            print_success "Process $pid killed"
        else
            print_warning "kill failed, trying with sudo..."
            sudo kill "$pid" 2>/dev/null && print_success "Process killed" || print_error "Could not kill PID $pid"
        fi
    else
        print_info "Cancelled"
    fi
    echo
}

show_help() {
    print_header "${NF_PLUG} Port Manager"
    echo
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "list"          "Show all listening ports with PIDs"
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "find <port>"   "Show which process is using a port"
    printf "  ${BRIGHT_GREEN}%-18s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "kill <port>"   "Kill the process listening on a port"
    echo
}

main() {
    local cmd="${1:-list}"
    shift || true

    case "$cmd" in
        list|ls|l)      list_ports ;;
        find|who|f)     find_port "$@" ;;
        kill|stop|k)    kill_port "$@" ;;
        help|--help|-h) show_help ;;
        *)
            print_error "Unknown command: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
