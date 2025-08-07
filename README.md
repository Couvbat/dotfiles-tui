# Couvbat Dotfiles for Hyprland

An advanced configuration of Hyprland for Arch Linux based distributions. This package includes a modern TUI installer to selectively install and set up the required components.

## Installation

The installation could not work on every hardware as I tailored this install to my own laptop's system.

I recommend to install a base Hyprland system before installing the Couvbat Hyprland Dotfiles. Then you have a stable starting point and can test Hyprland on your system beforehand. Hyprland is complex, under ongoing development, and requires additional components.

You can find the Hyprland installation instructions here: https://wiki.hyprland.org/Getting-Started/Installation/

> IMPORTANT: Please make sure that all packages on your system are updated before running the installation script.

> PLEASE NOTE: Every Linux distribution, setup, and personal configuration can be different. Therefore, I cannot guarantee that the Couvbat Dotfiles will work everywhere. You install at your own risk.

### Using the TUI Installer (Recommended)

```shell
git clone https://github.com/Couvbat/dotfiles.git
cd dotfiles
go build -o dotfiles-installer .
./dotfiles-installer
```

### Quick Install Script

```shell
git clone https://github.com/Couvbat/dotfiles.git
cd dotfiles
./install-tui.sh
```

## Features

- **Interactive TUI**: Modern terminal-based interface with selective component installation
- **Modular Design**: Choose specific packages, applications, and configurations
- **Graphics Driver Support**: Comprehensive NVIDIA and AMD driver options
- **Application Categories**: Organized installation of development tools, browsers, entertainment apps, and more
- **Safe Installation**: Install only what you need with clear feedback

Please rebuild all packages to ensure that you get the latest commit.

## Inspirations

This repo was originally a fork of the ML4W Dotfiles.

The following projects have inspired me:

- https://github.com/mylinuxforwork/dotfiles

- https://github.com/JaKooLit/Hyprland-Dots
- https://github.com/prasanthrangan/hyprdots
- https://github.com/sudo-harun/dotfiles
- https://github.com/dianaw353/hyprland-configuration-rootfs

and many more...
