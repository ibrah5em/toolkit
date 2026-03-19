#!/usr/bin/env bash
# =====================================================
# Update Everything - apt, pip, Docker images, Ollama
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

update_apt() {
    print_header "${NF_PACKAGE} System Packages (apt)"
    echo

    print_loading "Updating package lists..."
    if sudo apt update -qq 2>/dev/null; then
        print_success "Package lists updated"
    else
        print_error "Failed to update package lists"
        return 1
    fi

    print_loading "Upgrading packages..."
    if sudo apt upgrade -y 2>/dev/null; then
        print_success "System packages upgraded"
    else
        print_warning "Some packages failed to upgrade"
    fi

    sudo apt autoremove -y -qq 2>/dev/null
    sudo apt clean 2>/dev/null
    print_success "Cleanup done"
    echo
}

update_pip() {
    print_header "${NF_PYTHON} Python (pip)"
    echo

    if ! command_exists pip3; then
        print_warning "pip3 not found, skipping"
        return
    fi

    print_loading "Upgrading pip..."
    pip3 install --upgrade pip --quiet 2>/dev/null && print_success "pip upgraded" || true

    print_loading "Checking global packages..."
    local outdated
    outdated=$(pip3 list --outdated 2>/dev/null | tail -n +3 | awk '{print $1}')

    if [ -z "$outdated" ]; then
        print_success "All global packages up to date"
    else
        local count
        count=$(echo "$outdated" | wc -l)
        print_info "Upgrading $count outdated package(s)..."
        echo "$outdated" | while read -r pkg; do
            pip3 install --upgrade "$pkg" --quiet 2>/dev/null \
                && echo -e "  ${BRIGHT_GREEN}${RESET} $pkg" \
                || echo -e "  ${BRIGHT_YELLOW}${RESET} $pkg (failed)"
        done
        print_success "Done"
    fi
    echo
}

update_docker_images() {
    print_header "${NF_DOCKER} Docker Images"
    echo

    if ! command_exists docker; then
        print_warning "Docker not installed, skipping"
        return
    fi

    if ! docker ps > /dev/null 2>&1; then
        print_warning "Docker daemon not running, skipping"
        return
    fi

    local images
    images=$(docker ps -a --format '{{.Image}}' | sort -u)

    if [ -z "$images" ]; then
        print_info "No containers found, nothing to update"
        echo
        return
    fi

    local updated=0 failed=0
    while IFS= read -r image; do
        printf "  ${BRIGHT_CYAN}↓${RESET} %-45s" "$image"
        if docker pull "$image" > /dev/null 2>&1; then
            echo -e "${BRIGHT_GREEN}done${RESET}"
            ((updated++))
        else
            echo -e "${BRIGHT_RED}failed${RESET}"
            ((failed++))
        fi
    done <<< "$images"

    echo
    print_success "$updated image(s) updated"
    [ "$failed" -gt 0 ] && print_warning "$failed image(s) failed"
    echo
}

update_ollama_models() {
    print_header "${NF_CUBE} Ollama Models"
    echo

    if ! command_exists ollama; then
        print_warning "Ollama not installed, skipping"
        return
    fi

    local models
    models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

    if [ -z "$models" ]; then
        print_info "No Ollama models installed"
        echo
        return
    fi

    local updated=0
    while IFS= read -r model; do
        print_loading "Pulling $model..."
        if ollama pull "$model" > /dev/null 2>&1; then
            print_success "$model updated"
            ((updated++))
        else
            print_warning "Failed to pull $model"
        fi
    done <<< "$models"

    echo
    print_success "$updated model(s) checked"
    echo
}

main() {
    clear
    print_header "${NF_REFRESH} Update Everything — $(date '+%Y-%m-%d %H:%M')"
    echo

    local START
    START=$(date +%s)

    update_apt
    update_pip
    update_docker_images
    update_ollama_models

    local DURATION=$(( $(date +%s) - START ))
    print_double_line
    echo -e "${BRIGHT_GREEN}${BOLD}   All updates complete!${RESET}  ${DIM}(${DURATION}s)${RESET}"
    print_double_line
    echo
}

main "$@"
