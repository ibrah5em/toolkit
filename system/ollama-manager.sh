#!/usr/bin/env bash
#═══════════════════════════════════════════════════════════════════════════
# ULTIMATE OLLAMA MODEL MANAGER v2.0
# Features: Auto-retry, Protection, Status monitoring, Disk management
#═══════════════════════════════════════════════════════════════════════════

set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_TOOLKIT_DIR="$(dirname "${_SCRIPT_DIR}")"
source "${_TOOLKIT_DIR}/lib/config.sh"
source "${_TOOLKIT_DIR}/lib/ui.sh"
source "${_TOOLKIT_DIR}/lib/utils.sh"

# Configuration
MODELS_PATH="$HOME/.ollama/models"
MAX_RETRIES=999
LOCK_ENABLED=true
OLLAMA_BIN="${OLLAMA_BIN:-ollama}"

# Unique to this script
print_step() {
    echo -e "${MAGENTA} $1${RESET}"
}

# Progress bar function
show_progress() {
    local duration=${1:-2}
    local width=50
    local count=0
    local delay
    delay=$(awk "BEGIN {printf \"%.3f\", $duration/$width}")

    printf "${CYAN}["
    while [ $count -lt $width ]; do
        printf ""
        count=$((count + 1))
        sleep "$delay"
    done
    printf "]${RESET}\n"
}

#═══════════════════════════════════════════════════════════════════════════
# Protection Functions
#═══════════════════════════════════════════════════════════════════════════

unlock_models() {
    print_step "Unlocking models for modification..."

    if command_exists chattr; then
        sudo chattr -i "$MODELS_PATH/blobs/"* 2>/dev/null || true
        sudo chattr -i "$MODELS_PATH/manifests/"* 2>/dev/null || true
    fi

    chmod -R 755 "$MODELS_PATH" 2>/dev/null || true

    print_success "Models unlocked"
}

