# DRFT Configuration Management

This document explains DRFT's flexible configuration system for Ubuntu versions and build settings.

## Overview

DRFT supports multiple Ubuntu versions and build configurations to accommodate different development environments and preferences.

## Supported Ubuntu Versions

### Ubuntu 20.04 (Focal Fossa) - **Default**
- **Python**: python3.9
- **Clang**: clang-10
- **Stability**: Very stable, widely tested
- **Recommendation**: Best for production builds and maximum compatibility

### Ubuntu 22.04 (Jammy Jellyfish) 
- **Python**: python3.9  
- **Clang**: clang-14
- **Stability**: Stable, newer toolchain
- **Recommendation**: Good for development with newer compilers

## Configuration Methods

### 1. Configuration Script (Recommended)

```bash
# View current configuration
./scripts/config.sh show

# Switch Ubuntu version
./scripts/config.sh set 20.04  # Ubuntu 20.04
./scripts/config.sh set 22.04  # Ubuntu 22.04

# Set build job count
./scripts/config.sh jobs 4     # 4 parallel jobs
./scripts/config.sh jobs 2     # 2 parallel jobs (default)

# Reset to defaults
./scripts/config.sh reset

# Apply configuration to current shell
./scripts/config.sh apply
```

### 2. Environment Variable

```bash
# Temporary setting
export DRFT_UBUNTU_VERSION=22.04

# Permanent setting (add to ~/.bashrc)
echo 'export DRFT_UBUNTU_VERSION=20.04' >> ~/.bashrc
```

### 3. Manual File Configuration

Configuration is stored in `.drft-config` in project root:

```bash
# Example .drft-config file
export DRFT_UBUNTU_VERSION="20.04"
export PYTHON_VERSION="python3.9"
export CLANG_VERSION="clang-10"
export UBUNTU_CODENAME="focal"
```

## Build Performance Tuning

### Job Count Configuration
- **1-2 jobs**: Good for low-memory systems (4-8GB RAM)
- **3-4 jobs**: Good for medium systems (8-16GB RAM)
- **5-8 jobs**: Good for high-performance systems (16GB+ RAM)

### Memory Optimization
For low-memory systems:
```bash
# Set conservative build settings
./scripts/config.sh jobs 1

# Use environment variables
export MACH_BUILD_JOBS=1
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=1"
```

## CI/CD Integration

### GitHub Actions
The workflow automatically respects the `DRFT_UBUNTU_VERSION` environment variable:

```yaml
# In .github/workflows/release.yml
- name: Set environment for Ubuntu 20.04
  run: |
    echo "DRFT_UBUNTU_VERSION=20.04" >> $GITHUB_ENV
```

### Cache Keys
Build caches are version-specific to prevent conflicts:
- `ubuntu-20.04-drft-138.0.1-cargo-arm64-v8a`
- `ubuntu-22.04-drft-138.0.1-cargo-arm64-v8a`

## File Structure

```
DRFT/
├── .drft-config              # Configuration file (auto-generated)
├── scripts/
│   ├── config.sh             # Configuration manager
│   ├── versions.sh           # Version configuration (auto-updated)
│   └── dev.sh               # Development helper (updated)
└── .github/workflows/
    └── release.yml           # CI/CD workflow (configurable)
```

## Troubleshooting

### Configuration Not Applied
```bash
# Ensure configuration is sourced
source scripts/env_local.sh

# Or use config script
./scripts/config.sh apply
```

### Build Toolchain Issues
```bash
# Check current configuration
./scripts/config.sh show

# Reset to known working version
./scripts/config.sh reset

# Clear caches and rebuild
rm -rf build/ artifacts/ gecko/
```

### Switching Between Versions
```bash
# Switch to Ubuntu 22.04
./scripts/config.sh set 22.04
./scripts/dev.sh clean      # Clean previous build
./scripts/dev.sh build      # Rebuild with new config

# Switch back to Ubuntu 20.04  
./scripts/config.sh set 20.04
./scripts/dev.sh clean      # Clean previous build
./scripts/dev.sh build      # Rebuild with new config
```

## Best Practices

1. **Use Ubuntu 20.04** for production releases (maximum stability)
2. **Use Ubuntu 22.04** for development (newer toolchain)
3. **Set job count** based on available RAM
4. **Clean build directory** when switching Ubuntu versions
5. **Use configuration script** rather than manual edits
6. **Test with small changes** before major version switches

## Future Extensibility

The configuration system is designed to be extensible:
- Can support additional Ubuntu versions (18.04, 24.04)
- Can add more build parameters
- Can integrate with CI/CD systems
- Can support different build profiles (debug, release, profile)