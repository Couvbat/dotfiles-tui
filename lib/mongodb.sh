#!/bin/bash

# =============================================================================
# MONGODB INSTALLATION SCRIPT
# =============================================================================
# This script handles MongoDB installation and configuration
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_mongodb() {
    echo "🍃 Installing MongoDB..."

    if ! _checkCommandExists mongod; then
        echo "📦 Installing MongoDB from AUR..."
        if _checkCommandExists paru; then
            echo "🔄 Attempting to install mongodb-bin..."
            if paru -S --noconfirm --skipreview mongodb-bin; then
                echo "✅ MongoDB installed successfully"
                enable_service "mongodb.service"
            else
                echo "⚠️  mongodb-bin failed, trying mongodb-community..."
                if paru -S --noconfirm --skipreview mongodb-community; then
                    echo "✅ MongoDB Community installed successfully"
                    enable_service "mongodb.service"
                else
                    echo "❌ Error: Failed to install MongoDB"
                    echo "ℹ️  You can manually install MongoDB later with:"
                    echo "   paru -S mongodb-bin"
                    FAILED_STEPS+=("MongoDB build not found")
                    return 1
                fi
            fi
        else
            echo "❌ Error: paru is required for MongoDB installation"
            echo "ℹ️  Install paru first, then run: paru -S mongodb-bin"
            FAILED_STEPS+=("Failed to install paru AUR helper")
            return 1
        fi
    else
        echo "✅ MongoDB is already installed"
    fi
}
