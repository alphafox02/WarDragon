# Troubleshooting Guide

This guide covers common issues and their solutions for WarDragon Pro v3.

## Quick Diagnostics

### System Health Check

```bash
# Check all critical services
sudo systemctl status dragonsync dji-receiver

# Check system resources
htop

# Check disk space
df -h

# Check network interfaces
ip addr show
```

### Detection Health Check

```bash
# Verify ZMQ streams are active (DJI on port 4221)
timeout 10 python3 -c "
import zmq
c = zmq.Context()
s = c.socket(zmq.SUB)
s.connect('tcp://127.0.0.1:4221')
s.setsockopt_string(zmq.SUBSCRIBE, '')
s.setsockopt(zmq.RCVTIMEO, 5000)
try:
    print('DJI DroneID:', s.recv_string()[:100])
except:
    print('DJI DroneID: No data')
"

# ZMQ Port Reference:
# 4221 - DJI DroneID
# 4222 - Bluetooth Remote ID
# 4223 - WiFi Remote ID
# 4224 - Unified zmq_decoder output
```

## Power & Boot Issues

### Unit Won't Power On

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| No LEDs | Power supply issue | Check power adapter connection, try different outlet |
| Brief flash then off | Overcurrent protection | Disconnect peripherals, check for shorts |
| Power LED on, no boot | Boot failure | Wait 5 minutes; if no progress, re-flash SD/NVMe |

### Boot Takes Too Long

Normal boot time is 60-90 seconds. If longer:

1. Wait up to 5 minutes for first boot after updates
2. Check for filesystem issues: `sudo fsck -f /dev/nvme0n1p2`
3. Review boot logs: `journalctl -b`

### Random Reboots

1. Check power supply adequacy (12V, 3A minimum)
2. Monitor temperature: `sensors` or `cat /sys/class/thermal/thermal_zone*/temp`
3. Check for kernel panics: `journalctl -b -1 | tail -100`

## Network Issues

### Can't Connect to WarDragon

| Method | Diagnosis | Solution |
|--------|-----------|----------|
| Ethernet | Check link light | Try different cable/port |
| WiFi Hotspot | Scan for SSID | Verify hotspot enabled |
| WiFi Client | Check router DHCP | Verify WiFi credentials |

### Find WarDragon IP Address

If you don't know the IP:

```bash
# Check router DHCP leases for the assigned IP

# Or scan your subnet
nmap -sn <your-subnet>/24 | grep -B2 -i dragon

# If using hotspot, WarDragon is at 192.168.12.1
```

### Hotspot Not Broadcasting

```bash
# Check if hotspot is enabled
nmcli connection show --active | grep -i hotspot

# Check interface status
iw dev wlan0 info

# Restart hotspot
sudo nmcli connection down WarDragon-Hotspot
sudo nmcli connection up WarDragon-Hotspot

# Check for errors
journalctl -u NetworkManager -n 50
```

### No Internet Through WarDragon

If connected to hotspot but no internet:

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should be 1

