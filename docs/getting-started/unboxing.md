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
- USB-C to dual USB-A adapter cable (for keyboard/mouse)
- HDMI dummy plug (pre-installed in right-angle HDMI adapter)
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
| Left Side - Port 1 (ESP32) | Dual-band 2.4/5 GHz | WiFi Remote ID (secondary)* |
| Right Side - Port 1 (BT5) | 2.4 GHz | Bluetooth Remote ID |

*ESP32 port may be removed in future versions

**Optional:**
| Port | Antenna | Purpose |
|------|---------|---------|
| Right Side - Port 2 (GPS) | GPS antenna | External GPS (improves accuracy) |
| Left Side - Port 4 (TX) | N/A | Unused (ANTSDR TX port) |

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

## Initial Local Setup (Required)

> **Important**: WarDragon ships without remote access enabled for security. You must complete this initial local setup before you can access the unit remotely via SSH or remote desktop.

### Step 5: Connect Monitor and Keyboard

**HDMI Connection:**

1. Locate the **right-angle HDMI adapter** on the right side of the PC (when looking down at the unit)
2. Remove the **HDMI dummy plug** that is pre-installed in the adapter
3. Connect an HDMI cable from the adapter to your monitor
4. **Keep the dummy plug safe** - you will need to reinstall it after setup

**USB Connection (Keyboard/Mouse):**

1. Locate the **USB-C port** on the right side of the case exterior (under a protective cap)
2. Remove the cap and insert the included **USB-C to dual USB-A adapter cable**
3. Connect a USB keyboard and mouse to the adapter

### Step 6: Initial Login and Configuration

Once the system boots and you see the desktop:

1. **Log in** with the default credentials (provided separately)
2. **Change the default password** for security
3. **Configure network settings** as needed:
   - Set a static IP on "Wired connection 2" if desired (see [Network Setup](network-setup.md))
   - Configure WiFi hotspot if needed (see [Hotspot Setup](hotspot-setup.md))
4. **Install remote access software** for headless operation:
   - **RustDesk** - For remote desktop access
   - **OpenSSH** - For SSH command-line access

   ```bash
   # Install OpenSSH server
   sudo apt update && sudo apt install openssh-server
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

5. **Test remote connectivity** before disconnecting the monitor

### Step 7: Restore HDMI Dummy Plug

> **Critical**: The HDMI dummy plug must be reinstalled for remote desktop to work properly.

After verifying remote access works:

1. Disconnect the HDMI cable from the right-angle adapter
2. **Reinstall the HDMI dummy plug** into the adapter
3. Disconnect the USB-C adapter cable and replace the protective cap
4. The unit is now configured for headless operation

**Why the dummy plug?** The dummy plug simulates a connected display, which is required for remote desktop software (like RustDesk) to render a desktop session. Without it, remote desktop connections will fail or show a blank screen.

## Connecting to WarDragon (After Initial Setup)

Once you have completed the initial local setup above, you can connect remotely:

### Option 1: SSH (Command Line)

```bash
ssh dragon@<wardragon-ip>
```

### Option 2: Remote Desktop (RustDesk)

1. Open RustDesk on your computer
2. Enter the WarDragon's RustDesk ID
3. Connect using your configured password

### Option 3: Direct Ethernet (Network Access)

1. Connect an Ethernet cable between your computer and the WarDragon's Ethernet port
2. The external Ethernet port ("Wired connection 2") is configured for DHCP by default
3. Check your router/network for the assigned IP address

### Option 4: WiFi Hotspot

If configured per the [Hotspot Setup](hotspot-setup.md) guide:

1. Look for a WiFi network named `WarDragon` (or your configured SSID)
2. Connect using your configured password
3. The WarDragon will be at `192.168.12.1`

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
