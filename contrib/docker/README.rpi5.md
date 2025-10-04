# Building Asterisk for Raspberry Pi 5 (ARM64) in Docker

This guide will help you build and deploy Asterisk on a Raspberry Pi 5 using Docker containers. The Raspberry Pi 5 uses ARM64 (aarch64) architecture, so we use Debian-based images and DEB packages instead of the CentOS/RPM approach used for x86_64 systems.

## Prerequisites

- Raspberry Pi 5 with Raspberry Pi OS (64-bit) or any ARM64-compatible Linux distribution
- Docker installed on your Raspberry Pi 5 or build machine
- At least 4GB of RAM recommended for building
- Sufficient storage space (at least 10GB free)

## Quick Start

### Option 1: Build on Raspberry Pi 5

If you're building directly on your Raspberry Pi 5:

```bash
# 1. Clone the Asterisk repository
git clone https://github.com/xukrutdonut/asterisk.git
cd asterisk

# 2. Build the packager container image
docker build --pull -f contrib/docker/Dockerfile.packager.rpi5 -t asterisk-build-rpi5 .

# 3. Build the Asterisk DEB package
docker run -ti \
    -v $(pwd):/application:ro \
    -v $(pwd)/out:/build \
    -w /application asterisk-build-rpi5 \
    /application/contrib/docker/make-package-deb.sh 20.0.0

# 4. Build the runtime container image
docker build --rm -t asterisk-rpi5:20.0.0 -f contrib/docker/Dockerfile.rpi5 .

# 5. Run Asterisk
docker run -d \
    --name asterisk \
    --network host \
    -v asterisk-config:/etc/asterisk \
    -v asterisk-sounds:/var/lib/asterisk/sounds \
    -v asterisk-spool:/var/spool/asterisk \
    asterisk-rpi5:20.0.0
```

### Option 2: Cross-build using Docker Buildx (from x86_64 machine)

If you want to build ARM64 images from an x86_64 machine:

```bash
# 1. Set up Docker buildx for multi-architecture builds
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# 2. Build the packager container for ARM64
docker buildx build --platform linux/arm64 \
    -f contrib/docker/Dockerfile.packager.rpi5 \
    -t asterisk-build-rpi5 \
    --load .

# 3. Build the package (using QEMU emulation)
docker run -ti --platform linux/arm64 \
    -v $(pwd):/application:ro \
    -v $(pwd)/out:/build \
    -w /application asterisk-build-rpi5 \
    /application/contrib/docker/make-package-deb.sh 20.0.0

# 4. Build the runtime container
docker buildx build --platform linux/arm64 \
    --rm -t asterisk-rpi5:20.0.0 \
    -f contrib/docker/Dockerfile.rpi5 \
    --load .
```

## Configuration

After starting the container, you'll need to configure Asterisk:

```bash
# Access Asterisk CLI
docker exec -it asterisk asterisk -rvvv

# Or edit configuration files in the mounted volume
docker exec -it asterisk bash
cd /etc/asterisk
# Edit your configuration files here
```

### Important Configuration Files

- `/etc/asterisk/asterisk.conf` - Main Asterisk configuration
- `/etc/asterisk/sip.conf` - SIP channel configuration
- `/etc/asterisk/pjsip.conf` - PJSIP channel configuration (recommended)
- `/etc/asterisk/extensions.conf` - Dialplan configuration
- `/etc/asterisk/voicemail.conf` - Voicemail configuration

## Persistent Storage

The example commands use Docker volumes for persistent storage:

- `asterisk-config` - Configuration files
- `asterisk-sounds` - Sound files (prompts, music on hold)
- `asterisk-spool` - Voicemail and call recordings

You can also use bind mounts for easier access:

```bash
docker run -d \
    --name asterisk \
    --network host \
    -v /path/to/your/config:/etc/asterisk \
    -v /path/to/your/sounds:/var/lib/asterisk/sounds \
    -v /path/to/your/spool:/var/spool/asterisk \
    asterisk-rpi5:20.0.0
```

