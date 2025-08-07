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
            if paru -S --noconfirm mongodb-bin; then
                echo "✅ MongoDB installed successfully"
                enable_service "mongodb.service"
            else
                echo "❌ Error: Failed to install MongoDB"
                FAILED_STEPS+=("MongoDB installation failed")
                return 1
            fi
        else
            echo "❌ Error: paru is required for MongoDB installation"
            FAILED_STEPS+=("MongoDB: paru not found")
            return 1
        fi
    else
        echo "✅ MongoDB is already installed"
    fi
}
