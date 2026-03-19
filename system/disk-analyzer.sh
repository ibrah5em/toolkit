#!/usr/bin/env bash
# =====================================================
# Disk Analyzer - Find what's eating your space
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# ── Top directories by size ──────────────────────────
top_dirs() {
    local target="${1:-$HOME}"
    local n="${2:-15}"

    print_header "${NF_CHART} Largest Directories in ${target}"
    echo

    if [ ! -d "$target" ]; then
        print_error "Not a directory: $target"
        return 1
    fi

    print_loading "Scanning (this may take a moment)..."
    echo

    printf "  ${BRIGHT_CYAN}%-10s  %s${RESET}\n" "Size" "Directory"
    print_single_line

    du -h --max-depth=1 "$target" 2>/dev/null \
        | sort -rh \
        | head -n "$((n + 1))" \
        | tail -n "$n" \
        | while IFS=$'\t' read -r size dir; do
            local name="${dir/#$HOME/~}"
            printf "  ${BRIGHT_YELLOW}%-10s${RESET}  ${BRIGHT_WHITE}%s${RESET}\n" "$size" "$name"
        done

    echo
    local total
    total=$(du -sh "$target" 2>/dev/null | cut -f1)
    echo -e "  ${BRIGHT_CYAN}Total:${RESET} ${BOLD}${BRIGHT_GREEN}$total${RESET}"
    echo
}

