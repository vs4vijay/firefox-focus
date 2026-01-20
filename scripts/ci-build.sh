#!/bin/bash
#
# CI Build script for Firefox Focus
# This script is designed to run in GitHub Actions or similar CI environments
#

set -eu
set -o pipefail
set -o xtrace

# Validate required environment variables
: "${VERSION_NAME:?VERSION_NAME environment variable is required}"
: "${VERSION_CODE:?VERSION_CODE environment variable is required}"

# Determine build type and ABI based on version code
case $(echo "$VERSION_CODE" | cut -c 7) in
0)
    BUILD_TYPE='apk'
    BUILD_ABI='armeabi-v7a'
    ;;
1)
    BUILD_TYPE='apk'
    BUILD_ABI='x86'
    ;;
2)
    BUILD_TYPE='apk'
    BUILD_ABI='x86_64'
    ;;
3)
    BUILD_TYPE='apk'
    BUILD_ABI='arm64-v8a'
    ;;
4)
    BUILD_TYPE='apk'
    BUILD_ABI='universal'
    ;;
*)
    echo "Unknown target code in $VERSION_CODE." >&2
    exit 1
    ;;
esac

echo "================================================"
echo "Firefox Focus CI Build"
echo "Version: $VERSION_NAME ($VERSION_CODE)"
echo "Build Type: $BUILD_TYPE"
echo "ABI: $BUILD_ABI"
echo "================================================"

# Setup Android SDK
echo "Setting up Android SDK..."
source "./scripts/setup-android-sdk.sh"

# Get sources
echo "Downloading sources..."
bash -x ./scripts/get_sources.sh

# Update environment variables for this build
echo "Sourcing environment..."
source "scripts/env_local.sh"

# Prepare sources
echo "Preparing sources..."
bash -x ./scripts/prebuild.sh "$VERSION_NAME" "$VERSION_CODE"

# Build
echo "Building..."
bash -x scripts/build.sh "$BUILD_TYPE"

# Copy APK/AAB with proper naming
if [[ "$BUILD_TYPE" == "apk" ]]; then
    APK_IN="$(ls "$APK_ARTIFACTS"/*.apk | head -n 1)"
    if [ -n "$APK_IN" ]; then
        APK_OUT="$APK_ARTIFACTS/FirefoxFocus-v${VERSION_NAME}-${BUILD_ABI}.apk"
        mv "$APK_IN" "$APK_OUT"
        echo "APK ready at: $APK_OUT"
    else
        echo "ERROR: APK not found in $APK_ARTIFACTS"
        exit 1
    fi
fi

echo "================================================"
echo "CI Build completed successfully!"
echo "================================================"