lock_models() {
    if [ "$LOCK_ENABLED" = false ]; then
        print_info "Auto-lock disabled, skipping..."
        return 0
    fi

    print_step "Locking models for protection..."

    chmod -R 555 "$MODELS_PATH" 2>/dev/null || true

    if command_exists chattr; then
        sudo chattr +i "$MODELS_PATH/blobs/"* 2>/dev/null || true
        sudo chattr +i "$MODELS_PATH/manifests/"* 2>/dev/null || true
        print_success "Models locked (read-only + immutable)"
    else
        print_success "Models locked (read-only)"
        print_warning "Install e2fsprogs for immutable flag protection"
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# Enhanced Status Functions
#═══════════════════════════════════════════════════════════════════════════

show_detailed_status() {
    print_header "${NF_CUBE} OLLAMA DETAILED STATUS"

    echo -e "\n${MAGENTA}${BOLD}Installed Models:${RESET}"
    if command_exists $OLLAMA_BIN; then
        $OLLAMA_BIN list 2>/dev/null || print_error "Failed to list models"
    else
        print_error "Ollama not found in PATH"
    fi

    echo -e "\n${MAGENTA}${BOLD}Protection Status:${RESET}"
    if [ -d "$MODELS_PATH" ]; then
        local permissions=$(ls -ld "$MODELS_PATH" | awk '{print $1}')
        echo "  Directory: $permissions"

        if command_exists lsattr && [ -d "$MODELS_PATH/blobs" ]; then
            local immutable_count=$(lsattr "$MODELS_PATH/blobs/"* 2>/dev/null | grep -c "^....i" || echo 0)
            if [ "$immutable_count" -gt 0 ]; then
                echo -e "  Immutable: ${GREEN}$immutable_count files protected${RESET}"
            else
                echo -e "  Immutable: ${YELLOW}Not protected${RESET}"
            fi
        fi
    else
        echo "  Models directory not found"
    fi

    echo -e "\n${MAGENTA}${BOLD}Storage Analysis:${RESET}"
    if [ -d "$MODELS_PATH" ]; then
        local total_size=$(du -sh "$MODELS_PATH" 2>/dev/null | cut -f1)
        local blob_size=$(du -sh "$MODELS_PATH/blobs" 2>/dev/null | cut -f1 || echo "0")
        local manifest_size=$(du -sh "$MODELS_PATH/manifests" 2>/dev/null | cut -f1 || echo "0")

        echo "  Total: $total_size"
        echo "  Blobs: $blob_size"
        echo "  Manifests: $manifest_size"

        local avail_space=$(df -h "$MODELS_PATH" | awk 'NR==2 {print $4}')
        echo "  Available: $avail_space"
    fi

    echo -e "\n${MAGENTA}${BOLD}System Status:${RESET}"
    if systemctl --user is-active ollama >/dev/null 2>&1; then
        echo -e "  Ollama Service: ${GREEN}Running${RESET}"
    else
        echo -e "  Ollama Service: ${RED}Not running${RESET}"
    fi

    if command_exists $OLLAMA_BIN; then
        echo -e "  Ollama Version: $($OLLAMA_BIN --version 2>/dev/null || echo "Unknown")"
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# Enhanced Download Function
#═══════════════════════════════════════════════════════════════════════════

download_model() {
    local MODEL="$1"
    local RETRY_COUNT=0
    local START_TIME=$(date +%s)

    if [ -z "$MODEL" ]; then
        print_error "No model specified"
        echo "Usage: $0 pull <model-name>"
        echo "Examples:"
        echo "  $0 pull llama3.2:3b"
        echo "  $0 pull mistral:latest"
        exit 1
    fi

    print_header "${NF_DOWNLOAD} DOWNLOADING MODEL: $MODEL"

    if $OLLAMA_BIN list 2>/dev/null | grep -q "^$MODEL"; then
        print_warning "Model $MODEL already exists"
        read -p "Re-download? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Download cancelled"
            exit 0
        fi
    fi

    print_step "Checking disk space..."
    local avail_kb=$(df -k "$MODELS_PATH" | awk 'NR==2 {print $4}')
    if [ "$avail_kb" -lt 10000000 ]; then
        print_warning "Low disk space available: $(echo "scale=1; $avail_kb/1024/1024" | bc)GB"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    unlock_models

    echo ""
    echo -e "${CYAN}Press Ctrl+C to pause, then re-run to resume${RESET}"
    echo -e "${CYAN}Using ollama binary: $(which $OLLAMA_BIN)${RESET}"
    echo "════════════════════════════════════════════════════════"
    echo ""

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        print_step "Download attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"

        if $OLLAMA_BIN pull "$MODEL"; then
            local END_TIME=$(date +%s)
            local DURATION=$((END_TIME - START_TIME))

            echo ""
            print_success "Model downloaded successfully in ${DURATION} seconds!"

            lock_models

            print_step "Model details:"
            $OLLAMA_BIN show "$MODEL" --modelfile 2>/dev/null | head -20 || true

            return 0
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo ""
        print_warning "Download interrupted (attempt $RETRY_COUNT)"

        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo -e "${BLUE}Resuming in 3 seconds... (Ctrl+C to cancel)${RESET}"
            for i in {3..1}; do
                echo -ne "Resuming in $i...\r"
                sleep 1
            done
            echo ""
        fi
    done

    print_error "Max retries reached ($MAX_RETRIES attempts)"
    lock_models
    exit 1
}

#═══════════════════════════════════════════════════════════════════════════
# Enhanced Remove Model Function
#═══════════════════════════════════════════════════════════════════════════

remove_model() {
    local MODEL="$1"

    if [ -z "$MODEL" ]; then
        print_error "No model specified"
        echo "Usage: $0 remove <model-name>"
        exit 1
    fi

    print_header "${NF_TRASH} REMOVING MODEL: $MODEL"

    local model_size=""
    if [ -d "$MODELS_PATH/blobs" ]; then
        model_size=$(du -sh "$MODELS_PATH" 2>/dev/null | cut -f1 || echo "unknown")
    fi

    echo -e "${RED}${BOLD}WARNING: This will permanently delete the model${RESET}"
    echo -e "${RED}Model: $MODEL${RESET}"
    [ -n "$model_size" ] && echo -e "${RED}Size: ~$model_size${RESET}"
    echo ""

    read -p "Type 'DELETE' to confirm: " confirm

    if [ "$confirm" != "DELETE" ]; then
        print_info "Deletion cancelled"
        exit 0
    fi

    unlock_models

    print_step "Removing model..."
    if $OLLAMA_BIN rm "$MODEL"; then
        print_success "Model removed"

        print_step "Cleaning up..."
        show_progress 1

        lock_models

        show_detailed_status
    else
        print_error "Failed to remove model"
        lock_models
        exit 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# Cleanup Functions
#═══════════════════════════════════════════════════════════════════════════

cleanup_orphaned() {
    print_header "${NF_ERASER} CLEANING ORPHANED LAYERS"

    print_warning "This will remove unused model layers"
    print_warning "Make sure no models are being downloaded or modified"

    read -p "Continue? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Cleanup cancelled"
        exit 0
    fi

    unlock_models

    print_step "Running Ollama garbage collection..."
    if $OLLAMA_BIN prune; then
        print_success "Cleanup completed"
    else
        print_error "Cleanup failed"
    fi

    lock_models
    show_detailed_status
}

#═══════════════════════════════════════════════════════════════════════════
# Model Inspector
#═══════════════════════════════════════════════════════════════════════════

inspect_model() {
    local MODEL="$1"

    if [ -z "$MODEL" ]; then
        print_error "No model specified"
        echo "Usage: $0 inspect <model-name>"
        exit 1
    fi

    print_header "${NF_SEARCH} INSPECTING MODEL: $MODEL"

    if ! $OLLAMA_BIN list 2>/dev/null | grep -q "^$MODEL"; then
        print_error "Model not found locally"
        exit 1
    fi

    echo -e "\n${MAGENTA}${BOLD}Model Information:${RESET}"
    $OLLAMA_BIN show "$MODEL" --modelfile 2>/dev/null || print_error "Could not get model details"

    echo -e "\n${MAGENTA}${BOLD}Storage Details:${RESET}"
    if [ -d "$MODELS_PATH/blobs" ]; then
        local size_kb=$(find "$MODELS_PATH" -type f -name "*.bin" -o -name "*.gguf" 2>/dev/null | xargs du -k 2>/dev/null | awk '{sum+=$1} END {print sum}')
        if [ -n "$size_kb" ]; then
            local size_gb=$(echo "scale=2; $size_kb/1024/1024" | bc)
            echo "  Approximate size: ${size_gb}GB"
        fi
    fi

    echo -e "\n${MAGENTA}${BOLD}Model Location:${RESET}"
    echo "  $MODELS_PATH"
}

#═══════════════════════════════════════════════════════════════════════════
# Quick Start Functions
#═══════════════════════════════════════════════════════════════════════════

quick_start() {
    print_header "${NF_ROCKET} QUICK START"

    echo -e "\n${BOLD}Popular Models:${RESET}"
    echo "1) llama3.2:3b        (Lightweight, general purpose)"
    echo "2) mistral:7b         (Good balance of size/performance)"
    echo "3) codellama:7b       (Programming focused)"
    echo "4) phi3:mini          (Small but capable)"
    echo "5) Custom model"

    echo -e "\n${YELLOW}Enter your choice (1-5):${RESET} "
    read choice

    case $choice in
        1) MODEL="llama3.2:3b" ;;
        2) MODEL="mistral:7b" ;;
        3) MODEL="codellama:7b" ;;
        4) MODEL="phi3:mini" ;;
        5)
            echo -e "\n${YELLOW}Enter model name (e.g., 'qwen2.5:7b'):${RESET} "
            read MODEL
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    download_model "$MODEL"
}

