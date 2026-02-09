# DRFT (Drift Browser) Build Guide

This repository contains build scripts for compiling DRFT (Drift Browser) APK from Mozilla Central source code. DRFT reimagines mobile browsing with bubble-style tabs that preserve your current screen and mental context. Open links instantly, revisit later, and close in batches — designed for speed, calm, and focus.

## Overview

The build system fetches Firefox source code from Mozilla Central's git repository and builds DRFT with customizable configurations. The scripts are designed to work both locally and in CI environments (GitHub Actions).

## Prerequisites

### System Requirements

- **OS**: Linux (Ubuntu 22.04+ recommended) or macOS
- **RAM**: At least 8GB (16GB+ recommended)
- **Disk Space**: At least 40GB free space
- **Build Time**: 2-8 hours depending on hardware

### Required Software

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    cmake \
    clang \
    nasm \
    ninja-build \
    patch \
    perl \
    python3.9 \
    python3.9-venv \
    wget \
    xz-utils \
    zlib1g-dev \
    git \
    curl \
    unzip
```

#### Other Requirements
- **JDK 17**: Required for Android builds
- **Rust**: Will be automatically installed by the build scripts
- **Android SDK & NDK**: Will be automatically downloaded by setup-android-sdk.sh

## Building Locally

### Step 1: Download Sources

```bash
./scripts/get_sources.sh
```

This script will:
- Download Firefox 138.0.1 source code from Mozilla archive
- Download bundletool for APK signing
- Generate the environment configuration file

### Step 2: Set Up Environment

```bash
source scripts/env_local.sh
```

This sources the environment variables needed for the build.

### Step 3: Prepare the Build

```bash
./scripts/prebuild.sh <version-name> <version-code>
```

Example:
```bash
./scripts/prebuild.sh "138.0.1" "3138013"
```

**Version Code Format**: `3<version><abi><revision>`

ABI codes:
- `0` - armeabi-v7a
- `1` - x86
- `2` - x86_64
- `3` - arm64-v8a
- `4` - universal (all ABIs)

Examples:
- `3138010` - Version 138.0.1, armeabi-v7a, revision 0
- `3138013` - Version 138.0.1, arm64-v8a, revision 0
- `3138020` - Version 138.0.1, x86_64, revision 0

This script will:
- Set up Rust toolchain
- Configure Android SDK and NDK
- Prepare GeckoView, Android Components, and Focus sources
- Set version information

### Step 4: Build the APK

```bash
./scripts/build.sh apk
```

Or to build an AAB (Android App Bundle):
```bash
./scripts/build.sh bundle
```

The build process will:
1. Build GeckoView (the browser engine)
2. Build Android Components
3. Build DRFT app
4. Copy the final APK to `artifacts/apk/`

### Build Output

After a successful build, you'll find the APK at:
```
artifacts/apk/drft-arm64-v8a-release-unsigned.apk
```

## Building with CI (GitHub Actions)

The repository includes a complete GitHub Actions workflow that builds DRFT automatically.

### Manual Trigger

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build DRFT** workflow
3. Click **Run workflow**
4. Enter:
   - **Version Name**: e.g., `138.0.1`
   - **Version Code**: e.g., `3138013`
5. Click **Run workflow**

The workflow will build APKs for multiple ABIs in parallel:
- arm64-v8a (most common)
- armeabi-v7a (older devices)
- x86_64 (emulators)

### Automatic Trigger

The workflow also runs automatically on:
- Push to `main` branch
- Tag push matching `v*` pattern

### Artifacts

After the build completes:
1. Go to the workflow run page
2. Scroll down to **Artifacts** section
3. Download the APK for your target architecture
4. If it was triggered by a tag or manual workflow_dispatch, a draft release will be created

## Directory Structure

```
DRFT/
├── .github/
│   └── workflows/
│       └── release.yml       # GitHub Actions workflow
├── scripts/
│   ├── versions.sh           # Version configuration
│   ├── get_sources.sh        # Download Firefox sources
│   ├── setup-android-sdk.sh  # Set up Android SDK/NDK
│   ├── env_common.sh         # Common environment variables
│   ├── env_local.sh          # Generated local environment (by get_sources.sh)
│   ├── prebuild.sh           # Prepare sources for building
│   ├── build.sh              # Main build script
│   └── ci-build.sh           # CI-specific build wrapper
├── build/                    # Build artifacts (generated)
├── gecko/                    # Firefox source code (downloaded)
├── artifacts/                # Final build outputs (generated)
│   ├── apk/                  # APK files
│   └── aar/                  # AAR libraries
└── BUILD.md                  # This file
```

## Troubleshooting

### Out of Memory

If you encounter out-of-memory errors:
1. Reduce parallel jobs: `export MACH_BUILD_JOBS=2`
2. Increase system swap space
3. Use a machine with more RAM

### Build Failures

1. Check that all prerequisites are installed
2. Ensure you have enough disk space (40GB+)
3. Try cleaning and rebuilding:
   ```bash
   rm -rf build/ gecko/ artifacts/
   ./scripts/get_sources.sh
   # ... repeat build steps
   ```

### Rust Toolchain Issues

If Rust fails to install or compile:
```bash
rm -rf ~/.cargo ~/.rustup
# Re-run prebuild.sh to reinstall
```

### Android SDK Issues

If Android SDK setup fails:
```bash
rm -rf ~/android-sdk
source scripts/setup-android-sdk.sh
```

## Customization

### Changing Firefox Version

Edit `scripts/versions.sh`:
```bash
FIREFOX_TAG="138.0.1"  # Change to desired version
```

### Adding Patches

To apply custom patches to the Firefox source:
1. Create patch files in a `patches/` directory
2. Modify `scripts/prebuild.sh` to apply patches after source download
3. Use `patch -p1 < patches/your-patch.patch` in the gecko directory

### Build Configuration

Modify the mozconfig generation in `scripts/prebuild.sh` to add/remove Firefox build options.

## References

- [IronFox Build System](IronFox/) - Reference implementation
- [Firefox Build Documentation](https://firefox-source-docs.mozilla.org/setup/index.html)
- [GeckoView Documentation](https://mozilla.github.io/geckoview/)
- [Android Components](https://github.com/mozilla-mobile/android-components)

## Version Code Convention

Version codes follow this format: `3<actual-version><abi-identifier><revision>`

Examples for DRFT v138.0.1:
- `3138010` - armeabi-v7a, initial build
- `3138013` - arm64-v8a, initial build
- `3138020` - x86_64, initial build
- `3138014` - universal APK, initial build

The prefix `3` distinguishes these builds. Increment the revision number (last digit) for subsequent builds of the same version.

## License

The build scripts are provided as-is. Firefox and DRFT are subject to Mozilla's licenses (MPL 2.0).
