#!/bin/bash

# Build the TUI installer
echo "Building dotfiles TUI installer..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go first."
    echo "Visit: https://golang.org/doc/install"
    exit 1
fi

# Initialize Go module if go.mod doesn't exist
if [ ! -f "go.mod" ]; then
    go mod init dotfiles-installer
fi

# Download dependencies
echo "Downloading dependencies..."
go mod tidy

# Build the application
echo "Building application..."
go build -o dotfiles-installer main.go

if [ $? -eq 0 ]; then
    # Make the installer executable
    chmod +x dotfiles-installer
    echo "✅ Build successful!"
    echo "✅ Installer made executable"
    echo ""
    echo "Run the installer with: ./dotfiles-installer"
    echo ""
else
    echo "❌ Build failed!"
    exit 1
fi