# Enable if needed
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Check NAT rules
sudo iptables -t nat -L
```

## Remote Access Issues

### Can't SSH to WarDragon

| Symptom | Cause | Solution |
|---------|-------|----------|
| Connection refused | SSH not installed | Requires initial local setup - see [Unboxing](../getting-started/unboxing.md) |
| Connection timeout | Wrong IP or firewall | Verify IP address and network connectivity |
| Permission denied | Wrong credentials | Check username/password |

> **Note**: WarDragon ships without SSH enabled for security. You must complete the [initial local setup](../getting-started/unboxing.md#initial-local-setup-required) with a monitor and keyboard to install and configure OpenSSH.

### Remote Desktop Not Working (RustDesk)

| Symptom | Cause | Solution |
|---------|-------|----------|
| Can't connect | RustDesk not installed | Requires initial local setup |
| Black/blank screen | HDMI dummy plug missing | Reinstall the dummy plug in the right-angle HDMI adapter |
| No desktop rendered | Display not detected | Verify dummy plug is firmly seated |

> **Critical**: The HDMI dummy plug must be installed in the right-angle HDMI adapter for remote desktop to work. The plug simulates a connected display, allowing the system to render a desktop session. See [Unboxing](../getting-started/unboxing.md#step-7-restore-hdmi-dummy-plug) for details.

### First-Time Remote Access Checklist

If you cannot access WarDragon remotely, verify these were completed during initial setup:

1. ☐ OpenSSH server installed and enabled
2. ☐ RustDesk installed and configured (for remote desktop)
3. ☐ HDMI dummy plug reinstalled after initial setup
4. ☐ Network configured (static IP or DHCP)
5. ☐ Firewall allows SSH (port 22) and/or RustDesk

If any of these were not completed, you will need to reconnect a monitor and keyboard to complete the setup. See [Unboxing & First Boot](../getting-started/unboxing.md).

## Detection Issues

### No Drones Detected

#### Check Antenna Connections

1. Verify antennas are firmly connected
2. Confirm correct ports (see [Antenna Connections](../hardware/antenna-connections.md))
3. Check for SMA vs RP-SMA mismatch

#### Check Detection Services

```bash
# DJI DroneID service
sudo systemctl status dji-receiver
journalctl -u dji-receiver -n 50

# DragonSync
sudo systemctl status dragonsync
journalctl -u dragonsync -n 50
```

#### Test Detection Hardware

```bash
# List USB devices (should see ANTSDR, Panda, etc.)
lsusb

# Check for SDR
rtl_test -t 2>/dev/null || echo "No RTL-SDR found"
```

### DJI Drones Not Detected

1. **Verify ANTSDR E200 connected**:
   ```bash
   lsusb | grep -i antsdr
   ```

2. **Check dji_receiver service**:
   ```bash
   sudo systemctl status dji-receiver
   ```

3. **Verify antenna on correct port** (Port 2, left side)

4. **Check frequency coverage** - Some DJI drones use 5.8 GHz

### Remote ID Not Detected

1. **Check WiFi Remote ID service**:
   ```bash
   sudo systemctl status wifi-receiver
   journalctl -u wifi-receiver -n 50
   ```

2. **Check Bluetooth Remote ID service**:
   ```bash
   sudo systemctl status sniff-receiver
   journalctl -u sniff-receiver -n 50
   ```

3. **Verify WiFi adapter in monitor mode**:
   ```bash
   iw dev wlan1 info | grep type
   # Should show "monitor"
   ```

4. **Check Bluetooth dongle** (DragonTooth):
   ```bash
   ls /dev/sniffle*
   # Should show /dev/sniffle0
   ```

### Weak Detection Range

| Issue | Solution |
|-------|----------|
| Short range | Use higher gain antennas |
| Intermittent | Check antenna connections |
| Direction-dependent | Consider omnidirectional antenna |
| Urban environment | Elevate antenna, use directional |

## TAK Integration Issues

### Drones Not Appearing in ATAK

1. **Check multicast network**:
   ```bash
   # Verify multicast traffic
   sudo tcpdump -i any host 239.2.3.1 and port 6969
   ```

2. **Verify ATAK settings**:
   - SA Multicast enabled
   - Correct address (239.2.3.1:6969)
   - On same network as WarDragon

3. **Check DragonSync TAK output**:
   ```bash
   journalctl -u dragonsync | grep -i tak
   ```

### TAK Server Connection Failed

1. **Test connectivity**:
   ```bash
   nc -zv tak-server.example.com 8089
   ```

2. **Check TLS certificates** (if using TLS):
   ```bash
   openssl s_client -connect tak-server.example.com:8443
   ```

3. **Verify server accepts connections** (check server logs)

### ATAK Plugin Not Connecting

1. **Verify API enabled** in `/home/dragon/DragonSync/config.ini`:
   ```ini
   [SETTINGS]
   api_enabled = true
   api_host = 0.0.0.0
   api_port = 8088
   ```

2. **Test API**:
   ```bash
   curl http://localhost:8088/status
   ```

3. **Check firewall**:
   ```bash
   sudo nft list ruleset | grep 8088
   ```

## MQTT Issues

### Not Publishing to Broker

1. **Test broker connectivity**:
   ```bash
   mosquitto_pub -h <broker> -t test -m "hello"
   ```

2. **Check credentials** in config

3. **View MQTT debug**:
   ```bash
   journalctl -u dragonsync | grep -i mqtt
   ```

### Home Assistant Not Discovering

1. **Check discovery topic**:
   ```bash
   mosquitto_sub -h <broker> -t "homeassistant/#" -v
   ```

2. **Restart Home Assistant** after first discovery

3. **Verify Home Assistant discovery is enabled** in `config.ini`:
   ```ini
   mqtt_ha_enabled = true
   mqtt_ha_prefix = homeassistant
   ```

## GPS Issues

### No GPS Lock

1. **Check GPS status**:
   ```bash
   gpspipe -w -n 5
   ```

2. **If no data**, verify GPS module connection:
   ```bash
   ls /dev/ttyACM* /dev/ttyUSB*
   ```

3. **Try external antenna** (connected to GPS port, right side)

4. **Allow time** - First lock may take several minutes

### GPS Position Incorrect

1. **Check fix quality**:
   ```bash
   gpspipe -w | grep -i fix
   ```

2. **Verify antenna has sky view**

3. **Check for multipath** (reflections from buildings)

## Performance Issues

### High CPU Usage

```bash
# Identify culprit
top -o %CPU

