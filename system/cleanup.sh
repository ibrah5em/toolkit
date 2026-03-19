#!/usr/bin/env bash
# =====================================================
# System Cleanup Script
# =====================================================

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

print_info "System Cleanup Script"

clean_system() {
    print_loading "Cleaning system packages..."
    sudo apt autoremove -y
    sudo apt clean
    print_success "System packages cleaned"

    if command_exists docker; then
        print_loading "Pruning Docker..."
        docker system prune -f 2>/dev/null && print_success "Docker cleaned"
    fi

    if command_exists npm; then
        print_loading "Cleaning npm cache..."
        npm cache clean --force 2>/dev/null && print_success "npm cache cleaned"
    fi

    print_loading "Cleaning temporary files..."
    # Only clean current user's temp files, not all of /tmp
    find /tmp -maxdepth 1 -user "$(whoami)" -mtime +1 -delete 2>/dev/null || true
    find ~ -maxdepth 4 -name "*.tmp" ! -path "*/.git/*" ! -path "*/node_modules/*" -delete 2>/dev/null || true
    print_success "Temp files cleaned"
}

clean_projects() {
    if [ ! -d "$HOME/projects" ]; then
        print_info "No projects directory found, skipping project cleanup"
        return
    fi

    if ! confirm_action "Clean old project builds (node_modules/dist/build older than 30 days)?"; then
        print_info "Skipped project cleanup"
        return
    fi

    print_loading "Cleaning old project builds..."
    find ~/projects -name "node_modules" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
    find ~/projects -name "dist" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
    find ~/projects -name "build" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
    print_success "Old builds cleaned"
}

print_loading "Starting cleanup process..."
clean_system
clean_projects
print_success "Cleanup completed! System is sparkling!"
