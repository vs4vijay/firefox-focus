#!/bin/bash

# Common environment configuration for DRFT builds

# Get DRFT root directory
if [[ -z "${DRFT_ROOT+x}" ]]; then
    export DRFT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Source version configuration
source "$DRFT_ROOT/scripts/versions.sh"

# Build directories
export BUILDDIR="$DRFT_ROOT/build"
export GECKODIR="$DRFT_ROOT/gecko"
export ANDROID_COMPONENTS="$GECKODIR/mobile/android/android-components"
export FOCUS="$GECKODIR/mobile/android/focus-android"

# Output directories
export ARTIFACTS="$DRFT_ROOT/artifacts"
export APK_ARTIFACTS="$ARTIFACTS/apk"
export AAR_ARTIFACTS="$ARTIFACTS/aar"
export LOG_ARTIFACTS="$ARTIFACTS/logs"

mkdir -p "$APK_ARTIFACTS"
mkdir -p "$AAR_ARTIFACTS"
mkdir -p "$LOG_ARTIFACTS"

export env_source="true"

# Rust and Cargo
if [[ -z ${CARGO_HOME+x} ]]; then
    export CARGO_HOME=$HOME/.cargo
fi

# Gradle
if [[ -z ${GRADLE_USER_HOME+x} ]]; then
    export GRADLE_USER_HOME=$HOME/.gradle
fi

# Disable Gradle daemon and configuration cache for reproducible builds
mkdir -p "$GRADLE_USER_HOME"
echo "org.gradle.daemon=false" >> "$GRADLE_USER_HOME/gradle.properties"
echo "org.gradle.configuration-cache=false" >> "$GRADLE_USER_HOME/gradle.properties"

# Common build flags
export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=pip
export MACH_USE_SYSTEM_PYTHON=1

# Set low resource usage by default for CI compatibility
if [[ -z "${MACH_BUILD_JOBS+x}" ]]; then
    export MACH_BUILD_JOBS=2
fi

echo "DRFT environment configured:"
echo "DRFT Root: $DRFT_ROOT"
echo "Build Dir: $BUILDDIR"
echo "Gecko Dir: $GECKODIR"
