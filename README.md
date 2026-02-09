# DRFT (Drift Browser)

[![Build DRFT](https://github.com/vs4vijay/DRFT/actions/workflows/release.yml/badge.svg)](https://github.com/vs4vijay/DRFT/actions/workflows/release.yml)

DRFT (pronounced "Drift") is a revolutionary mobile browser that reimagines web browsing with bubble-style tabs that preserve your current screen and mental context. Open links instantly, revisit later, and close in batches — designed for speed, calm, and focus.

Built on Firefox's proven GeckoView engine, DRFT combines the power and compatibility of Firefox with an innovative user experience that helps you navigate the web without losing context.

## Features

🫧 **Bubble-Style Tabs** - Open links in floating bubbles that preserve your current context
⚡ **Instant Navigation** - Switch between bubbles without losing your place
🧘 **Focus Mode** - Designed to reduce cognitive load and browsing anxiety
🔄 **Batch Operations** - Close multiple bubbles at once when you're done
🔒 **Privacy First** - Built on Firefox's privacy-focused foundation
📱 **Native Performance** - Powered by GeckoView for smooth, responsive browsing

## Quick Start

### Download Pre-built APK

1. Go to the [Releases](https://github.com/vs4vijay/DRFT/releases) page
2. Download the latest APK for your device architecture
3. Install and enjoy DRFT!

### Build from Source

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

1. Go to **Actions** → **Build DRFT**
2. Click **Run workflow**
3. Enter version name (e.g., `138.0.1`) and version code (e.g., `3138013`)
4. Download APK from artifacts when complete

## Build System Features

✅ **Automated Source Fetching** - Downloads Firefox source from Mozilla Central
✅ **Multi-ABI Support** - Build for arm64-v8a, armeabi-v7a, x86_64
✅ **CI/CD Ready** - Complete GitHub Actions workflow included
✅ **Local Development** - Reusable scripts for local builds
✅ **Comprehensive Caching** - Speeds up CI builds significantly
✅ **Artifact Management** - Automatic APK artifact uploads
✅ **Release Automation** - Draft releases created automatically

## Documentation

- **[BUILD.md](BUILD.md)** - Comprehensive build guide
- **[BUBBLES.md](BUBBLES.md)** - Bubble-style tabs concept and implementation
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
DRFT/
├── .github/workflows/     # GitHub Actions workflows
├── scripts/              # Build scripts and utilities
├── IronFox/             # Reference implementation
├── BUILD.md             # Detailed build guide
└── README.md            # This file
```

## How DRFT Works

DRFT introduces a revolutionary browsing paradigm with **bubble-style tabs**:

1. **Open in Bubble** - Tap any link to open it in a floating bubble
2. **Stay on Current Page** - Your original content remains visible and accessible  
3. **Quick Switch** - Tap bubbles to instantly switch between contexts
4. **Batch Close** - When done, close multiple bubbles at once
5. **Pull to Refresh** - Natural mobile gestures for content updates

This approach eliminates the cognitive overhead of traditional tab management, helping you browse faster and with less stress.

## Acknowledgments

This build system is inspired by and references:
- [IronFox](https://gitlab.com/ironfox-oss/IronFox) - Privacy-focused Firefox fork
- [Mozilla Firefox](https://www.mozilla.org/firefox/) - The upstream browser
- [Android Components](https://github.com/mozilla-mobile/android-components) - Mozilla's Android component library

## License

## License

DRFT build scripts are provided as-is. The browser itself is based on Firefox and subject to Mozilla's licenses (MPL 2.0).

## Contributing

We welcome contributions! Please see our contributing guidelines for:
- Bug reports and feature requests
- Code contributions and pull requests
- Build system improvements
- Documentation updates

## Support

- 📖 [Documentation](BUILD.md)
- 🐛 [Issue Tracker](https://github.com/vs4vijay/DRFT/issues)
- 💬 [Discussions](https://github.com/vs4vijay/DRFT/discussions)

---

**DRFT** - Navigate the web without losing your flow. 🫧

## Contributing

Contributions are welcome! Please ensure scripts remain compatible with both local and CI environments.

## Troubleshooting

For common issues and solutions, see [BUILD.md](BUILD.md#troubleshooting).

---

**Note**: This is an independent build system and is not officially affiliated with Mozilla.
