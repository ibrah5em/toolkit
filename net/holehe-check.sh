#!/usr/bin/env bash
# =====================================================
# Holehe Check - OSINT email lookup via holehe
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# ── Config ───────────────────────────────────────────
HOLEHE_DIR="${HOLEHE_DIR:-$HOME/tools/holehe}"
HOLEHE_VENV="${HOLEHE_DIR}/venv"
HOLEHE_BIN="${HOLEHE_VENV}/bin/holehe"
DEFAULT_OUTPUT="${HOLEHE_DIR}/results.txt"

# ── Venv Activation ──────────────────────────────────
_activate_venv() {
    if [ ! -f "${HOLEHE_BIN}" ]; then
        print_error "holehe not found at ${HOLEHE_BIN}"
        print_info  "Run: cd ${HOLEHE_DIR} && python3 -m venv venv && source venv/bin/activate && pip install holehe"
        exit 1
    fi
    # Activate silently
    source "${HOLEHE_VENV}/bin/activate"
}

# ── Commands ─────────────────────────────────────────
check_email() {
    local email="$1"
    local output="${2:-}"

    _activate_venv

    print_header "${NF_SEARCH} Holehe Email Lookup"
    echo

    print_loading "Checking ${email}..."
    echo

    if [ -n "$output" ]; then
        print_single_line
        echo -e "${BRIGHT_CYAN}  Email:${RESET}  ${BRIGHT_WHITE}${email}${RESET}" | tee -a "$output"
        print_single_line
        holehe "$email" | tee -a "$output"
        echo "" >> "$output"
        echo
        print_success "Results saved to ${DIM}${output}${RESET}"
    else
        holehe "$email"
    fi
    echo
}

batch_check() {
    local output="${DEFAULT_OUTPUT}"
    local emails=()
    local file=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output) output="$2"; shift 2 ;;
            -f|--file)   file="$2";   shift 2 ;;
            *)           emails+=("$1"); shift ;;
        esac
    done

    if [ -n "$file" ]; then
        if [ ! -f "$file" ]; then
            print_error "File not found: $file"
            exit 1
        fi
        mapfile -t file_emails < "$file"
        emails+=("${file_emails[@]}")
    fi

    if [ ${#emails[@]} -eq 0 ]; then
        print_error "No emails provided"
        echo
        show_help
        exit 1
    fi

    _activate_venv

    print_header "${NF_SEARCH} Holehe Batch Lookup"
    echo

    printf "  ${BRIGHT_CYAN}%-30s${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "Output file:" "${output}"
    printf "  ${BRIGHT_CYAN}%-30s${RESET} ${BRIGHT_WHITE}%s${RESET}\n" "Emails:"      "${#emails[@]}"
    echo

    > "$output"

    local count=0
    for email in "${emails[@]}"; do
        [[ -z "$email" ]] && continue
        (( count++ ))

        print_loading "(${count}/${#emails[@]}) Checking ${email}..."

        {
            echo "============================="
            echo "EMAIL: ${email}"
            echo "============================="
            holehe "$email" 2>&1
            echo ""
        } >> "$output"

        print_success "Done: ${email}"
    done

    echo
    print_double_line
    print_success "Batch complete — ${count} email(s) checked"
    print_info    "Results saved to ${DIM}${output}${RESET}"
    echo
}

show_help() {
    print_header "${NF_SEARCH} Holehe Check"
    echo
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "check <email>"            "Check a single email"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "check <email> -o <file>"  "Check and save output to file"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "batch <e1> <e2> ..."      "Check multiple emails"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "batch -f <file>"          "Check emails from a file (one per line)"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "batch ... -o <file>"      "Save batch results to custom output file"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "help"                     "Show this help message"
    echo
    printf "  ${DIM}Default output: %s${RESET}\n" "${DEFAULT_OUTPUT}"
    echo
}

# ── Main ─────────────────────────────────────────────
main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        check|c)            check_email "$@" ;;
        batch|b|multi)      batch_check "$@" ;;
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
