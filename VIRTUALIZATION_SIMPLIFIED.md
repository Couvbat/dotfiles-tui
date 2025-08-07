# Virtualization Support - QEMU/KVM, VirtualBox Guest, and Wine

## ✅ What's Available

### Virtualization Category
Added a focused "Virtualization" category with 3 essential options:

#### 1. **QEMU/KVM** - Complete virtualization stack
- Full QEMU desktop installation
- libvirt virtualization API  
- virt-manager GUI management tool
- Network bridge utilities and DHCP/DNS
- User added to libvirt and kvm groups
- Service enabling for libvirtd and virtlogd
- Hardware virtualization detection

#### 2. **VirtualBox Guest Additions** - For running inside VirtualBox VMs
- VirtualBox guest utilities and drivers
- VMware/VirtualBox graphics driver (xf86-video-vmware)
- VirtualBox guest services (vboxservice)
- Shared folder support (vboxsf group)
- Improved graphics, mouse integration, clipboard sharing
- Automatic VM environment detection

#### 3. **Wine** - Windows application compatibility
- Wine compatibility layer
- Winetricks configuration helper
- Wine Gecko web browser engine
- Wine Mono .NET runtime

## 🗑️ What Was Removed

- VirtualBox host software (kept guest additions)
- VMware tools (except guest graphics drivers which are included)
- Container runtimes (Podman, Buildah, etc.)
- Virtualization development tools (Vagrant, Packer, Terraform, Ansible)
- Standalone virtualization support checker

## 📁 Files Updated

### **lib/virtualization.sh** 
- Contains 3 focused functions
- `install_qemu_kvm()` - Full KVM virtualization stack
- `install_virtualbox_guest()` - Guest additions for VirtualBox VMs
- `install_wine()` - Windows compatibility
- Includes VM environment detection
- Proper service and group management

### **main.go** 
- Virtualization category now has 3 focused options
- VirtualBox Guest Additions option for VM users

### **TUI_README.md**
- Updated documentation to reflect VM guest support

## 🎯 Result

Perfect virtualization support that covers:
- **Host virtualization** with QEMU/KVM for running VMs
- **Guest optimization** with VirtualBox Guest Additions for running inside VMs  
- **Windows app compatibility** with Wine
- **Smart detection** of virtualization environments
- **Clean interface** without overwhelming options

Ideal for both VM hosts and guests! 🚀
