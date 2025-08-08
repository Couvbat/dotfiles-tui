#!/bin/bash

# =============================================================================
# VIRTUALIZATION TOOLS INSTALLATION SCRIPT
# =============================================================================
# Description: Install and configure QEMU/KVM virtualization and Wine
# This script provides functions to install QEMU/KVM with virt-manager
# and Wine for Windows application compatibility.
# =============================================================================

# Function to install QEMU/KVM with virt-manager
install_qemu_kvm() {
    echo "🔧 Installing QEMU/KVM virtualization stack..."
    
    local qemu_packages=(
        "qemu-desktop"           # QEMU with desktop integration
        "libvirt"               # Virtualization API
        "virt-manager"          # GUI management tool
        "virt-viewer"           # VNC/SPICE client
        "dnsmasq"               # DHCP/DNS server for virtual networks
        "vde2"                  # Virtual Distributed Ethernet
        "bridge-utils"          # Network bridge utilities
        "openbsd-netcat"        # Network debugging
        "ebtables"              # Ethernet bridge tables
        "iptables"              # Firewall rules
        "dmidecode"             # Hardware information
    )
    
    if _installPackages "${qemu_packages[@]}"; then
        echo "✅ QEMU/KVM packages installed successfully"
        
        # Enable and start libvirt services
        enable_service "libvirtd.service"
        enable_service "virtlogd.service"
        
        # Add user to libvirt and kvm groups
        if sudo usermod -aG libvirt "$USER" && sudo usermod -aG kvm "$USER"; then
            echo "✅ User added to libvirt and kvm groups"
            echo "ℹ️  You may need to log out and back in for group changes to take effect."
        else
            echo "⚠️  Warning: Failed to add user to virtualization groups"
            FAILED_STEPS+=("Failed to add user to libvirt/kvm groups")
        fi
        
        # Enable nested virtualization if supported
        if [[ -f /sys/module/kvm_intel/parameters/nested ]] || [[ -f /sys/module/kvm_amd/parameters/nested ]]; then
            echo "ℹ️  Nested virtualization may be available - check system configuration"
        fi
        
        # Check virtualization support
        if grep -E "(vmx|svm)" /proc/cpuinfo >/dev/null; then
            echo "✅ Hardware virtualization support detected"
        else
            echo "⚠️  Warning: Hardware virtualization not detected"
            echo "ℹ️  Enable VT-x/AMD-V in BIOS settings for better performance"
        fi
        
    else
        echo "❌ Failed to install QEMU/KVM packages"
        FAILED_STEPS+=("QEMU/KVM installation failed")
        return 1
    fi
}

# Function to install VirtualBox Guest Additions (for running inside VirtualBox VMs)
install_virtualbox_guest() {
    echo "🔧 Installing VirtualBox Guest Additions..."
    
        # Check VM environment and install appropriate drivers
    if vm_env_check | grep -q "VirtualBox"; then
        echo "✅ VirtualBox environment detected"
        vbox_guest_packages=(
            "virtualbox-guest-utils"
            "mesa"                # 3D acceleration and graphics support
            "xorg-server"         # X.Org display server
            "xorg-xinit"          # X.Org initialization
        )
    
    if _installPackages "${vbox_guest_packages[@]}"; then
        echo "✅ VirtualBox Guest Additions installed successfully"
        
        # Enable VirtualBox guest services
        enable_service "vboxservice.service"
        
        # Load VirtualBox guest kernel modules
        if sudo modprobe vboxguest vboxsf vboxvideo; then
            echo "✅ VirtualBox guest kernel modules loaded"
        else
            echo "⚠️  Warning: Failed to load VirtualBox guest kernel modules"
            echo "ℹ️  Modules will be loaded automatically on next boot"
        fi
        
        # Add user to vboxsf group for shared folder access
        if sudo usermod -aG vboxsf "$USER"; then
            echo "✅ User added to vboxsf group for shared folder access"
            echo "ℹ️  You may need to log out and back in for group changes to take effect."
        else
            echo "⚠️  Warning: Failed to add user to vboxsf group"
        fi
        
        echo "ℹ️  VirtualBox Guest Additions features:"
        echo "   • Improved graphics performance and resolution"
        echo "   • Mouse pointer integration"
        echo "   • Shared folders between host and guest"
        echo "   • Clipboard sharing"
        echo "   • Time synchronization"
        
    else
        echo "❌ Failed to install VirtualBox Guest Additions"
        FAILED_STEPS+=("VirtualBox Guest Additions installation failed")
        return 1
    fi
}

# Function to install Wine for Windows application virtualization
install_wine() {
    echo "🔧 Installing Wine for Windows application compatibility..."
    
    local wine_packages=(
        "wine"                  # Wine compatibility layer
        "winetricks"            # Wine configuration helper
        "wine-gecko"            # Web browser engine for Wine
        "wine-mono"             # .NET runtime for Wine
    )
    
    if _installPackages "${wine_packages[@]}"; then
        echo "✅ Wine packages installed successfully"
        echo "ℹ️  Run 'winecfg' to configure Wine after installation"
        echo "ℹ️  Use 'winetricks' to install additional Windows components"
    else
        echo "❌ Failed to install Wine packages"
        FAILED_STEPS+=("Wine installation failed")
        return 1
    fi
}
