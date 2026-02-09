#!/bin/bash
#
# DRFT prebuild script
# Prepares the source code for building
#

set -e

# Include version info
source "$rootdir/scripts/versions.sh"

function localize_maven {
    # Replace custom Maven repositories with mavenLocal()
    find ./* -name '*.gradle' -type f -exec sed -i 's|google()|mavenLocal()\n    google()|g' {} \;
    find ./* -name '*.gradle' -type f -exec sed -i 's|mavenCentral()|mavenLocal()\n    mavenCentral()|g' {} \;
    # Make gradlew scripts call gradle wrapper
    find ./* -name gradlew -type f | while read -r gradlew; do
        echo -e '#!/bin/sh\ngradle "$@"' >"$gradlew"
        chmod 755 "$gradlew"
    done
}

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 versionName versionCode" >&2
    exit 1
fi

VERSION_NAME="$1"
VERSION_CODE="$2"

# shellcheck disable=SC2154
if [[ "$env_source" != "true" ]]; then
    echo "Use 'source scripts/env_local.sh' before calling prebuild or build"
    exit 1
fi

if [ ! -d "$ANDROID_HOME" ]; then
    echo "\$ANDROID_HOME($ANDROID_HOME) does not exist."
    exit 1
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo "\$ANDROID_NDK($ANDROID_NDK) does not exist."
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{sub("^$", "0", $2); print $1$2}')
[ "$JAVA_VER" -ge 17 ] || {
    echo "Java 17 or newer must be set as default JDK"
    exit 1
}

if [[ -z "$FIREFOX_TAG" ]]; then
    echo "\$FIREFOX_TAG is not set! Aborting..."
    exit 1
fi

# Create build directory
mkdir -p "$rootdir/build"

# Set up Rust
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-update-default-toolchain
fi

# shellcheck disable=SC1090,SC1091
source "$CARGO_HOME/env"
rustup default "$RUST_VERSION"
rustup target add thumbv7neon-linux-androideabi
rustup target add armv7-linux-androideabi
rustup target add aarch64-linux-android
rustup target add i686-linux-android
rustup target add x86_64-linux-android

# Install cbindgen if not present
if ! cargo install --list | grep -q "cbindgen v$CBINDGEN_VERSION"; then
    cargo install --vers "$CBINDGEN_VERSION" cbindgen
fi

# Setup F-Droid's gradle script if not in PATH
if ! command -v gradle &> /dev/null; then
    echo "Setting up F-Droid gradle wrapper..."
    mkdir -p "$HOME/bin"
    if [ ! -f "$HOME/bin/gradle" ]; then
        wget https://gitlab.com/fdroid/fdroidserver/-/raw/master/gradlew-fdroid -O "$HOME/bin/gradle"
        chmod +x "$HOME/bin/gradle"
    fi
    export PATH="$HOME/bin:$PATH"
fi

# Android Components
# shellcheck disable=SC2154
echo "Configuring Android Components..."
pushd "$android_components" > /dev/null
localize_maven
popd > /dev/null

# DRFT
# shellcheck disable=SC2154
echo "Configuring DRFT..."
pushd "$focus" > /dev/null

# Set version name and code
echo "Setting version to $VERSION_NAME ($VERSION_CODE)"
sed -i \
    -e "s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/" \
    -e "s/versionCode [0-9]*/versionCode $VERSION_CODE/" \
    app/build.gradle

# Rename app from Focus to DRFT
echo "Rebranding app to DRFT..."

# Update app ID in build.gradle (most critical)
sed -i -e 's/applicationId "org.mozilla.focus"/applicationId "org.mozilla.drft"/' app/build.gradle

# Update app name in strings.xml
if [ -f "app/src/main/res/values/strings.xml" ]; then
    sed -i -e 's/Focus/DRFT/g' app/src/main/res/values/strings.xml
    sed -i -e 's/Firefox Focus/DRFT/g' app/src/main/res/values/strings.xml
fi

# Update package name in AndroidManifest.xml (critical for build)
if [ -f "app/src/main/AndroidManifest.xml" ]; then
    sed -i -e 's/package="org\.mozilla\.focus"/package="org.mozilla.drft"/g' app/src/main/AndroidManifest.xml
    sed -i -e 's/org\.mozilla\.focus/org\.mozilla\.drft/g' app/src/main/AndroidManifest.xml
    sed -i -e 's/Focus/DRFT/g' app/src/main/AndroidManifest.xml
fi

# Update app icon references if they exist
find app/src/main/res -name "*.xml" -type f -exec sed -i -e 's/focus_/drft_/g' {} \; 2>/dev/null || true

# Update key source files that are most likely to cause build issues
KEY_FILES=(
    "app/src/main/java/org/mozilla/focus/FocusApplication.kt"
    "app/src/main/java/org/mozilla/focus/Components.kt"
    "app/src/main/java/org/mozilla/focus/activity/MainActivity.kt"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "$file" ]; then
        sed -i -e 's/org\.mozilla\.focus/org\.mozilla\.drft/g' "$file"
    fi
done

# Disable crash reporting
sed -i -e '/crashReporterEnabled/s/true/false/' app/build.gradle

# Disable telemetry
sed -i -e '/telemetryEnabled/s/true/false/' app/build.gradle

# Set target ABI based on version code
# Development: Always use arm64-v8a (Pixel 9 Pro XL)
case $(echo "$2" | cut -c 7) in
3)
    # APK for arm64-v8a
    abi='"arm64-v8a"'
    ;;
*)
    echo "Development build only supports arm64-v8a (code suffix 3). Got: $(echo "$2" | cut -c 7)" >&2
    exit 1
    ;;
esac

echo "Setting target ABI to: $abi"
sed -i -e "s/include \".*\"/include $abi/" app/build.gradle

localize_maven
popd > /dev/null

# GeckoView
echo "Configuring GeckoView..."
pushd "$mozilla_release" > /dev/null

# Create mozconfig for GeckoView (minimal working configuration)
{
    echo 'ac_add_options --enable-application=mobile/android'
    echo 'ac_add_options --disable-debug'
    echo 'ac_add_options --disable-tests'
    echo 'ac_add_options --disable-updater'
    echo 'ac_add_options --enable-release'
    echo "ac_add_options --with-android-sdk=\"$ANDROID_HOME\""
    echo "ac_add_options --with-android-ndk=\"$ANDROID_NDK\""
    echo 'mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj'
    echo 'export CC=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/clang'
    echo 'export CXX=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++'
    echo 'export LD=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/ld'
} > mozconfig

popd > /dev/null

echo ""
echo "Prebuild completed successfully!"
echo "Next step: ./scripts/build.sh apk"
