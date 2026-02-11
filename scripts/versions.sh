#!/bin/bash

# DRFT (Drift Browser) Version Configuration
# Based on Firefox 138.0.1

# =====================================
# CONFIGURABLE SETTINGS
# =====================================

# Ubuntu version for builds (change this to switch between versions)
# Options: "20.04", "22.04"
UBUNTU_VERSION="${DRFT_UBUNTU_VERSION:-20.04}"

# Set OS version specific defaults
if [[ "$UBUNTU_VERSION" == "20.04" ]]; then
    PYTHON_VERSION="python3.9"
    CLANG_VERSION="clang-10"
    UBUNTU_CODENAME="focal"
elif [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    PYTHON_VERSION="python3.9"
    CLANG_VERSION="clang-14"
    UBUNTU_CODENAME="jammy"
else
    echo "Warning: Unsupported Ubuntu version: $UBUNTU_VERSION"
    echo "Defaulting to 20.04..."
    UBUNTU_VERSION="20.04"
    PYTHON_VERSION="python3.9"
    CLANG_VERSION="clang-10"
    UBUNTU_CODENAME="focal"
fi

# =====================================
# FIREFOX SOURCES
# =====================================

# Sources
FIREFOX_TAG="138.0.1"
FIREFOX_TAG_NAME="FIREFOX_${FIREFOX_TAG//./_}_RELEASE"
FIREFOX_RELEASE_PATH="releases/${FIREFOX_TAG}"
FIREFOX_VERSION="138.0.1"

# Application Services
APPSERVICES_VERSION="v138.0.1"
APPSERVICES_COMMIT="602d2d443957ea8d2e489eb0ffb54d4edf65a31b"

# firefox-l10n
L10N_COMMIT="c476a531734e1f30560d7505c27cf386dca6240f"

# Glean
GLEAN_VERSION="v66.2.0"
GLEAN_COMMIT="e95d7e50678aaa678b9556f4b8b98cdadc0f1c07"

# For RC builds, uncomment and modify these:
#FIREFOX_RC_BUILD_NAME="build1"
#FIREFOX_TAG_NAME="FIREFOX_${FIREFOX_TAG//./_}_${FIREFOX_RC_BUILD_NAME^^}"
#FIREFOX_RELEASE_PATH="candidates/${FIREFOX_TAG}-candidates/${FIREFOX_RC_BUILD_NAME}"

# =====================================
# ANDROID TOOLS
# =====================================

# Android SDK/NDK versions
ANDROID_BUILDTOOLS_VERSION="36.1.0"
ANDROID_NDK_REVISION="29.0.14206865" # r29
ANDROID_PLATFORM_VERSION="36.1"
ANDROID_SDK_REVISION="13114758"
ANDROID_SDK_TARGET="36"

# Tools versions
BUNDLETOOL_VERSION="1.18.3"
RUST_VERSION="1.83.0"
CBINDGEN_VERSION="0.29.2"

# =====================================
# DIRECTORIES
# =====================================

# Directory configuration
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_SH="${ROOTDIR}/scripts/env_local.sh"
BUILDDIR="${ROOTDIR}/build"
GECKODIR="${ROOTDIR}/gecko"
ANDROID_COMPONENTS="${GECKODIR}/mobile/android/android-components"
FOCUS="${GECKODIR}/mobile/android/focus-android"

# =====================================
# DRFT CONFIGURATION
# =====================================

# DRFT Configuration
DRFT_VERSION="${FIREFOX_VERSION}"
DRFT_APP_ID="org.drft.browser"
DRFT_APP_NAME="DRFT"

# =====================================
# EXPORT CONFIGURABLE VARIABLES
# =====================================

export UBUNTU_VERSION
export PYTHON_VERSION
export CLANG_VERSION
export UBUNTU_CODENAME
export DRFT_UBUNTU_VERSION

echo "=== DRFT Build Configuration ==="
echo "Ubuntu Version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
echo "Python: $PYTHON_VERSION"
echo "Clang: $CLANG_VERSION"
echo "================================"
