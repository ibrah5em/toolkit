#!/usr/bin/env bash
# =====================================================
# System Health Check
# Monitor all critical services and resources
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# Status counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

check_status() {
    local name="$1"
    local status="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    printf "  %-30s" "$name"

    case "$status" in
        "pass")
            echo -e "${BRIGHT_GREEN} OK${RESET}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "fail")
            echo -e "${BRIGHT_RED} FAILED${RESET}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "warning")
            echo -e "${BRIGHT_YELLOW} WARNING${RESET}"
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
    esac
}

# Check Ollama service
check_ollama() {
    if pgrep -f "ollama serve" > /dev/null 2>&1; then
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            check_status "Ollama Service" "pass"

            local model_count=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
            if [ "$model_count" -gt 0 ]; then
                echo -e "    ${CYAN}└─ Models installed: ${model_count}${RESET}"
            fi
        else
            check_status "Ollama Service" "warning"
            echo -e "    ${YELLOW}└─ Running but not responding${RESET}"
        fi
    else
        check_status "Ollama Service" "fail"
    fi
}

# Check Docker
check_docker() {
    if command_exists docker; then
        if docker ps > /dev/null 2>&1; then
            check_status "Docker Service" "pass"

            local running=$(docker ps -q | wc -l)
            local total=$(docker ps -a -q | wc -l)
            echo -e "    ${CYAN}└─ Containers: ${running} running / ${total} total${RESET}"
        else
            check_status "Docker Service" "fail"
        fi
    else
        check_status "Docker Service" "fail"
        echo -e "    ${RED}└─ Not installed${RESET}"
    fi
}

# Check OpenWebUI
check_openwebui() {
    if docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
        local health=$(docker inspect --format='{{.State.Health.Status}}' open-webui 2>/dev/null)

        if [ "$health" = "healthy" ]; then
            check_status "OpenWebUI Container" "pass"

            if curl -s http://localhost:3000 > /dev/null 2>&1; then
                echo -e "    ${CYAN}└─ Web interface responding${RESET}"
            fi
        elif [ "$health" = "starting" ]; then
            check_status "OpenWebUI Container" "warning"
            echo -e "    ${YELLOW}└─ Still starting up${RESET}"
        else
            check_status "OpenWebUI Container" "warning"
            echo -e "    ${YELLOW}└─ Health status: ${health}${RESET}"
        fi
    else
        check_status "OpenWebUI Container" "fail"
    fi
}

# Check disk space
check_disk_space() {
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$usage" -lt 80 ]; then
        check_status "Disk Space (/)" "pass"
        echo -e "    ${CYAN}└─ ${usage}% used${RESET}"
    elif [ "$usage" -lt 90 ]; then
        check_status "Disk Space (/)" "warning"
        echo -e "    ${YELLOW}└─ ${usage}% used (consider cleanup)${RESET}"
    else
        check_status "Disk Space (/)" "fail"
        echo -e "    ${RED}└─ ${usage}% used (critical!)${RESET}"
    fi

    if [ -d "$HOME/.ollama/models" ]; then
        local ollama_size=$(du -sh "$HOME/.ollama/models" 2>/dev/null | cut -f1)
        echo -e "    ${CYAN}└─ Ollama models: ${ollama_size}${RESET}"
    fi
}

# Check memory usage
check_memory() {
    local mem_usage=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')

    if [ "$mem_usage" -lt 80 ]; then
        check_status "Memory Usage" "pass"
        echo -e "    ${CYAN}└─ ${mem_usage}% used${RESET}"
    elif [ "$mem_usage" -lt 90 ]; then
        check_status "Memory Usage" "warning"
        echo -e "    ${YELLOW}└─ ${mem_usage}% used${RESET}"
    else
        check_status "Memory Usage" "fail"
        echo -e "    ${RED}└─ ${mem_usage}% used (high!)${RESET}"
    fi
}

# Check network connectivity
check_network() {
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        check_status "Network Connectivity" "pass"

        if curl -s https://registry.ollama.ai > /dev/null 2>&1; then
            echo -e "    ${CYAN}└─ Ollama registry reachable${RESET}"
        fi
    else
        check_status "Network Connectivity" "fail"
    fi
}

