#!/bin/bash

# DRFT (Drift Browser) Version Configuration
# Based on Firefox 138.0.1

# Sources
FIREFOX_TAG="138.0.1"
FIREFOX_TAG_NAME="FIREFOX_${FIREFOX_TAG//./_}_RELEASE"
FIREFOX_RELEASE_PATH="releases/${FIREFOX_TAG}"

# For RC builds, uncomment and modify these:
#FIREFOX_RC_BUILD_NAME="build1"
#FIREFOX_TAG_NAME="FIREFOX_${FIREFOX_TAG//./_}_${FIREFOX_RC_BUILD_NAME^^}"
#FIREFOX_RELEASE_PATH="candidates/${FIREFOX_TAG}-candidates/${FIREFOX_RC_BUILD_NAME}"

# Tools versions
BUNDLETOOL_TAG="1.18.0"
RUST_VERSION="1.83.0"
CBINDGEN_VERSION="0.28.0"

# Directory configuration
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_SH="${ROOTDIR}/scripts/env_local.sh"
BUILDDIR="${ROOTDIR}/build"
GECKODIR="${ROOTDIR}/gecko"
ANDROID_COMPONENTS="${GECKODIR}/mobile/android/android-components"
FOCUS="${GECKODIR}/mobile/android/drft-android"
