# Example Asterisk Configuration Files for Raspberry Pi 5

These example configuration files provide a starting point for configuring Asterisk on your Raspberry Pi 5.

## Files

- `pjsip.conf.rpi5` - Example PJSIP (SIP) configuration with two sample extensions
- `extensions.conf.rpi5` - Example dialplan with basic internal calling features

## How to Use

### Method 1: Copy to Running Container

```bash
# Copy PJSIP configuration
docker cp examples/pjsip.conf.rpi5 asterisk:/etc/asterisk/pjsip.conf

# Copy dialplan
docker cp examples/extensions.conf.rpi5 asterisk:/etc/asterisk/extensions.conf

# Reload configuration
docker exec asterisk asterisk -rx "core reload"
```

### Method 2: Copy to Volume Before Starting

```bash
# Create a local config directory
mkdir -p ~/asterisk-config

# Copy example configs
cp examples/pjsip.conf.rpi5 ~/asterisk-config/pjsip.conf
cp examples/extensions.conf.rpi5 ~/asterisk-config/extensions.conf

# Edit the configs as needed
nano ~/asterisk-config/pjsip.conf
nano ~/asterisk-config/extensions.conf

# Run container with your configs
docker run -d \
    --name asterisk \
    --network host \
    -v ~/asterisk-config:/etc/asterisk \
    asterisk-rpi5:20.0.0
```

### Method 3: Use in Docker Compose

Update your `docker-compose.rpi5.yml`:

```yaml
services:
  asterisk:
    image: asterisk-rpi5:20.0.0
    volumes:
      - ./examples:/etc/asterisk/examples:ro
      - asterisk-config:/etc/asterisk
```

Then copy files inside the container:
```bash
docker exec asterisk cp /etc/asterisk/examples/pjsip.conf.rpi5 /etc/asterisk/pjsip.conf
docker exec asterisk cp /etc/asterisk/examples/extensions.conf.rpi5 /etc/asterisk/extensions.conf
docker restart asterisk
```

## Configuration Details

### pjsip.conf.rpi5

This file configures:
- Two example extensions (1000 and 1001)
- UDP and TCP transports on port 5060
- Optimized for Raspberry Pi 5 with NAT traversal support
- Common codecs: ulaw, alaw, gsm, g722

**Important:** Change the default passwords before use!

### extensions.conf.rpi5

This file provides:
- Internal extension dialing (10XX)
- Voicemail access (*97)
- Echo test (*43)
- Speaking clock (*60)
- Music on hold test (*70)
- Basic external call handling

## Next Steps

1. **Customize the configurations:**
   - Change extension passwords in `pjsip.conf`
   - Add more extensions as needed
   - Modify dialplan to match your needs
   - Update external IP addresses if behind NAT

2. **Add more configuration files:**
   - `voicemail.conf` - Voicemail configuration
   - `modules.conf` - Module loading configuration
   - `logger.conf` - Logging configuration
   - `http.conf` - Web interface configuration

3. **Test your configuration:**
   ```bash
   # Check PJSIP endpoints
   docker exec asterisk asterisk -rx "pjsip show endpoints"
   
   # Check dialplan
   docker exec asterisk asterisk -rx "dialplan show from-internal"
   
   # Test extension registration with a SIP client
   ```

## Security Notes

- **Always change default passwords!**
- Use strong passwords for SIP accounts
- Consider using TLS for SIP signaling
- Restrict access to Asterisk ports in your firewall
- Keep your Asterisk container updated
- Use fail2ban or similar for intrusion prevention

## Troubleshooting

If Asterisk doesn't start after applying configs:

```bash
# Check for configuration errors
docker exec asterisk asterisk -rx "core show config errors"

# Check PJSIP configuration
docker exec asterisk asterisk -rx "pjsip show endpoints"

# View logs
docker logs asterisk

# Test configuration without starting
docker exec asterisk asterisk -rx "pjsip show endpoints"
```

## Additional Resources

- [Asterisk Documentation](https://docs.asterisk.org)
- [PJSIP Configuration](https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip)
- [Dialplan Basics](https://wiki.asterisk.org/wiki/display/AST/Dialplan)
