#!/usr/bin/env bash
# =====================================================
# Venv Manager - Python virtual environment overview
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command python3 "Install Python: sudo apt install python3" || exit 1

# List all project venvs with size, Python version, package count
list_venvs() {
    print_header "${NF_PYTHON} Python Virtual Environments in ${PROJECTS_DIR}"
    echo

    if [ ! -d "$PROJECTS_DIR" ]; then
        print_error "Projects directory not found: $PROJECTS_DIR"
        return 1
    fi

    local found=0

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD} Project              Python     Size    Packages${RESET}"
    draw_box_middle

    for dir in "$PROJECTS_DIR"/*/; do
        [ -f "$dir/venv/bin/python" ] || continue
        local name py_ver size pkg_count
        name=$(basename "$dir")
        py_ver=$("$dir/venv/bin/python" --version 2>/dev/null | awk '{print $2}')
        size=$(du -sh "$dir/venv" 2>/dev/null | cut -f1)
        pkg_count=$("$dir/venv/bin/pip" list 2>/dev/null | tail -n +3 | wc -l)
        printf "${BRIGHT_CYAN}│${RESET} ${BRIGHT_GREEN}%-20s${RESET} ${BRIGHT_YELLOW}%-10s${RESET} ${BRIGHT_BLUE}%-7s${RESET} ${DIM}%d pkgs${RESET}\n" \
            "$name" "$py_ver" "$size" "$pkg_count"
        ((found++))
    done

    draw_box_bottom
    echo

    if [ "$found" -eq 0 ]; then
        print_info "No virtual environments found in $PROJECTS_DIR"
    else
        echo -e "${BRIGHT_CYAN}  Total: ${BOLD}${BRIGHT_GREEN}${found}${RESET} virtual environment(s)"
    fi
    echo
}

# Show outdated packages for a project's venv
check_outdated() {
    local project="$1"
    if [ -z "$project" ]; then
        print_error "Usage: venv-manager outdated <project-name>"
        exit 1
    fi

    local venv_dir="$PROJECTS_DIR/$project/venv"
    if [ ! -d "$venv_dir" ]; then
        print_error "No venv found for project: $project"
        exit 1
    fi

    print_header "${NF_PACKAGE} Outdated Packages: ${project}"
    echo
    print_loading "Checking..."

    local outdated
    outdated=$("$venv_dir/bin/pip" list --outdated --format=columns 2>/dev/null | tail -n +3)

    if [ -z "$outdated" ]; then
        print_success "All packages are up to date!"
    else
        printf "  ${BRIGHT_CYAN}%-25s %-12s %s${RESET}\n" "Package" "Current" "Latest"
        print_single_line
        echo "$outdated" | while IFS= read -r line; do
            echo "  $line"
        done
        echo
        if confirm_action "Upgrade all outdated packages?"; then
            echo "$outdated" | awk '{print $1}' | xargs "$venv_dir/bin/pip" install --upgrade --quiet 2>/dev/null
            print_success "Packages upgraded"
        fi
    fi
    echo
}

# Remove a project's venv (with size warning and confirmation)
remove_venv() {
    local project="$1"
    if [ -z "$project" ]; then
        print_error "Usage: venv-manager remove <project-name>"
        exit 1
    fi

    local venv_dir="$PROJECTS_DIR/$project/venv"
    if [ ! -d "$venv_dir" ]; then
        print_error "No venv found for project: $project"
        exit 1
    fi

    local size
    size=$(du -sh "$venv_dir" 2>/dev/null | cut -f1)

    echo
    draw_box_top
    draw_box_line "${BRIGHT_RED}${BOLD}Remove Virtual Environment${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Project:${RESET} $project"
    draw_box_line "${BRIGHT_CYAN}  Path:${RESET}    ${DIM}${venv_dir}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Size:${RESET}    $size"
    draw_box_bottom
    echo

    if confirm_action "Delete this virtual environment?"; then
        rm -rf "$venv_dir"
        print_success "Removed ($size freed)"
        print_info "Recreate with: cd $PROJECTS_DIR/$project && python3 -m venv venv"
    else
        print_info "Cancelled"
    fi
    echo
}

show_help() {
    print_header "${NF_PYTHON} Venv Manager"
    echo
    printf "  ${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "list"                "Show all venvs with size and package count"
    printf "  ${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "outdated <project>"  "Check (and optionally upgrade) outdated packages"
    printf "  ${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "remove <project>"    "Delete a project's virtual environment"
    echo
}

main() {
    local cmd="${1:-list}"
    shift || true

    case "$cmd" in
        list|ls|l)              list_venvs ;;
        outdated|check|upgrade) check_outdated "$@" ;;
        remove|rm|delete)       remove_venv "$@" ;;
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
