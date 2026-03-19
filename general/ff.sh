#!/usr/bin/env bash
# =====================================================
# FF - Fast file & content finder
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

EXCLUDE_DIRS=".git node_modules .venv venv __pycache__ .cache .ollama .npm-global"

_build_excludes() {
    local excludes=""
    for d in $EXCLUDE_DIRS; do
        excludes="$excludes -not -path '*/$d/*'"
    done
    echo "$excludes"
}

# ── Find files by name pattern ────────────────────────
find_files() {
    local pattern="$1"
    local dir="${2:-.}"

    if [ -z "$pattern" ]; then
        print_error "Usage: ff file <pattern> [dir]"
        return 1
    fi

    print_header "${NF_SEARCH} Files matching: ${pattern}"
    echo

    local count=0
    local excludes
    excludes=$(_build_excludes)

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local rel="${file/#$HOME/~}"
        local dir_part
        dir_part=$(dirname "$rel")
        local name_part
        name_part=$(basename "$rel")
        local size
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        local mod
        mod=$(stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)

        printf "  ${BRIGHT_CYAN}%-8s${RESET} ${DIM}%-20s${RESET} ${DIM}%s/${RESET}${BRIGHT_WHITE}%s${RESET}\n" \
            "$size" "$mod" "$dir_part" "$name_part"
        ((count++))
    done < <(eval "find '$dir' -type f -iname '*${pattern}*' $excludes 2>/dev/null" | head -30)

    echo
    if [ "$count" -eq 0 ]; then
        print_info "No files matching '$pattern'"
    else
        echo -e "  ${BRIGHT_CYAN}Found:${RESET} ${BOLD}${BRIGHT_GREEN}$count${RESET} file(s)"
    fi
    echo
}

# ── Search file contents (grep) ──────────────────────
search_content() {
    local pattern="$1"
    local dir="${2:-.}"
    local ext="${3:-}"

    if [ -z "$pattern" ]; then
        print_error "Usage: ff grep <pattern> [dir] [ext]"
        return 1
    fi

    print_header "${NF_SEARCH} Content matching: ${pattern}"
    [ -n "$ext" ] && echo -e "  ${DIM}Filtering: *.${ext}${RESET}"
    echo

    local include_flag=""
    [ -n "$ext" ] && include_flag="--include=*.${ext}"

    local exclude_flags=""
    for d in $EXCLUDE_DIRS; do
        exclude_flags="$exclude_flags --exclude-dir=$d"
    done

    local count=0
    local current_file=""

    grep -rn --color=never $include_flag $exclude_flags -i "$pattern" "$dir" 2>/dev/null \
        | head -50 \
        | while IFS=: read -r file lineno content; do
            local rel="${file/#$HOME/~}"
            if [ "$file" != "$current_file" ]; then
                [ -n "$current_file" ] && echo
                echo -e "  ${BRIGHT_CYAN}${NF_FILE_TEXT} ${rel}${RESET}"
                current_file="$file"
            fi
            # Trim leading whitespace from content
            content=$(echo "$content" | sed 's/^[[:space:]]*//')
            printf "    ${DIM}%4s${RESET}  %.100s\n" "$lineno" "$content"
            ((count++))
        done

    echo
    echo -e "  ${BRIGHT_CYAN}Matches:${RESET} ${BOLD}${BRIGHT_GREEN}$count${RESET} line(s)"
    echo
}

# ── Find recent files ─────────────────────────────────
recent() {
    local dir="${1:-$HOME}"
    local minutes="${2:-60}"

    print_header "${NF_REFRESH} Files modified in the last ${minutes} minutes"
    echo

    local count=0
    local excludes
    excludes=$(_build_excludes)

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local rel="${file/#$HOME/~}"
        local size mod
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        mod=$(stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)

        printf "  ${BRIGHT_CYAN}%-8s${RESET} ${DIM}%-20s${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
            "$size" "$mod" "$rel"
        ((count++))
    done < <(eval "find '$dir' -type f -mmin -$minutes $excludes 2>/dev/null" \
        | grep -v '/\.' | head -25)

    echo
    if [ "$count" -eq 0 ]; then
        print_info "No recently modified files"
    else
        echo -e "  ${BRIGHT_CYAN}Found:${RESET} ${BOLD}${BRIGHT_GREEN}$count${RESET} file(s)"
    fi
    echo
}

# ── Find duplicates by size+name ──────────────────────
duplicates() {
    local dir="${1:-.}"

    print_header "${NF_SEARCH} Potential Duplicate Files in ${dir}"
    echo

    print_loading "Scanning..."
    echo

    local excludes
    excludes=$(_build_excludes)

    local dupes
    dupes=$(eval "find '$dir' -type f $excludes -printf '%s %f\n' 2>/dev/null" \
        | sort | uniq -d -w 20 | head -20)

    if [ -z "$dupes" ]; then
        print_success "No obvious duplicates found"
        echo
        return
    fi

    local count=0
    echo "$dupes" | while read -r size name; do
        echo -e "  ${BRIGHT_YELLOW}${NF_FILE_TEXT} $name${RESET}  ${DIM}($(numfmt --to=iec-i "$size" 2>/dev/null || echo "${size}B"))${RESET}"
        eval "find '$dir' -type f -name '$name' -size ${size}c $excludes 2>/dev/null" \
            | while read -r match; do
                echo -e "    ${DIM}${match/#$HOME/~}${RESET}"
            done
        ((count++))
    done

    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_SEARCH} FF - Fast Finder"
    echo
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "file <pattern> [dir]"      "Find files by name"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "grep <text> [dir] [ext]"   "Search file contents"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "recent [dir] [minutes]"    "Recently modified files (default: 60 min)"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "dupes [dir]"               "Find potential duplicate files"
    echo
    echo -e "  ${DIM}Auto-excludes: ${EXCLUDE_DIRS}${RESET}"
    echo
}

main() {
    local cmd="${1:---help}"
    shift || true

    case "$cmd" in
        file|f|name|n)          find_files "$@" ;;
        grep|g|search|content)  search_content "$@" ;;
        recent|r|new)           recent "$@" ;;
        dupes|dup|d|duplicate)  duplicates "$@" ;;
        help|--help|-h)         show_help ;;
        *)
            # Bare pattern: search by filename
            find_files "$cmd" "$@"
            ;;
    esac
}

main "$@"
