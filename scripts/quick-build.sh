#!/bin/bash
#
# Quick build script for DRFT
# Automates the entire build process in one command
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "========================================="
echo "DRFT Quick Build Script"
echo "========================================="
echo ""

# Default version
DEFAULT_VERSION_NAME="138.0.1"
DEFAULT_VERSION_CODE="3138013"

# Parse arguments
VERSION_NAME="${1:-$DEFAULT_VERSION_NAME}"
VERSION_CODE="${2:-$DEFAULT_VERSION_CODE}"

echo "Version: $VERSION_NAME"
echo "Version Code: $VERSION_CODE"
echo ""

# Check if sources already exist
if [ ! -d "gecko" ]; then
    echo "Step 1/4: Downloading sources..."
    bash -x ./scripts/get_sources.sh
else
    echo "Step 1/4: Sources already downloaded (skipping)"
fi

echo ""
echo "Step 2/4: Setting up environment..."
# shellcheck disable=SC1091
source scripts/env_local.sh

echo ""
echo "Step 3/4: Preparing build..."
bash -x ./scripts/prebuild.sh "$VERSION_NAME" "$VERSION_CODE"

echo ""
echo "Step 4/4: Building APK..."
bash -x ./scripts/build.sh apk

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="
echo ""
echo "Your APK is ready at:"
find artifacts/apk -name "*.apk" -type f
echo ""
