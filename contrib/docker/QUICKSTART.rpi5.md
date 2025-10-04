# Raspberry Pi 5 Quick Start Guide

This is a quick reference for building and running Asterisk on Raspberry Pi 5.

## Prerequisites

```bash
# Install Docker on Raspberry Pi OS
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Build and Run (Fastest Method)

```bash
# 1. Clone the repository
git clone https://github.com/xukrutdonut/asterisk.git
cd asterisk

# 2. Run the automated build script
./contrib/docker/build-rpi5.sh 20.0.0

# 3. Run Asterisk
docker run -d --name asterisk --network host asterisk-rpi5:20.0.0

# 4. Access Asterisk CLI
docker exec -it asterisk asterisk -rvvv
```

## Using Docker Compose

```bash
# 1. After building (step 2 above), deploy with docker-compose
docker-compose -f contrib/docker/docker-compose.rpi5.yml up -d

# 2. View logs
docker-compose -f contrib/docker/docker-compose.rpi5.yml logs -f

# 3. Access CLI
docker exec -it asterisk asterisk -rvvv

# 4. Stop
docker-compose -f contrib/docker/docker-compose.rpi5.yml down
```

## Basic Commands

```bash
# Start Asterisk
docker start asterisk

# Stop Asterisk
docker stop asterisk

# Restart Asterisk
docker restart asterisk

# View logs
docker logs asterisk

# Access Asterisk CLI
docker exec -it asterisk asterisk -rvvv

# Access container shell
docker exec -it asterisk bash

# Remove container
docker stop asterisk && docker rm asterisk
```

## Initial Configuration

After first run, configure Asterisk:

```bash
# Access the container
docker exec -it asterisk bash

# Navigate to config directory
cd /etc/asterisk

# Edit main configuration
vi asterisk.conf

# Edit SIP/PJSIP configuration
vi pjsip.conf

# Edit dialplan
vi extensions.conf

# Exit and restart Asterisk
exit
docker restart asterisk
```

## Verifying Installation

```bash
# Check Asterisk version
docker exec asterisk asterisk -V

# Check running status
docker ps | grep asterisk

# Test CLI access
docker exec asterisk asterisk -rx "core show version"

# Check loaded modules
docker exec asterisk asterisk -rx "module show"
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs asterisk

# Try running in foreground
docker run --rm -it --network host asterisk-rpi5:20.0.0
```

### Cannot connect to Asterisk CLI
```bash
# Check if Asterisk is running
docker exec asterisk ps aux | grep asterisk

# Try restarting
docker restart asterisk
```

### Performance issues
```bash
# Set CPU to performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check CPU temperature
vcgencmd measure_temp

# Monitor resources
docker stats asterisk
```

## Default Ports

- **SIP:** 5060 (UDP/TCP)
- **SIP TLS:** 5061 (TCP)
- **RTP:** 10000-20000 (UDP)
- **HTTP:** 8088 (TCP)
- **HTTPS:** 8089 (TCP)
- **IAX2:** 4569 (UDP)

## Important Directories

- **Config:** `/etc/asterisk`
- **Sounds:** `/var/lib/asterisk/sounds`
- **Voicemail:** `/var/spool/asterisk/voicemail`
- **Logs:** `/var/log/asterisk`
- **Database:** `/var/lib/asterisk/astdb.sqlite3`

## Next Steps

1. Configure your SIP endpoints in `pjsip.conf`
2. Set up your dialplan in `extensions.conf`
3. Configure voicemail in `voicemail.conf`
4. Set up logging in `logger.conf`
5. Review security settings in `asterisk.conf`

For detailed information, see [README.rpi5.md](README.rpi5.md)
