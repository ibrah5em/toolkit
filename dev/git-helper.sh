#!/usr/bin/env bash
# =====================================================
# Git Helper - Dashboard, log, branch cleanup, repo scan
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command git "Install git: sudo apt install git" || exit 1

# Detailed status of current repo
show_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi

    local branch remote last staged unstaged untracked
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    remote=$(git remote get-url origin 2>/dev/null || echo "no remote")
    last=$(git log -1 --format="%h — %s (%cr)" 2>/dev/null || echo "no commits")
    staged=$(git diff --cached --name-only 2>/dev/null | wc -l)
    unstaged=$(git diff --name-only 2>/dev/null | wc -l)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

    print_header "${NF_GIT} Git Status — $(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"
    echo

    draw_box_top
    draw_box_line "${BRIGHT_CYAN}  Branch:${RESET}      ${BRIGHT_GREEN}${branch}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Remote:${RESET}      ${DIM}${remote}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Last commit:${RESET} ${DIM}${last}${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_GREEN}  Staged:${RESET}      ${staged} file(s)"
    draw_box_line "${BRIGHT_YELLOW}  Unstaged:${RESET}    ${unstaged} file(s)"
    draw_box_line "${BRIGHT_RED}  Untracked:${RESET}   ${untracked} file(s)"
    draw_box_bottom
    echo

    if [ "$((staged + unstaged + untracked))" -gt 0 ]; then
        git status --short 2>/dev/null | sed 's/^/  /'
        echo
    fi
}

# Pretty commit graph
show_log() {
    local n="${1:-20}"
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi
    print_header "${NF_GIT} Git Log — last ${n} commits"
    echo
    git log --oneline --graph --decorate --color=always -"${n}" 2>/dev/null
    echo
}

# List all branches
show_branches() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi
    print_header "${NF_GIT} Branches"
    echo
    git branch -a --color=always 2>/dev/null | sed 's/^/  /'
    echo
    print_info "Current: $(git branch --show-current 2>/dev/null)"
    echo
}

# Scan all git repos in PROJECTS_DIR
scan_repos() {
    print_header "${NF_GIT} All Repositories in ${PROJECTS_DIR}"
    echo

    if [ ! -d "$PROJECTS_DIR" ]; then
        print_error "Projects directory not found: $PROJECTS_DIR"
        return 1
    fi

    local found=0
    for dir in "$PROJECTS_DIR"/*/; do
        [ -d "$dir/.git" ] || continue
        local name branch changes last
        name=$(basename "$dir")
        branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "detached")
        changes=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l)
        last=$(git -C "$dir" log -1 --format="%cr" 2>/dev/null || echo "no commits")

        if [ "$changes" -gt 0 ]; then
            printf "  ${BRIGHT_YELLOW}${RESET} %-25s ${BRIGHT_CYAN}%-15s${RESET} ${BRIGHT_YELLOW}%2d change(s)${RESET}  ${DIM}%s${RESET}\n" \
                "$name" "$branch" "$changes" "$last"
        else
            printf "  ${BRIGHT_GREEN}${RESET} %-25s ${BRIGHT_CYAN}%-15s${RESET} ${BRIGHT_GREEN}clean${RESET}         ${DIM}%s${RESET}\n" \
                "$name" "$branch" "$last"
        fi
        ((found++))
    done

    echo
    [ "$found" -eq 0 ] \
        && print_info "No git repositories found in $PROJECTS_DIR" \
        || echo -e "${BRIGHT_CYAN}  Total: ${BOLD}${BRIGHT_GREEN}${found}${RESET} repo(s)"
    echo
}

# Delete branches already merged into main/master
clean_branches() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not inside a git repository"
        exit 1
    fi

    print_header "${NF_ERASER} Clean Merged Branches"
    echo

    # Detect main branch
    local main_branch
    main_branch=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    if [ -z "$main_branch" ]; then
        git rev-parse --verify main  >/dev/null 2>&1 && main_branch="main"  || \
        git rev-parse --verify master>/dev/null 2>&1 && main_branch="master" || \
        main_branch=$(git branch --show-current)
    fi

    local merged
    merged=$(git branch --merged "$main_branch" 2>/dev/null \
        | grep -v "^\*" | grep -vE "^[[:space:]]*(main|master|${main_branch})[[:space:]]*$")

    if [ -z "$merged" ]; then
        print_success "No merged branches to clean"
        return
    fi

    echo -e "${BRIGHT_YELLOW}Merged branches (will be deleted):${RESET}"
    echo "$merged" | sed 's/^/    /'
    echo

    if confirm_action "Delete these branches?"; then
        echo "$merged" | xargs git branch -d 2>/dev/null
        print_success "Merged branches removed"
    else
        print_info "Cancelled"
    fi
    echo
}

show_help() {
    print_header "${NF_GIT} Git Helper"
    echo
    printf "  ${BRIGHT_GREEN}%-14s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "status"     "Detailed status of current repo"
    printf "  ${BRIGHT_GREEN}%-14s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "log [n]"    "Pretty commit graph (default: 20 commits)"
    printf "  ${BRIGHT_GREEN}%-14s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "branches"   "List all local and remote branches"
    printf "  ${BRIGHT_GREEN}%-14s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "scan"       "Overview of all repos in projects dir"
    printf "  ${BRIGHT_GREEN}%-14s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "clean"      "Delete branches merged into main"
    echo
}

main() {
    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
        status|st|s)        show_status ;;
        log|l)              show_log "$@" ;;
        branches|branch|b)  show_branches ;;
        scan|repos|r)       scan_repos ;;
        clean|prune|c)      clean_branches ;;
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
