#!/bin/bash

# =============================================================================
# NVIDIA GRAPHICS DRIVER CONFIGURATION SCRIPT
# =============================================================================
# This script handles NVIDIA driver installation and system configuration
# Uses shared utilities for safety and consistency

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Initialize variables
readonly AUR_HELPER="paru"
readonly MKINITCPIO_CONF="/etc/mkinitcpio.conf"
readonly NVIDIA_CONF="/etc/modprobe.d/nvidia.conf"
readonly GRUB_CONF="/etc/default/grub"

configure_nvidia() {
    echo "🎮 Configuring NVIDIA Graphics Drivers..."
    
    # Validate that we can proceed
    if ! _checkCommandExists "$AUR_HELPER"; then
        echo "❌ Error: $AUR_HELPER is not installed. Please install it first."
        FAILED_STEPS+=("NVIDIA: $AUR_HELPER not found")
        return 1
    fi

    # Install NVIDIA and related packages for each kernel
    echo "📦 Installing NVIDIA packages..."
    local nvidia_pkgs=("nvidia-dkms" "nvidia-settings" "nvidia-utils" "libva-nvidia-driver")
    
    if [[ -d /usr/lib/modules ]]; then
        for krnl in $(cat /usr/lib/modules/*/pkgbase 2>/dev/null); do
            for pkg in "${krnl}-headers" "${nvidia_pkgs[@]}"; do
                if ! $AUR_HELPER -S --noconfirm --needed "$pkg"; then
                    echo "⚠️  Warning: Failed to install $pkg"
                    FAILED_STEPS+=("NVIDIA: Failed to install $pkg")
                fi
            done
        done
    else
        echo "⚠️  Warning: /usr/lib/modules directory not found"
    fi

    # Configure mkinitcpio.conf
    configure_mkinitcpio

    # Configure nvidia modprobe options
    configure_nvidia_modprobe

    # Rebuild initramfs
    rebuild_initramfs

    # Configure bootloader
    configure_bootloader

    echo "✅ NVIDIA configuration completed"
}

configure_mkinitcpio() {
    echo "🔧 Configuring mkinitcpio for NVIDIA..."
    
    if [[ ! -f "$MKINITCPIO_CONF" ]]; then
        echo "❌ Error: $MKINITCPIO_CONF not found!"
        FAILED_STEPS+=("mkinitcpio.conf not found")
        return 1
    fi
    
    # Check if NVIDIA modules are already configured
    if grep -qE '^MODULES=.*nvidia.*nvidia_modeset.*nvidia_uvm.*nvidia_drm' "$MKINITCPIO_CONF"; then
        echo "✅ NVIDIA modules already configured in mkinitcpio.conf"
        return 0
    fi
    
    # Add NVIDIA modules
    safe_modify_system_file "$MKINITCPIO_CONF" \
        's/^(MODULES=\([^)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
        "Adding NVIDIA modules to mkinitcpio.conf"
}

configure_nvidia_modprobe() {
    echo "🔧 Configuring NVIDIA modprobe options..."
    
    local nvidia_options="options nvidia_drm modeset=1 fbdev=1"
    
    if [[ ! -f "$NVIDIA_CONF" ]]; then
        echo "📄 Creating $NVIDIA_CONF"
        echo "$nvidia_options" | sudo tee "$NVIDIA_CONF" > /dev/null
    else
        if ! grep -q "$nvidia_options" "$NVIDIA_CONF"; then
            backup_system_file "$NVIDIA_CONF"
            echo "$nvidia_options" | sudo tee -a "$NVIDIA_CONF" > /dev/null
            echo "✅ Added NVIDIA options to $NVIDIA_CONF"
        else
            echo "✅ NVIDIA options already configured"
        fi
    fi
}

rebuild_initramfs() {
    echo "🔄 Rebuilding initramfs..."
    if sudo mkinitcpio -P; then
        echo "✅ Initramfs rebuilt successfully"
    else
        echo "❌ Error: Failed to rebuild initramfs"
        FAILED_STEPS+=("Failed to rebuild initramfs")
        return 1
    fi
}

configure_bootloader() {
    echo "🔧 Configuring bootloader for NVIDIA..."
    
    if [[ -f "$GRUB_CONF" ]]; then
        echo "📝 Configuring GRUB..."
        
        # Check if NVIDIA parameters are already present
        if grep -q "nvidia_drm.modeset=1 nvidia_drm.fbdev=1" "$GRUB_CONF"; then
            echo "✅ NVIDIA parameters already in GRUB configuration"
        else
            safe_modify_system_file "$GRUB_CONF" \
                's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' \
                "Adding NVIDIA parameters to GRUB"
                
            echo "🔄 Updating GRUB configuration..."
            if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
                echo "✅ GRUB configuration updated"
            else
                echo "❌ Error: Failed to update GRUB configuration"
                FAILED_STEPS+=("Failed to update GRUB")
                return 1
            fi
        fi
    else
        echo "ℹ️  GRUB configuration not found, skipping bootloader configuration"
    fi
}

    # Add NVIDIA kernel params to systemd-boot if present
    if [ -f /boot/loader/loader.conf ]; then
        if [ $(ls -l /boot/loader/entries/*.conf.ml4w.bkp 2>/dev/null | wc -l) -ne $(ls -l /boot/loader/entries/*.conf 2>/dev/null | wc -l) ]; then
            find /boot/loader/entries/ -type f -name "*.conf" | while read imgconf; do
                sudo cp ${imgconf} ${imgconf}.ml4w.bkp
                sdopt=$(grep -w "^options" ${imgconf} | sed 's/\b quiet\b//g' | sed 's/\b splash\b//g' | sed 's/\b nvidia-drm.modeset=.\b//g' | sed 's/\b nvidia_drm.fbdev=.\b//g')
                sudo sed -i "/^options/c${sdopt} quiet splash nvidia-drm.modeset=1 nvidia_drm.fbdev=1" ${imgconf}
            done
        else
            echo -e "\033[0;33m[SKIP]\033[0m systemd-boot is already configured..."
        fi
    fi

    echo "NVIDIA configuration complete!"
}
