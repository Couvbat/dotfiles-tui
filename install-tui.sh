#!/bin/bash

echo "🚀 Dotfiles TUI Installer"
echo "========================"
echo

# Check if we're in the right directory
if [ ! -f "lib/packages.sh" ]; then
    echo "❌ Error: Please run this script from the dotfiles directory."
    echo "The lib/packages.sh file was not found."
    exit 1
fi

# Source utilities to access validation functions
source lib/utils.sh

# Validate and auto-install system requirements (including Go)
echo "🔍 Checking system requirements..."
validate_system_requirements

# Double-check that Go is now available
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go installation failed or is not in PATH."
    echo "Please install Go manually: https://golang.org/doc/install"
    exit 1
fi

echo "✅ All system requirements satisfied"

if ! ./fix-permissions.sh; then
    echo "❌ Failed to fix permissions"
    exit 1
fi

# Check if the installer binary exists
if [ ! -f "dotfiles-installer" ]; then
    echo "📦 Building TUI installer..."
    if ! ./build.sh; then
        echo "❌ Failed to build installer"
        exit 1
    fi
else
    # Ensure installer is executable
    chmod +x dotfiles-installer
fi

# Run the installer
echo "🎯 Starting TUI installer..."
echo
./dotfiles-installer
