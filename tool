#!/usr/bin/env bash
# =====================================================
# Ibrahem's Terminal Toolkit - Ultimate Edition
# =====================================================

# Source shared libraries
_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_TOOL_DIR}/lib/config.sh"
source "${_TOOL_DIR}/lib/ui.sh"
source "${_TOOL_DIR}/lib/utils.sh"

# ASCII Art
show_toolkit_art() {
    clear
    echo -e "${GRADIENT_1}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║      ████████╗ ██████╗  ██████╗ ██╗     ██╗  ██╗██╗████████╗   ║
    ║      ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██║ ██╔╝██║╚══██╔══╝   ║
    ║         ██║   ██║   ██║██║   ██║██║     █████╔╝ ██║   ██║      ║
    ║         ██║   ██║   ██║██║   ██║██║     ██╔═██╗ ██║   ██║      ║
    ║         ██║   ╚██████╔╝╚██████╔╝███████╗██║  ██╗██║   ██║      ║
    ║         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝      ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
}

# Get icon and color for a file extension (sets globals ICON and COLOR)
get_icon() {
    local extension="$1"
    case $extension in
        sh|bash)    ICON=$'\uf489'; COLOR="${BRIGHT_BLUE}" ;;      # bash terminal
        py)         ICON=$'\ue606'; COLOR="${BRIGHT_YELLOW}" ;;    # python
        js)         ICON=$'\ue60c'; COLOR="${BRIGHT_YELLOW}" ;;    # javascript
        ts)         ICON=$'\ue628'; COLOR="${BRIGHT_BLUE}" ;;      # typescript
        rb)         ICON=$'\ue21e'; COLOR="${BRIGHT_RED}" ;;       # ruby
        go)         ICON=$'\ue627'; COLOR="${BRIGHT_CYAN}" ;;      # go
        rs)         ICON=$'\ue7a8'; COLOR="${BRIGHT_RED}" ;;       # rust
        php)        ICON=$'\ue608'; COLOR="${BRIGHT_MAGENTA}" ;;   # php
        java)       ICON=$'\ue738'; COLOR="${BRIGHT_RED}" ;;       # java
        c|h)        ICON=$'\ue61e'; COLOR="${BRIGHT_BLUE}" ;;      # c
        cpp|cc|cxx) ICON=$'\ue61d'; COLOR="${BRIGHT_BLUE}" ;;      # c++
        cs)         ICON=$'\uf031b'; COLOR="${BRIGHT_MAGENTA}" ;;  # c#
        lua)        ICON=$'\ue620'; COLOR="${BRIGHT_BLUE}" ;;      # lua
        pl)         ICON=$'\ue769'; COLOR="${BRIGHT_BLUE}" ;;      # perl
        swift)      ICON=$'\ue755'; COLOR="${BRIGHT_RED}" ;;       # swift
        kt|kts)     ICON=$'\ue634'; COLOR="${BRIGHT_MAGENTA}" ;;   # kotlin
        json)       ICON=$'\ue60b'; COLOR="${BRIGHT_YELLOW}" ;;    # json
        yaml|yml)   ICON=$'\ue6d8'; COLOR="${BRIGHT_RED}" ;;       # yaml
        toml)       ICON=$'\ue6b2'; COLOR="${BRIGHT_RED}" ;;       # toml
        md)         ICON=$'\ue609'; COLOR="${BRIGHT_WHITE}" ;;     # markdown
        html)       ICON=$'\ue60e'; COLOR="${BRIGHT_RED}" ;;       # html
        css)        ICON=$'\ue60d'; COLOR="${BRIGHT_BLUE}" ;;      # css
        *)          ICON=$'\uf15b'; COLOR="${BRIGHT_WHITE}" ;;     # default file
    esac
}

