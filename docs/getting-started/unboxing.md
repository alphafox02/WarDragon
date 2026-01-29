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
| Left Side - Port 2 (RX E200) | Dual-band 2.4/5 GHz | DJI DroneID detection |
| Left Side - Port 3 (RX Panda) | Dual-band 2.4/5 GHz | WiFi Remote ID |
| Right Side - Port 2 (BT5) | 2.4 GHz | Bluetooth Remote ID |

**Optional:**
| Port | Antenna | Purpose |
|------|---------|---------|
| Right Side - Port 1 (GPS) | GPS antenna | External GPS (improves accuracy) |

### Step 3: Power Connection

1. Connect the 12V power supply to the WarDragon
2. Connect the power supply to AC mains
3. The power LED should illuminate

**Power Requirements:**
- Input: 12V DC, 3A minimum
- Connector: 5.5mm x 2.1mm barrel jack
- Typical consumption: ~25W

### Step 4: First Boot

On first power-up:

1. The system takes approximately 60-90 seconds to fully boot
2. LED indicators will show boot progress
3. Once booted, the activity LED will begin blinking

**LED Status During Boot:**

| Phase | LED Behavior |
|-------|--------------|
| Power on | Power LED solid green |
| Booting | Activity LED solid |
| Ready | Activity LED slow blink |
| Detecting | Activity LED rapid blink |

## Connecting to WarDragon

### Option 1: Direct Ethernet Connection

1. Connect an Ethernet cable between your computer and the WarDragon
2. Configure your computer's Ethernet for DHCP or set a static IP in the 192.168.1.x range
3. The WarDragon default IP is typically `192.168.1.10` (verify in your configuration)

### Option 2: WiFi Hotspot

If configured, WarDragon can broadcast its own WiFi network:

1. Look for a WiFi network named `WarDragon-XXXX` (where XXXX is unique to your unit)
2. Connect using the default password (provided with your unit)
3. Access the web interface at `192.168.50.1`

See [Hotspot Setup](hotspot-setup.md) for configuration details.

### Option 3: Join Existing Network

If WarDragon is configured to join your WiFi network:

1. Check your router's DHCP leases for a device named `wardragon`
2. Use that IP address to connect

## Accessing the Web Interface

Once connected, open a web browser and navigate to the WarDragon's IP address:

```
http://<wardragon-ip>
```

You'll see the DragonOS web interface with:

- System status
- Detection feeds
- Configuration options
- Log viewers

## Verifying Detection

To verify all detection systems are working:

### 1. Check Service Status

SSH into the WarDragon or use the web terminal:

```bash
ssh dragon@<wardragon-ip>
# Default password provided with your unit
```

Check running services:

```bash
sudo systemctl status dragonsync
sudo systemctl status dji-receiver
```

### 2. Monitor ZMQ Streams

View live detection data:

```bash
# Watch DJI DroneID detections
zmq_monitor tcp://127.0.0.1:5556

# Watch WiFi/BT Remote ID
zmq_monitor tcp://127.0.0.1:5557
```

### 3. Check Antenna Connections

If no detections appear:

1. Verify antennas are firmly connected
2. Check that antennas are on correct ports
3. Ensure antenna types match (SMA vs RP-SMA)

## Next Steps

Once your WarDragon is powered on and connected:

1. [Network Configuration](network-setup.md) - Configure networking
2. [Hotspot Setup](hotspot-setup.md) - Enable/configure WiFi hotspot
3. [TAK Integration](../integration/tak-integration.md) - Connect to ATAK/TAK Server
4. [DragonSync Configuration](../software/dragonsync.md) - Fine-tune detection settings

## Troubleshooting First Boot

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| No power LED | Power supply issue | Check connections, try different outlet |
| Stuck in boot | Corrupted boot | Allow 5 minutes; if no progress, contact support |
| No network | Ethernet/WiFi config | Try direct Ethernet connection |
| No detections | Antenna issues | Verify antenna connections and types |

See [Troubleshooting](../troubleshooting/common-issues.md) for more help.
