#!/usr/bin/env bash
# =====================================================
# Extract - Universal archive extractor
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# ── Extract a single archive ─────────────────────────
extract_file() {
    local file="$1"
    local dest="${2:-.}"

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi

    local filename
    filename=$(basename "$file")
    local size
    size=$(du -h "$file" 2>/dev/null | cut -f1)

    print_loading "Extracting ${BOLD}$filename${RESET}${BRIGHT_BLUE} (${size})"

    mkdir -p "$dest"

    local exit_code=0
    case "$file" in
        *.tar.gz|*.tgz)     tar -xzf "$file" -C "$dest"      ;;
        *.tar.bz2|*.tbz2)   tar -xjf "$file" -C "$dest"      ;;
        *.tar.xz|*.txz)     tar -xJf "$file" -C "$dest"      ;;
        *.tar.zst)           tar --zstd -xf "$file" -C "$dest" ;;
        *.tar)               tar -xf "$file" -C "$dest"       ;;
        *.gz)                gunzip -k "$file"                 ;;
        *.bz2)               bunzip2 -k "$file"               ;;
        *.xz)                unxz -k "$file"                  ;;
        *.zip)               unzip -o "$file" -d "$dest"      ;;
        *.7z)
            require_command 7z "Install with: sudo apt install p7zip-full" || return 1
            7z x "$file" -o"$dest"
            ;;
        *.rar)
            require_command unrar "Install with: sudo apt install unrar" || return 1
            unrar x "$file" "$dest"
            ;;
        *.deb)               dpkg-deb -x "$file" "$dest"      ;;
        *.rpm)
            require_command rpm2cpio "Install with: sudo apt install rpm" || return 1
            cd "$dest" && rpm2cpio "$file" | cpio -idmv 2>/dev/null
            ;;
        *.zst)
            require_command zstd "Install with: sudo apt install zstd" || return 1
            zstd -d "$file" -o "${dest}/$(basename "${file%.zst}")"
            ;;
        *)
            print_error "Unsupported format: $filename"
            return 1
            ;;
    esac
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        local count
        count=$(find "$dest" -type f -newer "$file" 2>/dev/null | wc -l)
        print_success "Extracted to ${DIM}$dest${RESET}${BRIGHT_GREEN} ($count files)"
    else
        print_error "Extraction failed (exit code: $exit_code)"
    fi

    return $exit_code
}

# ── Peek inside an archive ───────────────────────────
peek_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi

    local filename
    filename=$(basename "$file")
    local size
    size=$(du -h "$file" 2>/dev/null | cut -f1)

    print_header "${NF_SEARCH} Contents of ${filename} (${size})"
    echo

    case "$file" in
        *.tar.gz|*.tgz)     tar -tzf "$file" | head -30  ;;
        *.tar.bz2|*.tbz2)   tar -tjf "$file" | head -30  ;;
        *.tar.xz|*.txz)     tar -tJf "$file" | head -30  ;;
        *.tar)               tar -tf "$file" | head -30   ;;
        *.zip)               unzip -l "$file" | head -35  ;;
        *.7z)                7z l "$file" 2>/dev/null | head -35 ;;
        *.rar)               unrar l "$file" 2>/dev/null | head -35 ;;
        *.deb)               dpkg-deb -c "$file" | head -30 ;;
        *)
            print_error "Unsupported format for peek: $filename"
            return 1
            ;;
    esac

    echo
    echo -e "  ${DIM}(showing first entries)${RESET}"
    echo
}

# ── Batch extract ─────────────────────────────────────
batch_extract() {
    local dir="${1:-.}"
    local found=0

    print_header "${NF_PACKAGE} Batch Extract Archives in ${dir}"
    echo

    for ext in tar.gz tgz tar.bz2 tar.xz zip 7z rar; do
        for file in "$dir"/*."$ext"; do
            [ -f "$file" ] || continue
            extract_file "$file"
            echo
            ((found++))
        done
    done

    if [ "$found" -eq 0 ]; then
        print_info "No archives found in $dir"
    else
        echo
        print_success "Extracted $found archive(s)"
    fi
    echo
}

# ── Help ──────────────────────────────────────────────
show_help() {
    print_header "${NF_PACKAGE} Extract"
    echo
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "<file> [dest]"             "Extract archive to dest (default: .)"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "peek <file>"               "List contents without extracting"
    printf "  ${BRIGHT_GREEN}%-28s${RESET} ${BRIGHT_BLACK}│${RESET} ${BRIGHT_WHITE}%s${RESET}\n" \
        "batch [dir]"               "Extract all archives in a directory"
    echo
    echo -e "  ${DIM}Supports: tar.gz, tar.bz2, tar.xz, tar.zst, zip, 7z, rar, deb, rpm${RESET}"
    echo
}

main() {
    local cmd="${1:---help}"
    shift || true

    case "$cmd" in
        peek|list|ls|l)     peek_file "$@" ;;
        batch|all)          batch_extract "$@" ;;
        help|--help|-h)     show_help ;;
        *)
            # Default: treat first arg as a file to extract
            if [ -f "$cmd" ]; then
                extract_file "$cmd" "$@"
            else
                print_error "Not a file: $cmd"
                echo
                show_help
                exit 1
            fi
            ;;
    esac
}

main "$@"