# List all scripts with stunning display
list_scripts() {
    echo
    echo -e "${GRADIENT_1}${BOLD}  ${NF_FOLDER_OPEN} SCRIPT LIBRARY${RESET}"
    echo

    draw_box_top

    local count=0
    local has_scripts=false

    if [ -d "$SCRIPTS_DIR" ]; then
        while IFS= read -r file; do
            has_scripts=true
            category=$(basename "$(dirname "$file")")
            script=$(basename "$file")
            extension="${script##*.}"
            script_name="${script%.*}"

            get_icon "$extension"

            printf " ${COLOR}${ICON}${RESET}  ${GRADIENT_2}%-15s${RESET}  ${COLOR}%-30s${RESET} ${DIM}.%-3s${RESET}\n" \
                "$category" "$script_name" "$extension"

            ((count++))
        done < <(find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" \) -not -path "*/lib/*" 2>/dev/null | sort)
    fi

    if ! $has_scripts; then
        draw_box_line "${BRIGHT_YELLOW}  No scripts found yet. Use ${BOLD}tool add${RESET}${BRIGHT_YELLOW} to get started!${RESET}"
    fi

    draw_box_bottom
    echo
    echo -e "${BRIGHT_CYAN}  Total Scripts: ${BOLD}${BRIGHT_GREEN}$count${RESET}"
    echo
}

# Add a new script
add_script() {
    echo
    echo -e "${GRADIENT_2}${BOLD}  ${NF_DOWNLOAD} ADD NEW SCRIPT${RESET}"
    echo

    echo
    echo -e "${BRIGHT_YELLOW}  Enter the path to your script:${RESET}"
    echo -ne "${BRIGHT_BLACK}   ${RESET}"
    read -r src

    if [[ ! -f "$src" ]]; then
        echo
        print_error "File not found: $src"
        return 1
    fi

    echo
    echo -e "${BRIGHT_YELLOW}  Enter category (e.g., backup, system, tools):${RESET}"
    echo -ne "${BRIGHT_BLACK}   ${RESET}"
    read -r category

    if [[ -z "$category" ]]; then
        category="general"
        echo
        print_warning "No category specified, using: ${BOLD}general${RESET}"
    fi

    target_dir="$SCRIPTS_DIR/$category"
    mkdir -p "$target_dir"

    cp "$src" "$target_dir/"
    chmod +x "$target_dir/$(basename "$src")"

    echo
    print_success "Script successfully added!"

    extension="${src##*.}"
    get_icon "$extension"

    echo
    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Script Details${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Icon:${RESET}     ${COLOR}${ICON}${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Name:${RESET}     ${BRIGHT_WHITE}$(basename "$src")${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Category:${RESET} ${BRIGHT_MAGENTA}$category${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Location:${RESET} ${DIM}$target_dir${RESET}"
    draw_box_bottom
    echo
}

# Delete a script with confirmation
delete_script() {
    echo
    echo -e "${BRIGHT_RED}${BOLD}  ${NF_TRASH} DELETE SCRIPT${RESET}"
    echo

    echo
    echo -e "${BRIGHT_YELLOW}  Enter script name to delete:${RESET}"
    echo -ne "${BRIGHT_BLACK}   ${RESET}"
    read -r name

    SCRIPT_PATH=$(find "$SCRIPTS_DIR" -type f \( -name "$name" -o -name "$name.sh" -o -name "$name.py" -o -name "$name.js" -o -name "$name.ts" -o -name "$name.rb" -o -name "$name.go" -o -name "$name.rs" \) 2>/dev/null | head -n 1)

    if [[ -z "$SCRIPT_PATH" ]]; then
        echo
        print_error "Script not found: $name"
        return 1
    fi

    extension="${SCRIPT_PATH##*.}"
    get_icon "$extension"

    echo
    draw_box_top
    draw_box_line "${BRIGHT_RED}${BOLD}WARNING: You are about to delete${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_WHITE}  Script:${RESET}   ${COLOR}${ICON}  $(basename "$SCRIPT_PATH")${RESET}"
    draw_box_line "${BRIGHT_WHITE}  Location:${RESET} ${DIM}$SCRIPT_PATH${RESET}"
    draw_box_bottom

    echo
    echo -ne "${BRIGHT_YELLOW}  Are you sure? ${RESET}${DIM}(y/N)${RESET} "
    read -r confirmation

    if [[ $confirmation =~ ^[Yy]$ ]]; then
        rm "$SCRIPT_PATH"
        echo
        print_success "Script deleted successfully"

        category_dir=$(dirname "$SCRIPT_PATH")
        if [ -z "$(ls -A "$category_dir" 2>/dev/null)" ]; then
            echo
            echo -ne "${BRIGHT_YELLOW}  Category folder is empty. Remove it? ${RESET}${DIM}(y/N)${RESET} "
            read -r remove_dir
            if [[ $remove_dir =~ ^[Yy]$ ]]; then
                rmdir "$category_dir"
                print_success "Empty category folder removed"
            fi
        fi
    else
        echo
        print_info "Operation cancelled"
    fi
    echo
}

# Show statistics
show_stats() {
    echo
    echo -e "${GRADIENT_3}${BOLD}  ${NF_CHART} TOOLKIT STATISTICS${RESET}"
    echo

    local total_scripts=0
    local categories=0
    local total_size=0

    if [ -d "$SCRIPTS_DIR" ]; then
        total_scripts=$(find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" \) -not -path "*/lib/*" 2>/dev/null | wc -l)
        categories=$(find "$SCRIPTS_DIR" -type d -mindepth 1 2>/dev/null | wc -l)
        total_size=$(du -sh "$SCRIPTS_DIR" 2>/dev/null | cut -f1)
    fi

    echo
    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Overview${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}   Total Scripts:${RESET}  ${BRIGHT_GREEN}${BOLD}$total_scripts${RESET}"
    draw_box_line "${BRIGHT_CYAN}   Categories:${RESET}     ${BRIGHT_BLUE}${BOLD}$categories${RESET}"
    draw_box_line "${BRIGHT_CYAN}   Total Size:${RESET}     ${BRIGHT_YELLOW}$total_size${RESET}"
    draw_box_line "${BRIGHT_CYAN}   Location:${RESET}       ${DIM}$SCRIPTS_DIR${RESET}"
    draw_box_bottom

    if [ "$categories" -gt 0 ]; then
        echo
        echo -e "${BRIGHT_MAGENTA}${BOLD}  Categories Breakdown${RESET}"
        echo

        find "$SCRIPTS_DIR" -type d -mindepth 1 2>/dev/null | while read -r dir; do
            count=$(find "$dir" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rb" -o -name "*.go" -o -name "*.rs" \) 2>/dev/null | wc -l)
            category_name=$(basename "$dir")
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)

            bar_length=$((count * 2))
            if [ $bar_length -gt 20 ]; then bar_length=20; fi
            bar=$(printf "█%.0s" $(seq 1 $bar_length))

            printf "   ${BRIGHT_CYAN}%-15s${RESET} ${BRIGHT_GREEN}%-20s${RESET} ${BRIGHT_YELLOW}%2d scripts${RESET} ${DIM}(%s)${RESET}\n" \
                "$category_name" "$bar" "$count" "$size"
        done
    fi
    echo
}

# Show help
show_help() {
    show_toolkit_art

    echo
    echo -e "${GRADIENT_3}${BOLD}  COMMANDS${RESET}"
    echo
    printf "  ${BRIGHT_GREEN}${NF_FOLDER_OPEN} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "list" "Display all available scripts"
    printf "  ${BRIGHT_GREEN}${NF_DOWNLOAD} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "add" "Add a new script to the toolkit"
    printf "  ${BRIGHT_GREEN}${NF_TRASH} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "delete" "Remove a script from the toolkit"
    printf "  ${BRIGHT_GREEN}${NF_CHART} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "stats" "Show detailed toolkit statistics"
    printf "  ${BRIGHT_GREEN}${NF_SEARCH} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "search <kw>" "Find scripts matching a keyword"
    printf "  ${BRIGHT_GREEN}${NF_PENCIL} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "edit <n>" "Open a script in \$EDITOR"
    printf "  ${BRIGHT_GREEN}${NF_INFO} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "help" "Display this help message"
    printf "  ${BRIGHT_CYAN}${NF_PLAY} %-12s${RESET} ${BRIGHT_BLACK}│${RESET}  ${BRIGHT_WHITE}%-45s${RESET}\n" \
        "<script>" "Execute any script by name"
    echo
}

# Search scripts by name keyword
search_scripts() {
    local query="$1"

    if [[ -z "$query" ]]; then
        print_error "Usage: tool search <keyword>"
        exit 1
    fi

    echo
    echo -e "${GRADIENT_2}${BOLD}  ${NF_SEARCH} SEARCH: ${BRIGHT_WHITE}\"$query\"${RESET}"
    echo

    draw_box_top

    local count=0
    while IFS= read -r file; do
        category=$(basename "$(dirname "$file")")
        script=$(basename "$file")
        extension="${script##*.}"
        script_name="${script%.*}"

        get_icon "$extension"

        printf " ${COLOR}${ICON}${RESET}  ${GRADIENT_2}%-15s${RESET}  ${COLOR}%-30s${RESET} ${DIM}.%-3s${RESET}\n" \
            "$category" "$script_name" "$extension"
        ((count++))
    done < <(find "$SCRIPTS_DIR" -type f \( -name "*$query*" \) -not -path "*/lib/*" 2>/dev/null | sort)

    draw_box_bottom
    echo
    echo -e "${BRIGHT_CYAN}  Found: ${BOLD}${BRIGHT_GREEN}$count${RESET}"
    echo
}

# Open a script in $EDITOR
edit_script() {
    local script_name="$1"

    if [[ -z "$script_name" ]]; then
        print_error "Usage: tool edit <script-name>"
        exit 1
    fi

    SCRIPT_PATH=$(find "$SCRIPTS_DIR" -type f \( -name "$script_name" -o -name "$script_name.sh" -o -name "$script_name.py" -o -name "$script_name.js" -o -name "$script_name.ts" -o -name "$script_name.rb" -o -name "$script_name.go" -o -name "$script_name.rs" \) 2>/dev/null | head -n 1)

    if [[ -z "$SCRIPT_PATH" ]]; then
        print_error "Script not found: $script_name"
        exit 1
    fi

    local editor="${EDITOR:-nano}"
    print_info "Opening ${BRIGHT_WHITE}$(basename "$SCRIPT_PATH")${RESET}${BRIGHT_CYAN} with ${BOLD}$editor${RESET}"
    "$editor" "$SCRIPT_PATH"
}

# Execute script
execute_script() {
    local script_name="$1"
    shift

    SCRIPT_PATH=$(find "$SCRIPTS_DIR" -type f \( -name "$script_name" -o -name "$script_name.sh" -o -name "$script_name.py" -o -name "$script_name.js" -o -name "$script_name.ts" -o -name "$script_name.rb" -o -name "$script_name.go" -o -name "$script_name.rs" \) 2>/dev/null | head -n 1)

    if [[ -z "$SCRIPT_PATH" ]]; then
        echo
        print_error "Script not found: $script_name"
        echo
        print_info "Use ${BOLD}tool list${RESET}${BRIGHT_CYAN} to see available scripts${RESET}"
        echo
        exit 1
    fi

    extension="${SCRIPT_PATH##*.}"
    get_icon "$extension"

    echo
    echo -e "${GRADIENT_1}${BOLD}  ${NF_ROCKET} LAUNCHING SCRIPT${RESET}"
    echo

    draw_box_top
    draw_box_line "${BRIGHT_WHITE}${BOLD}Execution Details${RESET}"
    draw_box_middle
    draw_box_line "${BRIGHT_CYAN}  Script:${RESET}   ${COLOR}${ICON}  $(basename "$SCRIPT_PATH")${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Path:${RESET}     ${DIM}$SCRIPT_PATH${RESET}"
    draw_box_line "${BRIGHT_CYAN}  Time:${RESET}     ${BRIGHT_YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    draw_box_bottom

    echo

    START=$(date +%s)

    case "$SCRIPT_PATH" in
        *.sh)
            if [[ -x "$SCRIPT_PATH" ]]; then
                "$SCRIPT_PATH" "$@"
            else
                bash "$SCRIPT_PATH" "$@"
            fi
            ;;
        *.py)
            python3 "$SCRIPT_PATH" "$@"
            ;;
        *.js)
            node "$SCRIPT_PATH" "$@"
            ;;
        *.ts)
            ts-node "$SCRIPT_PATH" "$@"
            ;;
        *.rb)
            ruby "$SCRIPT_PATH" "$@"
            ;;
        *.go)
            go run "$SCRIPT_PATH" "$@"
            ;;
        *.rs)
            rustc "$SCRIPT_PATH" -o /tmp/tool_rs_exec && /tmp/tool_rs_exec "$@"
            ;;
        *)
            print_error "Unsupported file type"
            exit 1
            ;;
    esac

    EXIT_CODE=$?
    END=$(date +%s)
    DURATION=$((END-START))

    echo

    if [ $EXIT_CODE -eq 0 ]; then
        print_success "Script completed successfully in ${BOLD}${DURATION}s${RESET}"
    else
        print_error "Script failed with exit code ${BOLD}$EXIT_CODE${RESET} after ${BOLD}${DURATION}s${RESET}"
    fi

    echo
}

# Main logic
main() {
    if [[ -z "$1" ]]; then
        show_help
        exit 0
    fi

    CMD="$1"
    shift

    case "$CMD" in
        list|l|ls)
            list_scripts
            ;;
        add|a|new)
            add_script
            ;;
        delete|del|d|rm|remove)
            delete_script
            ;;
        stats|s|statistics)
            show_stats
            ;;
        search|find|grep)
            search_scripts "$@"
            ;;
        edit|e)
            edit_script "$@"
            ;;
        help|h|--help|-h)
            show_help
            ;;
        *)
            execute_script "$CMD" "$@"
            ;;
    esac
}

main "$@"
