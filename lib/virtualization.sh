#!/bin/bash

# =============================================================================
# VIRTUALIZATION TOOLS INSTALLATION SCRIPT
# =============================================================================
# Description: Install and configure virtualization platforms and tools
# This script provides functions to install QEMU/KVM, VirtualBox, VMware tools,
# and other virtualization-related software.
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
        
    else
        echo "❌ Failed to install QEMU/KVM packages"
        FAILED_STEPS+=("QEMU/KVM installation failed")
        return 1
    fi
}

# Function to install VirtualBox
install_virtualbox() {
    echo "🔧 Installing VirtualBox..."
    
    local vbox_packages=(
        "virtualbox"            # VirtualBox main package
        "virtualbox-host-modules-arch"  # Kernel modules for Arch
        "virtualbox-guest-iso"  # Guest additions ISO
    )
    
    if _installPackages "${vbox_packages[@]}"; then
        echo "✅ VirtualBox packages installed successfully"
        
        # Add user to vboxusers group
        if sudo usermod -aG vboxusers "$USER"; then
            echo "✅ User added to vboxusers group"
            echo "ℹ️  You may need to log out and back in for group changes to take effect."
        else
            echo "⚠️  Warning: Failed to add user to vboxusers group"
            FAILED_STEPS+=("Failed to add user to vboxusers group")
        fi
        
        # Load VirtualBox kernel modules
        if sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci; then
            echo "✅ VirtualBox kernel modules loaded"
        else
            echo "⚠️  Warning: Failed to load VirtualBox kernel modules"
            echo "ℹ️  You may need to reboot for kernel modules to work properly"
        fi
        
    else
        echo "❌ Failed to install VirtualBox packages"
        FAILED_STEPS+=("VirtualBox installation failed")
        return 1
    fi
}

# Function to install VMware Workstation support tools
install_vmware_tools() {
    echo "🔧 Installing VMware tools and utilities..."
    
    # Note: VMware Workstation itself is proprietary and must be installed manually
    # This installs open-source tools for VMware compatibility
    
    local vmware_packages=(
        "open-vm-tools"         # Open-source VMware tools
        "gtkmm3"               # GUI toolkit for VMware tools
    )
    
    if _installPackages "${vmware_packages[@]}"; then
        echo "✅ VMware tools installed successfully"
        
        # Enable VMware services if running in VMware
        if systemd-detect-virt | grep -q vmware; then
            enable_service "vmtoolsd.service"
            enable_service "vmware-vmblock-fuse.service"
            echo "✅ VMware services enabled (detected VMware environment)"
        else
            echo "ℹ️  VMware tools installed but not running in VMware environment"
        fi
        
    else
        echo "❌ Failed to install VMware tools"
        FAILED_STEPS+=("VMware tools installation failed")
        return 1
    fi
}

# Function to install container runtimes (complementary to virtualization)
install_container_runtimes() {
    echo "🔧 Installing additional container runtimes..."
    
    local container_packages=(
        "podman"                # Daemonless container engine
        "buildah"               # Container image builder
        "skopeo"                # Container image operations
        "crun"                  # Fast OCI runtime
        "fuse-overlayfs"        # User-space overlay filesystem
    )
    
    if _installPackages "${container_packages[@]}"; then
        echo "✅ Container runtimes installed successfully"
        
        # Configure rootless containers for current user
        if ! grep -q "^$USER:" /etc/subuid; then
            echo "$USER:100000:65536" | sudo tee -a /etc/subuid >/dev/null
            echo "$USER:100000:65536" | sudo tee -a /etc/subgid >/dev/null
            echo "✅ Configured rootless container support"
        else
            echo "✅ Rootless container support already configured"
        fi
        
    else
        echo "❌ Failed to install container runtimes"
        FAILED_STEPS+=("Container runtimes installation failed")
        return 1
    fi
}

# Function to install virtualization development tools
install_virt_dev_tools() {
    echo "🔧 Installing virtualization development tools..."
    
    local dev_packages=(
        "vagrant"               # Development environment manager
        "packer"                # Machine image builder
        "terraform"             # Infrastructure as code
        "ansible"               # Configuration management
    )
    
    # These are typically AUR packages, check if paru is available
    if ! _checkCommandExists "paru"; then
        echo "⚠️  Warning: paru not available, skipping AUR virtualization tools"
        echo "ℹ️  Install paru first to get Vagrant, Packer, Terraform, and Ansible"
        return 0
    fi
    
    local failed_packages=()
    for package in "${dev_packages[@]}"; do
        if ! _isInstalled "$package"; then
            echo "📦 Installing $package..."
            if paru -S --needed --noconfirm "$package"; then
                echo "✅ $package installed successfully"
            else
                echo "❌ Failed to install $package"
                failed_packages+=("$package")
            fi
        else
            echo "✅ $package is already installed"
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        echo "⚠️  Some virtualization dev tools failed to install: ${failed_packages[*]}"
        FAILED_STEPS+=("Virtualization dev tools: ${failed_packages[*]}")
    else
        echo "✅ All virtualization development tools installed successfully"
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

# Function to check virtualization support
check_virtualization_support() {
    echo "🔍 Checking virtualization support..."
    
    # Check if hardware virtualization is enabled
    if grep -E "(vmx|svm)" /proc/cpuinfo >/dev/null; then
        echo "✅ Hardware virtualization support detected"
        
        # Check specific CPU features
        if grep -q "vmx" /proc/cpuinfo; then
            echo "ℹ️  Intel VT-x support available"
        fi
        if grep -q "svm" /proc/cpuinfo; then
            echo "ℹ️  AMD SVM support available"
        fi
    else
        echo "⚠️  Warning: Hardware virtualization not detected"
        echo "ℹ️  Enable VT-x/AMD-V in BIOS settings for better performance"
    fi
    
    # Check if KVM is available
    if [[ -r /dev/kvm ]]; then
        echo "✅ KVM device available"
    else
        echo "⚠️  Warning: KVM device not available"
        echo "ℹ️  KVM kernel modules may need to be loaded"
    fi
    
    # Check current virtualization environment
    local virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    if [[ "$virt_type" != "none" ]]; then
        echo "ℹ️  Running in virtualization environment: $virt_type"
    else
        echo "ℹ️  Running on bare metal"
    fi
}
