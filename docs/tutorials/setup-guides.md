# Setup Guides

Quick reference guides for common WarDragon setup tasks.

## Quick Setup Checklist

### First Boot

- [ ] Connect antennas to correct ports
- [ ] Connect power supply
- [ ] Wait for boot (~90 seconds)
- [ ] Connect via Ethernet or WiFi
- [ ] Verify network connectivity (ping, etc.)
- [ ] Check detection services running

### Field Deployment

- [ ] Charge/verify power source
- [ ] Pack transport case with unit
- [ ] Verify all antennas included
- [ ] Configure hotspot if needed
- [ ] Test ATAK connectivity
- [ ] Verify GPS lock capability

## Common Configurations

### Standalone Operation (Hotspot Mode)

For field use without existing network infrastructure:

1. Enable WiFi hotspot (see [Hotspot Setup](../getting-started/hotspot-setup.md))
2. Connect ATAK devices to WarDragon WiFi
3. Configure ATAK for multicast (239.2.3.1:6969)
4. Verify detections appear in ATAK

**Diagram:**
```
              ┌─────────────┐
              │  WarDragon  │
              │  (Hotspot)  │
              └──────┬──────┘
                     │ WiFi
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
   │  ATAK   │  │  ATAK   │  │  iTAK   │
   │ Device 1│  │ Device 2│  │ Device 3│
   └─────────┘  └─────────┘  └─────────┘
```

### Network Connected (Client Mode)

For integration with existing infrastructure:

1. Connect WarDragon to network (Ethernet or WiFi client)
2. Configure DragonSync for TAK Server
3. Optionally enable MQTT for Home Assistant
4. Configure analytics dashboard

**Diagram:**
```
   ┌─────────────┐     ┌─────────────┐
   │  WarDragon  │────►│ TAK Server  │
   └──────┬──────┘     └──────┬──────┘
          │                   │
          │            ┌──────▼──────┐
          │            │ ATAK Devices│
          │            └─────────────┘
          │
   ┌──────▼──────┐
   │ MQTT Broker │
   └──────┬──────┘
          │
   ┌──────▼──────┐
   │Home Assistant│
   └─────────────┘
```

### Hybrid Mode

Maximum flexibility for diverse teams:

1. Enable hotspot for local devices
2. Connect Ethernet to network
3. Route traffic between interfaces
4. Field devices use hotspot
5. Server access via Ethernet

## Detection Services

All Remote ID protocols (WiFi, Bluetooth, UART/ESP32) are handled by a single unified service — `zmq-decoder` (droneid-go). DJI DroneID runs separately via `dji-receiver`.

### Service Overview

| Service | Role | ZMQ Output |
|---------|------|-----------|
| `zmq-decoder` | WiFi RID + BLE + UART/ESP32 (droneid-go) | 4224 |
| `dji-receiver` | DJI DroneID via AntSDR E200 | 4221 → 4224 |
| `dragonsync` | Aggregates 4224/4225, outputs TAK/MQTT | — |

### Check All Detection Services

```bash
sudo systemctl status zmq-decoder dji-receiver dragonsync
```

### Restart Detection

```bash
sudo systemctl restart zmq-decoder
sudo systemctl restart dji-receiver
```

### Disable DJI Detection (if no AntSDR)

```bash
sudo systemctl disable dji-receiver
sudo systemctl stop dji-receiver
```

Verify ANTSDR E200 antenna connected to Left Side - Port 3 (RX E200).

## Output Configuration

Edit `/home/dragon/DragonSync/config.ini` to configure outputs.

### TAK Only (Default)

Simplest configuration for TAK users:

```ini
[SETTINGS]
# Multicast enabled by default
enable_multicast = true
tak_multicast_addr = 239.2.3.1
tak_multicast_port = 6969

# Disable other outputs
mqtt_enabled = false
lattice_enabled = false
api_enabled = true
```

### MQTT Only (Home Assistant)

For smart home integration:

```ini
[SETTINGS]
# Disable TAK multicast
enable_multicast = false

# Enable MQTT with Home Assistant discovery
mqtt_enabled = true
mqtt_host = 192.168.1.100
mqtt_port = 1883
mqtt_ha_enabled = true

# Keep API for monitoring
api_enabled = true
```

### Full Integration

All outputs enabled:

```ini
[SETTINGS]
enable_multicast = true
mqtt_enabled = true
lattice_enabled = true
api_enabled = true
```

## Antenna Placement Guide

### Mobile/Vehicle Mount

```
              ▲ Roof-mounted antennas
              │ (best LoS to sky)
    ┌─────────┼─────────┐
    │    WarDragon      │
    │    (inside)       │
    └───────────────────┘
```

- Mount antennas on vehicle roof
- Use weatherproof antenna bases
- Run low-loss coax inside
- Consider magnetic mounts for temporary use

### Fixed Installation

```
    ┌─────────────────────────────┐
    │     Building/Structure      │
    │                             │
    │  Antennas ─►  ▲  ▲  ▲      │ Roof level
    │               │  │  │       │
    │               │  │  │       │
    │         WarDragon           │ Inside
    └─────────────────────────────┘
```

- Mount antennas as high as practical
- Clear line of sight to sky
- Weatherproof all connections
- Consider lightning protection

### Portable/Backpack

```
       ▲ Antenna on pole/mast
       │
    ┌──┴──┐
    │Pack │ WarDragon in backpack
    │     │ Short antenna runs
    └─────┘
```

- Use compact, foldable antennas
- Short coax runs minimize loss
- Consider directional antennas for range

## Service Management

### Check All Services

```bash
sudo systemctl status zmq-decoder dji-receiver dragonsync
```

### Restart Services

```bash
sudo systemctl restart zmq-decoder
sudo systemctl restart dji-receiver
sudo systemctl restart dragonsync
```

### View Logs

```bash
# All drone detection (WiFi + BLE + UART)
journalctl -u zmq-decoder -f

# DJI DroneID
journalctl -u dji-receiver -f

# DragonSync
journalctl -u dragonsync -f
```

### Enable/Disable Autostart

```bash
# Enable service at boot
sudo systemctl enable dragonsync

# Disable service at boot
sudo systemctl disable dragonsync
```

## Backup Configuration

### Export Settings

```bash
# Backup DragonSync config
cp /home/dragon/DragonSync/config.ini ~/config-backup.ini

# Backup network settings
sudo nmcli connection export "WarDragon-Hotspot" > ~/hotspot-backup.nmconnection
```

### Restore Settings

```bash
# Restore DragonSync config
cp ~/config-backup.ini /home/dragon/DragonSync/config.ini
sudo systemctl restart dragonsync

# Restore network settings
sudo nmcli connection import type wifi file ~/hotspot-backup.nmconnection
```

## Related Documentation

- [Video Tutorials](video-index.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
- [DragonSync Configuration](../software/dragonsync.md)
