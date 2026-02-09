#!/bin/bash
#
# DRFT Development Helper Script
# Helps with common development tasks
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

function show_help() {
    echo "DRFT Development Helper"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init        - Set up development environment"
    echo "  build       - Build DRFT APK"
    echo "  clean       - Clean build artifacts"
    echo "  run         - Install and run on connected device"
    echo "  log         - Show logcat for DRFT"
    echo "  bubbles     - Show bubble-style tabs documentation"
    echo "  help        - Show this help message"
    echo ""
}

function init_env() {
    echo "Setting up DRFT development environment..."
    
    if [ ! -f "scripts/env_local.sh" ]; then
        echo "Downloading sources first..."
        ./scripts/get_sources.sh
    fi
    
    echo "Sourcing environment..."
    source scripts/env_local.sh
    
    echo "Preparing build..."
    ./scripts/prebuild.sh "138.0.1" "3138013"
    
    echo "Development environment ready!"
    echo "Run '$0 build' to create the APK"
}

function build_apk() {
    echo "Building DRFT APK..."
    
    if [ ! -f "scripts/env_local.sh" ]; then
        echo "Environment not set up. Run '$0 init' first."
        exit 1
    fi
    
    source scripts/env_local.sh
    ./scripts/build.sh apk
    
    echo ""
    echo "Build complete! APK location:"
    find artifacts/apk -name "*.apk" -exec ls -lh {} \;
}

function clean_artifacts() {
    echo "Cleaning build artifacts..."
    rm -rf build/
    rm -rf artifacts/
    rm -f scripts/env_local.sh
    
    echo "Clean complete!"
}

function run_apk() {
    echo "Installing DRFT on connected device..."
    
    APK_PATH=$(find artifacts/apk -name "*.apk" | head -n 1)
    if [ -z "$APK_PATH" ]; then
        echo "No APK found. Run '$0 build' first."
        exit 1
    fi
    
    adb install -r "$APK_PATH"
    adb shell am start -n org.mozilla.drft/.App
    
    echo "DRFT started on device!"
}

function show_logs() {
    echo "Showing DRFT logs (Ctrl+C to exit)..."
    adb logcat | grep "DRFT\|drft\|org.mozilla.drft"
}

function show_bubbles() {
    if [ -f "BUBBLES.md" ]; then
        if command -v less >/dev/null 2>&1; then
            less BUBBLES.md
        else
            cat BUBBLES.md
        fi
    else
        echo "BUBBLES.md documentation not found."
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
    log)
        show_logs
        ;;
    logs)
        show_logs
        ;;
    bubbles)
        show_bubbles
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac