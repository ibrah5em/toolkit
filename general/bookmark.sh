#!/usr/bin/env bash
# =====================================================
# Bookmark - Save and jump to directories
# =====================================================
# Usage: source this or use `tool bookmark`
# For cd to actually work in your shell, add to .zshrc:
#   bm() { eval "$(~/scripts/general/bookmark.sh cd "$@")"; }

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

BOOKMARK_FILE="$HOME/.config/toolkit/bookmarks"
mkdir -p "$(dirname "$BOOKMARK_FILE")"
touch "$BOOKMARK_FILE"

# ── Save current dir with a name ─────────────────────
save_bookmark() {
    local name="$1"
    local dir="${2:-$(pwd)}"

    if [ -z "$name" ]; then
        print_error "Usage: bookmark save <name> [path]"
        return 1
    fi

    if ! validate_name "$name"; then
        return 1
    fi

    if [ ! -d "$dir" ]; then
        print_error "Directory does not exist: $dir"
        return 1
    fi

    dir=$(cd "$dir" && pwd)

    # Remove existing bookmark with same name
    grep -v "^${name}=" "$BOOKMARK_FILE" > "${BOOKMARK_FILE}.tmp" 2>/dev/null
    mv "${BOOKMARK_FILE}.tmp" "$BOOKMARK_FILE"

    echo "${name}=${dir}" >> "$BOOKMARK_FILE"
    print_success "Saved ${BOLD}${name}${RESET}${BRIGHT_GREEN} ${NF_CHEVRON} ${dir}"
}

# ── Print cd command (eval this in caller shell) ──────
goto_bookmark() {
    local name="$1"

    if [ -z "$name" ]; then
        print_error "Usage: bookmark cd <name>"
        return 1
    fi

    local dir
    dir=$(grep "^${name}=" "$BOOKMARK_FILE" 2>/dev/null | head -1 | cut -d= -f2-)

    if [ -z "$dir" ]; then
        print_error "Bookmark not found: $name"
        echo
        print_info "Available bookmarks:"
        list_bookmarks
        return 1
    fi

    if [ ! -d "$dir" ]; then
        print_error "Directory no longer exists: $dir"
        return 1
    fi

    # If running in subshell (tool bookmark cd X), print the cd command
    # If sourced, we can cd directly
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        echo "cd '$dir'"
    else
        cd "$dir" || return 1
        print_info "Now in: ${BOLD}$dir${RESET}"
    fi
}

# ── List all bookmarks ────────────────────────────────
list_bookmarks() {
    print_header "${NF_STAR} Bookmarks"
    echo

    if [ ! -s "$BOOKMARK_FILE" ]; then
        print_info "No bookmarks yet. Save one with: ${BOLD}bookmark save <name>${RESET}"
        echo
        return
    fi

    local count=0
    while IFS='=' read -r name dir; do
        [ -z "$name" ] && continue
        [[ "$name" =~ ^# ]] && continue

        local status_icon="${BRIGHT_GREEN}${NF_CHECK}${RESET}"
        [ ! -d "$dir" ] && status_icon="${BRIGHT_RED}${NF_CROSS}${RESET}"

        local short_dir="${dir/#$HOME/~}"
        printf "  ${status_icon}  ${BRIGHT_CYAN}${BOLD}%-15s${RESET} ${NF_CHEVRON} ${DIM}%s${RESET}\n" \
            "$name" "$short_dir"
        ((count++))
    done < "$BOOKMARK_FILE"

    echo
    echo -e "  ${BRIGHT_CYAN}Total:${RESET} ${BOLD}${BRIGHT_GREEN}$count${RESET} bookmark(s)"
    echo
}

# ── Remove a bookmark ─────────────────────────────────
remove_bookmark() {
    local name="$1"

    if [ -z "$name" ]; then
        print_error "Usage: bookmark rm <name>"
        return 1
    fi

    if ! grep -q "^${name}=" "$BOOKMARK_FILE" 2>/dev/null; then
        print_error "Bookmark not found: $name"
        return 1
    fi

    grep -v "^${name}=" "$BOOKMARK_FILE" > "${BOOKMARK_FILE}.tmp"
    mv "${BOOKMARK_FILE}.tmp" "$BOOKMARK_FILE"
    print_success "Removed bookmark: ${BOLD}$name${RESET}"
}

# ── Clean dead bookmarks ─────────────────────────────
clean_bookmarks() {
    print_header "${NF_ERASER} Cleaning Dead Bookmarks"
    echo

    local removed=0
    local temp
    temp=$(mktemp)

    while IFS='=' read -r name dir; do
        [ -z "$name" ] && continue
        [[ "$name" =~ ^# ]] && { echo "${name}=${dir}" >> "$temp"; continue; }

        if [ -d "$dir" ]; then
            echo "${name}=${dir}" >> "$temp"
        else
            print_warning "Removed ${BOLD}$name${RESET}${BRIGHT_YELLOW} (${dir} gone)"
            ((removed++))
        fi
    done < "$BOOKMARK_FILE"

    mv "$temp" "$BOOKMARK_FILE"

    echo
    if [ "$removed" -eq 0 ]; then
        print_success "All bookmarks are valid"
    else
        print_success "Removed $removed dead bookmark(s)"
    fi
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_STAR} Bookmark"
    echo
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "list"               "Show all bookmarks"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "save <name> [path]" "Save current dir (or path) as bookmark"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "cd <name>"          "Print cd command (use with: eval \$(tool bookmark cd x))"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "rm <name>"          "Remove a bookmark"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "clean"              "Remove bookmarks pointing to deleted dirs"
    echo
    echo -e "  ${DIM}Tip: Add to .zshrc for instant jump:${RESET}"
    echo -e "  ${DIM}  bm() { eval \"\$(~/scripts/general/bookmark.sh cd \"\$@\")\"; }${RESET}"
    echo
}

main() {
    local cmd="${1:-list}"
    shift || true

    case "$cmd" in
        list|ls|l)              list_bookmarks ;;
        save|add|s|a)           save_bookmark "$@" ;;
        cd|go|j|jump)           goto_bookmark "$@" ;;
        rm|remove|del|delete)   remove_bookmark "$@" ;;
        clean|prune)            clean_bookmarks ;;
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
