#!/bin/bash

# DRFT Bootstrap Script
# Sets up build environment and installs dependencies

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

# Get DRFT root directory
DRFT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DRFT_ROOT

echo_blue_text "🫧 DRFT (Drift Browser) Bootstrap Script"
echo_blue_text "========================================="

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/fedora-release ]]; then
            echo "fedora"
        elif [[ -f /etc/lsb-release ]]; then
            echo "ubuntu"
        elif [[ -f /etc/arch-release ]]; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

DRFT_OS=$(detect_os)
echo_green_text "Detected OS: $DRFT_OS"

# Install dependencies based on OS
install_dependencies() {
    echo_green_text "Installing dependencies..."
    
    case $DRFT_OS in
        "ubuntu")
            sudo apt update
            sudo apt install -y \
                cmake \
                clang \
                nasm \
                ninja-build \
                patch \
                perl \
                python3.9 \
                python3.9-venv \
                wget \
                xz-utils \
                zlib1g-dev \
                git \
                curl \
                unzip \
                openjdk-17-jdk
                
            # Add Adoptium repository for Java
            wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/adoptium.gpg
            echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
            sudo apt update
            ;;
            
        "fedora")
            sudo dnf update -y
            sudo dnf install -y \
                cmake \
                clang \
                nasm \
                ninja-build \
                patch \
                perl \
                python3.9 \
                wget \
                xz \
                zlib-devel \
                git \
                curl \
                unzip \
                java-17-openjdk-devel
            ;;
            
        "macos")
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                echo_red_text "Homebrew is not installed! Please install it first:"
                echo_red_text "https://brew.sh/"
                exit 1
            fi
            
            brew update
            brew install \
                cmake \
                nasm \
                ninja \
                git \
                perl \
                python@3.9 \
                wget \
                xz \
                openjdk@17
            ;;
            
        "windows")
            echo_yellow_text "Windows detected!"
            echo_yellow_text "Please install the following manually:"
            echo "  • Git (https://git-scm.com/)"
            echo "  • CMake (https://cmake.org/download/)"
            echo "  • Java 17 JDK (https://adoptium.net/)"
            echo "  • Python 3.9+ (https://www.python.org/)"
            echo "  • Visual Studio Build Tools or MinGW"
            echo ""
            echo_yellow_text "After installation, run: bash scripts/setup-android-sdk.sh"
            ;;
            
        *)
            echo_red_text "Unsupported operating system: $DRFT_OS"
            echo_red_text "Please manually install the required dependencies."
            exit 1
            ;;
    esac
}

# Set up Java environment
setup_java() {
    echo_green_text "Setting up Java environment..."
    
    if [[ $DRFT_OS == "macos" ]]; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    elif [[ $DRFT_OS == "windows" ]]; then
        # Try common Java installation paths on Windows
        for java_path in \
            "/c/Program Files/Java/jdk-17"* \
            "/c/Program Files (x86)/Java/jdk-17"* \
            "/c/Program Files/Eclipse Adoptium/jdk-17"*; do
            if [[ -d "$java_path" ]]; then
                export JAVA_HOME="$(cygpath -w "$java_path")"
                break
            fi
        done
    elif [[ -d /usr/lib/jvm/java-17-openjdk-amd64 ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    elif [[ -d /usr/lib/jvm/java-17-openjdk ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    fi
    
    if [[ -n "$JAVA_HOME" ]]; then
        echo "JAVA_HOME=$JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        echo_red_text "Warning: Java 17 not found. Please set JAVA_HOME manually."
    fi
}

# Create environment file
create_env_file() {
    echo_green_text "Creating environment configuration..."
    
    cat > "$DRFT_ROOT/scripts/env_local.sh" << 'EOF'
#!/bin/bash

# DRFT Local Environment Configuration
# This file is auto-generated by bootstrap.sh

# Get DRFT root directory
export DRFT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source version configuration
source "$DRFT_ROOT/scripts/versions.sh"

# Source common environment
source "$DRFT_ROOT/scripts/env_common.sh"

# Java configuration
if [[ -z "${JAVA_HOME+x}" ]]; then
    if command -v java &> /dev/null; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    fi
fi

# Android SDK configuration (will be set by setup-android-sdk.sh)
if [[ -f "$DRFT_ROOT/scripts/env_android.sh" ]]; then
    source "$DRFT_ROOT/scripts/env_android.sh"
fi

# Rust configuration (will be set by prebuild.sh)
if [[ -f "$DRFT_ROOT/scripts/env_rust.sh" ]]; then
    source "$DRFT_ROOT/scripts/env_rust.sh"
fi

echo "DRFT environment configured successfully!"
echo "DRFT Root: $DRFT_ROOT"
echo "Java: $(java -version 2>&1 | head -n1)"
EOF

    chmod +x "$DRFT_ROOT/scripts/env_local.sh"
}

# Main execution
main() {
    echo_blue_text "Starting bootstrap process..."
    
    # Install dependencies
    install_dependencies
    
    # Set up Java
    setup_java
    
    # Create environment file
    create_env_file
    
    echo_green_text "✅ Bootstrap completed successfully!"
    echo
    echo_blue_text "Next steps:"
    echo "1. Source the environment: source scripts/env_local.sh"
    echo "2. Run setup-android-sdk.sh to install Android SDK/NDK"
    echo "3. Run get_sources.sh to download Firefox sources"
    echo "4. Run prebuild.sh to prepare the build"
    echo "5. Run build.sh to build DRFT"
    echo
}

main "$@"