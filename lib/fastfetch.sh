#!/bin/bash

# =============================================================================
# FASTFETCH SETUP SCRIPT
# =============================================================================
# This script handles Fastfetch configuration and logo setup
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Initialize variables
readonly IMAGES_DIR="$(pwd)/share/Images"

setup_fastfetch() {
    echo "⚡ Setting up Fastfetch..."

    # Create Images directory if it doesn't exist
    if [[ ! -d "$HOME/Images" ]]; then
        echo "📁 Creating Images directory..."
        mkdir -p "$HOME/Images"
    fi

    # Copy logo for Fastfetch config
    if [[ -d "$IMAGES_DIR" ]]; then
        echo "📋 Copying Fastfetch assets..."
        if cp -r "$IMAGES_DIR/." "$HOME/Images/"; then
            echo "✅ Fastfetch assets copied successfully"
        else
            echo "❌ Failed to copy Fastfetch assets"
            FAILED_STEPS+=("Fastfetch assets copy failed")
            return 1
        fi
    else
        echo "❌ Images directory not found: $IMAGES_DIR"
        FAILED_STEPS+=("Fastfetch images directory not found")
        return 1
    fi

    # Generate logo for kitty terminal if available
    if _checkCommandExists kitten && [[ -f "$HOME/Images/logo.png" ]]; then
        echo "🖼️  Generating terminal logo..."
        if kitten icat -n --align=left --transfer-mode=stream "$HOME/Images/logo.png" > "$HOME/Images/logo.bin"; then
            echo "✅ Terminal logo generated successfully"
        else
            echo "⚠️  Warning: Failed to generate terminal logo (non-critical)"
        fi
    else
        echo "ℹ️  Kitty not available or logo not found, skipping terminal logo generation"
    fi
}
