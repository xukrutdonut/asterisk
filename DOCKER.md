# Docker Installation for Asterisk on Raspberry Pi 5

This repository includes everything you need to run Asterisk on a Raspberry Pi 5 using Docker with a single command.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/xukrutdonut/asterisk.git
cd asterisk

# Build and run Asterisk
docker compose up -d --build
```

That's it! Asterisk will build and start running in the background.

**Note:** The first build takes 15-30 minutes depending on your Raspberry Pi 5.

## What Gets Created

The `docker compose up -d --build` command will:

1. **Build Stage 1:** Create a build environment with all necessary dependencies
2. **Build Stage 2:** Compile Asterisk from source with bundled pjproject
3. **Build Stage 3:** Create a DEB package for Asterisk
4. **Runtime Stage:** Create a lightweight runtime container with only necessary libraries
5. **Start Asterisk:** Run the container in the background with persistent storage

## Persistent Storage

Docker volumes are automatically created for:

- **asterisk-config** - Configuration files (`/etc/asterisk`)
- **asterisk-sounds** - Sound files and prompts (`/var/lib/asterisk/sounds`)
- **asterisk-spool** - Voicemail and recordings (`/var/spool/asterisk`)
- **asterisk-logs** - Log files (`/var/log/asterisk`)

Your configuration and data persist across container restarts and rebuilds.

## Common Commands

### Managing the Container

```bash
# Start Asterisk (after initial build)
docker compose up -d

# Stop Asterisk
docker compose down

# Restart Asterisk
docker compose restart

# View logs
docker compose logs -f

# Rebuild and restart
docker compose up -d --build
```

### Accessing Asterisk

```bash
# Access Asterisk CLI
docker exec -it asterisk asterisk -rvvv

# Access container shell
docker exec -it asterisk bash

# Run a one-time CLI command
docker exec asterisk asterisk -rx "core show version"
```

### Configuration

```bash
# Edit configuration inside the container
docker exec -it asterisk bash
cd /etc/asterisk
vi pjsip.conf
vi extensions.conf
exit

# Restart to apply changes
docker compose restart
```

## Architecture

The Docker setup uses a multi-stage build process:

```
┌─────────────────────┐
│   Stage 1: Builder  │  <- Debian Bookworm with build tools
│   - Install deps    │     and Asterisk dependencies
│   - Configure       │
│   - Compile         │
│   - Create DEB      │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Stage 2: Runtime   │  <- Debian Bookworm Slim
│   - Copy DEB        │     with only runtime libraries
│   - Install runtime │
│   - Run Asterisk    │
└─────────────────────┘
```

## Network Configuration

The default `docker-compose.yml` uses `network_mode: host`, which:

- ✅ Gives Asterisk direct access to all host network interfaces
- ✅ Simplifies SIP/RTP configuration (no NAT issues)
- ✅ Works with most VoIP scenarios out of the box
- ⚠️ Means the container has full network access

## Exposed Ports

When using `network_mode: host`, these ports are accessible on your Raspberry Pi:

- **5060/udp, 5060/tcp** - SIP signaling
- **5061/tcp** - SIP over TLS
- **8088/tcp, 8089/tcp** - HTTP/HTTPS management interface
- **4569/udp** - IAX2 protocol
- **10000-20000/udp** - RTP media streams

## Customization

### Change Asterisk Version

Edit `docker-compose.yml`:

```yaml
services:
  asterisk:
    build:
      args:
        VERSION: "21.0.0"  # Change this
```

### Resource Limits

Uncomment the `deploy` section in `docker-compose.yml` to limit CPU/memory:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

### Timezone

Change the timezone in `docker-compose.yml`:

```yaml
environment:
  - TZ=Europe/Madrid  # Your timezone
```

## Troubleshooting

### Build Fails

```bash
# Clean up and rebuild
docker compose down
docker system prune -f
docker compose up -d --build
```

### Container Won't Start

```bash
# Check logs
docker logs asterisk

# Verify the image exists
docker images | grep asterisk
```

### Configuration Issues

```bash
# Check Asterisk is running
docker exec asterisk asterisk -rx "core show version"

# Verify modules loaded
docker exec asterisk asterisk -rx "module show"

# Check for errors
docker exec asterisk asterisk -rx "core show sysinfo"
```

### Can't Access CLI

```bash
# Make sure container is running
docker ps | grep asterisk

# Try accessing with full path
docker exec -it asterisk /usr/sbin/asterisk -rvvv
```

## Additional Resources

- **[INICIO-RAPIDO-RPI5.md](INICIO-RAPIDO-RPI5.md)** - Spanish quick start guide / Guía en español
- **[contrib/docker/README.rpi5.md](contrib/docker/README.rpi5.md)** - Comprehensive Docker documentation
- **[contrib/docker/QUICKSTART.rpi5.md](contrib/docker/QUICKSTART.rpi5.md)** - Quick reference guide
- **[Asterisk Documentation](https://docs.asterisk.org)** - Official Asterisk documentation

## Alternative: Manual Build Process

If you prefer to build step-by-step instead of using docker-compose:

```bash
# Use the automated build script
./contrib/docker/build-rpi5.sh 20.0.0

# Then run manually
docker run -d --name asterisk --network host asterisk-rpi5:20.0.0
```

Or see [contrib/docker/README.rpi5.md](contrib/docker/README.rpi5.md) for detailed manual instructions.

## Support

- [Asterisk Community Forums](https://community.asterisk.org)
- [Official Documentation](https://docs.asterisk.org)
- [GitHub Issues](https://github.com/xukrutdonut/asterisk/issues)

---

**Note:** This Docker setup is specifically optimized for Raspberry Pi 5 (ARM64/aarch64 architecture).
