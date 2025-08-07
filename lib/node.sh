#!/bin/bash

# =============================================================================
# NODE.JS INSTALLATION SCRIPT
# =============================================================================
# This script handles Node.js and NVM installation
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_node() {
    echo "🟢 Installing Node.js via NVM..."

    if ! _checkCommandExists nvm; then
        echo "📦 Installing NVM (Node Version Manager)..."
        
        # Download and install NVM
        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
            echo "✅ NVM installed successfully"
            
            # Source NVM for current session
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        else
            echo "❌ Error: Failed to install NVM"
            FAILED_STEPS+=("NVM install failed")
            return 1
        fi
    else
        echo "✅ NVM is already installed"
    fi

    # Install Node.js LTS if NVM is available
    if _checkCommandExists nvm; then
        echo "📦 Installing Node.js LTS..."
        if nvm install --lts; then
            echo "✅ Node.js LTS installed successfully"
            nvm use --lts
            echo "📊 Node.js version: $(node --version)"
            echo "📊 npm version: $(npm --version)"
        else
            echo "❌ Error: Failed to install Node.js"
            FAILED_STEPS+=("Node.js install failed")
            return 1
        fi
    else
        echo "❌ Error: NVM command not found after installation"
        FAILED_STEPS+=("NVM command not available")
        return 1
    fi
}
