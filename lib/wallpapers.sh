#!/bin/bash

# =============================================================================
# WALLPAPERS SETUP SCRIPT
# =============================================================================
# This script handles wallpaper repository cloning and setup
# Uses shared utilities for security and consistency

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Initialize variables
readonly WALLPAPER_REPO="https://github.com/couvbat/wallpapers.git"
readonly TARGET_DIR="$HOME/Wallpapers"
readonly CACHE_DIR="$HOME/.config/ml4w/cache"

setup_wallpapers() {
    echo "🖼️  Setting up wallpapers..."

    # Create secure temporary directory
    local temp_dir
    temp_dir=$(create_temp_dir)
    
    echo "📁 Using temporary directory: $temp_dir"

    # Clone the wallpapers repository into temporary directory
    echo "📥 Cloning wallpapers repository..."
    if ! git clone "$WALLPAPER_REPO" "$temp_dir/wallpapers"; then
        echo "❌ Error: Failed to clone wallpapers repository"
        FAILED_STEPS+=("Wallpapers clone failed")
        return 1
    fi

    # Ensure the target wallpaper directory exists
    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "📁 Creating wallpapers directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi

    # Copy wallpapers from the cloned repository
    local wallpapers_source="$temp_dir/wallpapers/share"
    if [[ -d "$wallpapers_source" ]]; then
        echo "📋 Copying wallpapers to $TARGET_DIR/"
        if cp -r "$wallpapers_source"/* "$TARGET_DIR/"; then
            echo "✅ Wallpapers copied successfully"
        else
            echo "❌ Error: Failed to copy wallpapers"
            FAILED_STEPS+=("Wallpapers copy failed")
            return 1
        fi
    else
        echo "❌ Error: Wallpapers directory not found in repository: $wallpapers_source"
        FAILED_STEPS+=("Wallpapers source directory not found")
        return 1
    fi

    # Set the default wallpaper
    setup_default_wallpaper

    echo "✅ Wallpaper setup completed successfully"
}

setup_default_wallpaper() {
    echo "🎨 Setting up default wallpaper..."
    
    local default_wallpaper="$TARGET_DIR/Solitary-Glow.png"
    
    # Ensure cache directory exists
    if [[ ! -d "$CACHE_DIR" ]]; then
        mkdir -p "$CACHE_DIR"
    fi
    
    # Check if default wallpaper exists
    if [[ -f "$default_wallpaper" ]]; then
        echo "$default_wallpaper" > "$CACHE_DIR/current_wallpaper"
        echo "✅ Default wallpaper set to: $default_wallpaper"
    else
        echo "⚠️  Warning: Default wallpaper not found, using first available wallpaper"
        local first_wallpaper
        first_wallpaper=$(find "$TARGET_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | head -1)
        
        if [[ -n "$first_wallpaper" ]]; then
            echo "$first_wallpaper" > "$CACHE_DIR/current_wallpaper"
            echo "✅ Default wallpaper set to: $first_wallpaper"
        else
            echo "❌ Error: No wallpapers found in $TARGET_DIR"
            FAILED_STEPS+=("No wallpapers found")
            return 1
        fi
    fi
}

    # Check and install pywal if not available
    if ! _checkCommandExists wal; then
        echo "Installing pywal"
        sudo pacman -S --noconfirm python-pywal
    fi

    # Create the Hyprland color template
    mkdir -p "$HOME/.config/wal/templates"
    echo '# Auto generated color theme for Hyprland
$background = rgb({background.strip})
$foreground = rgb({foreground.strip})
$color0 = rgb({color0.strip})
$color1 = rgb({color1.strip})
$color2 = rgb({color2.strip})
$color3 = rgb({color3.strip})
$color4 = rgb({color4.strip})
$color5 = rgb({color5.strip})
$color6 = rgb({color6.strip})
$color7 = rgb({color7.strip})
$color8 = rgb({color8.strip})
$color9 = rgb({color9.strip})
$color10 = rgb({color10.strip})
$color11 = rgb({color11.strip})
$color12 = rgb({color12.strip})
$color13 = rgb({color13.strip})
$color14 = rgb({color14.strip})
$color15 = rgb({color15.strip})' > "$HOME/.config/wal/templates/colors-hyprland.conf"

    # Activate pywal with the default wallpaper
    if [ ! -f ~/.cache/wal/colors-hyprland.conf ]; then
        wal -i "$default_wallpaper" -t
        echo ":: Pywal and templates activated."
    else
        echo ":: Pywal already activated."
    fi
}