# Check if a port is in use (lsof preferred, falls back to ss then netstat)
_port_in_use() {
    local port="$1"
    if command_exists lsof; then
        lsof -i :"$port" > /dev/null 2>&1
    elif command_exists ss; then
        ss -tlnp | grep -q ":${port} " 2>/dev/null
    elif command_exists netstat; then
        netstat -tlnp 2>/dev/null | grep -q ":${port} "
    else
        return 1
    fi
}

# Check important ports
check_ports() {
    local all_ok=true

    if _port_in_use 11434; then
        echo -e "  ${GREEN}${RESET} Port 11434 (Ollama)"
    else
        echo -e "  ${RED}${RESET} Port 11434 (Ollama) - Not listening"
        all_ok=false
    fi

    if _port_in_use 3000; then
        echo -e "  ${GREEN}${RESET} Port 3000 (OpenWebUI)"
    else
        echo -e "  ${YELLOW}${RESET} Port 3000 (OpenWebUI) - Not listening"
        all_ok=false
    fi

    if $all_ok; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Check scripts directory
check_scripts() {
    if [ -d "$SCRIPTS_DIR" ]; then
        local script_count=$(find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" \) | wc -l)
        check_status "Scripts Directory" "pass"
        echo -e "    ${CYAN}└─ ${script_count} scripts available${RESET}"
    else
        check_status "Scripts Directory" "fail"
    fi
}

# Quick recommendations
show_recommendations() {
    echo
    print_header "${NF_BOLT} Recommendations"
    echo

    if [ $FAILED_CHECKS -gt 0 ] || [ $WARNING_CHECKS -gt 0 ]; then
        if ! pgrep -f "ollama serve" > /dev/null 2>&1; then
            echo -e "  ${YELLOW}•${RESET} Start Ollama: ${CYAN}tool startup${RESET}"
        fi

        if ! docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
            echo -e "  ${YELLOW}•${RESET} Start OpenWebUI: ${CYAN}docker start open-webui${RESET}"
        fi

        local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt 80 ]; then
            echo -e "  ${YELLOW}•${RESET} Run cleanup: ${CYAN}tool cleanup${RESET}"
        fi
    else
        echo -e "  ${GREEN}${RESET} All systems nominal!"
    fi
    echo
}

# Summary
show_summary() {
    echo
    print_header "${NF_HEARTBEAT} Health Check Summary"
    echo

    local pass_color="${GREEN}"
    local fail_color="${RED}"
    local warn_color="${YELLOW}"

    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        pass_color="${BRIGHT_GREEN}"
    fi

    echo -e "  ${CYAN}Total Checks:${RESET}    ${TOTAL_CHECKS}"
    echo -e "  ${pass_color}Passed:${RESET}         ${PASSED_CHECKS}"
    echo -e "  ${warn_color}Warnings:${RESET}       ${WARNING_CHECKS}"
    echo -e "  ${fail_color}Failed:${RESET}         ${FAILED_CHECKS}"
    echo

    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "  ${BRIGHT_GREEN}Overall Status:  HEALTHY${RESET}"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "  ${BRIGHT_YELLOW}Overall Status:  NEEDS ATTENTION${RESET}"
    else
        echo -e "  ${BRIGHT_RED}Overall Status:  CRITICAL${RESET}"
    fi
    echo
}

# Main execution
main() {
    clear
    print_header "${NF_HEARTBEAT} System Health Check - $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    echo -e "${BRIGHT_CYAN}${NF_SERVER} Core Services:${RESET}"
    echo
    check_ollama
    check_docker
    check_openwebui

    echo
    echo -e "${BRIGHT_CYAN}${NF_CHART} System Resources:${RESET}"
    echo
    check_disk_space
    check_memory

    echo
    echo -e "${BRIGHT_CYAN}${NF_GLOBE} Network & Connectivity:${RESET}"
    echo
    check_network

    echo
    echo -e "${BRIGHT_CYAN}${NF_PLUG} Port Status:${RESET}"
    echo
    check_ports

    echo
    echo -e "${BRIGHT_CYAN}${NF_TERMINAL} Environment:${RESET}"
    echo
    check_scripts

    show_summary
    show_recommendations
}

main "$@"