#═══════════════════════════════════════════════════════════════════════════
# Main Menu
#═══════════════════════════════════════════════════════════════════════════

show_help() {
    cat << EOF
╔═══════════════════════════════════════════════════════════════╗
║  ULTIMATE OLLAMA MODEL MANAGER v2.0                            ║
╚═══════════════════════════════════════════════════════════════╝

Usage: $0 <command> [options]

Commands:
  pull <model>        Download model with auto-retry and protection
  remove <model>      Safely remove a model (with size warning)
  list                Show all installed models
  status              Show detailed system and model status (alias: info)
  inspect <model>     Show detailed information about a model
  lock                Lock all models (read-only + immutable)
  unlock              Unlock models for manual changes
  cleanup             Remove orphaned/unused model layers
  quick               Interactive quick start menu
  help                Show this help message

Examples:
  $0 pull llama3.2:3b
  $0 pull mistral:latest
  $0 remove llama3.2:3b
  $0 inspect codellama:7b
  $0 status
  $0 quick

Enhancements:
  - Auto-retry on interrupted downloads (999 retries)
  - Automatic model protection (immutable + read-only)
  - Detailed storage analysis and disk space checks
  - Model inspection tool
  - Orphaned layer cleanup
  - Quick start wizard for beginners
  - Download timing and progress tracking
  - Disk space verification before downloads

Environment Variables:
  OLLAMA_BIN=/path/to/ollama    Custom ollama binary path
  LOCK_ENABLED=false            Disable auto-locking (default: true)
  MAX_RETRIES=5                 Change retry limit (default: 999)

EOF
}

#═══════════════════════════════════════════════════════════════════════════
# Main Execution
#═══════════════════════════════════════════════════════════════════════════

require_command $OLLAMA_BIN "Please install Ollama first. Visit: https://ollama.ai" || exit 1

if [ ! -d "$MODELS_PATH" ]; then
    print_warning "Models directory not found at: $MODELS_PATH"
    print_info "Ollama will create it automatically on first use"
fi

COMMAND="${1:-help}"

case "$COMMAND" in
    pull|download|add)
        download_model "$2"
        ;;

    remove|rm|delete)
        remove_model "$2"
        ;;

    list|ls)
        $OLLAMA_BIN list
        ;;

    status)
        show_detailed_status
        ;;

    inspect|show|info)
        inspect_model "$2"
        ;;

    lock|protect)
        lock_models
        print_success "Models locked"
        ;;

    unlock|unprotect)
        unlock_models
        print_success "Models unlocked"
        ;;

    cleanup|prune|gc)
        cleanup_orphaned
        ;;

    quick|start|wizard)
        quick_start
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
