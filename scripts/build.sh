#!/bin/bash
#
# DRFT build script
# Builds the APK or AAB bundle
#

set -euo pipefail

if [ -z "$1" ]; then
    echo "Usage: $0 apk|bundle" >&2
    exit 1
fi

build_type="$1"

if [ "$build_type" != "apk" ] && [ "$build_type" != "bundle" ]; then
    echo "Unknown build type: '$build_type'" >&2
    echo "Usage: $0 apk|bundle" >&2
    exit 1
fi

# shellcheck disable=SC2154
if [[ "$env_source" != "true" ]]; then
    echo "Use 'source scripts/env_local.sh' before calling prebuild or build"
    exit 1
fi

# Source Cargo environment
# shellcheck disable=SC1090,SC1091
source "$CARGO_HOME/env"

echo "================================================"
echo "Building GeckoView..."
echo "================================================"

# Build GeckoView
# shellcheck disable=SC2154
pushd "$mozilla_release" > /dev/null

./mach build
./mach package

# Publish GeckoView to local Maven repository
gradle :geckoview:publishReleasePublicationToMavenLocal

popd > /dev/null

echo ""
echo "================================================"
echo "Publishing Android Components..."
echo "================================================"

# Build and publish Android Components
# shellcheck disable=SC2154
pushd "$android_components" > /dev/null
gradle publishToMavenLocal
popd > /dev/null

echo ""
echo "================================================"
echo "Building DRFT..."
echo "================================================"

# Build DRFT
# shellcheck disable=SC2154
pushd "$focus" > /dev/null

if [[ "$build_type" == "apk" ]]; then
    gradle :app:assembleRelease

    # Find and copy APK to output directory
    APK_PATH=$(find app/build/outputs/apk/focus/release -name "*.apk" | head -n 1)
    if [ -n "$APK_PATH" ]; then
        APK_FILENAME="drft-$(basename "$APK_PATH" | sed 's/focus-/drft-/')"
        cp "$APK_PATH" "$APK_ARTIFACTS/$APK_FILENAME"
        echo ""
        echo "================================================"
        echo "Build completed successfully!"
        echo "APK location: $APK_ARTIFACTS/$APK_FILENAME"
        echo "================================================"
    else
        echo "ERROR: APK not found after build!"
        exit 1
    fi
elif [[ "$build_type" == "bundle" ]]; then
    gradle :app:bundleRelease

    # Find and copy AAB to output directory
    AAB_PATH=$(find app/build/outputs/bundle -name "*.aab" | head -n 1)
    if [ -n "$AAB_PATH" ]; then
        AAB_FILENAME="drft-$(basename "$AAB_PATH" | sed 's/focus-/drft-/')"
        cp "$AAB_PATH" "$APK_ARTIFACTS/$AAB_FILENAME"
        echo ""
        echo "================================================"
        echo "Build completed successfully!"
        echo "AAB location: $APK_ARTIFACTS/$AAB_FILENAME"
        echo "================================================"
    else
        echo "ERROR: AAB not found after build!"
        exit 1
    fi
fi

popd > /dev/null
