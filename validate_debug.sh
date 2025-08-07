#!/bin/bash

# =============================================================================
# DOTFILES VALIDATION SCRIPT
# =============================================================================
# This script validates the dotfiles repository for common issues and
# provides recommendations for improvements.

set -uo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Counters
ISSUES_FOUND=0
WARNINGS_FOUND=0
CHECKS_PASSED=0

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} DOTFILES REPOSITORY VALIDATION${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_section() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS_FOUND++))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ISSUES_FOUND++))
}

check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description missing: $file"
        return 1
    fi
}

check_script_safety() {
    local script="$1"
    local description="$2"
    
    if [[ ! -f "$script" ]]; then
        print_error "$description not found: $script"
        return 1
    fi
    
    print_section "Checking $description for safety issues..."
    
    # Check for unsafe rm commands
    if grep -q "rm -rf \$" "$script"; then
        print_error "$description contains potentially unsafe 'rm -rf' with variables"
    else
        print_success "$description: No unsafe rm commands found"
    fi
    
    # Check for hardcoded paths
    local hardcoded_paths=$(grep -E "/home/[^/]+|/etc/[^\"'\s]+|/usr/[^\"'\s]+" "$script" | wc -l)
    if [[ $hardcoded_paths -gt 0 ]]; then
        print_warning "$description contains $hardcoded_paths potentially hardcoded paths"
    else
        print_success "$description: No hardcoded paths detected"
    fi
    
    # Check for sudo usage without validation
    if grep -q "sudo" "$script" && ! grep -q "validate_sudo_access\|backup_system_file\|enable_service" "$script"; then
        print_warning "$description uses sudo without proper validation/backup"
    else
        print_success "$description: Proper sudo usage or validation detected"
    fi
}

check_shared_utilities() {
    print_section "Checking for shared utilities usage..."
    
    local lib_files=($(find lib -name "*.sh" -not -name "utils.sh"))
    local utils_users=0
    
    for file in "${lib_files[@]}"; do
        if grep -q "source.*utils.sh" "$file"; then
            ((utils_users++))
            print_success "$file uses shared utilities"
        else
            print_warning "$file does not use shared utilities"
        fi
    done
    
    if [[ $utils_users -gt 0 ]]; then
        print_success "Found $utils_users scripts using shared utilities"
    else
        print_error "No scripts are using shared utilities"
    fi
}

check_error_handling() {
    print_section "Checking error handling patterns..."
    
    local lib_files=($(find lib -name "*.sh"))
    local files_with_error_handling=0
    
    for file in "${lib_files[@]}"; do
        if grep -q "FAILED_STEPS" "$file"; then
            ((files_with_error_handling++))
            print_success "$file has error handling"
        else
            print_warning "$file lacks error handling"
        fi
    done
    
    if [[ $files_with_error_handling -gt $((${#lib_files[@]} / 2)) ]]; then
        print_success "Most scripts have error handling"
    else
        print_error "Many scripts lack proper error handling"
    fi
}

check_security_practices() {
    print_section "Checking security practices..."
    
    # Check for temporary directory usage
    if grep -r "mktemp\|create_temp_dir" lib/ >/dev/null 2>&1; then
        print_success "Scripts use secure temporary directories"
    else
        print_warning "Scripts may not use secure temporary directories"
    fi
    
    # Check for file backup practices
    if grep -r "backup_system_file\|\.backup\." lib/ >/dev/null 2>&1; then
        print_success "Scripts create backups before modifying system files"
    else
        print_warning "Scripts may not backup files before modification"
    fi
    
    # Check for network validation
    if grep -r "validate_network\|ping.*archlinux" lib/ >/dev/null 2>&1; then
        print_success "Network connectivity validation found"
    else
        print_warning "No network connectivity validation found"
    fi
}

check_documentation() {
    print_section "Checking documentation..."
    
    local required_docs=("README.md" "TUI_README.md")
    for doc in "${required_docs[@]}"; do
        check_file_exists "$doc" "Documentation file $doc"
    done
    
    # Check for inline documentation
    local documented_scripts=0
    local lib_files=($(find lib -name "*.sh"))
    
    for file in "${lib_files[@]}"; do
        if head -20 "$file" | grep -q "# ===\|# Description\|# This script"; then
            ((documented_scripts++))
        fi
    done
    
    if [[ $documented_scripts -gt $((${#lib_files[@]} / 2)) ]]; then
        print_success "Most scripts have inline documentation"
    else
        print_warning "Many scripts lack inline documentation"
    fi
}

# Main validation
main() {
    print_header
    
    # Check if we're in the right directory
    if [[ ! -f "main.go" ]] || [[ ! -d "lib" ]]; then
        print_error "Please run this script from the dotfiles repository root"
        exit 1
    fi
    
    # Core file checks
    print_section "Checking core files..."
    check_file_exists "lib/utils.sh" "Shared utilities"
    check_file_exists "lib/packages.sh" "Package management script"
    check_file_exists "lib/aur.sh" "AUR management script"
    check_file_exists "main.go" "TUI application"
    check_file_exists "build.sh" "Build script"
    
    # Safety checks
    for script in lib/*.sh; do
        if [[ -f "$script" ]]; then
            check_script_safety "$script" "$(basename "$script")"
        fi
    done
    
    # Feature checks
    check_shared_utilities
    check_error_handling
    check_security_practices
    check_documentation
    
    # Summary
    echo
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} VALIDATION SUMMARY${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}Checks passed: $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS_FOUND${NC}"
    echo -e "${RED}Issues found: $ISSUES_FOUND${NC}"
    echo
    
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        echo -e "${GREEN}✅ Repository validation passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Repository has issues that should be addressed.${NC}"
        exit 1
    fi
}

# Run validation
main "$@"
