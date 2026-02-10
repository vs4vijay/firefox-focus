#!/bin/bash

# DRFT Android SDK/NDK Setup Script
# Downloads and configures Android SDK and NDK

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

# Source environment
if [[ -f "scripts/env_local.sh" ]]; then
    source scripts/env_local.sh
else
    echo_red_text "Environment not configured. Please run bootstrap.sh first."
    exit 1
fi

echo_blue_text "🤖 DRFT Android SDK/NDK Setup"
echo_blue_text "============================="

# Android SDK directory
if [[ "${ANDROID_HOME+x}" == "" ]]; then
    export ANDROID_HOME=$HOME/android-sdk
fi

export ANDROID_SDK_ROOT="$ANDROID_HOME"
ANDROID_NDK_DIR="$ANDROID_HOME/ndk/$ANDROID_NDK_REVISION"

# Download and install command line tools
echo_green_text "Setting up Android SDK..."
if [ ! -d "$ANDROID_HOME" ]; then
    mkdir -p "$ANDROID_HOME"
    cd "$ANDROID_HOME/.." || exit 1
    rm -Rf "$(basename "$ANDROID_HOME")"

    # Detect OS for correct download
    case "$OSTYPE" in
        linux*)
            ANDROID_SDK_FILE="commandlinetools-linux-${ANDROID_SDK_REVISION}_latest.zip"
            ;;
        darwin*)
            ANDROID_SDK_FILE="commandlinetools-mac-${ANDROID_SDK_REVISION}_latest.zip"
            ;;
        msys*|cygwin*|win32*)
            ANDROID_SDK_FILE="commandlinetools-win-${ANDROID_SDK_REVISION}_latest.zip"
            ;;
        *)
            echo_red_text "Unsupported OS for Android SDK: $OSTYPE"
            exit 1
            ;;
    esac

    # https://developer.android.com/studio/index.html#command-tools
    echo "Downloading Android SDK..."
    wget "https://dl.google.com/android/repository/${ANDROID_SDK_FILE}" -O tools-$ANDROID_SDK_REVISION.zip
    rm -Rf "$ANDROID_HOME"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    unzip -q tools-$ANDROID_SDK_REVISION.zip -d "$ANDROID_HOME/cmdline-tools"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm -vf tools-$ANDROID_SDK_REVISION.zip
fi

# Find sdkmanager
if [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    SDK_MANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
elif [ -x "$ANDROID_HOME/cmdline-tools/bin/sdkmanager" ]; then
    SDK_MANAGER="$ANDROID_HOME/cmdline-tools/bin/sdkmanager"
else
    echo_red_text "ERROR: no usable sdkmanager found in $ANDROID_HOME"
    echo "Checking other possible paths:"
    find "$ANDROID_HOME" -type f -name sdkmanager
    exit 1
fi

PATH=$PATH:$(dirname "$SDK_MANAGER")
export PATH

# Accept licenses
echo_green_text "Accepting Android SDK licenses..."
{ yes || true; } | sdkmanager --sdk_root="$ANDROID_HOME" --licenses

# Install required components
echo_green_text "Installing Android SDK components..."
$SDK_MANAGER "build-tools;${ANDROID_BUILDTOOLS_VERSION}"
$SDK_MANAGER "platforms;android-${ANDROID_SDK_TARGET}"
$SDK_MANAGER "ndk;${ANDROID_NDK_REVISION}"

export ANDROID_NDK="$ANDROID_HOME/ndk/${ANDROID_NDK_REVISION}"
[ -d "$ANDROID_NDK" ] || {
    echo_red_text "Error: $ANDROID_NDK does not exist."
    exit 1
}

# Set additional NDK environment variables for Firefox build
export ANDROID_NDK_ROOT="$ANDROID_NDK"
export ANDROID_NDK_HOME="$ANDROID_NDK"

# Create Android environment file
echo_green_text "Creating Android environment configuration..."
cat > "$DRFT_ROOT/scripts/env_android.sh" << EOF
#!/bin/bash

# Android SDK/NDK Environment Configuration for DRFT

export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_ROOT="$ANDROID_NDK"
export ANDROID_NDK_HOME="$ANDROID_NDK"
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"

# Android build variables
export ANDROID_SDK_TARGET="${ANDROID_SDK_TARGET}"
export ANDROID_BUILDTOOLS_VERSION="${ANDROID_BUILDTOOLS_VERSION}"
export ANDROID_NDK_REVISION="${ANDROID_NDK_REVISION}"
EOF

chmod +x "$DRFT_ROOT/scripts/env_android.sh"

echo_green_text "✅ Android SDK/NDK setup completed successfully!"
echo_blue_text "Android SDK: $ANDROID_HOME"
echo_blue_text "Android NDK: $ANDROID_NDK"
echo_blue_text "Build Tools: $ANDROID_BUILDTOOLS_VERSION"
echo_blue_text "Platform: android-$ANDROID_SDK_TARGET"
