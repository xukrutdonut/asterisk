# Docker Build Process for Asterisk on Raspberry Pi 5

## Overview

This document explains what happens when you run `docker compose up -d --build`.

## Single Command

```bash
docker compose up -d --build
```

This one command executes a multi-stage build process and deploys Asterisk.

## Build Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                      User Command                                     │
│                  docker compose up -d --build                         │
└─────────────────────────────────┬────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Stage 1: Builder                                   │
│                   FROM debian:bookworm                                │
├──────────────────────────────────────────────────────────────────────┤
│  1. Install build dependencies                                        │
│     ✓ GCC, make, autotools                                           │
│     ✓ Libraries: libedit, jansson, ssl, etc.                        │
│     ✓ FPM (package builder)                                          │
│                                                                       │
│  2. Copy source code                                                  │
│     ✓ Asterisk source → /tmp/application                            │
│     ✓ Excludes: .git, out/, *.md (via .dockerignore)               │
│                                                                       │
│  3. Configure Asterisk                                               │
│     ✓ ./configure --with-pjproject-bundled                          │
│     ✓ Build menuselect                                               │
│     ✓ Configure options (no sound files)                            │
│                                                                       │
│  4. Compile Asterisk                                                 │
│     ✓ make all                                                       │
│     ✓ make install DESTDIR=/tmp/installdir                          │
│     ⏱  Time: 15-25 minutes on RPi5                                   │
│                                                                       │
│  5. Create DEB package                                               │
│     ✓ fpm -t deb -s dir                                              │
│     ✓ Package: asterisk-rpi5_20.0.0_arm64.deb                       │
│     ✓ Location: /build/                                              │
└─────────────────────────────────┬────────────────────────────────────┘
                                  │
                                  │ Copy DEB package
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│                   Stage 2: Runtime                                    │
│                FROM debian:bookworm-slim                              │
├──────────────────────────────────────────────────────────────────────┤
│  1. Copy DEB from builder                                            │
│     ✓ COPY --from=builder /build/*.deb /tmp/                        │
│                                                                       │
│  2. Install runtime dependencies                                     │
│     ✓ Only libraries needed to run (not build)                      │
│     ✓ Smaller image size (~400MB vs ~2GB)                           │
│                                                                       │
│  3. Install Asterisk DEB                                             │
│     ✓ dpkg -i asterisk-rpi5_20.0.0_arm64.deb                        │
│                                                                       │
│  4. Create directories                                               │
│     ✓ /var/run/asterisk                                             │
│     ✓ /var/log/asterisk                                             │
│     ✓ /var/lib/asterisk                                             │
│     ✓ /var/spool/asterisk                                           │
│     ✓ /etc/asterisk                                                 │
│                                                                       │
│  5. Configure container                                              │
│     ✓ Expose ports: 5060, 8088, 4569, 10000-20000                  │
│     ✓ Entrypoint: /usr/sbin/asterisk                                │
│     ✓ CMD: -f -vvvvv -g -c (foreground, verbose)                   │
└─────────────────────────────────┬────────────────────────────────────┘
                                  │
                                  │ Image ready
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│                   Docker Compose Deployment                           │
├──────────────────────────────────────────────────────────────────────┤
│  1. Create volumes                                                    │
│     ✓ asterisk-config                                                │
│     ✓ asterisk-sounds                                                │
│     ✓ asterisk-spool                                                 │
│     ✓ asterisk-logs                                                  │
│                                                                       │
│  2. Start container                                                   │
│     ✓ Name: asterisk                                                 │
│     ✓ Network: host mode                                             │
│     ✓ Restart: unless-stopped                                        │
│     ✓ Volumes mounted                                                │
│                                                                       │
│  3. Asterisk starts                                                   │
│     ✓ Runs in foreground                                             │
│     ✓ Logs to stdout (visible via docker logs)                      │
│     ✓ Ready to accept connections                                    │
└─────────────────────────────────┬────────────────────────────────────┘
                                  │
                                  ▼
                        ┌─────────────────────┐
                        │   Asterisk Running   │
                        │  Ready for use! 🎉   │
                        └─────────────────────┘
```

## What Gets Built

### Stage 1 Output (Builder)
- **Size**: ~2 GB (includes all build tools)
- **Contains**: 
  - Build environment
  - Asterisk compiled binaries
  - DEB package: `asterisk-rpi5_20.0.0_arm64.deb`
- **Lifetime**: Discarded after Stage 2 completes
- **Purpose**: Build and package only

### Stage 2 Output (Runtime)
- **Size**: ~400-500 MB (runtime only)
- **Contains**:
  - Minimal Debian base
  - Runtime libraries
  - Asterisk installed from DEB
- **Lifetime**: This becomes your running container
- **Purpose**: Run Asterisk efficiently

## Timeline

### First Build (on Raspberry Pi 5)
```
0:00  - Command executed: docker compose up -d --build
0:01  - Stage 1 begins: Pull debian:bookworm base image
0:02  - Installing build dependencies (apt-get update/install)
2:00  - Copying source code
2:30  - Running ./configure
4:00  - Compiling Asterisk (make all)
18:00 - Installing binaries (make install)
20:00 - Creating DEB package with FPM
21:00 - Stage 2 begins: Pull debian:bookworm-slim
21:30 - Installing runtime dependencies
22:30 - Installing Asterisk DEB
23:00 - Container starts
23:30 - Asterisk initializes
24:00 - Ready! ✓
```

**Total**: ~25 minutes (varies by system)

### Subsequent Builds (with cache)
```
0:00  - Command executed: docker compose up -d --build
0:01  - Using cached layers (most steps)
1:00  - Only changed layers rebuild
2:00  - Container starts
2:30  - Ready! ✓
```

**Total**: ~2-3 minutes (if no source changes)

## Caching Strategy

Docker caches each layer. Changes at a layer invalidate all subsequent layers:

```
Layer 1: Base image (debian:bookworm)         ← Rarely changes
Layer 2: Install dependencies                 ← Rarely changes
Layer 3: Install FPM                          ← Rarely changes
Layer 4: Copy source code                     ← Changes often
Layer 5: Configure Asterisk                   ← Changes if source changes
Layer 6: Compile Asterisk                     ← Changes if source/config changes
Layer 7: Create DEB                           ← Changes if compile changes
```

**Optimization**: Layers 1-3 are almost always cached, saving ~2 minutes per build.

## What Happens Behind the Scenes

### 1. Docker Compose Reads Configuration
```yaml
services:
  asterisk:
    build:
      context: .           # Use current directory
      dockerfile: Dockerfile
      args:
        VERSION: "20.0.0"
```

### 2. Docker Builds Image
- Reads `Dockerfile`
- Executes each instruction sequentially
- Creates layers for each RUN/COPY/ADD command
- Caches layers when possible

### 3. Multi-Stage Build
- **Stage 1** runs completely
- DEB package is created in builder container
- **Stage 2** starts fresh with minimal base
- `COPY --from=builder` extracts only the DEB

### 4. Container Launch
- Image is tagged automatically
- Volumes are created if they don't exist
- Container starts with specified configuration
- Asterisk begins running in foreground

## Resource Usage

### During Build (Stage 1)
- **CPU**: High (100% on all cores)
- **RAM**: 2-4 GB
- **Disk**: ~6 GB temporary
- **Network**: ~500 MB download (dependencies)

### During Runtime (Stage 2)
- **CPU**: Low (5-10% idle, varies with calls)
- **RAM**: 100-500 MB
- **Disk**: ~500 MB (image + volumes)
- **Network**: Varies (SIP/RTP traffic)

## Troubleshooting Build Issues

### Build Fails at Stage 1
```bash
# Check available disk space
df -h

# Check available memory
free -h

# Clean up Docker
docker system prune -f

# Retry build
docker compose up -d --build
```

### Build is Slow
```bash
# On x86_64 (cross-compilation)
# → Expected: QEMU emulation is slow
# → Solution: Build on actual RPi5 if possible

# On RPi5
# → Check: Is CPU throttled? (temperature)
# → Check: Is swap being used? (memory pressure)
```

### Build Succeeds but Container Fails
```bash
# Check container logs
docker logs asterisk

# Check if DEB was installed correctly
docker exec asterisk dpkg -l | grep asterisk

# Verify Asterisk binary exists
docker exec asterisk which asterisk
```

## Comparison: Old vs New

### Old Method (3 containers, manual steps)
```
[Packager Container] → [DEB Package] → [Runtime Container] → [Running Container]
     Manual Step 1          Manual Step 2       Manual Step 3
```

### New Method (1 command, automated)
```
[Build Stage 1] → [Build Stage 2] → [Running Container]
             All automated via docker-compose
```

## Architecture Benefits

1. **Reproducible**: Same command always produces same result
2. **Efficient**: Multi-stage reduces final image size by 75%
3. **Cacheable**: Rebuilds are fast if source hasn't changed
4. **Portable**: Works on any ARM64 system
5. **Standard**: Uses standard Docker/Compose patterns
6. **Maintainable**: Single Dockerfile, single command

## Next Steps After Build

Once the build completes and container is running:

```bash
# 1. Verify it's working
docker exec asterisk asterisk -rx "core show version"

# 2. Access the CLI
docker exec -it asterisk asterisk -rvvv

# 3. Check logs
docker logs -f asterisk

# 4. Configure
docker exec -it asterisk bash
cd /etc/asterisk
# Edit configuration files...
```

---

**Pro Tip**: Run `docker compose up --build` (without `-d`) to see build output in real-time. Great for troubleshooting!
