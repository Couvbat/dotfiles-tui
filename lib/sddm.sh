#!/bin/bash

# =============================================================================
# SDDM DISPLAY MANAGER SETUP SCRIPT
# =============================================================================
# This script handles SDDM theme installation and configuration
# Uses shared utilities for security and consistency

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Initialize variables
readonly SDDM_THEME_REPO="https://codeberg.org/minMelody/sddm-sequoia.git"
readonly SDDM_THEME_NAME="sequoia"
readonly SDDM_THEME_PATH="/usr/share/sddm/themes/$SDDM_THEME_NAME"
readonly SDDM_ASSET_FOLDER="$SDDM_THEME_PATH/backgrounds"
readonly SDDM_WALLPAPERS_DIR="$HOME/Wallpapers"
readonly SDDM_CONFIG_DIR="/etc/sddm.conf.d"

setup_sddm() {
    echo "🖥️  Setting up SDDM Display Manager..."

    # Create SDDM configuration directories if they don't exist
    if [[ ! -d "$SDDM_CONFIG_DIR" ]]; then
        echo "📁 Creating SDDM configuration directory"
        sudo mkdir -p "$SDDM_CONFIG_DIR"
    fi

    # Install SDDM theme
    install_sddm_theme

    # Copy wallpapers to SDDM theme
    copy_wallpapers_to_theme

    # Configure SDDM
    configure_sddm_settings

    echo "✅ SDDM setup completed successfully"
}

install_sddm_theme() {
    echo "🎨 Installing Sequoia SDDM theme..."
    
    # Remove existing theme if present
    if [[ -d "$SDDM_THEME_PATH" ]]; then
        echo "🗑️  Removing existing Sequoia theme"
        sudo rm -rf "$SDDM_THEME_PATH"
    fi

    # Create secure temporary directory
    local temp_dir
    temp_dir=$(create_temp_dir)
    
    echo "📥 Cloning SDDM theme repository..."
    if ! git clone "$SDDM_THEME_REPO" "$temp_dir/sddm-theme"; then
        echo "❌ Error: Failed to clone SDDM theme repository"
        FAILED_STEPS+=("SDDM theme clone failed")
        return 1
    fi

    echo "📋 Installing SDDM theme..."
    if sudo cp -r "$temp_dir/sddm-theme" "$SDDM_THEME_PATH"; then
        echo "✅ SDDM theme installed successfully"
    else
        echo "❌ Error: Failed to install SDDM theme"
        FAILED_STEPS+=("SDDM theme installation failed")
        return 1
    fi
}

copy_wallpapers_to_theme() {
    echo "🖼️  Copying wallpapers to SDDM theme..."
    
    if [[ ! -d "$SDDM_WALLPAPERS_DIR" ]]; then
        echo "⚠️  Warning: Wallpapers directory not found: $SDDM_WALLPAPERS_DIR"
        FAILED_STEPS+=("SDDM wallpapers directory not found")
        return 1
    fi

    # Create backgrounds directory in theme
    if sudo mkdir -p "$SDDM_ASSET_FOLDER"; then
        echo "📁 Created SDDM backgrounds directory"
    else
        echo "❌ Error: Failed to create SDDM backgrounds directory"
        FAILED_STEPS+=("Failed to create SDDM backgrounds directory")
        return 1
    fi

    # Copy wallpapers
    if sudo cp -r "$SDDM_WALLPAPERS_DIR"/* "$SDDM_ASSET_FOLDER/"; then
        echo "✅ Wallpapers copied to SDDM theme"
    else
        echo "❌ Error: Failed to copy wallpapers to SDDM theme"
        FAILED_STEPS+=("Failed to copy wallpapers to SDDM")
        return 1
    fi
}

configure_sddm_settings() {
    echo "⚙️  Configuring SDDM settings..."
    
    local sddm_config_file="$SDDM_CONFIG_DIR/sddm.conf"
    local theme_config_file="$SDDM_CONFIG_DIR/theme.conf"
    
    # Copy SDDM configuration files from share directory
    local share_sddm_dir="$(pwd)/share/sddm"
    
    if [[ -f "$share_sddm_dir/sddm.conf" ]]; then
        echo "📄 Installing SDDM configuration..."
        if sudo cp "$share_sddm_dir/sddm.conf" "$sddm_config_file"; then
            echo "✅ SDDM configuration installed"
        else
            echo "❌ Error: Failed to install SDDM configuration"
            FAILED_STEPS+=("Failed to install SDDM configuration")
        fi
    else
        echo "⚠️  Warning: SDDM configuration file not found in share directory"
    fi
    
    if [[ -f "$share_sddm_dir/theme.conf" ]]; then
        echo "📄 Installing SDDM theme configuration..."
        if sudo cp "$share_sddm_dir/theme.conf" "$theme_config_file"; then
            echo "✅ SDDM theme configuration installed"
        else
            echo "❌ Error: Failed to install SDDM theme configuration"
            FAILED_STEPS+=("Failed to install SDDM theme configuration")
        fi
    else
        echo "⚠️  Warning: SDDM theme configuration file not found in share directory"
    fi
}

    git clone "$SDDM_THEME_REPO" ~/sequoia && rm -rf ~/sequoia/.git
    sudo mv ~/sequoia "$SDDM_THEME_PATH"

    # Create the backgrounds directory in the theme if it doesn't exist
    if [ -d "$SDDM_ASSET_FOLDER" ]; then
        echo ":: Sequoia theme backgrounds directory already exists, removing old version"
        sudo rm -rf "$SDDM_ASSET_FOLDER"
    fi

    echo ":: Creating SDDM theme backgrounds directory"
    sudo mkdir -p "$SDDM_ASSET_FOLDER"

    # Copy the wallpaper from our share directory to SDDM theme
    echo ":: Copying wallpaper to SDDM theme"
    sudo cp "$SDDM_WALLPAPERS_DIR/Solitary-Glow.png" "$SDDM_ASSET_FOLDER/current_wallpaper.jpg"
    echo ":: Default wallpaper copied to SDDM theme folder"

    # Copy our SDDM configurations
    echo ":: Copying SDDM configuration files"
            sudo cp share/sddm/sddm.conf "$SDDM_CONFIG_DIR/"
    sudo cp share/sddm/theme.conf "$SDDM_THEME_PATH/theme.conf"

    # Enable SDDM service
    sudo systemctl enable sddm.service
    echo ":: SDDM service enabled"
}
