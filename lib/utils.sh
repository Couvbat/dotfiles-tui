#!/bin/bash

# =============================================================================
# SHARED UTILITY FUNCTIONS
# =============================================================================
# This file contains common functions used across multiple installation scripts
# to eliminate code duplication and ensure consistency.

# Prevent multiple loading
if [[ "${UTILS_LOADED:-}" == "1" ]]; then
    return 0
fi
readonly UTILS_LOADED=1

# Global variables for consistent paths (only set if not already defined)
if [[ -z "${BACKUP_DIR:-}" ]]; then
    readonly BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
fi
if [[ -z "${CONFIG_DIR:-}" ]]; then
    readonly CONFIG_DIR="$HOME/.config"
fi
if [[ -z "${TEMP_BASE:-}" ]]; then
    readonly TEMP_BASE="/tmp/dotfiles_install_$$"
fi

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if user has sudo access
validate_sudo_access() {
    if ! groups | grep -qE "\b(wheel|sudo)\b"; then
        echo "❌ Error: User must be in wheel or sudo group for installation"
        echo "   Please run: sudo usermod -aG wheel $USER"
        echo "   Then log out and back in."
        exit 1
    fi
    
    # Test sudo access without actually running a command
    if ! sudo -n true 2>/dev/null; then
        echo "🔐 Testing sudo access..."
        if ! sudo true; then
            echo "❌ Error: Cannot obtain sudo privileges"
            exit 1
        fi
    fi
}

# Check if we have sufficient disk space (requires 5GB minimum)
validate_disk_space() {
    local required_space=5000000  # 5GB in KB
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $required_space ]]; then
        echo "❌ Error: Insufficient disk space"
        echo "   Required: 5GB, Available: $((available_space / 1000000))GB"
        exit 1
    fi
}

# Check internet connectivity
validate_network() {
    echo "🌐 Checking network connectivity..."
    if ! ping -c 1 archlinux.org &>/dev/null; then
        echo "❌ Error: No internet connection detected"
        echo "   Please check your network connection and try again."
        exit 1
    fi
}

