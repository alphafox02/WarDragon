# Unboxing & First Boot

This guide walks you through setting up your WarDragon Pro v3 for the first time.

## What's in the Box

Your WarDragon Pro v3 kit includes:

- WarDragon Pro v3 unit
- Protective transport case
- Power supply (12V DC)
- Antenna kit:
  - Dual-band 2.4/5 GHz antennas (qty: 2-3)
  - 2.4 GHz antenna for Bluetooth
  - GPS antenna (if external GPS option included)
- Quick start card

## Initial Setup

### Step 1: Inspect the Unit

Before powering on:

1. Remove the unit from the transport case
2. Check for any shipping damage
3. Verify all antenna ports are intact
4. Ensure the case ventilation is unobstructed

### Step 2: Connect Antennas

Connect antennas to the appropriate ports. See [Antenna Connections](../hardware/antenna-connections.md) for the full port map.

**Minimum required connections:**

| Port | Antenna | Purpose |
|------|---------|---------|
| Left Side - Port 3 (RX E200) | Dual-band 2.4/5 GHz | DJI DroneID detection |
| Left Side - Port 2 (RX Panda) | Dual-band 2.4/5 GHz | WiFi Remote ID |
| Right Side - Port 1 (BT5) | 2.4 GHz | Bluetooth Remote ID |

**Optional:**
| Port | Antenna | Purpose |
|------|---------|---------|
| Right Side - Port 2 (GPS) | GPS antenna | External GPS (improves accuracy) |

### Step 3: Power Connection

1. Connect the 12V power supply to the WarDragon
2. Connect the power supply to AC mains
3. The power button LED should illuminate

**Power Requirements:**
- Input: 12V DC, 3A minimum
- Connector: 5.5mm x 2.1mm barrel jack
- Typical consumption: ~25W

### Step 4: First Boot

On first power-up:

1. The system takes approximately 60-90 seconds to fully boot
2. The power button LED indicates the system is on
3. Internal LEDs (E200, GPS) may be partially visible through the case

## Connecting to WarDragon

### Option 1: Direct Ethernet Connection

1. Connect an Ethernet cable between your computer and the WarDragon's Ethernet port
2. The WarDragon's external Ethernet port is configured for DHCP
3. Check your router/network for the assigned IP address

### Option 2: WiFi Hotspot

If configured per the [Hotspot Setup](hotspot-setup.md) guide:

1. Look for a WiFi network named `WarDragon` (or your configured SSID)
2. Connect using your configured password
3. The WarDragon will be at `192.168.12.1`

### Option 3: Monitor + Keyboard

Connect a monitor and keyboard directly to the unit for local access.

### Option 4: Remote Access (Post-Install)

For remote access, you can install:
- **RustDesk** - For remote desktop access
- **OpenSSH** - For SSH access

These are not pre-installed and require local setup first.

## Verifying System Status

Once connected (via monitor/keyboard or remote access):

```bash
# Check running services
sudo systemctl status dragonsync
```

## Next Steps

Once your WarDragon is powered on and connected:

1. [Network Configuration](network-setup.md) - Configure networking
2. [Hotspot Setup](hotspot-setup.md) - Enable/configure WiFi hotspot
3. [TAK Integration](../integration/tak-integration.md) - Connect to ATAK/TAK Server
4. [DragonSync Configuration](../software/dragonsync.md) - Fine-tune detection settings

## Troubleshooting First Boot

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| Power button not lit | Power supply issue | Check connections, try different outlet |
| Stuck in boot | Corrupted boot | Allow 5 minutes; if no progress, contact support |
| No network | Ethernet/WiFi config | Try direct Ethernet connection |
| No detections | Antenna issues | Verify antenna connections |

See [Troubleshooting](../troubleshooting/common-issues.md) for more help.
