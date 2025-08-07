#!/bin/bash

# =============================================================================
# ZSH SHELL SETUP SCRIPT
# =============================================================================
# This script handles ZSH installation and configuration with Oh My Zsh
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

setup_zsh() {
    echo "🐚 Setting up ZSH Shell..."

    if ! _checkCommandExists zsh; then
        echo "📦 Installing zsh..."
        if _installPackages "zsh"; then
            echo "✅ ZSH installed successfully"
        else
            echo "❌ Failed to install ZSH"
            FAILED_STEPS+=("ZSH installation failed")
            return 1
        fi
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != "/bin/zsh" ]] && [[ "$SHELL" != "/usr/bin/zsh" ]]; then
        echo "🔧 Changing default shell to ZSH..."
        local zsh_path
        zsh_path=$(which zsh)
        
        # Check if zsh is in /etc/shells
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "📝 Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        
        if sudo chsh -s "$zsh_path" "$USER"; then
            echo "✅ Default shell changed to ZSH"
            echo "ℹ️  Please log out and back in for the shell change to take effect"
        else
            echo "❌ Failed to change default shell"
            FAILED_STEPS+=("Failed to change shell to ZSH")
        fi
    else
        echo "✅ ZSH is already the default shell"
    fi

    # Install Oh My Zsh
    install_oh_my_zsh
    
    # Install ZSH plugins
    install_zsh_plugins
}

install_oh_my_zsh() {
    echo "🎨 Setting up Oh My Zsh..."
    
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "📥 Installing Oh My Zsh..."
        if wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh; then
            echo "✅ Oh My Zsh installed successfully"
        else
            echo "❌ Failed to install Oh My Zsh"
            FAILED_STEPS+=("Oh My Zsh installation failed")
            return 1
        fi
    else
        echo "✅ Oh My Zsh is already installed"
    fi
}

install_zsh_plugins() {
    echo "🔌 Installing ZSH plugins..."
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        echo "📦 Installing zsh-syntax-highlighting..."
        if git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"; then
            echo "✅ zsh-syntax-highlighting installed"
        else
            echo "❌ Failed to install zsh-syntax-highlighting"
            FAILED_STEPS+=("zsh-syntax-highlighting installation failed")
        fi
    else
        echo "✅ zsh-syntax-highlighting already installed"
    fi

    # Install fast-syntax-highlighting
    if [[ ! -d "$plugins_dir/fast-syntax-highlighting" ]]; then
        echo "📦 Installing fast-syntax-highlighting..."
        if git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugins_dir/fast-syntax-highlighting"; then
            echo "✅ fast-syntax-highlighting installed"
        else
            echo "❌ Failed to install fast-syntax-highlighting"
            FAILED_STEPS+=("fast-syntax-highlighting installation failed")
        fi
    else
        echo "✅ fast-syntax-highlighting already installed"
    fi

    # Install zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        echo "📦 Installing zsh-autosuggestions..."
        if git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"; then
            echo "✅ zsh-autosuggestions installed"
        else
            echo "❌ Failed to install zsh-autosuggestions"
            FAILED_STEPS+=("zsh-autosuggestions installation failed")
        fi
    else
        echo "✅ zsh-autosuggestions already installed"
    fi
}