validate_system_requirements() {
    local missing_commands=()
    local required_commands=("pacman" "git" "curl" "wget" "go")
    
    # Check which commands are missing
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    # Auto-install missing commands (except pacman which should always be present)
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo "📦 Missing required commands: ${missing_commands[*]}"
        
        # Check if pacman is missing (critical error)
        if [[ " ${missing_commands[*]} " =~ " pacman " ]]; then
            echo "❌ Error: pacman is not available. This script requires Arch Linux."
            exit 1
        fi
        
        # Install missing packages
        echo "🔧 Installing missing packages..."
        local packages_to_install=()
        
        for cmd in "${missing_commands[@]}"; do
            case "$cmd" in
                "git") packages_to_install+=("git") ;;
                "curl") packages_to_install+=("curl") ;;
                "wget") packages_to_install+=("wget") ;;
                "go") packages_to_install+=("go") ;;
            esac
        done
        
        if [[ ${#packages_to_install[@]} -gt 0 ]]; then
            echo "   Installing: ${packages_to_install[*]}"
            if sudo pacman -S --noconfirm "${packages_to_install[@]}"; then
                echo "✅ Successfully installed missing packages"
            else
                echo "❌ Error: Failed to install required packages"
                echo "   Please run: sudo pacman -S ${packages_to_install[*]}"
                exit 1
            fi
        fi
    fi
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

# Create backup directory
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "📁 Created backup directory: $BACKUP_DIR"
    fi
}

# Backup a system file before modification
backup_system_file() {
    local file="$1"
    local backup_name
    
    if [[ -z "$file" ]]; then
        echo "❌ Error: No file specified for backup"
        return 1
    fi
    
    if [[ -f "$file" ]]; then
        backup_name="$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
        create_backup_dir
        
        if sudo cp "$file" "$BACKUP_DIR/$backup_name"; then
            echo "💾 Backed up $file to $BACKUP_DIR/$backup_name"
        else
            echo "⚠️  Warning: Failed to backup $file"
            return 1
        fi
    else
        echo "ℹ️  File $file does not exist, no backup needed"
    fi
}

# =============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# =============================================================================

# Check if a package is installed
_isInstalled() {
    if [[ -z "$1" ]]; then
        echo "❌ Error: No package name provided to _isInstalled"
        return 1
    fi
    pacman -Qs --color always "$1" | grep "local" | grep -q "$1 "
}

# Check if a command exists
_checkCommandExists() {
    if [[ -z "$1" ]]; then
        echo "❌ Error: No command name provided to _checkCommandExists"
        return 1
    fi
    command -v "$1" &>/dev/null
}

# Install system packages with proper error handling
_installPackages() {
    if [[ $# -eq 0 ]]; then
        echo "❌ Error: No packages specified for installation"
        return 1
    fi
    
    local toInstall=()
    local pkg
    
    echo "🔍 Checking package installation status..."
    for pkg in "$@"; do
        if _isInstalled "$pkg"; then
            echo "✅ $pkg is already installed."
        else
            toInstall+=("$pkg")
            echo "📦 $pkg will be installed."
        fi
    done
    
    if [[ ${#toInstall[@]} -gt 0 ]]; then
        echo "🚀 Installing ${#toInstall[@]} package(s): ${toInstall[*]}"
        
        # Update package database first
        if ! sudo pacman -Sy; then
            echo "⚠️  Warning: Failed to update package database"
        fi
        
        # Install packages
        if ! sudo pacman -S --needed --noconfirm "${toInstall[@]}"; then
            echo "❌ Failed to install packages: ${toInstall[*]}"
            FAILED_STEPS+=("pacman: ${toInstall[*]}")
            return 1
        else
            echo "✅ Successfully installed: ${toInstall[*]}"
        fi
    else
        echo "✅ All packages are already installed."
    fi
}

# =============================================================================
# SYSTEM MODIFICATION FUNCTIONS
# =============================================================================

# Safely modify system files with backup
safe_modify_system_file() {
    local file="$1"
    local search_pattern="$2"
    local replacement="$3"
    local description="$4"
    
    if [[ -z "$file" || -z "$search_pattern" || -z "$replacement" ]]; then
        echo "❌ Error: Missing parameters for safe_modify_system_file"
        return 1
    fi
    
    echo "🔧 $description"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo "❌ Error: File $file does not exist"
        FAILED_STEPS+=("File not found: $file")
        return 1
    fi
    
    # Create backup
    if ! backup_system_file "$file"; then
        echo "❌ Error: Failed to backup $file, aborting modification"
        return 1
    fi
    
    # Perform modification
    if sudo sed -i "$search_pattern" "$file"; then
        echo "✅ Successfully modified $file"
    else
        echo "❌ Error: Failed to modify $file"
        FAILED_STEPS+=("Failed to modify: $file")
        return 1
    fi
}

# =============================================================================
# TEMPORARY DIRECTORY MANAGEMENT
# =============================================================================

# Create secure temporary directory
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d "$TEMP_BASE.XXXXXX")
    
    if [[ ! -d "$temp_dir" ]]; then
        echo "❌ Error: Failed to create temporary directory"
        exit 1
    fi
    
    # Set up cleanup trap (but suppress output during critical operations)
    trap "cleanup_temp_dir_silent '$temp_dir'" EXIT
    echo "$temp_dir"
}

# Clean up temporary directory (with output)
cleanup_temp_dir() {
    local temp_dir="$1"
    if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
        rm -rf "$temp_dir" 2>/dev/null
        echo "🧹 Cleaned up temporary directory: $temp_dir"
    fi
}

# Clean up temporary directory (silent for critical operations)
cleanup_temp_dir_silent() {
    local temp_dir="$1"
    if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
        rm -rf "$temp_dir" 2>/dev/null
    fi
}

# =============================================================================
# SERVICE MANAGEMENT FUNCTIONS
# =============================================================================

# Enable and start a systemd service safely
enable_service() {
    local service="$1"
    local user_service="${2:-false}"
    
    if [[ -z "$service" ]]; then
        echo "❌ Error: No service specified"
        return 1
    fi
    
    echo "🔧 Managing service: $service"
    
    if [[ "$user_service" == "true" ]]; then
        # User service
        if systemctl --user enable "$service" 2>/dev/null; then
            echo "✅ Enabled user service: $service"
            if systemctl --user start "$service" 2>/dev/null; then
                echo "✅ Started user service: $service"
            else
                echo "⚠️  Warning: Failed to start user service: $service"
            fi
        else
            echo "⚠️  Warning: Failed to enable user service: $service"
            FAILED_STEPS+=("Failed to enable user service: $service")
        fi
    else
        # System service
        if sudo systemctl enable "$service" 2>/dev/null; then
            echo "✅ Enabled system service: $service"
            if sudo systemctl start "$service" 2>/dev/null; then
                echo "✅ Started system service: $service"
            else
                echo "⚠️  Warning: Failed to start system service: $service"
            fi
        else
            echo "⚠️  Warning: Failed to enable system service: $service"
            FAILED_STEPS+=("Failed to enable system service: $service")
        fi
    fi
}

# =============================================================================
# INITIALIZATION FUNCTION
# =============================================================================

# Initialize utilities and perform basic system checks
init_utils() {
    echo "🚀 Initializing dotfiles installation utilities..."
    
    # Ensure FAILED_STEPS array exists
    if [[ ! -v FAILED_STEPS ]]; then
        declare -g -a FAILED_STEPS=()
    fi
    
    # Run system validation
    validate_sudo_access
    validate_system_requirements
    validate_network
    validate_disk_space
    
    echo "✅ System validation completed successfully"
}

# =============================================================================
# ERROR REPORTING
# =============================================================================

# Report installation summary
report_installation_summary() {
    echo ""
    echo "==============================================="
    echo "🎯 INSTALLATION SUMMARY"
    echo "==============================================="
    
    if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
        echo "✅ All installation steps completed successfully!"
        echo "🎉 Your Hyprland dotfiles setup is ready!"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Reboot your system to ensure all changes take effect"
        echo "   2. Log in to your new Hyprland session"
        echo "   3. Customize settings in ~/.config/hypr/"
        echo ""
        echo "📂 Backup location: $BACKUP_DIR"
        return 0
    else
        echo "⚠️  Installation completed with ${#FAILED_STEPS[@]} issue(s):"
        for step in "${FAILED_STEPS[@]}"; do
            echo "   ❌ $step"
        done
        echo ""
        echo "📋 Check the installation log for details: ~/install.log"
        echo "📂 System backups available at: $BACKUP_DIR"
        echo ""
        echo "🔧 You may need to manually resolve these issues before proceeding."
        return 1
    fi
}