# ── Large files finder ────────────────────────────────
big_files() {
    local target="${1:-$HOME}"
    local min_mb="${2:-50}"
    local n=20

    print_header "${NF_SEARCH} Files Larger Than ${min_mb}MB in ${target}"
    echo

    print_loading "Scanning..."
    echo

    local count=0

    printf "  ${BRIGHT_CYAN}%-10s  %-12s  %s${RESET}\n" "Size" "Modified" "File"
    print_single_line

    find "$target" -type f -size +"${min_mb}M" \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/.ollama/*" \
        -printf '%s\t%T@\t%p\n' 2>/dev/null \
        | sort -rn \
        | head -n "$n" \
        | while IFS=$'\t' read -r bytes epoch path; do
            local size mod name
            size=$(numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null || echo "${bytes}B")
            mod=$(date -d "@${epoch%%.*}" '+%Y-%m-%d' 2>/dev/null || echo "?")
            name="${path/#$HOME/~}"
            printf "  ${BRIGHT_YELLOW}%-10s${RESET}  ${DIM}%-12s${RESET}  ${BRIGHT_WHITE}%s${RESET}\n" \
                "$size" "$mod" "$name"
            ((count++))
        done

    echo
    if [ "$count" -eq 0 ]; then
        print_info "No files larger than ${min_mb}MB found"
    fi
    echo
}

# ── Disk overview ─────────────────────────────────────
overview() {
    print_header "${NF_FLOPPY} Disk Overview"
    echo

    printf "  ${BRIGHT_CYAN}%-15s %-8s %-8s %-8s %-6s${RESET}\n" \
        "Filesystem" "Size" "Used" "Avail" "Use%"
    print_single_line

    df -h --type=ext4 --type=9p --type=drvfs 2>/dev/null | tail -n +2 | while read -r fs size used avail pct mount; do
        local pct_num="${pct%\%}"
        local color="${BRIGHT_GREEN}"
        [ "$pct_num" -ge 70 ] && color="${BRIGHT_YELLOW}"
        [ "$pct_num" -ge 90 ] && color="${BRIGHT_RED}"

        printf "  ${BRIGHT_WHITE}%-15s${RESET} %-8s %-8s %-8s ${color}%-6s${RESET}\n" \
            "$mount" "$size" "$used" "$avail" "$pct"
    done

    echo

    # Known heavy hitters
    echo -e "  ${BRIGHT_MAGENTA}${BOLD}Heavy Hitters${RESET}"
    echo

    local items=(
        ".ollama/models:Ollama Models"
        ".cache:User Cache"
        ".npm-global:npm Global"
        ".local:Local Packages"
        "projects:Projects"
    )

    for item in "${items[@]}"; do
        local dir="${item%%:*}"
        local label="${item##*:}"
        if [ -d "$HOME/$dir" ]; then
            local size
            size=$(du -sh "$HOME/$dir" 2>/dev/null | cut -f1)
            printf "  ${BRIGHT_CYAN}  %-20s${RESET} ${BRIGHT_YELLOW}%s${RESET}\n" "$label" "$size"
        fi
    done
    echo
}

# ── Stale node_modules / venvs ────────────────────────
stale() {
    local days="${1:-30}"

    print_header "${NF_ERASER} Stale Build Artifacts (untouched ${days}+ days)"
    echo

    if [ ! -d "$HOME/projects" ]; then
        print_info "No projects directory found"
        return
    fi

    local total_size=0
    local found=0

    # node_modules
    while IFS= read -r dir; do
        local proj size
        proj=$(dirname "$dir")
        proj="${proj/#$HOME\/projects\//}"
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        printf "  ${BRIGHT_YELLOW}${NF_PACKAGE}  %-30s${RESET} ${DIM}node_modules${RESET}  ${BRIGHT_RED}%s${RESET}\n" \
            "$proj" "$size"
        ((found++))
    done < <(find "$HOME/projects" -maxdepth 3 -name "node_modules" -type d -mtime +"$days" 2>/dev/null)

    # venvs
    while IFS= read -r dir; do
        local proj size
        proj=$(dirname "$dir")
        proj="${proj/#$HOME\/projects\//}"
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        printf "  ${BRIGHT_YELLOW}${NF_PYTHON}  %-30s${RESET} ${DIM}venv${RESET}          ${BRIGHT_RED}%s${RESET}\n" \
            "$proj" "$size"
        ((found++))
    done < <(find "$HOME/projects" -maxdepth 3 -name "venv" -type d -mtime +"$days" 2>/dev/null)

    # __pycache__
    while IFS= read -r dir; do
        local proj size
        proj=$(dirname "$dir")
        proj="${proj/#$HOME\/projects\//}"
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        printf "  ${DIM}${NF_PYTHON}  %-30s __pycache__    %s${RESET}\n" "$proj" "$size"
        ((found++))
    done < <(find "$HOME/projects" -maxdepth 4 -name "__pycache__" -type d 2>/dev/null)

    echo
    if [ "$found" -eq 0 ]; then
        print_success "No stale artifacts found"
    else
        echo -e "  ${BRIGHT_CYAN}Found:${RESET} ${BOLD}${BRIGHT_YELLOW}$found${RESET} stale artifact(s)"
        echo
        if confirm_action "Remove all stale node_modules and venvs?"; then
            find "$HOME/projects" -maxdepth 3 -name "node_modules" -type d -mtime +"$days" -exec rm -rf {} + 2>/dev/null
            find "$HOME/projects" -maxdepth 3 -name "venv" -type d -mtime +"$days" -exec rm -rf {} + 2>/dev/null
            find "$HOME/projects" -maxdepth 4 -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
            print_success "Stale artifacts removed"
        else
            print_info "Cancelled"
        fi
    fi
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_FLOPPY} Disk Analyzer"
    echo
    printf "  ${BRIGHT_GREEN}%-24s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "overview"                "Filesystem usage + heavy hitters"
    printf "  ${BRIGHT_GREEN}%-24s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "top [dir] [n]"          "Top N largest subdirectories (default: ~, 15)"
    printf "  ${BRIGHT_GREEN}%-24s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "big [dir] [mb]"         "Find files larger than N MB (default: 50)"
    printf "  ${BRIGHT_GREEN}%-24s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "stale [days]"           "Find old node_modules/venvs (default: 30 days)"
    echo
}

main() {
    local cmd="${1:-overview}"
    shift || true

    case "$cmd" in
        overview|ov|o|df)       overview ;;
        top|dirs|t)             top_dirs "$@" ;;
        big|large|files|f)      big_files "$@" ;;
        stale|old|prune|clean)  stale "$@" ;;
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
