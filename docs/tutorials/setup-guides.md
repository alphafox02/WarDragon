# Setup Guides

Quick reference guides for common WarDragon setup tasks.

## Quick Setup Checklist

### First Boot

- [ ] Connect antennas to correct ports
- [ ] Connect power supply
- [ ] Wait for boot (~90 seconds)
- [ ] Connect via Ethernet or WiFi
- [ ] Verify web interface accessible
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

## Protocol-Specific Setup

### DJI DroneID Only

If focusing only on DJI detection:

```yaml
# In DragonSync config
inputs:
  dji_droneid:
    enabled: true
  droneid_wifi:
    enabled: false
  droneid_bt:
    enabled: false
```

Verify ANTSDR E200 antenna connected to port 2 (left side).

### Remote ID Only

For compliance monitoring (non-DJI):

```yaml
inputs:
  dji_droneid:
    enabled: false
  droneid_wifi:
    enabled: true
  droneid_bt:
    enabled: true
```

### All Protocols

Default configuration - all detection enabled:

```yaml
inputs:
  dji_droneid:
    enabled: true
  droneid_wifi:
    enabled: true
  droneid_bt:
    enabled: true
```

## Output Configuration

### TAK Only

Simplest configuration for TAK users:

```yaml
outputs:
  tak:
    enabled: true
    mode: multicast
  mqtt:
    enabled: false
  lattice:
    enabled: false
  api:
    enabled: false
```

### MQTT Only (Home Assistant)

For smart home integration:

```yaml
outputs:
  tak:
    enabled: false
  mqtt:
    enabled: true
    homeassistant_discovery: true
  lattice:
    enabled: false
  api:
    enabled: false
```

### Full Integration

All outputs enabled:

```yaml
outputs:
  tak:
    enabled: true
  mqtt:
    enabled: true
  lattice:
    enabled: true
  api:
    enabled: true
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
sudo systemctl status dragonsync
sudo systemctl status dji-receiver
```

### Restart Services

```bash
sudo systemctl restart dragonsync
```

### View Logs

```bash
# DragonSync logs
journalctl -u dragonsync -f

# System logs
journalctl -f

# Detection-specific
journalctl -u dji-receiver -f
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
cp /home/dragon/DragonSync/config.yaml ~/config-backup.yaml

# Backup network settings
sudo nmcli connection export "WarDragon-Hotspot" > ~/hotspot-backup.nmconnection
```

### Restore Settings

```bash
# Restore DragonSync config
cp ~/config-backup.yaml /home/dragon/DragonSync/config.yaml
sudo systemctl restart dragonsync

# Restore network settings
sudo nmcli connection import type wifi file ~/hotspot-backup.nmconnection
```

## Related Documentation

- [Video Tutorials](video-index.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
- [DragonSync Configuration](../software/dragonsync.md)
