#!/usr/bin/env bash
# =====================================================
# Docker Cleanup Utility
# Safe cleanup of Docker resources
# =====================================================

set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

require_command docker "Install Docker Desktop or docker-ce" || exit 1

# Show current Docker usage
show_docker_usage() {
    print_header "${NF_DOCKER} Current Docker Usage"
    echo

    local running_containers=$(docker ps -q | wc -l)
    local stopped_containers=$(docker ps -a -q | wc -l)
    local exited_containers=$(docker ps -a -f status=exited -q | wc -l)

    echo -e "${CYAN}Containers:${RESET}"
    echo -e "  Running:  ${running_containers}"
    echo -e "  Stopped:  ${stopped_containers}"
    echo -e "  Exited:   ${BRIGHT_YELLOW}${exited_containers}${RESET}"

    echo

    local total_images=$(docker images -q | wc -l)
    local dangling_images=$(docker images -f "dangling=true" -q | wc -l)

    echo -e "${CYAN}Images:${RESET}"
    echo -e "  Total:    ${total_images}"
    echo -e "  Dangling: ${BRIGHT_YELLOW}${dangling_images}${RESET}"

    echo

    local total_volumes=$(docker volume ls -q | wc -l)
    local dangling_volumes=$(docker volume ls -f "dangling=true" -q | wc -l)

    echo -e "${CYAN}Volumes:${RESET}"
    echo -e "  Total:    ${total_volumes}"
    echo -e "  Dangling: ${BRIGHT_YELLOW}${dangling_volumes}${RESET}"

    echo

    local total_networks=$(docker network ls -q | wc -l)

    echo -e "${CYAN}Networks:${RESET}"
    echo -e "  Total:    ${total_networks}"

    echo

    echo -e "${CYAN}Disk Usage:${RESET}"
    docker system df

    echo
}

# Remove stopped containers
cleanup_stopped_containers() {
    log_info "Looking for stopped containers..."

    local stopped=$(docker ps -a -f status=exited -q | wc -l)

    if [ "$stopped" -eq 0 ]; then
        log_success "No stopped containers to remove"
        return 0
    fi

    echo -e "${YELLOW}Found ${stopped} stopped containers${RESET}"

    echo
    docker ps -a -f status=exited --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    echo

    read -p "Remove these containers? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker container prune -f
        log_success "Stopped containers removed"
    else
        log_info "Skipped"
    fi
}

# Remove dangling images
cleanup_dangling_images() {
    log_info "Looking for dangling images..."

    local dangling=$(docker images -f "dangling=true" -q | wc -l)

    if [ "$dangling" -eq 0 ]; then
        log_success "No dangling images to remove"
        return 0
    fi

    echo -e "${YELLOW}Found ${dangling} dangling images${RESET}"
    echo

    read -p "Remove dangling images? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker image prune -f
        log_success "Dangling images removed"
    else
        log_info "Skipped"
    fi
}

# Remove unused volumes
cleanup_unused_volumes() {
    log_info "Looking for unused volumes..."

    local unused=$(docker volume ls -f "dangling=true" -q | wc -l)

    if [ "$unused" -eq 0 ]; then
        log_success "No unused volumes to remove"
        return 0
    fi

    log_warning "Found ${unused} unused volumes"
    echo
    docker volume ls -f "dangling=true"
    echo

    log_warning "This will permanently delete volume data!"
    read -p "Remove unused volumes? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        docker volume prune -f
        log_success "Unused volumes removed"
    else
        log_info "Skipped"
    fi
}

# Remove unused networks
cleanup_unused_networks() {
    log_info "Looking for unused networks..."

    read -p "Remove unused networks? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker network prune -f
        log_success "Unused networks removed"
    else
        log_info "Skipped"
    fi
}

# Remove build cache
cleanup_build_cache() {
    log_info "Checking build cache..."

    local cache_size=$(docker system df -v | grep "Build Cache" | awk '{print $4}')

    if [ -n "$cache_size" ] && [ "$cache_size" != "0B" ]; then
        echo -e "${YELLOW}Build cache: ${cache_size}${RESET}"
        echo

        read -p "Clear build cache? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker builder prune -f
            log_success "Build cache cleared"
        else
            log_info "Skipped"
        fi
    else
        log_success "No build cache to clear"
    fi
}

# Full system cleanup (aggressive)
full_cleanup() {
    log_warning "FULL SYSTEM CLEANUP"
    echo
    echo -e "${YELLOW}This will remove:${RESET}"
    echo "  - All stopped containers"
    echo "  - All unused images"
    echo "  - All unused volumes"
    echo "  - All unused networks"
    echo "  - All build cache"
    echo
    log_warning "This action cannot be undone!"
    echo

    read -p "Type 'CLEANUP' to confirm: " confirm

    if [ "$confirm" = "CLEANUP" ]; then
        echo
        log_info "Performing full cleanup..."
        echo

        docker system prune -a -f --volumes

        echo
        log_success "Full cleanup completed!"
    else
        log_info "Cancelled"
    fi
}

# Show menu
show_menu() {
    print_header "${NF_DOCKER} Docker Cleanup Utility"
    echo
    echo "Choose cleanup option:"
    echo
    echo "  1) Show current usage"
    echo "  2) Remove stopped containers"
    echo "  3) Remove dangling images"
    echo "  4) Remove unused volumes"
    echo "  5) Remove unused networks"
    echo "  6) Clear build cache"
    echo "  7) Full cleanup (aggressive)"
    echo "  8) Custom cleanup (step-by-step)"
    echo "  0) Exit"
    echo
}

# Interactive cleanup
interactive_cleanup() {
    log_info "Starting step-by-step cleanup..."
    echo

    cleanup_stopped_containers
    echo

    cleanup_dangling_images
    echo

    cleanup_unused_volumes
    echo

    cleanup_unused_networks
    echo

    cleanup_build_cache
    echo

    log_success "Interactive cleanup completed!"
}

# Show savings
show_savings() {
    echo
    print_header "${NF_DOCKER} Space Reclaimed"
    echo
    docker system df
    echo
}

# Main menu loop
main() {
    if [ "$1" = "--full" ] || [ "$1" = "-f" ]; then
        show_docker_usage
        full_cleanup
        show_savings
        exit 0
    fi

    if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
        show_docker_usage
        interactive_cleanup
        show_savings
        exit 0
    fi

    while true; do
        clear
        show_menu

        read -p "Enter choice [0-8]: " choice
        echo

        case $choice in
            1)
                show_docker_usage
                read -p "Press Enter to continue..."
                ;;
            2)
                cleanup_stopped_containers
                read -p "Press Enter to continue..."
                ;;
            3)
                cleanup_dangling_images
                read -p "Press Enter to continue..."
                ;;
            4)
                cleanup_unused_volumes
                read -p "Press Enter to continue..."
                ;;
            5)
                cleanup_unused_networks
                read -p "Press Enter to continue..."
                ;;
            6)
                cleanup_build_cache
                read -p "Press Enter to continue..."
                ;;
            7)
                full_cleanup
                show_savings
                read -p "Press Enter to continue..."
                ;;
            8)
                interactive_cleanup
                show_savings
                read -p "Press Enter to continue..."
                ;;
            0)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                sleep 2
                ;;
        esac
    done
}

main "$@"
