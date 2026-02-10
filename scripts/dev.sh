#!/bin/bash
#
# DRFT Development Helper Script
# Helps with common development tasks
#

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

function show_help() {
    echo_blue_text "🫧 DRFT Development Helper"
    echo_blue_text "=========================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init        - Set up development environment"
    echo "  build       - Build DRFT APK"
    echo "  clean       - Clean build artifacts"
    echo "  run         - Install and run on connected device"
    echo "  log         - Show logcat for DRFT"
    echo "  status      - Show development status"
    echo "  env         - Show environment variables"
    echo "  bubbles     - Show bubble-style tabs documentation"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init                     # Initialize environment"
    echo "  $0 build                    # Build DRFT"
    echo "  $0 run                      # Install and run on device"
    echo "  $0 log                      # Show logs"
    echo ""
}

function init_env() {
    echo_blue_text "🚀 Setting up DRFT development environment..."
    
    # Run bootstrap if needed
    if [[ ! -f "scripts/env_local.sh" ]]; then
        echo_green_text "Running bootstrap script..."
        if [[ -f "scripts/bootstrap.sh" ]]; then
            bash scripts/bootstrap.sh
        else
            echo_red_text "Bootstrap script not found!"
            exit 1
        fi
    fi
    
    echo_green_text "Sourcing environment..."
    source scripts/env_local.sh
    
    # Setup Android SDK if not already set up
    if [[ ! -f "scripts/env_android.sh" ]]; then
        echo_green_text "Setting up Android SDK..."
        bash scripts/setup-android-sdk.sh
    fi
    
    echo_green_text "Downloading Firefox sources..."
    if [[ ! -d "$GECKODIR" ]]; then
        bash scripts/get_sources.sh
    else
        echo_yellow_text "Firefox sources already exist, skipping download"
    fi
    
    echo_green_text "Preparing build environment..."
    bash scripts/prebuild.sh "138.0.1" "3138013"
    
    echo_green_text "✅ Development environment ready!"
    echo_yellow_text "You can now run: $0 build"
}

function build_apk() {
    echo_blue_text "🔨 Building DRFT APK..."
    
    if [[ ! -f "scripts/env_local.sh" ]]; then
        echo_red_text "Environment not set up. Run '$0 init' first."
        exit 1
    fi
    
    source scripts/env_local.sh
    
    # Check if sources exist
    if [[ ! -d "$GECKODIR" ]]; then
        echo_red_text "Firefox sources not found. Run '$0 init' first."
        exit 1
    fi
    
    bash scripts/build.sh apk
    
    echo ""
    echo_green_text "✅ Build completed!"
    echo_yellow_text "APK location:"
    find artifacts/apk -name "*.apk" -exec ls -lh {} \;
}

function clean_artifacts() {
    echo_blue_text "🧹 Cleaning build artifacts..."
    rm -rf build/
    rm -rf artifacts/
    rm -f scripts/env_local.sh scripts/env_android.sh scripts/env_rust.sh
    
    echo_green_text "✅ Clean complete!"
}

function run_apk() {
    echo_blue_text "📱 Installing and running DRFT..."
    
    # Check if ADB is available
    if ! command -v adb &> /dev/null; then
        echo_red_text "ADB not found. Please install Android SDK platform-tools."
        exit 1
    fi
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        echo_red_text "No Android device connected. Please connect a device and enable USB debugging."
        exit 1
    fi
    
    APK_PATH=$(find artifacts/apk -name "*.apk" | head -n 1)
    if [[ -z "$APK_PATH" ]]; then
        echo_red_text "No APK found. Run '$0 build' first."
        exit 1
    fi
    
    echo_green_text "Installing APK..."
    adb install -r "$APK_PATH"
    
    echo_green_text "Launching DRFT..."
    adb shell am start -n org.drft.browser/.App || adb shell am start -n org.mozilla.drft/.App
    
    echo_green_text "✅ DRFT is running on your device!"
}

