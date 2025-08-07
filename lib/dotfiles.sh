#!/bin/bash

# =============================================================================
# DOTFILES COPY SCRIPT
# =============================================================================
# This script handles copying dotfiles to the user's home directory
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Initialize variables
readonly DOTFILES_DIR="$(pwd)/share/dotfiles"

copy_dotfiles() {
    echo "📂 Copying dotfiles configuration..."

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "❌ Error: dotfiles directory not found at $DOTFILES_DIR"
        FAILED_STEPS+=("Dotfiles source directory not found")
        return 1
    fi

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    # Copy dotfiles to home directory
    echo "📋 Copying configuration files..."
    if cp -r "$DOTFILES_DIR/." "$HOME/"; then
        echo "✅ Dotfiles copied successfully"
        
        # Set appropriate permissions
        echo "🔐 Setting file permissions..."
        find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        
        echo "✅ Dotfiles setup completed"
    else
        echo "❌ Error: Failed to copy dotfiles"
        FAILED_STEPS+=("Dotfiles copy operation failed")
        return 1
    fi
}
