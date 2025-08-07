#!/bin/bash

# =============================================================================
# FIX PERMISSIONS SCRIPT
# =============================================================================
# This script fixes executable permissions for all scripts and binaries
# Run this on Linux systems after cloning or transferring files
# =============================================================================

echo "🔧 Fixing executable permissions..."

# Make shell scripts executable
echo "📜 Making shell scripts executable..."
chmod +x *.sh
chmod +x lib/*.sh

# Make installer binary executable if it exists
if [ -f "dotfiles-installer" ]; then
    echo "🚀 Making installer binary executable..."
    chmod +x dotfiles-installer
fi

# Check if we're in the right directory
if [ ! -f "main.go" ]; then
    echo "⚠️  Warning: Not in dotfiles directory - main.go not found"
    echo "Please run this script from the dotfiles repository root"
    exit 1
fi

echo "✅ All permissions fixed!"
echo ""
echo "You can now run:"
echo "  ./build.sh          - Build the installer"
echo "  ./install-tui.sh    - Quick start script"
echo "  ./dotfiles-installer - Run the TUI installer directly"
echo "  ./validate.sh       - Validate the installation"
echo ""
