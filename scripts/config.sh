#!/bin/bash

# DRFT Configuration Script
# Allows switching between Ubuntu versions and build settings

set -euo pipefail

# Colors
echo_red_text() {
    echo -e "\033[31m$1\033[0m"
}

echo_green_text() {
    echo -e "\033[32m$1\033[0m"
}

echo_blue_text() {
    echo -e "\033[34m$1\033[0m"
}

echo_yellow_text() {
    echo -e "\033[33m$1\033[0m"
}

# Get DRFT root directory
DRFT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DRFT_ROOT"

echo_blue_text "🔧 DRFT Configuration Manager"
echo_blue_text "============================"

# Configuration file path
CONFIG_FILE="$DRFT_ROOT/.drft-config"

# Show current configuration
show_current_config() {
    echo_blue_text "Current Configuration:"
    echo "======================"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo_green_text "Ubuntu Version: ${DRFT_UBUNTU_VERSION:-20.04}"
        echo_green_text "Python Version: ${PYTHON_VERSION:-python3.9}"
        echo_green_text "Clang Version: ${CLANG_VERSION:-clang-10}"
        echo_green_text "Build Jobs: ${MACH_BUILD_JOBS:-2}"
    else
        echo_yellow_text "No configuration found. Using defaults:"
        echo_yellow_text "Ubuntu Version: 20.04"
        echo_yellow_text "Python Version: python3.9"
        echo_yellow_text "Clang Version: clang-10"
        echo_yellow_text "Build Jobs: 2"
    fi
    echo
}

# Set Ubuntu version
set_ubuntu_version() {
    local version="$1"
    
    case "$version" in
        "20.04")
            PYTHON_VERSION="python3.9"
            CLANG_VERSION="clang-10"
            UBUNTU_CODENAME="focal"
            ;;
        "22.04")
            PYTHON_VERSION="python3.9"
            CLANG_VERSION="clang-14"
            UBUNTU_CODENAME="jammy"
            ;;
        *)
            echo_red_text "Unsupported Ubuntu version: $version"
            echo_yellow_text "Supported versions: 20.04, 22.04"
            return 1
            ;;
    esac
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# DRFT Configuration
# Generated on $(date)
export DRFT_UBUNTU_VERSION="$version"
export PYTHON_VERSION="$PYTHON_VERSION"
export CLANG_VERSION="$CLANG_VERSION"
export UBUNTU_CODENAME="$UBUNTU_CODENAME"
EOF

    echo_green_text "✅ Configuration updated to Ubuntu $version"
    echo_green_text "   Python: $PYTHON_VERSION"
    echo_green_text "   Clang: $CLANG_VERSION"
    echo_green_text "   Codename: $UBUNTU_CODENAME"
    
    # Update scripts/versions.sh if needed
    sed -i "s/DRFT_UBUNTU_VERSION:-[0-9.]*/DRFT_UBUNTU_VERSION:-$version/" scripts/versions.sh
    
    echo_yellow_text "📝 Configuration saved to $CONFIG_FILE"
    echo_yellow_text "🔄 Updated scripts/versions.sh"
}

# Set build configuration
set_build_config() {
    local jobs="$1"
    
    if [[ ! "$jobs" =~ ^[0-9]+$ ]] || [[ "$jobs" -lt 1 ]] || [[ "$jobs" -gt 8 ]]; then
        echo_red_text "Invalid build jobs count: $jobs (must be 1-8)"
        return 1
    fi
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update existing config
        sed -i '/^export MACH_BUILD_JOBS=/d' "$CONFIG_FILE"
        echo "export MACH_BUILD_JOBS=\"$jobs\"" >> "$CONFIG_FILE"
    else
        # Create new config
        cat > "$CONFIG_FILE" << EOF
# DRFT Configuration
export DRFT_UBUNTU_VERSION="20.04"
export PYTHON_VERSION="python3.9"
export CLANG_VERSION="clang-10"
export UBUNTU_CODENAME="focal"
export MACH_BUILD_JOBS="$jobs"
EOF
    fi
    
    echo_green_text "✅ Build jobs set to: $jobs"
}

# Apply configuration to environment
apply_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo_red_text "No configuration found. Run 'config.sh set' first."
        return 1
    fi
    
    echo_blue_text "Applying configuration..."
    source "$CONFIG_FILE"
    
    # Export to current shell
    export DRFT_UBUNTU_VERSION
    export PYTHON_VERSION
    export CLANG_VERSION
    export UBUNTU_CODENAME
    
    echo_green_text "✅ Configuration applied to current shell"
    echo_yellow_text "💡 To make permanent, add this to your ~/.bashrc:"
    echo_yellow_text "source $CONFIG_FILE"
}

# Reset configuration
reset_config() {
    echo_red_text "Resetting configuration to defaults..."
    rm -f "$CONFIG_FILE"
    
    # Reset versions.sh
    sed -i 's/DRFT_UBUNTU_VERSION:-[0-9.]*/DRFT_UBUNTU_VERSION:-20.04/' scripts/versions.sh
    
    echo_green_text "✅ Configuration reset to defaults (Ubuntu 20.04)"
}

# Show help
show_help() {
    echo_blue_text "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  show              - Show current configuration"
    echo "  set <version>     - Set Ubuntu version (20.04, 22.04)"
    echo "  jobs <number>     - Set build job count (1-8)"
    echo "  apply             - Apply configuration to current shell"
    echo "  reset             - Reset configuration to defaults"
    echo "  help              - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 show                    # Show current config"
    echo "  $0 set 22.04               # Switch to Ubuntu 22.04"
    echo "  $0 jobs 4                  # Set 4 build jobs"
    echo "  $0 apply                    # Apply config to shell"
    echo ""
}

# Main logic
case "${1:-help}" in
    "show")
        show_current_config
        ;;
    "set")
        if [[ -z "${2:-}" ]]; then
            echo_red_text "Error: Ubuntu version required"
            echo_yellow_text "Usage: $0 set <version>"
            echo_yellow_text "Supported versions: 20.04, 22.04"
            exit 1
        fi
        set_ubuntu_version "$2"
        ;;
    "jobs")
        if [[ -z "${2:-}" ]]; then
            echo_red_text "Error: Job count required"
            echo_yellow_text "Usage: $0 jobs <number>"
            echo_yellow_text "Supported range: 1-8"
            exit 1
        fi
        set_build_config "$2"
        ;;
    "apply")
        apply_config
        ;;
    "reset")
        reset_config
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo_red_text "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac