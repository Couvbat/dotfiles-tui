#!/bin/bash

# =============================================================================
# PACKAGE INSTALLATION SCRIPT
# =============================================================================
# This script handles the installation of core system packages for Hyprland
# Uses shared utilities from utils.sh for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

install_packages() {
    echo "🏗️  Installing Core System Packages..."
    
    # Core system packages - essential for basic functionality
    core_packages=(
        "pacman-contrib"
        "git"
        "base-devel"
        "wget"
        "curl"
        "gcc"
        "sed"
        "networkmanager"
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
        "linux-headers"
        "xorg"
        "egl-wayland"
        "xorg-xwayland"
        "gvfs"
        "libnotify"
        "polkit-gnome"
        "fuse2"
        "python-pip"
        "python-gobject"
    )
    
    if _installPackages "${core_packages[@]}"; then
        echo "✅ Core packages installed successfully"
        enable_service "NetworkManager.service"
    else
        echo "❌ Failed to install some core packages"
        return 1
    fi
}

# Hyprland Window Manager and essential components
install_hyprland_wm() {
    echo "🪟 Installing Hyprland Window Manager..."
    hyprland_packages=(
        "hyprland"
        "hyprpaper"
        "hyprlock"
        "hypridle"
        "hyprpicker"
        "waybar"
        "rofi-wayland"
        "swaync"
        "slurp"
        "grim"
        "cliphist"
        "xclip"
        "qt5-wayland"
        "qt6-wayland"
    )
    
    if _installPackages "${hyprland_packages[@]}"; then
        echo "✅ Hyprland components installed successfully"
    else
        echo "❌ Failed to install some Hyprland components"
        return 1
    fi
}

# Desktop portal packages
install_desktop_portals() {
    echo ":: Installing Desktop Portals..."
    portal_packages=(
        "xdg-desktop-portal-gtk"
        "xdg-desktop-portal-hyprland"
    )
    _installPackages "${portal_packages[@]}"
}

# SDDM display manager and themes
install_display_manager() {
    echo ":: Installing SDDM Display Manager..."
    sddm_packages=(
        "sddm"
        "qt5-graphicaleffects"
        "qt5-quickcontrols2"
        "qt5-svg"
        "qt6ct"
    )
    _installPackages "${sddm_packages[@]}"
}

# Security and keyring packages
install_security_tools() {
    echo ":: Installing Security Tools..."
    security_packages=(
        "gnome-keyring"
        "libsecret"
        "seahorse"
    )
    _installPackages "${security_packages[@]}"
}

# Terminal and shell utilities (core shell tools only)
install_terminal_tools() {
    echo ":: Installing Terminal Tools..."
    terminal_packages=(
        "zsh"
        "zsh-completions"
        "eza"
        "fzf"
        "fd"
        "atuin"
        "zoxide"
        "jq"
    )
    _installPackages "${terminal_packages[@]}"
}

# Network utilities
install_network_tools() {
    echo ":: Installing Network Tools..."
    network_packages=(
        "nm-connection-editor"
        "network-manager-applet"
        "gping"
        "dog"
    )
    _installPackages "${network_packages[@]}"
}

# File manager and system utilities (system tools only)
install_file_manager() {
    echo ":: Installing File Manager Tools..."
    file_packages=(
        "nwg-dock-hyprland"
        "nwg-look"
    )
    _installPackages "${file_packages[@]}"
}

# Multimedia tools
install_multimedia_base() {
    echo ":: Installing Multimedia Base..."
    multimedia_packages=(
        "pavucontrol"
        "brightnessctl"
        "imagemagick"
    )
    _installPackages "${multimedia_packages[@]}"
}

# Bluetooth support (core bluetooth only)
install_bluetooth() {
    echo "📶 Installing Bluetooth Support..."
    bluetooth_packages=(
        "bluez-utils"
    )
    
    if _installPackages "${bluetooth_packages[@]}"; then
        echo "✅ Bluetooth packages installed successfully"
        enable_service "bluetooth.service"
    else
        echo "❌ Failed to install Bluetooth packages"
        return 1
    fi
}

# Theming and appearance
install_theming() {
    echo ":: Installing Theming Support..."
    theming_packages=(
        "papirus-icon-theme"
        "breeze"
        "libadwaita"
        "python-pywal"
    )
    _installPackages "${theming_packages[@]}"
}

# Software management (core package management only)
install_software_management() {
    echo ":: Installing Software Management..."
    software_packages=(
        "flatpak"
    )
    _installPackages "${software_packages[@]}"
}

# Fonts
install_fonts() {
    echo ":: Installing Fonts..."
    font_packages=(
        "ttf-fira-code"
        "ttf-fira-sans"
        "ttf-dejavu"
        "otf-font-awesome"
        "ttf-firacode-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
        "noto-fonts-extra"
    )
    _installPackages "${font_packages[@]}"
}