# Common causes:
# - Debug logging enabled (switch to INFO level)
# - Too many ZMQ subscriptions
# - High detection rate
```

### High Memory Usage

```bash
# Check memory
free -h

# Identify memory hogs
ps aux --sort=-%mem | head -10
```

### System Running Hot

1. **Check temperature**:
   ```bash
   cat /sys/class/thermal/thermal_zone*/temp
   # Divide by 1000 for Celsius
   ```

2. **Ensure adequate ventilation** around base plate

3. **Reduce load** if overheating persists

## Log Analysis

### Where to Find Logs

| Log | Location | Command |
|-----|----------|---------|
| DragonSync | journald | `journalctl -u dragonsync` |
| DJI Receiver | journald | `journalctl -u dji-receiver` |
| System | journald | `journalctl -b` |
| Network | journald | `journalctl -u NetworkManager` |

### Enable Debug Logging

Temporarily enable debug for troubleshooting:

```bash
# Edit service or config to set log level DEBUG
# Then restart service
sudo systemctl restart dragonsync

# Watch debug output
journalctl -u dragonsync -f
```

## Factory Reset

If all else fails, reset to defaults:

### Reset Network Configuration

```bash
# Remove all connections
sudo nmcli connection delete $(nmcli -t -f NAME connection show)

# Recreate defaults
sudo nmcli connection add type ethernet con-name "Wired" ifname eth0
```

### Reset DragonSync Configuration

```bash
# Backup current config
cp /home/dragon/DragonSync/config.ini ~/config-backup.ini

# Download fresh config from repository
curl -o /home/dragon/DragonSync/config.ini \
  https://raw.githubusercontent.com/alphafox02/DragonSync/main/config.ini

# Or edit manually to reset specific settings
nano /home/dragon/DragonSync/config.ini

# Restart
sudo systemctl restart dragonsync
```

### Full System Reset

Contact support for full re-imaging instructions.

## Getting Help

If you can't resolve the issue:

1. **Gather diagnostic info**:
   ```bash
   # Create diagnostic bundle
   sudo journalctl -b > ~/diag-journal.txt
   ip addr > ~/diag-network.txt
   lsusb > ~/diag-usb.txt
   ```

2. **Join DragonOS Discord** for community support

3. **Contact cemaxecuter** for hardware issues

## Related Documentation

- [Hardware Overview](../hardware/pro-v3-overview.md)
- [Network Setup](../getting-started/network-setup.md)
- [DragonSync Configuration](../software/dragonsync.md)
