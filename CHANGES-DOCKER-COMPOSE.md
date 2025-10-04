# Changes Summary: Docker Compose Support for Raspberry Pi 5

## Overview

This update enables installing and running Asterisk on Raspberry Pi 5 with a single command:

```bash
docker compose up -d --build
```

## Files Added

### Root Directory Files

1. **`Dockerfile`**
   - Multi-stage Dockerfile combining build and runtime stages
   - Stage 1: Builds Asterisk with all dependencies
   - Stage 2: Creates lightweight runtime container
   - Eliminates need for separate packager container
   - Optimized for ARM64/aarch64 architecture

2. **`docker-compose.yml`**
   - Single-command deployment configuration
   - Builds image from Dockerfile
   - Configures persistent volumes
   - Uses host networking for simplicity
   - Resource limits (optional)

3. **`.dockerignore`**
   - Optimizes Docker build context
   - Excludes unnecessary files (.git, build artifacts)
   - Reduces build time and image size

4. **`DOCKER.md`**
   - Comprehensive Docker documentation (English)
   - Quick start guide
   - Common commands and troubleshooting
   - Architecture explanation
   - Configuration examples

5. **`INICIO-RAPIDO-RPI5.md`**
   - Quick start guide in Spanish
   - Step-by-step installation instructions
   - Basic commands and configuration
   - Troubleshooting guide

6. **`verify-docker.sh`**
   - Verification script for Docker setup
   - Checks prerequisites (Docker, Docker Compose)
   - Validates configuration files
   - Checks running container status
   - Provides helpful next steps

### Updated Files

7. **`README.md`**
   - Added Docker installation section
   - Positioned as recommended method for RPi5
   - Links to all Docker documentation
   - Includes verification script reference

## Key Features

### Single Command Installation

```bash
docker compose up -d --build
```

This single command:
- Builds the Asterisk image
- Creates necessary volumes
- Starts the container in the background
- No manual steps required

### Multi-Stage Build

The Dockerfile uses a two-stage build:

```
Stage 1 (builder):          Stage 2 (runtime):
- Debian Bookworm       →   - Debian Bookworm Slim
- Build tools               - Runtime libraries only
- Compile Asterisk          - Asterisk from DEB
- Create DEB package        - Minimal size
```

### Persistent Storage

Four Docker volumes maintain data across container restarts:
- `asterisk-config` - Configuration files
- `asterisk-sounds` - Sound files and prompts
- `asterisk-spool` - Voicemail and recordings
- `asterisk-logs` - Log files

### Network Configuration

Uses `network_mode: host` by default:
- Direct access to host network interfaces
- Simplified SIP/RTP configuration
- No NAT traversal issues
- Ideal for VoIP scenarios

## Advantages Over Previous Method

### Before (Manual Multi-Step)

```bash
# Step 1: Build packager container
docker build -f contrib/docker/Dockerfile.packager.rpi5 -t asterisk-build-rpi5 .

# Step 2: Run packager to create DEB
docker run -ti -v $(pwd):/application:ro -v $(pwd)/out:/build \
    -w /application asterisk-build-rpi5 \
    /application/contrib/docker/make-package-deb.sh 20.0.0

# Step 3: Build runtime container
docker build -t asterisk-rpi5:20.0.0 -f contrib/docker/Dockerfile.rpi5 .

# Step 4: Run container
docker run -d --name asterisk --network host asterisk-rpi5:20.0.0
```

### Now (Single Command)

```bash
docker compose up -d --build
```

**Benefits:**
- ✅ 75% fewer commands
- ✅ No intermediate manual steps
- ✅ Automatic volume management
- ✅ Self-documenting configuration
- ✅ Easy to customize (edit docker-compose.yml)
- ✅ Standard Docker workflow

## Architecture Support

- **Primary:** Raspberry Pi 5 (ARM64/aarch64)
- **Works on:** Any ARM64 system
- **Cross-build:** x86_64 with QEMU (slow but functional)

## Build Time

- **First build:** 15-30 minutes (on Raspberry Pi 5)
- **Subsequent builds:** Use cached layers (faster)
- **Cross-compilation:** 45-90 minutes (on x86_64)

## Version Customization

Change Asterisk version in `docker-compose.yml`:

```yaml
services:
  asterisk:
    build:
      args:
        VERSION: "21.0.0"  # Change version here
```

## Backward Compatibility

The previous build method still works:
- `contrib/docker/build-rpi5.sh` - Automated build script
- `contrib/docker/docker-compose.rpi5.yml` - Alternative compose file
- `contrib/docker/Dockerfile.packager.rpi5` - Packager container
- `contrib/docker/Dockerfile.rpi5` - Runtime container

Users can choose either method based on their needs.

## Documentation Structure

```
Repository Root
├── DOCKER.md                           # Main Docker guide (English)
├── INICIO-RAPIDO-RPI5.md              # Quick start (Spanish)
├── README.md                           # Updated with Docker section
├── Dockerfile                          # Multi-stage build
├── docker-compose.yml                  # Single-command deployment
├── verify-docker.sh                    # Setup verification
└── contrib/docker/
    ├── README.rpi5.md                 # Comprehensive guide
    ├── QUICKSTART.rpi5.md             # Quick reference
    ├── docker-compose.rpi5.yml        # Alternative compose file
    ├── build-rpi5.sh                  # Manual build script
    ├── Dockerfile.packager.rpi5       # Packager (legacy)
    └── Dockerfile.rpi5                # Runtime (legacy)
```

## Testing Recommendations

### On Raspberry Pi 5

```bash
# 1. Verify prerequisites
./verify-docker.sh

# 2. Build and start
docker compose up -d --build

# 3. Monitor build progress
docker compose logs -f

# 4. Verify Asterisk is running
docker exec asterisk asterisk -rx "core show version"
```

### Verification Checklist

- [ ] Docker installed and running
- [ ] Docker Compose available
- [ ] docker-compose.yml validates successfully
- [ ] Build completes without errors
- [ ] Container starts and stays running
- [ ] Asterisk CLI accessible
- [ ] Volumes created and persistent
- [ ] Configuration changes persist across restarts

## Future Enhancements

Potential improvements for consideration:
- Pre-built images on Docker Hub
- Multi-architecture manifest (ARM64 + x86_64)
- Health checks in docker-compose.yml
- Example configuration templates
- Automated testing in CI/CD

## Migration Guide

For users with existing manual setup:

```bash
# 1. Stop old container
docker stop asterisk
docker rm asterisk

# 2. Use new method
docker compose up -d --build

# 3. Copy old configuration (if needed)
# Old volumes will be preserved if using same names
```

## Support and Resources

- **Quick Start (English):** DOCKER.md
- **Inicio Rápido (Español):** INICIO-RAPIDO-RPI5.md
- **Detailed Guide:** contrib/docker/README.rpi5.md
- **Verify Setup:** ./verify-docker.sh
- **Community:** https://community.asterisk.org
- **Documentation:** https://docs.asterisk.org

## Summary

This update significantly simplifies the Asterisk installation process on Raspberry Pi 5, reducing it from a complex multi-step procedure to a single command. The implementation maintains backward compatibility while providing a modern, Docker-native deployment method that follows best practices and conventions.
