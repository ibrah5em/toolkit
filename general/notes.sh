#!/usr/bin/env bash
# =====================================================
# Quick Notes - Terminal note-taking by day
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

NOTES_DIR="${NOTES_DIR:-$HOME/notes}"
mkdir -p "$NOTES_DIR"

_today_file() {
    echo "$NOTES_DIR/$(date +%Y-%m-%d).md"
}

# Add a timestamped note (opens editor if no text given)
add_note() {
    local text="$*"
    local file
    file=$(_today_file)

    # Create file with date header if it doesn't exist yet
    if [ ! -f "$file" ]; then
        echo "# Notes — $(date '+%A, %B %d %Y')" > "$file"
        echo >> "$file"
    fi

    local timestamp
    timestamp=$(date '+%H:%M')

    if [ -n "$text" ]; then
        echo "- **[$timestamp]** $text" >> "$file"
        print_success "Note saved → $(basename "$file")"
    else
        # Append a blank entry and open editor
        echo "- **[$timestamp]** " >> "$file"
        local editor="${EDITOR:-nano}"
        "$editor" "$file"
    fi
}

# Show today's notes
show_today() {
    local file
    file=$(_today_file)

    print_header "${NF_PENCIL} Today — $(date '+%A, %B %d')"
    echo

    if [ ! -f "$file" ]; then
        print_info "No notes for today yet."
        echo
        print_info "Add one with: ${BOLD}notes add your note here${RESET}"
    else
        cat "$file"
    fi
    echo
}

# Search across all note files
search_notes() {
    local query="$1"
    if [ -z "$query" ]; then
        print_error "Usage: notes search <keyword>"
        exit 1
    fi

    print_header "${NF_SEARCH} Search: \"${query}\""
    echo

    local found=0
    while IFS= read -r file; do
        local matches
        matches=$(grep -n -i "$query" "$file" 2>/dev/null)
        if [ -n "$matches" ]; then
            echo -e "${BRIGHT_CYAN}$(basename "$file"):${RESET}"
            echo "$matches" | while IFS= read -r line; do
                echo -e "  ${DIM}${line}${RESET}"
            done
            echo
            ((found++))
        fi
    done < <(find "$NOTES_DIR" -name "*.md" 2>/dev/null | sort -r)

    [ "$found" -eq 0 ] && print_info "No matches found for \"$query\""
    echo
}

# List recent note files
list_notes() {
    print_header "${NF_FILE_TEXT} Recent Notes"
    echo

    local count=0
    while IFS= read -r file; do
        local date_label lines
        date_label=$(basename "$file" .md)
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        printf "  ${BRIGHT_GREEN}%-12s${RESET}  ${DIM}%d lines${RESET}\n" "$date_label" "$lines"
        ((count++))
        [ "$count" -ge 10 ] && break
    done < <(find "$NOTES_DIR" -name "*.md" 2>/dev/null | sort -r)

    echo
    [ "$count" -eq 0 ] \
        && print_info "No notes yet. Start with: notes add your first note" \
        || echo -e "${BRIGHT_CYAN}  Notes dir: ${DIM}${NOTES_DIR}${RESET}"
    echo
}

show_help() {
    print_header "${NF_PENCIL} Quick Notes"
    echo
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "add [text]"       "Add a note (opens \$EDITOR if no text)"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "today"            "Show today's notes"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "search <keyword>" "Search across all notes"
    printf "  ${BRIGHT_GREEN}%-22s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "list"             "List recent note files"
    echo
    echo -e "  ${DIM}Notes stored in: ${NOTES_DIR}${RESET}"
    echo
}

main() {
    local cmd="${1:-today}"
    shift || true

    case "$cmd" in
        add|a|new)          add_note "$@" ;;
        today|t|show|view)  show_today ;;
        search|find|s)      search_notes "$@" ;;
        list|ls|l)          list_notes ;;
        help|--help|-h)     show_help ;;
        # Anything unrecognized is treated as a note to add directly
        *)                  add_note "$cmd" "$@" ;;
    esac
}

main "$@"