function show_logs() {
    echo_blue_text "📋 Showing DRFT logs (Ctrl+C to exit)..."
    
    if ! command -v adb &> /dev/null; then
        echo_red_text "ADB not found. Please install Android SDK platform-tools."
        exit 1
    fi
    
    adb logcat | grep -E "DRFT|drft|org\.drft\.browser|org\.mozilla\.drft|Gecko|System.out"
}

function show_status() {
    echo_blue_text "📊 DRFT Development Status"
    echo_blue_text "=========================="
    
    # Environment
    if [[ -f "scripts/env_local.sh" ]]; then
        source scripts/env_local.sh 2>/dev/null || true
        echo_green_text "✅ Environment configured"
    else
        echo_red_text "❌ Environment not configured"
    fi
    
    # Android SDK
    if [[ -f "scripts/env_android.sh" ]]; then
        source scripts/env_android.sh 2>/dev/null || true
        echo_green_text "✅ Android SDK configured"
    else
        echo_red_text "❌ Android SDK not configured"
    fi
    
    # Sources
    if [[ -d "${GECKODIR:-gecko}" ]]; then
        echo_green_text "✅ Firefox sources present"
    else
        echo_red_text "❌ Firefox sources not found"
    fi
    
    # Build artifacts
    if find artifacts/apk -name "*.apk" -exec test -f {} \; 2>/dev/null | grep -q .; then
        echo_green_text "✅ APK built"
    else
        echo_red_text "❌ APK not built"
    fi
    
    # Device connection
    if command -v adb &> /dev/null && adb devices 2>/dev/null | grep -q "device$"; then
        echo_green_text "✅ Android device connected"
    else
        echo_yellow_text "⚠️  No Android device connected"
    fi
}

function show_env() {
    echo_blue_text "🔧 DRFT Environment Variables"
    echo_blue_text "=============================="
    
    if [[ -f "scripts/env_local.sh" ]]; then
        source scripts/env_local.sh
        
        echo "DRFT_ROOT: ${DRFT_ROOT:-<not set>}"
        echo "JAVA_HOME: ${JAVA_HOME:-<not set>}"
        echo "ANDROID_HOME: ${ANDROID_HOME:-<not set>}"
        echo "ANDROID_NDK_ROOT: ${ANDROID_NDK_ROOT:-<not set>}"
        echo "CARGO_HOME: ${CARGO_HOME:-<not set>}"
        echo "GRADLE_USER_HOME: ${GRADLE_USER_HOME:-<not set>}"
        echo "MACH_BUILD_JOBS: ${MACH_BUILD_JOBS:-<not set>}"
        
        # Java version
        if command -v java &> /dev/null; then
            echo "Java: $(java -version 2>&1 | head -n1)"
        fi
        
        # Rust version
        if command -v rustc &> /dev/null; then
            echo "Rust: $(rustc --version)"
        fi
    else
        echo_red_text "Environment not configured. Run '$0 init' first."
    fi
}

function show_bubbles() {
    echo_blue_text "🫧 DRFT Bubble-Style Tabs"
    echo_blue_text "========================="
    
    if [[ -f "BUBBLES.md" ]]; then
        if command -v less >/dev/null 2>&1; then
            less BUBBLES.md
        else
            cat BUBBLES.md
        fi
    else
        echo_yellow_text "BUBBLES.md not found. Here's the concept:"
        echo ""
        echo "DRFT reimagines mobile browsing with bubble-style tabs that preserve your"
        echo "current screen and mental context. Open links instantly, revisit later,"
        echo "and close in batches — designed for speed, calm, and focus."
        echo ""
        echo "Key features:"
        echo "• Open links in floating bubbles that preserve context"
        echo "• Switch between bubbles without losing your place"
        echo "• Close multiple bubbles at once"
        echo "• Reduce cognitive load and browsing anxiety"
    fi
}

# Main script logic
case "${1:-help}" in
    init)
        init_env
        ;;
    build)
        build_apk
        ;;
    clean)
        clean_artifacts
        ;;
    run)
        run_apk
        ;;
    log|logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    env)
        show_env
        ;;
    bubbles)
        show_bubbles
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo_red_text "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac