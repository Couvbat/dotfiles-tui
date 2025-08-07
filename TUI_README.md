# Dotfiles TUI Installer

A beautiful Terminal User Interface (TUI) installer for your dotfiles, built with [Bubble Tea](https://github.com/charmbracelet/bubbletea).

## Features

- 🎨 **Beautiful TUI** - Interactive and intuitive interface
- 🎯 **Selective Installation** - Choose exactly what you want to install
- 📦 **Categorized Components** - Organized into logical groups
- 🔍 **Real-time Progress** - See what's happening during installation
- ⚠️ **Error Handling** - Clear feedback on any issues
- 📝 **Detailed Logging** - All output saved to `~/install.log`

## Installation Categories

### Graphics Drivers
- NVIDIA Drivers (proprietary with CUDA support)
- AMD Drivers (open-source)
- Intel Drivers (integrated graphics)

### Development Tools
- Visual Studio Code
- Neovim (included in core packages)
- Git (included in core packages)
- Docker with docker-compose
- Node.js and npm
- MongoDB

### Web Browsers
- Zen Browser (Firefox-based, privacy-focused)
- Firefox
- Chromium

### Communication
- Discord (Vesktop - better Wayland support)
- Telegram Desktop
- Signal Desktop

### Media & Entertainment
- Spotify (Spotube - open-source client)
- VLC Media Player
- GIMP
- Pinta (simple image editor)

### Gaming
- Steam (with GPU-specific 32-bit libraries)

### Virtualization
- QEMU/KVM - Complete virtualization stack with virt-manager GUI
- VirtualBox - Oracle VirtualBox with host modules and kernel support
- VMware Tools - Open-source VMware tools for compatibility
- Container Runtimes - Podman, Buildah, and rootless container support
- Virtualization Dev Tools - Vagrant, Packer, Terraform, Ansible (AUR packages)
- Wine - Windows application compatibility layer
- Virtualization Support Check - Verify hardware capabilities

### Terminal Applications
- Terminal Emulator (Kitty) - GPU-accelerated terminal
- System Monitor (btop) - Modern resource monitor
- bat - Better version of cat with syntax highlighting
- Fastfetch - System information display
- tldr - Simplified man pages
- onefetch - Git repository information

### File Managers
- Nautilus - GNOME file manager with extensions
- Superfile - Modern terminal-based file manager

### System Applications
- Calculator - GNOME calculator
- Software Center (Discover) - KDE application manager
- Bluetooth Manager (Blueman) - Graphical Bluetooth management
- Text Editor (Neovim) - Modern Vim-based editor

### Entertainment
- cmatrix - Terminal Matrix effect screensaver

### System Configuration
- Core Packages (essential system packages) *[Required]*
- AUR Helper (paru) and AUR packages *[Required]*
- Hyprland Window Manager (Wayland compositor)
- Desktop Portals (XDG desktop integration)
- SDDM Login Manager (display manager with themes)
- Security Tools (keyring and credential management)
- Terminal Tools (shell utilities like zsh, eza, fzf, etc.)
- Network Tools (network utilities and connection management)
- File Manager Tools (system file management utilities)
- Multimedia Base (audio/video control and image processing)
- Bluetooth Support (core Bluetooth utilities)
- Theming Support (icons, themes, and appearance tools)
- Software Management (Flatpak support)
- Fonts (essential and programming fonts)
- Zsh Shell with plugins
- Wallpapers and themes
- Fastfetch system info tool
- Dotfiles (configuration files) *[Required]*

## Usage

### Quick Start

1. **Clone and navigate to your dotfiles directory**:
   ```bash
   cd /path/to/your/dotfiles
   ```

2. **Build the installer**:
   ```bash
   ./build.sh
   ```

3. **Run the installer**:
   ```bash
   ./dotfiles-installer
   ```

### Manual Build

If you prefer to build manually:

```bash
# Ensure Go is installed
go version

# Download dependencies
go mod tidy

# Build the application
go build -o dotfiles-installer main.go

# Run the installer
./dotfiles-installer
```

## Navigation

- **Arrow Keys** or **hjkl**: Navigate through options
- **←→**: Switch between categories
- **↑↓**: Navigate within categories
- **Space**: Toggle selection (for optional components)
- **Enter**: Start installation
- **q**: Quit

## Legend

- **[●]** - Required component (cannot be deselected)
- **[✓]** - Selected optional component
- **[ ]** - Unselected optional component
- **▶** - Current selection

## Requirements

- **Go 1.21+** for building the installer
- **Arch Linux** or Arch-based distribution
- **Internet connection** for downloading packages
- **sudo privileges** for system package installation

## What Gets Installed

The installer respects your selections and only installs what you choose. Required components ensure your system has essential functionality:

- **Core Packages**: Base system dependencies, Hyprland, terminal, fonts, etc.
- **AUR Helper**: Installs `paru` and selected AUR packages
- **Dotfiles**: Copies your configuration files to appropriate locations

Optional components allow you to customize your installation based on your needs.

## Logging

All installation output is logged to `~/install.log`. If something goes wrong, check this file for detailed error information.

## Troubleshooting

### Build Issues

```bash
# Ensure Go is properly installed
go version

# Clear Go module cache if needed
go clean -modcache
go mod download
```

### Installation Issues

1. Check `~/install.log` for detailed error messages
2. Ensure you have internet connectivity
3. Verify you have sufficient disk space
4. Make sure you're running with appropriate permissions

### Graphics Driver Issues

- Only select one graphics driver option
- NVIDIA drivers may require a reboot to function properly
- AMD/Intel drivers use open-source implementations

## Contributing

Feel free to modify the installer to suit your needs:

1. **Add new categories**: Update the `categories` slice in `main.go`
2. **Add new applications**: Create functions in `lib/apps.sh`
3. **Customize styling**: Modify the lipgloss styles in `main.go`

## License

This installer is part of your dotfiles configuration and follows the same license as your dotfiles repository.
