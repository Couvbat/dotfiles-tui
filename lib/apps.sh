#!/bin/bash

# Load shared utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Prevent multiple loading
if [[ "${APPS_LOADED:-}" == "1" ]]; then
    return 0
fi
readonly APPS_LOADED=1

# Array to track failed steps
FAILED_STEPS=()

# System configuration paths (only set if not already defined)
if [[ -z "${MKINITCPIO_CONF:-}" ]]; then
    readonly MKINITCPIO_CONF="/etc/mkinitcpio.conf"
fi
if [[ -z "${GRUB_DEFAULT:-}" ]]; then
    readonly GRUB_DEFAULT="/etc/default/grub"
fi
if [[ -z "${GRUB_CONFIG:-}" ]]; then
    readonly GRUB_CONFIG="/boot/grub/grub.cfg"
fi
if [[ -z "${NVIDIA_MODPROBE_CONF:-}" ]]; then
    readonly NVIDIA_MODPROBE_CONF="/etc/modprobe.d/nvidia.conf"
fi

# Function to install NVIDIA DKMS drivers
install_nvidia_dkms() {
    echo "🎮 Installing NVIDIA DKMS drivers..."
    
    local nvidia_packages=(
        "nvidia-dkms"
        "nvidia-settings"
        "nvidia-utils"
        "libva-nvidia-driver"
    )
    
    if _installPackages "${nvidia_packages[@]}"; then
        echo "✅ NVIDIA DKMS drivers installed successfully."
    else
        echo "❌ Failed to install NVIDIA DKMS drivers"
        FAILED_STEPS+=("NVIDIA DKMS driver installation failed")
        return 1
    fi
}===========================
# APPLICATIONS INSTALLATION SCRIPT
# =============================================================================
# This script handles installation of various applications and drivers
# Uses shared utilities for consistency and security

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Function to configure NVIDIA graphics drivers with options
configure_nvidia() {
    echo "🎮 NVIDIA Graphics Driver Configuration..."
    echo "   1) NVIDIA DKMS (recommended for most users)"
    echo "   2) NVIDIA Open DKMS (newer open-source kernel modules)"
    echo "   3) Nouveau (open-source, basic functionality)"
    echo "   4) Nouveau + Vulkan (open-source with Vulkan support)"
    echo
    
    while true; do
        read -p "🔧 Choose NVIDIA driver option (1-4): " nvidia_choice
        case $nvidia_choice in
            1)
                install_nvidia_dkms
                break
                ;;
            2)
                install_nvidia_open_dkms
                break
                ;;
            3)
                install_nouveau
                break
                ;;
            4)
                install_nouveau_vulkan
                break
                ;;
            *)
                echo "❌ Invalid choice. Please select 1-4."
                ;;
        esac
    done
}

# Function to install NVIDIA DKMS drivers
install_nvidia_dkms() {
    echo "🔧 Installing NVIDIA DKMS drivers..."
    
    nvidia_dkms_packages=(
        "nvidia-dkms"
        "nvidia-settings" 
        "nvidia-utils"
        "lib32-nvidia-utils"
        "libva-nvidia-driver"
        "opencl-nvidia"
        "cuda"
    )
    
    _installPackages "${nvidia_dkms_packages[@]}"
    configure_nvidia_common
    echo "🔧 NVIDIA DKMS drivers installed successfully."
}

# Function to install NVIDIA Open DKMS drivers
install_nvidia_open_dkms() {
    echo "🔧 Installing NVIDIA Open DKMS drivers..."
    
    nvidia_open_packages=(
        "nvidia-open-dkms"
        "nvidia-settings"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "libva-nvidia-driver"
        "opencl-nvidia"
    )
    
    _installPackages "${nvidia_open_packages[@]}"
    configure_nvidia_common
    echo "🔧 NVIDIA Open DKMS drivers installed successfully."
}

# Function to install Nouveau drivers
install_nouveau() {
    echo "🔧 Installing Nouveau drivers..."
    
    nouveau_packages=(
        "mesa"
        "lib32-mesa"
        "xf86-video-nouveau"
        "libva-mesa-driver"
        "lib32-libva-mesa-driver"
    )
    
    _installPackages "${nouveau_packages[@]}"
    
    # Enable early KMS for Nouveau
    if [ -f "$MKINITCPIO_CONF" ]; then
        if ! grep -q "nouveau" "$MKINITCPIO_CONF"; then
            sudo sed -i 's/MODULES=(/MODULES=(nouveau /' "$MKINITCPIO_CONF"
            sudo mkinitcpio -P
        fi
    fi
    
    echo "🔧 Nouveau drivers installed successfully."
}

