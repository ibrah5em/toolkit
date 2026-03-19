#!/usr/bin/env bash
# Quick system monitor

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/ui.sh"

# CPU usage via /proc/stat (reliable across distros)
cpu_usage() {
    local line1 line2
    line1=$(grep '^cpu ' /proc/stat)
    sleep 0.5
    line2=$(grep '^cpu ' /proc/stat)

    local idle1 total1 idle2 total2
    idle1=$(echo "$line1" | awk '{print $5}')
    total1=$(echo "$line1" | awk '{for(i=2;i<=NF;i++) sum+=$i; print sum}')
    idle2=$(echo "$line2" | awk '{print $5}')
    total2=$(echo "$line2" | awk '{for(i=2;i<=NF;i++) sum+=$i; print sum}')

    echo $(( (total2 - total1 - (idle2 - idle1)) * 100 / (total2 - total1) ))
}

# Color a percentage: green < 60, yellow < 85, red >= 85
color_pct() {
    local pct="$1"
    if [ "$pct" -lt 60 ]; then
        echo -e "${BRIGHT_GREEN}${pct}%${RESET}"
    elif [ "$pct" -lt 85 ]; then
        echo -e "${BRIGHT_YELLOW}${pct}%${RESET}"
    else
        echo -e "${BRIGHT_RED}${pct}%${RESET}"
    fi
}

echo
echo -e "${BRIGHT_CYAN}${BOLD}  ${NF_HEARTBEAT} SYSTEM STATUS${RESET}"
print_single_line

cpu=$(cpu_usage)
mem_pct=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
disk_pct=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

printf "  ${ACCENT_BLUE}${NF_COG}  CPU${RESET}     %s used\n" "$(color_pct "$cpu")"
printf "  ${ACCENT_PURPLE}${NF_CUBE}  RAM${RESET}     %s used  ${DIM}(%s)${RESET}\n" "$(color_pct "$mem_pct")" "$(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
printf "  ${ACCENT_ORANGE}${NF_FLOPPY}  Disk${RESET}    %s used  ${DIM}(%s)${RESET}\n" "$(color_pct "$disk_pct")" "$(df -h / | awk 'NR==2 {print $3 "/" $2}')"

if command -v sensors >/dev/null 2>&1; then
    temp=$(sensors 2>/dev/null | grep "Package id 0:" | awk '{print $4}' || echo "N/A")
    printf "  ${ACCENT_PINK}${NF_BOLT}  Temp${RESET}    ${BRIGHT_WHITE}%s${RESET}\n" "$temp"
else
    printf "  ${ACCENT_PINK}${NF_BOLT}  Temp${RESET}    ${DIM}N/A (install lm-sensors)${RESET}\n"
fi

printf "  ${ACCENT_TEAL}${NF_REFRESH}  Uptime${RESET}  ${BRIGHT_WHITE}%s${RESET}\n" "$(uptime -p | sed 's/up //')"
echo
