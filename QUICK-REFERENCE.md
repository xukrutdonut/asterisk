# Asterisk Docker Quick Reference Card

## Installation

```bash
git clone https://github.com/xukrutdonut/asterisk.git
cd asterisk
docker compose up -d --build
```

## Essential Commands

### Container Management
```bash
docker compose up -d              # Start container
docker compose down               # Stop and remove container
docker compose restart            # Restart container
docker compose up -d --build      # Rebuild and start
```

### Accessing Asterisk
```bash
docker exec -it asterisk asterisk -rvvv        # Access CLI
docker exec asterisk asterisk -rx "COMMAND"    # Run single command
docker exec -it asterisk bash                   # Shell access
```

### Logs
```bash
docker compose logs -f            # Follow all logs
docker logs asterisk              # Container logs
docker logs -f asterisk           # Follow container logs
```

## Common CLI Commands

Once in the Asterisk CLI (`docker exec -it asterisk asterisk -rvvv`):

```
core show version                 # Show Asterisk version
core show channels                # Show active channels
core show uptime                  # Show uptime
module show                       # List loaded modules
pjsip show endpoints              # Show SIP endpoints
dialplan show                     # Show dialplan
core reload                       # Reload configuration
core restart now                  # Restart Asterisk
exit                             # Exit CLI
```

## Configuration

### Edit Configuration Files
```bash
# Method 1: Inside container
docker exec -it asterisk bash
cd /etc/asterisk
vi pjsip.conf
vi extensions.conf
exit
docker compose restart

# Method 2: Using docker exec
docker exec asterisk vi /etc/asterisk/pjsip.conf
docker compose restart
```

### Configuration Locations
- Config: `/etc/asterisk`
- Sounds: `/var/lib/asterisk/sounds`
- Spool: `/var/spool/asterisk`
- Logs: `/var/log/asterisk`

## Volumes

```bash
docker volume ls | grep asterisk              # List volumes
docker volume inspect asterisk_asterisk-config  # Inspect volume
```

### Backup Volumes
```bash
docker run --rm -v asterisk_asterisk-config:/data -v $(pwd):/backup \
  debian:bookworm-slim tar czf /backup/config-backup.tar.gz /data
```

### Restore Volumes
```bash
docker run --rm -v asterisk_asterisk-config:/data -v $(pwd):/backup \
  debian:bookworm-slim tar xzf /backup/config-backup.tar.gz -C /
```

## Troubleshooting

### Container Won't Start
```bash
docker logs asterisk                # Check logs
docker compose config               # Validate compose file
docker compose down                 # Stop everything
docker compose up -d --build        # Rebuild
```

### Reset Everything
```bash
docker compose down -v              # Stop and remove volumes
docker system prune -f              # Clean up
docker compose up -d --build        # Fresh start
```

### Check Status
```bash
docker ps | grep asterisk                           # Running?
docker exec asterisk asterisk -rx "core show version"  # Responsive?
./verify-docker.sh                                  # Full check
```

## Network Ports

Using `network_mode: host` (default):
- **5060/udp, 5060/tcp** - SIP
- **5061/tcp** - SIP TLS
- **8088/tcp, 8089/tcp** - HTTP/HTTPS
- **4569/udp** - IAX2
- **10000-20000/udp** - RTP

## Customization

### Change Version
Edit `docker-compose.yml`:
```yaml
    build:
      args:
        VERSION: "21.0.0"
```

### Change Timezone
Edit `docker-compose.yml`:
```yaml
    environment:
      - TZ=Europe/Madrid
```

### Resource Limits
Edit `docker-compose.yml`, uncomment:
```yaml
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

## File Structure

```
asterisk/
├── Dockerfile              # Multi-stage build
├── docker-compose.yml      # Deployment config
├── .dockerignore          # Build optimization
├── verify-docker.sh       # Setup verification
├── DOCKER.md              # Full documentation (EN)
├── INICIO-RAPIDO-RPI5.md # Quick start (ES)
└── contrib/docker/        # Additional Docker files
```

## Quick Diagnostics

```bash
# Is Docker running?
docker ps

# Is container running?
docker ps | grep asterisk

# What's the container doing?
docker logs --tail 50 asterisk

# Can we connect to Asterisk?
docker exec asterisk asterisk -rx "core show version"

# What's using resources?
docker stats asterisk

# What files are in config?
docker exec asterisk ls -la /etc/asterisk
```

## Getting Help

1. **Verify setup**: `./verify-docker.sh`
2. **Check logs**: `docker compose logs -f`
3. **Full guide**: `DOCKER.md` (EN) or `INICIO-RAPIDO-RPI5.md` (ES)
4. **Community**: https://community.asterisk.org
5. **Docs**: https://docs.asterisk.org

## One-Liners

```bash
# Rebuild everything
docker compose down && docker compose up -d --build

# Show Asterisk version
docker exec asterisk asterisk -V

# Reload config
docker exec asterisk asterisk -rx "core reload"

# Show active calls
docker exec asterisk asterisk -rx "core show channels"

# Backup config
docker cp asterisk:/etc/asterisk ./asterisk-config-backup

# Stream logs with grep
docker logs -f asterisk 2>&1 | grep ERROR
```

---

**Tip**: Bookmark this file for quick access to common commands!