# Function to install Nouveau with Vulkan support
install_nouveau_vulkan() {
    echo "🔧 Installing Nouveau drivers with Vulkan support..."
    
    nouveau_vulkan_packages=(
        "mesa"
        "lib32-mesa"
        "xf86-video-nouveau"
        "libva-mesa-driver"
        "lib32-libva-mesa-driver"
        "vulkan-nouveau"
        "lib32-vulkan-nouveau"
    )
    
    _installPackages "${nouveau_vulkan_packages[@]}"
    
    # Enable early KMS for Nouveau
    if [ -f "$MKINITCPIO_CONF" ]; then
        if ! grep -q "nouveau" "$MKINITCPIO_CONF"; then
            sudo sed -i 's/MODULES=(/MODULES=(nouveau /' "$MKINITCPIO_CONF"
            sudo mkinitcpio -P
        fi
    fi
    
    echo "🔧 Nouveau drivers with Vulkan support installed successfully."
}

# Common NVIDIA configuration
configure_nvidia_common() {
    # Ensure MODULES in /etc/mkinitcpio.conf contains NVIDIA modules
    if [ -f "$MKINITCPIO_CONF" ]; then
        if ! grep -qE '^MODULES=.*nvidia.*nvidia_modeset.*nvidia_uvm.*nvidia_drm' "$MKINITCPIO_CONF"; then
            sudo sed -Ei 's/^(MODULES=\([^)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINITCPIO_CONF"
            echo "🔧 NVIDIA modules added to $MKINITCPIO_CONF"
        fi
    else
        echo "🔧 Warning: $MKINITCPIO_CONF not found!"
        FAILED_STEPS+=("mkinitcpio.conf not found")
    fi

    # Ensure /etc/modprobe.d/nvidia.conf has correct options
    if [ ! -f "$NVIDIA_MODPROBE_CONF" ]; then
        echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee "$NVIDIA_MODPROBE_CONF"
    else
        if ! grep -q "options nvidia_drm modeset=1 fbdev=1" "$NVIDIA_MODPROBE_CONF"; then
            echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a "$NVIDIA_MODPROBE_CONF"
        fi
    fi

    # Rebuild initramfs
    sudo mkinitcpio -P

    # Add NVIDIA kernel params to GRUB if present
    if [ -f "$GRUB_DEFAULT" ]; then
        if ! grep -q "nvidia_drm.modeset=1" "$GRUB_DEFAULT"; then
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' "$GRUB_DEFAULT"
            sudo grub-mkconfig -o "$GRUB_CONFIG"
        fi
    fi
    
    # Add pacman hook to rebuild initramfs after nvidia updates
    sudo mkdir -p /etc/pacman.d/hooks
    cat << EOF | sudo tee /etc/pacman.d/hooks/nvidia.hook
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=nvidia-open-dkms
Target=linux

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF
}

