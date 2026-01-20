# Firefox Focus Build System

[![Build Firefox Focus](https://github.com/your-repo/firefox-focus/actions/workflows/release.yml/badge.svg)](https://github.com/your-repo/firefox-focus/actions/workflows/release.yml)

A complete build system for compiling Firefox Focus APK from Mozilla Central source code, with support for both local development and CI/CD workflows.

## Quick Start

### Local Build

```bash
# 1. Download sources
./scripts/get_sources.sh

# 2. Set up environment
source scripts/env_local.sh

# 3. Prepare for building
./scripts/prebuild.sh "138.0.1" "3138013"

# 4. Build APK
./scripts/build.sh apk
```

Your APK will be in `artifacts/apk/`

### GitHub Actions Build

1. Go to **Actions** → **Build Firefox Focus**
2. Click **Run workflow**
3. Enter version name (e.g., `138.0.1`) and version code (e.g., `3138013`)
4. Download APK from artifacts when complete

## Features

✅ **Automated Source Fetching** - Downloads Firefox source from Mozilla Central
✅ **Multi-ABI Support** - Build for arm64-v8a, armeabi-v7a, x86_64
✅ **CI/CD Ready** - Complete GitHub Actions workflow included
✅ **Local Development** - Reusable scripts for local builds
✅ **Comprehensive Caching** - Speeds up CI builds significantly
✅ **Artifact Management** - Automatic APK artifact uploads
✅ **Release Automation** - Draft releases created automatically

## Documentation

- **[BUILD.md](BUILD.md)** - Comprehensive build guide
- **[Scripts Overview](#scripts)** - Description of all build scripts
- **[Version Codes](#version-codes)** - Understanding version code format

## Scripts

| Script | Purpose |
|--------|---------|
| `versions.sh` | Version configuration and directory setup |
| `get_sources.sh` | Download Firefox sources from Mozilla Central |
| `setup-android-sdk.sh` | Install and configure Android SDK/NDK |
| `env_common.sh` | Common environment variables |
| `prebuild.sh` | Configure sources for building |
| `build.sh` | Main build script (local use) |
| `ci-build.sh` | CI-specific build wrapper |

## Version Codes

Version codes follow this format: `3<version><abi><revision>`

**ABI Identifiers:**
- `0` - armeabi-v7a
- `1` - x86
- `2` - x86_64
- `3` - arm64-v8a
- `4` - universal

**Examples:**
- `3138010` - v138.0.1, armeabi-v7a, revision 0
- `3138013` - v138.0.1, arm64-v8a, revision 0
- `3138023` - v138.0.2, arm64-v8a, revision 0

## Requirements

- **OS**: Linux (Ubuntu 22.04+) or macOS
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 40GB free space
- **Java**: JDK 17
- **Build Time**: 2-8 hours

See [BUILD.md](BUILD.md) for detailed requirements.

## Repository Structure

```
firefox-focus/
├── .github/workflows/     # GitHub Actions workflows
├── scripts/              # Build scripts
├── IronFox/             # Reference implementation
├── BUILD.md             # Detailed build guide
└── README.md            # This file
```

## Acknowledgments

This build system is inspired by and references:
- [IronFox](https://gitlab.com/ironfox-oss/IronFox) - Privacy-focused Firefox fork
- [Mozilla Firefox](https://www.mozilla.org/firefox/) - The upstream browser
- [Android Components](https://github.com/mozilla-mobile/android-components) - Mozilla's Android component library

## License

Build scripts are provided as-is. Firefox and Firefox Focus are subject to Mozilla's licenses (MPL 2.0).

## Contributing

Contributions are welcome! Please ensure scripts remain compatible with both local and CI environments.

## Troubleshooting

For common issues and solutions, see [BUILD.md](BUILD.md#troubleshooting).

---

**Note**: This is an independent build system and is not officially affiliated with Mozilla.
