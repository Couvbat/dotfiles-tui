#!/bin/bash

# =============================================================================
# AUR PACKAGE MANAGEMENT SCRIPT
# =============================================================================
# This script handles AUR helper installation and AUR package management
# Uses shared utilities for security and consistency

# Prevent multiple loading
if [[ "${AUR_LOADED:-}" == "1" ]]; then
    return 0
fi
readonly AUR_LOADED=1

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Function to install AUR packages
_installAurPackages() {
    if [[ $# -eq 0 ]]; then
        echo "❌ Error: No AUR packages specified"
        return 1
    fi
    
    local toInstall=()
    local pkg
    
    echo "🔍 Checking AUR package installation status..."
    for pkg in "$@"; do
        if _isInstalled "$pkg"; then
            echo "✅ $pkg is already installed."
        else
            toInstall+=("$pkg")
            echo "📦 $pkg will be installed."
        fi
    done
    
    if [[ ${#toInstall[@]} -gt 0 ]]; then
        echo "🚀 Installing ${#toInstall[@]} AUR package(s): ${toInstall[*]}"
        if ! paru -S --noconfirm --skipreview "${toInstall[@]}"; then
            echo "❌ Failed to install AUR packages: ${toInstall[*]}"
            FAILED_STEPS+=("AUR: ${toInstall[*]}")
            return 1
        else
            echo "✅ Successfully installed AUR packages: ${toInstall[*]}"
        fi
    else
        echo "✅ All AUR packages are already installed."
    fi
}

_installParu() {
    echo "🔧 Installing paru AUR helper..."
    
    # Ensure base-devel and rust are installed
    if ! _installPackages "base-devel" "rust"; then
        echo "❌ Error: Failed to install build dependencies"
        FAILED_STEPS+=("Failed to install paru dependencies")
        return 1
    fi
    
    # Create secure temporary directory with simpler path
    local temp_path="/tmp/paru_install_$$"
    mkdir -p "$temp_path"
    
    echo "📁 Using temporary directory: $temp_path"
    
    # Clone paru repository
    if ! git clone https://aur.archlinux.org/paru.git "$temp_path/paru"; then
        echo "❌ Error: Failed to clone paru repository"
        rm -rf "$temp_path"
        FAILED_STEPS+=("Failed to clone paru repository")
        return 1
    fi
    
    # Build and install paru (redirect output to avoid interference)
    echo "🔨 Building paru..."
    if (cd "$temp_path/paru" && makepkg -si --noconfirm --needed > /dev/null 2>&1); then
        echo "✅ paru installed successfully"
        rm -rf "$temp_path"
    else
        echo "❌ Error: Failed to build/install paru"
        rm -rf "$temp_path"
        FAILED_STEPS+=("Failed to build paru")
        return 1
    fi
}

# TUI-compatible function: Only install AUR helper
install_aur_helper() {
    echo "🛠️  Setting up AUR helper (paru)..."
    
    # Ensure paru is installed
    if ! _checkCommandExists "paru"; then
        if _installParu; then
            echo "✅ paru has been installed successfully."
        else
            echo "❌ Failed to install paru"
            FAILED_STEPS+=("Failed to install paru AUR helper")
            return 1
        fi
    else
        echo "✅ paru is already installed."
    fi
}
