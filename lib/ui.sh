#!/usr/bin/env bash
# =====================================================
# UI Functions - Toolkit Shared Library
# =====================================================

# Double-source guard
[[ -n "${_TOOLKIT_UI_LOADED:-}" ]] && return 0
_TOOLKIT_UI_LOADED=1

# Source colors
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_LIB_DIR}/colors.sh"

# ── Nerd Font Icons ──────────────────────────────────
readonly NF_CHECK=$'\uf00c'         # 
readonly NF_CROSS=$'\uf00d'         # 
readonly NF_WARN=$'\uf071'          # 
readonly NF_INFO=$'\uf05a'          # 
readonly NF_SPINNER=$'\uf252'       #  (hourglass)
readonly NF_ROCKET=$'\uf135'        # 
readonly NF_FOLDER=$'\uf07b'        # 
readonly NF_FOLDER_OPEN=$'\uf07c'   # 
readonly NF_PACKAGE=$'\uf466'       # 
readonly NF_WRENCH=$'\uf0ad'        # 
readonly NF_TARGET=$'\uf05b'        # 
readonly NF_TRASH=$'\uf1f8'         # 
readonly NF_SEARCH=$'\uf002'        # 
readonly NF_PENCIL=$'\uf044'        # 
readonly NF_FILE_TEXT=$'\uf15c'     # 
readonly NF_REFRESH=$'\uf021'       # 
readonly NF_FLOPPY=$'\uf0c7'        # 
readonly NF_GLOBE=$'\uf0ac'         # 
readonly NF_SHIELD=$'\uf132'        # 
readonly NF_LOCK=$'\uf023'          # 
readonly NF_UNLOCK=$'\uf09c'        # 
readonly NF_BOLT=$'\uf0e7'          # 
readonly NF_ERASER=$'\uf12d'        # 
readonly NF_DOCKER=$'\uf308'        # 
readonly NF_PLUG=$'\uf1e6'          # 
readonly NF_CHART=$'\uf080'         # 
readonly NF_DESKTOP=$'\uf108'       # 
readonly NF_HOME=$'\uf015'          # 
readonly NF_LINK=$'\uf0c1'          # 
readonly NF_PYTHON=$'\ue606'        # 
readonly NF_CLIPBOARD=$'\uf0ea'     # 
readonly NF_FLASK=$'\uf0c3'         # 
readonly NF_BOOK=$'\uf02d'          # 
readonly NF_BAN=$'\uf05e'           # 
readonly NF_PLAY=$'\uf04b'          # 
readonly NF_DOWNLOAD=$'\uf019'      # 
readonly NF_UPLOAD=$'\uf093'        # 
readonly NF_GIT=$'\uf1d3'           # 
readonly NF_TERMINAL=$'\uf489'      # 
readonly NF_CHEVRON=$'\uf054'       # 
readonly NF_SERVER=$'\uf233'        # 
readonly NF_NETWORK=$'\uf0c8'       # 
readonly NF_KEY=$'\uf084'           # 
readonly NF_COG=$'\uf013'           # 
readonly NF_PAINT=$'\uf1fc'         # 
readonly NF_BULLHORN=$'\uf0a1'      # 
readonly NF_STAR=$'\uf005'          # 
readonly NF_HEARTBEAT=$'\uf21e'     # 
readonly NF_CUBE=$'\uf1b2'          # 
readonly NF_TAG=$'\uf02b'           # 

# ── Status messages ──────────────────────────────────
print_success() { echo -e "${BRIGHT_GREEN}${BOLD}${NF_CHECK}${RESET} ${BRIGHT_GREEN}$1${RESET}"; }
print_error()   { echo -e "${BRIGHT_RED}${BOLD}${NF_CROSS}${RESET} ${BRIGHT_RED}$1${RESET}"; }
print_warning() { echo -e "${BRIGHT_YELLOW}${BOLD}${NF_WARN}${RESET} ${BRIGHT_YELLOW}$1${RESET}"; }
print_info()    { echo -e "${BRIGHT_CYAN}${BOLD}${NF_INFO}${RESET} ${BRIGHT_CYAN}$1${RESET}"; }
print_loading() { echo -e "${BRIGHT_BLUE}${BOLD}${NF_SPINNER}${RESET} ${BRIGHT_BLUE}$1${RESET}"; }

log_success() { print_success "$@"; }
log_error()   { print_error "$@"; }
log_warning() { print_warning "$@"; }
log_info()    { print_info "$@"; }

# ── Box drawing ──────────────────────────────────────
draw_box_top()    { :; }
draw_box_middle() { :; }
draw_box_bottom() { :; }
draw_box_line()   { echo -e "$1"; }

# ── Lines ────────────────────────────────────────────
print_double_line() {
    echo -e "${BRIGHT_CYAN}═══════════════════════════════════════════════════════════════${RESET}"
}

print_single_line() {
    echo -e "${BRIGHT_BLACK}───────────────────────────────────────────────────────────────${RESET}"
}

# ── Header ───────────────────────────────────────────
print_header() {
    echo -e "${BRIGHT_CYAN}${BOLD}$1${RESET}"
}
