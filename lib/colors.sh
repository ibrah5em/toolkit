#!/usr/bin/env bash
# =====================================================
# Color Palette - Toolkit Shared Library
# =====================================================

# Double-source guard
[[ -n "${_TOOLKIT_COLORS_LOADED:-}" ]] && return 0
_TOOLKIT_COLORS_LOADED=1

# Base Colors
readonly BLACK="\033[0;30m"
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BLUE="\033[0;34m"
readonly MAGENTA="\033[0;35m"
readonly CYAN="\033[0;36m"
readonly WHITE="\033[0;37m"

# Bright Colors
readonly BRIGHT_BLACK="\033[1;30m"
readonly BRIGHT_RED="\033[1;31m"
readonly BRIGHT_GREEN="\033[1;32m"
readonly BRIGHT_YELLOW="\033[1;33m"
readonly BRIGHT_BLUE="\033[1;34m"
readonly BRIGHT_MAGENTA="\033[1;35m"
readonly BRIGHT_CYAN="\033[1;36m"
readonly BRIGHT_WHITE="\033[1;37m"

# Special Effects
readonly BOLD="\033[1m"
readonly DIM="\033[2m"
readonly ITALIC="\033[3m"
readonly UNDERLINE="\033[4m"

# Gradient Colors
readonly GRADIENT_1="\033[38;5;255m"  # White
readonly GRADIENT_2="\033[38;5;250m"  # Light Gray
readonly GRADIENT_3="\033[38;5;245m"  # Medium Gray
readonly GRADIENT_4="\033[38;5;240m"  # Dark Gray
readonly GRADIENT_5="\033[38;5;235m"  # Charcoal

# Accent Colors (256-color)
readonly ACCENT_BLUE="\033[38;5;75m"    # Soft blue
readonly ACCENT_GREEN="\033[38;5;114m"  # Muted green
readonly ACCENT_ORANGE="\033[38;5;209m" # Warm orange
readonly ACCENT_PURPLE="\033[38;5;141m" # Lavender
readonly ACCENT_TEAL="\033[38;5;80m"    # Teal
readonly ACCENT_PINK="\033[38;5;211m"   # Soft pink
readonly ACCENT_GOLD="\033[38;5;220m"   # Gold

# Reset
readonly RESET="\033[0m"
readonly NC="$RESET"  # Backward compatibility alias
