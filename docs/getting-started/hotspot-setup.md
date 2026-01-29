# Hotspot Setup

This guide explains how to configure WarDragon Pro v3 as a WiFi hotspot for field deployments where no existing network infrastructure is available.

## Overview

When configured as a hotspot, WarDragon:

- Creates its own WiFi access point
- Provides DHCP to connected clients
- Allows ATAK/TAK devices to connect directly
- Can simultaneously maintain Ethernet connectivity

## Video Tutorial

📺 **[WarDragon Internal Hotspot Setup](https://www.youtube.com/watch?v=H_VsW9bqTkQ)** - Step-by-step video walkthrough

## Quick Setup

### Enable Pre-configured Hotspot

If your WarDragon came with a pre-configured hotspot:

```bash
# Check if hotspot connection exists
nmcli connection show | grep -i hotspot

# Enable the hotspot
sudo nmcli connection up WarDragon-Hotspot

# Verify it's running
nmcli device status
```

### Create New Hotspot

If you need to create a new hotspot configuration:

```bash
# Create hotspot with custom SSID and password
sudo nmcli device wifi hotspot \
  ifname wlan0 \
  ssid "WarDragon-Field" \
  password "SecurePassword123"
```

## Detailed Configuration

### Step 1: Identify WiFi Interface

```bash
# List wireless interfaces
nmcli device status | grep wifi

# Should show wlan0 (internal WiFi)
# Note: wlan1 or similar may be the Panda adapter - don't use for hotspot
```

### Step 2: Create Hotspot Connection

```bash
# Create persistent hotspot configuration
sudo nmcli connection add \
  type wifi \
  ifname wlan0 \
  con-name "WarDragon-Hotspot" \
  autoconnect no \
  ssid "WarDragon" \
  mode ap \
  ipv4.method shared \
  ipv4.addresses "192.168.12.1/24" \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "YourSecurePassword"
```

### Step 3: Configure WiFi Security

For better security, use WPA2/WPA3:

```bash
sudo nmcli connection modify "WarDragon-Hotspot" \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.proto rsn \
  wifi-sec.group ccmp \
  wifi-sec.pairwise ccmp
```

### Step 4: Set WiFi Channel and Band

For best performance with ATAK devices:

```bash
# Use 2.4 GHz band (better compatibility)
sudo nmcli connection modify "WarDragon-Hotspot" \
  wifi.band bg \
  wifi.channel 6

# Or use 5 GHz for less interference (if devices support it)
sudo nmcli connection modify "WarDragon-Hotspot" \
  wifi.band a \
  wifi.channel 36
```

### Step 5: Enable and Test

```bash
# Start the hotspot
sudo nmcli connection up "WarDragon-Hotspot"

# Verify it's running
nmcli device wifi list ifname wlan0
iw dev wlan0 info
```

## Auto-Start on Boot

To have the hotspot start automatically:

```bash
# Enable autoconnect
sudo nmcli connection modify "WarDragon-Hotspot" connection.autoconnect yes

# Set priority (higher = preferred)
sudo nmcli connection modify "WarDragon-Hotspot" connection.autoconnect-priority 100
```

## DHCP Configuration

NetworkManager's "shared" mode automatically runs a DHCP server. Connected clients receive:

- IP addresses in 192.168.12.0/24 range
- Gateway: 192.168.12.1 (WarDragon)
- DNS: Forwarded through WarDragon

### Custom DHCP Range

For more control, edit dnsmasq configuration:

```bash
sudo nano /etc/NetworkManager/dnsmasq-shared.d/wardragon.conf
```

Add:

```
dhcp-range=192.168.12.10,192.168.12.100,12h
dhcp-option=option:router,192.168.12.1
dhcp-option=option:dns-server,192.168.12.1
```

Restart NetworkManager:

```bash
sudo systemctl restart NetworkManager
```

## Connecting Clients

### From ATAK/TAK Device

1. Open device WiFi settings
2. Find and connect to `WarDragon` (or your custom SSID)
3. Enter the password
4. Configure ATAK to use WarDragon's IP for CoT

### Client IP Assignment

View connected clients:

```bash
# Show DHCP leases
cat /var/lib/NetworkManager/dnsmasq-wlan0.leases

# Or check ARP table
arp -a
```

## Hybrid Mode: Hotspot + Ethernet

Run hotspot while maintaining Ethernet connectivity:

```bash
# Ensure Ethernet is connected
sudo nmcli connection up "Wired connection 2"

# Then enable hotspot
sudo nmcli connection up "WarDragon-Hotspot"

# Verify both active
nmcli device status
```

Benefits:
- Field devices connect via hotspot
- WarDragon reaches TAK Server via Ethernet
- NAT automatically routes between interfaces

## Hotspot + TAK Configuration

When using hotspot with ATAK:

### DragonSync CoT Output

Configure DragonSync to multicast on the hotspot interface:

```yaml
# In dragonsync config
outputs:
  tak:
    enabled: true
    multicast: true
    address: "239.2.3.1"
    port: 6969
    interface: "192.168.12.1"  # Hotspot interface
```

### ATAK Configuration

On connected ATAK devices:

1. Go to Settings → Network Preferences
2. Set TAK Server or SA Multicast
3. For multicast: Use `239.2.3.1:6969`
4. For direct: Use WarDragon's IP (`192.168.12.1`)

## Security Considerations

### Change Default Password

Always change the default hotspot password:

```bash
sudo nmcli connection modify "WarDragon-Hotspot" \
  wifi-sec.psk "NewSecurePassword"
```

### Hide SSID (Optional)

For covert operations:

```bash
sudo nmcli connection modify "WarDragon-Hotspot" \
  wifi.hidden yes
```

Clients must manually enter the SSID to connect.

### MAC Filtering (Advanced)

For additional security, implement MAC filtering via hostapd or iptables.

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Hotspot won't start | Interface busy | Stop other WiFi connections first |
| Clients can't connect | Wrong password | Verify password, check for special characters |
| No IP assigned | DHCP not running | Restart NetworkManager |
| Connected but no internet | NAT not enabled | Check ip_forward and iptables |
| Weak signal | Low TX power | Check regulatory domain settings |

### Debug Commands

```bash
# Check interface status
nmcli device show wlan0

# View connection details
nmcli connection show "WarDragon-Hotspot"

# Check for errors
journalctl -u NetworkManager -f

# Verify IP forwarding (for NAT)
cat /proc/sys/net/ipv4/ip_forward
```

## Related Documentation

- [Network Configuration](network-setup.md)
- [TAK Integration](../integration/tak-integration.md)
- [Video Tutorials](../tutorials/video-index.md)
