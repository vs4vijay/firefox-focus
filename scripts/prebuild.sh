#!/bin/bash
#
# Firefox Focus prebuild script
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

# Firefox Focus
# shellcheck disable=SC2154
echo "Configuring Firefox Focus..."
pushd "$focus" > /dev/null

# Set version name and code
echo "Setting version to $VERSION_NAME ($VERSION_CODE)"
sed -i \
    -e "s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/" \
    -e "s/versionCode [0-9]*/versionCode $VERSION_CODE/" \
    app/build.gradle

# Disable crash reporting
sed -i -e '/crashReporterEnabled/s/true/false/' app/build.gradle

# Disable telemetry
sed -i -e '/telemetryEnabled/s/true/false/' app/build.gradle

# Set target ABI based on version code
case $(echo "$2" | cut -c 7) in
0)
    # APK for armeabi-v7a
    abi='"armeabi-v7a"'
    ;;
1)
    # APK for x86
    abi='"x86"'
    ;;
2)
    # APK for x86_64
    abi='"x86_64"'
    ;;
3)
    # APK for arm64-v8a
    abi='"arm64-v8a"'
    ;;
4)
    # Universal APK with all ABIs
    abi='"arm64-v8a", "armeabi-v7a", "x86", "x86_64"'
    ;;
*)
    echo "Unknown target code in $2." >&2
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

# Create mozconfig for GeckoView
{
    echo 'ac_add_options --disable-crashreporter'
    echo 'ac_add_options --disable-debug'
    echo 'ac_add_options --disable-debug-symbols'
    echo 'ac_add_options --disable-tests'
    echo 'ac_add_options --disable-updater'
    echo 'ac_add_options --enable-application=mobile/android'
    echo 'ac_add_options --enable-hardening'
    echo 'ac_add_options --enable-optimize'
    echo 'ac_add_options --enable-release'
    echo 'ac_add_options --enable-rust-simd'
    echo 'ac_add_options --enable-strip'
    echo 'ac_add_options --with-android-distribution-directory=../focus-android/app'
    echo "ac_add_options --with-android-ndk=\"$ANDROID_NDK\""
    echo "ac_add_options --with-android-sdk=\"$ANDROID_HOME\""
    echo "ac_add_options --with-java-bin-path=\"$JAVA_HOME/bin\""
    echo "ac_add_options --with-gradle=$(command -v gradle)"
    echo 'mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj'
    echo 'export MOZ_CRASHREPORTER='
    echo 'export MOZ_DATA_REPORTING='
    echo 'export MOZ_TELEMETRY_REPORTING='
    echo 'export MOZILLA_OFFICIAL=1'
} > mozconfig

popd > /dev/null

echo ""
echo "Prebuild completed successfully!"
echo "Next step: ./scripts/build.sh apk"