## Network Considerations

### Using Host Network Mode (Recommended)

For simplest network configuration, use `--network host`:

```bash
docker run -d --name asterisk --network host asterisk-rpi5:20.0.0
```

This gives Asterisk direct access to the host's network interfaces, which simplifies SIP and RTP configuration.

### Using Bridge Network Mode

If you prefer bridge networking, you'll need to expose the necessary ports:

```bash
docker run -d \
    --name asterisk \
    -p 5060:5060/udp \
    -p 5060:5060/tcp \
    -p 5061:5061/tcp \
    -p 8088:8088/tcp \
    -p 8089:8089/tcp \
    -p 4569:4569/udp \
    -p 10000-20000:10000-20000/udp \
    asterisk-rpi5:20.0.0
```

**Note:** You'll need to configure Asterisk to use the correct external IP address and port ranges when using bridge mode.

## Performance Optimization for Raspberry Pi 5

### CPU Governor

For better performance, set the CPU governor to "performance":

```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Memory Considerations

The Raspberry Pi 5 has 4GB or 8GB of RAM. For production use:

- 4GB: Suitable for small deployments (< 10 concurrent calls)
- 8GB: Recommended for medium deployments (10-50 concurrent calls)

### Docker Resource Limits

You can limit Docker resources if needed:

```bash
docker run -d \
    --name asterisk \
    --network host \
    --memory="2g" \
    --cpus="2" \
    asterisk-rpi5:20.0.0
```

## Troubleshooting

### Check Asterisk Logs

```bash
docker logs asterisk
```

### Access Asterisk Console

```bash
docker exec -it asterisk asterisk -rvvv
```

### Verify Architecture

```bash
docker run --rm asterisk-rpi5:20.0.0 uname -m
# Should output: aarch64
```

### Build Issues

If you encounter build issues:

1. Ensure you have enough free space (10GB+)
2. Check that your Docker daemon has enough memory allocated
3. For cross-compilation, ensure QEMU is properly installed:
   ```bash
   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
   ```

### Common Errors

**Error: "exec format error"**
- You're trying to run an ARM64 container on a non-ARM64 system without QEMU
- Install QEMU: `apt-get install qemu-user-static`

**Error: "Cannot allocate memory"**
- Increase Docker memory limit
- Close other applications during build

## Docker Compose Example

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  asterisk:
    image: asterisk-rpi5:20.0.0
    container_name: asterisk
    network_mode: host
    restart: unless-stopped
    volumes:
      - asterisk-config:/etc/asterisk
      - asterisk-sounds:/var/lib/asterisk/sounds
      - asterisk-spool:/var/spool/asterisk
      - asterisk-logs:/var/log/asterisk
    environment:
      - TZ=America/New_York
    # Optional: limit resources
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

volumes:
  asterisk-config:
  asterisk-sounds:
  asterisk-spool:
  asterisk-logs:
```

Run with:
```bash
docker-compose up -d
```

## Advanced Configuration

### Custom Build Options

Edit `make-package-deb.sh` to customize the build. Common options:

```bash
# In the ./configure line, add:
./configure \
    --with-pjproject-bundled \
    --disable-xmldoc \
    --without-h323 \
    --without-kde \
    --without-misdn \
    --without-nbs \
    --without-netsnmp \
    --without-pwlib
```

### Installing Additional Modules

After building, you can install additional codecs or modules:

```bash
docker exec -it asterisk bash
cd /usr/src
# Download and compile additional modules
```

## References

- [Asterisk Official Documentation](https://docs.asterisk.org)
- [Docker Documentation](https://docs.docker.com)
- [Raspberry Pi 5 Specifications](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [FPM Package Tool](https://github.com/jordansissel/fpm)

## License

Asterisk is licensed under GPLv2. See the LICENSE file in the repository root.

## Support

For issues specific to this Docker implementation:
- Open an issue on GitHub
- Check existing issues and documentation

For general Asterisk support:
- Visit https://www.asterisk.org
- Join the Asterisk community forums