# Function to configure AMD graphics drivers
configure_amd() {
    echo "🔧 Configuring AMD graphics drivers..."
    
    amd_packages=(
        "mesa"
        "lib32-mesa"
        "xf86-video-amdgpu"
        "vulkan-radeon"
        "lib32-vulkan-radeon"
        "libva-mesa-driver"
        "lib32-libva-mesa-driver"
        "mesa-vdpau"
        "lib32-mesa-vdpau"
        "amd-ucode"
    )
    
    _installPackages "${amd_packages[@]}"
    
    # Enable early KMS for AMD
    if [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q "amdgpu" /etc/mkinitcpio.conf; then
            sudo sed -i 's/MODULES=(/MODULES=(amdgpu /' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
        fi
    fi
    
    # Add AMD kernel parameters if using GRUB
    if [ -f /etc/default/grub ]; then
        if ! grep -q "amd_iommu=on" /etc/default/grub; then
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amd_iommu=on"/' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi
    
    echo "🔧 AMD graphics drivers configured successfully."
}

# Function to configure Intel graphics drivers
configure_intel() {
    echo "🔧 Configuring Intel graphics drivers..."
    
    intel_packages=(
        "mesa"
        "lib32-mesa"
        "intel-media-driver"
        "vulkan-intel"
        "lib32-vulkan-intel"
        "libva-intel-driver"
        "intel-gpu-tools"
        "intel-ucode"
    )
    
    _installPackages "${intel_packages[@]}"
    
    # Enable early KMS for Intel
    if [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q "i915" /etc/mkinitcpio.conf; then
            sudo sed -i 's/MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
        fi
    fi
    
    echo "🔧 Intel graphics drivers configured successfully."
}

# Development Tools Functions

# Function to install Visual Studio Code
install_vscode() {
    echo "� Installing Visual Studio Code..."
    if ! _isInstalled "visual-studio-code-bin"; then
        if _checkCommandExists "paru"; then
            if paru -S --noconfirm visual-studio-code-bin; then
                echo "✅ Visual Studio Code installed successfully"
            else
                echo "❌ Error: Failed to install Visual Studio Code"
                FAILED_STEPS+=("Visual Studio Code installation failed")
                return 1
            fi
        else
            echo "❌ Error: paru is required but not installed"
            FAILED_STEPS+=("Visual Studio Code - paru not found")
            return 1
        fi
    else
        echo "✅ Visual Studio Code is already installed."
    fi
}

# Function to install Neovim
install_neovim() {
    echo "📝 Installing Neovim..."
    if ! _isInstalled "neovim"; then
        _installPackages "neovim"
    else
        echo "✅ Neovim is already installed."
    fi
}

# Function to install Git
install_git() {
    echo "📚 Installing Git..."
    if ! _isInstalled "git"; then
        _installPackages "git"
    else
        echo "✅ Git is already installed."
    fi
}

# Function to install terminal emulator
install_terminal_emulator() {
    echo "💻 Installing Terminal Emulator (Kitty)..."
    if ! _isInstalled "kitty"; then
        _installPackages "kitty"
    else
        echo "✅ Kitty is already installed."
    fi
}

# Function to install system monitor
install_system_monitor() {
    echo "📊 Installing System Monitor (btop)..."
    if ! _isInstalled "btop"; then
        _installPackages "btop"
    else
        echo "✅ btop is already installed."
    fi
}

# Function to install bat (better cat)
install_bat() {
    echo "🦇 Installing bat..."
    if ! _isInstalled "bat"; then
        _installPackages "bat"
    else
        echo "✅ bat is already installed."
    fi
}

# Function to install tldr (simplified man pages)
install_tldr() {
    echo "📖 Installing tldr..."
    if ! _isInstalled "tldr"; then
        _installPackages "tldr"
    else
        echo "✅ tldr is already installed."
    fi
}

# Function to install onefetch (git repo info)
install_onefetch() {
    echo "🐙 Installing onefetch..."
    if ! _isInstalled "onefetch"; then
        _installPackages "onefetch"
    else
        echo "✅ onefetch is already installed."
    fi
}

# Function to install Nautilus file manager
install_nautilus() {
    echo "📁 Installing Nautilus..."
    if ! _isInstalled "nautilus"; then
        _installPackages "nautilus"
    else
        echo "✅ Nautilus is already installed."
    fi
}

# Function to install Docker
install_docker() {
    echo "� Installing Docker..."
    local docker_packages=(
        "docker"
        "docker-compose"
        "docker-buildx"
    )
    
    if _installPackages "${docker_packages[@]}"; then
        echo "✅ Docker packages installed successfully"
        
        # Enable and start Docker services
        enable_service "docker.service"
        enable_service "containerd.service"
        
        # Add user to docker group
        if sudo usermod -aG docker "$USER"; then
            echo "✅ User added to docker group"
            echo "ℹ️  You may need to log out and back in for group changes to take effect."
        else
            echo "⚠️  Warning: Failed to add user to docker group"
        fi
    else
        echo "❌ Failed to install Docker packages"
        FAILED_STEPS+=("Docker installation failed")
        return 1
    fi
}

# Web Browsers Functions

# Function to install Zen Browser
install_zen() {
    echo "🔧 Installing Zen Browser..."
    if ! _isInstalled "zen-browser-bin"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm zen-browser-bin
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("Zen Browser - paru not found")
        fi
    else
        echo "🔧 Zen Browser is already installed."
    fi
}

# Function to install Firefox
install_firefox() {
    echo "🔧 Installing Firefox..."
    if ! _isInstalled "firefox"; then
        _installPackages "firefox"
    else
        echo "🔧 Firefox is already installed."
    fi
}

# Function to install Chromium
install_chromium() {
    echo "🔧 Installing Chromium..."
    if ! _isInstalled "chromium"; then
        _installPackages "chromium"
    else
        echo "🔧 Chromium is already installed."
    fi
}

# Communication Functions

# Function to install Vesktop (Discord)
install_vesktop() {
    echo "🔧 Installing Vesktop (Discord client)..."
    if ! _isInstalled "vesktop-bin"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm vesktop-bin
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("Vesktop - paru not found")
        fi
    else
        echo "🔧 Vesktop is already installed."
    fi
}

# Function to install Telegram
install_telegram() {
    echo "🔧 Installing Telegram..."
    if ! _isInstalled "telegram-desktop"; then
        _installPackages "telegram-desktop"
    else
        echo "🔧 Telegram is already installed."
    fi
}

# Function to install Signal
install_signal() {
    echo "🔧 Installing Signal..."
    if ! _isInstalled "signal-desktop"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm signal-desktop
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("Signal - paru not found")
        fi
    else
        echo "🔧 Signal is already installed."
    fi
}

# Media & Entertainment Functions

# Function to install Spotube
install_spotube() {
    echo "🔧 Installing Spotube..."
    if ! _isInstalled "spotube-bin"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm spotube-bin
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("Spotube - paru not found")
        fi
    else
        echo "🔧 Spotube is already installed."
    fi
}

# Function to install VLC
install_vlc() {
    echo "🔧 Installing VLC..."
    if ! _isInstalled "vlc"; then
        _installPackages "vlc"
    else
        echo "🔧 VLC is already installed."
    fi
}

# Function to install GIMP
install_gimp() {
    echo "🔧 Installing GIMP..."
    if ! _isInstalled "gimp"; then
        _installPackages "gimp"
    else
        echo "🔧 GIMP is already installed."
    fi
}

# Function to install Pinta
install_pinta() {
    echo "🔧 Installing Pinta..."
    if ! _isInstalled "pinta"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm pinta
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("Pinta - paru not found")
        fi
    else
        echo "🔧 Pinta is already installed."
    fi
}

# Additional Applications Functions

# Function to install LibreOffice
install_libreoffice() {
    echo "🔧 Installing LibreOffice..."
    if ! _isInstalled "libreoffice-fresh"; then
        _installPackages "libreoffice-fresh"
    else
        echo "🔧 LibreOffice is already installed."
    fi
}

# Function to install Thunderbird
install_thunderbird() {
    echo "🔧 Installing Thunderbird..."
    if ! _isInstalled "thunderbird"; then
        _installPackages "thunderbird"
    else
        echo "🔧 Thunderbird is already installed."
    fi
}

# Function to install Steam
install_steam() {
    echo "🔧 Installing Steam..."
    steam_packages=(
        "steam"
        "lib32-nvidia-utils"  # Only if nvidia is installed
        "lib32-vulkan-intel"  # Only if intel is installed
        "lib32-vulkan-radeon" # Only if amd is installed
    )
    
    # Check which GPU drivers are installed and adjust packages
    final_packages=("steam")
    
    if _isInstalled "nvidia-utils"; then
        final_packages+=("lib32-nvidia-utils")
    fi
    if _isInstalled "vulkan-intel"; then
        final_packages+=("lib32-vulkan-intel")
    fi
    if _isInstalled "vulkan-radeon"; then
        final_packages+=("lib32-vulkan-radeon")
    fi
    
    _installPackages "${final_packages[@]}"
    
    echo "🔧 Steam installed successfully."
}

# Function to install OBS Studio
install_obs() {
    echo "🔧 Installing OBS Studio..."
    if ! _isInstalled "obs-studio"; then
        _installPackages "obs-studio"
    else
        echo "🔧 OBS Studio is already installed."
    fi
}

# Terminal Applications

# Function to install terminal emulator
install_terminal_emulator() {
    echo "🔧 Installing Terminal Emulator..."
    if ! _isInstalled "kitty"; then
        _installPackages "kitty"
    else
        echo "🔧 Kitty is already installed."
    fi
}

# Function to install system monitor
install_system_monitor() {
    echo "🔧 Installing System Monitor..."
    if ! _isInstalled "btop"; then
        _installPackages "btop"
    else
        echo "🔧 btop is already installed."
    fi
}

# Function to install bat (better cat)
install_bat() {
    echo "🔧 Installing bat (better cat)..."
    if ! _isInstalled "bat"; then
        _installPackages "bat"
    else
        echo "🔧 bat is already installed."
    fi
}

# Function to install fastfetch (system info)
install_fastfetch_app() {
    echo "🔧 Installing Fastfetch..."
    if ! _isInstalled "fastfetch"; then
        _installPackages "fastfetch"
    else
        echo "🔧 Fastfetch is already installed."
    fi
}

# Function to install tldr (simplified man pages)
install_tldr() {
    echo "🔧 Installing tldr..."
    if ! _isInstalled "tldr"; then
        _installPackages "tldr"
    else
        echo "🔧 tldr is already installed."
    fi
}

# Function to install onefetch (git repo info)
install_onefetch() {
    echo "🔧 Installing onefetch..."
    if ! _isInstalled "onefetch"; then
        _installPackages "onefetch"
    else
        echo "🔧 onefetch is already installed."
    fi
}

# File Manager Applications

# Function to install Nautilus file manager
install_nautilus() {
    echo "🔧 Installing Nautilus File Manager..."
    if ! _isInstalled "nautilus"; then
        _installPackages "nautilus"
    else
        echo "🔧 Nautilus is already installed."
    fi
}

# Function to install Superfile (terminal file manager)
install_superfile() {
    echo "🔧 Installing Superfile..."
    if ! _isInstalled "superfile"; then
        _installPackages "superfile"
    else
        echo "🔧 Superfile is already installed."
    fi
}

# System Applications

# Function to install GNOME Calculator
install_calculator() {
    echo "🔧 Installing GNOME Calculator..."
    if ! _isInstalled "gnome-calculator"; then
        _installPackages "gnome-calculator"
    else
        echo "🔧 GNOME Calculator is already installed."
    fi
}

# Function to install KDE Discover
install_discover() {
    echo "🔧 Installing KDE Discover..."
    if ! _isInstalled "discover"; then
        _installPackages "discover"
    else
        echo "🔧 KDE Discover is already installed."
    fi
}

# Function to install Blueman (Bluetooth manager)
install_blueman() {
    echo "🔧 Installing Blueman..."
    if ! _isInstalled "blueman"; then
        _installPackages "blueman"
    else
        echo "🔧 Blueman is already installed."
    fi
}

# Text Editor Applications

# Function to install Neovim text editor
install_neovim_app() {
    echo "🔧 Installing Neovim..."
    if ! _isInstalled "neovim"; then
        _installPackages "neovim"
    else
        echo "🔧 Neovim is already installed."
    fi
}

# Entertainment Applications

# Function to install cmatrix
install_cmatrix() {
    echo "🔧 Installing cmatrix..."
    if ! _isInstalled "cmatrix"; then
        _installPackages "cmatrix"
    else
        echo "🔧 cmatrix is already installed."
    fi
}

# Function to install astroterm (pacman package)
install_astroterm() {
    echo "🔧 Installing astroterm..."
    if ! _isInstalled "astroterm"; then
        _installPackages "astroterm"
    else
        echo "🔧 astroterm is already installed."
    fi
}

# Function to install cbonsai (AUR package)
install_cbonsai() {
    echo "🔧 Installing cbonsai..."
    if ! _checkCommandExists "cbonsai"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm cbonsai
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("cbonsai - paru not found")
        fi
    else
        echo "🔧 cbonsai is already installed."
    fi
}

# Function to install pipes-rs (AUR package)
install_pipes_rs() {
    echo "🔧 Installing pipes-rs..."
    if ! _checkCommandExists "pipes-rs"; then
        if _checkCommandExists "paru"; then
            paru -S --noconfirm pipes-rs
        else
            echo "🔧 Error: paru is required but not installed"
            FAILED_STEPS+=("pipes-rs - paru not found")
        fi
    else
        echo "🔧 pipes-rs is already installed."
    fi
}

# Function to install astroterm (pacman package)
install_astroterm() {
    echo "🔧 Installing astroterm..."
    if ! _isInstalled "astroterm"; then
        _installPackages "astroterm"
    else
        echo "🔧 astroterm is already installed."
    fi
}

# Function to install all entertainment apps
install_entertainment_apps() {
    echo "🔧 Installing Entertainment Applications..."
    install_cmatrix
    install_cbonsai
    install_pipes_rs
    install_astroterm
}
}

# System Configuration Functions

# Function to setup Hyprland (now calls the packages function)
setup_hyprland() {
    install_hyprland_wm
}

# Helper function to check if a command exists (if not already defined)
_checkCommandExists() {
    command -v "$1" >/dev/null 2>&1
}
