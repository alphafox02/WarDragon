# Network Configuration

This guide covers network configuration options for your WarDragon Pro v3.

> **Prerequisite**: Network configuration requires local console access (monitor + keyboard) during initial setup. See [Unboxing & First Boot](unboxing.md) for instructions on connecting a monitor and keyboard. After configuring remote access, you can make network changes via SSH or remote desktop.

## Important: Internal Network Interfaces

**Do NOT modify "Wired connection 1"** - This interface is used internally for communication with the ANTSDR E200 and has a static IP configuration.

The external Ethernet port uses **"Wired connection 2"** - this is the interface you should configure for LAN connectivity.

## Network Modes

WarDragon can operate in several network modes:

| Mode | Use Case | Description |
|------|----------|-------------|
| Hotspot | Field deployment | WarDragon creates its own WiFi network |
| Client | Home/office | WarDragon joins existing WiFi network |
| Ethernet | Fixed installation | Wired connection to network |
| Hybrid | Flexible | Hotspot + Ethernet simultaneously |

## Default Network Settings

Out of the box:

| Interface | Configuration |
|-----------|--------------|
| Wired connection 1 | Static (internal E200 communication) - DO NOT MODIFY |
| Wired connection 2 | DHCP (external Ethernet port) |
| WiFi | Available for hotspot or client mode |

## Ethernet Configuration (Wired connection 2)

### DHCP (Default)

The external Ethernet port requests an IP address via DHCP. To find the assigned IP:

1. Check your router's DHCP lease table
2. Look for hostname `wardragon` or the device's MAC address
3. Use network scanning on your subnet

### Static IP

To configure a static IP on the external Ethernet port:

```bash
sudo nmcli connection modify "Wired connection 2" \
  ipv4.addresses "<your-ip>/<prefix>" \
  ipv4.gateway "<your-gateway>" \
  ipv4.dns "<dns-server>" \
  ipv4.method manual

sudo nmcli connection down "Wired connection 2"
sudo nmcli connection up "Wired connection 2"
```

## WiFi Client Mode

To connect WarDragon to an existing WiFi network:

```bash
# List available networks
nmcli device wifi list

# Connect to a network
sudo nmcli device wifi connect "YourNetworkSSID" password "YourPassword"

# Verify connection
nmcli connection show --active
```

The connection will automatically reconnect on boot.

## WiFi Hotspot Mode

See [Hotspot Setup](hotspot-setup.md) for detailed hotspot configuration.

When configured per the video tutorial, the hotspot uses:
- **IP**: 192.168.12.1
- **SSID**: Configurable

## Hybrid Mode (Hotspot + Ethernet)

For maximum flexibility, run hotspot on WiFi while maintaining Ethernet connectivity:

```bash
# Ensure Ethernet is connected
nmcli device status

# Enable hotspot on WiFi
sudo nmcli connection up <your-hotspot-connection>

# Both interfaces now active
ip addr show
```

This allows:
- Field devices to connect via hotspot
- WarDragon to reach internet/TAK servers via Ethernet
- Data forwarding between interfaces

## Network Diagnostics

### Check Interface Status

```bash
# All interfaces
ip addr show

# Routing table
ip route show

# DNS resolution
cat /etc/resolv.conf
```

### Test Connectivity

```bash
# Gateway
ping -c 3 <your-gateway>

# Internet
ping -c 3 8.8.8.8

# DNS resolution
ping -c 3 google.com
```

## TAK Server Connectivity

For TAK Server integration, ensure:

1. WarDragon can reach the TAK Server IP/hostname
2. Required ports are open:
   - TCP 8089 (default TAK server)
   - TCP 8443 (TLS)
   - UDP 6969 (multicast)

Test connectivity:

```bash
nc -zv <tak-server> <port>
```

## Troubleshooting

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| No IP address | `ip addr show` | Check cable/DHCP server |
| Can't reach gateway | `ping <gateway>` | Check IP/subnet config |
| DNS not working | `ping 8.8.8.8` works but names don't | Check DNS configuration |
| E200 not working | Modified Wired connection 1 | Restore default static config |

## Related Documentation

- [Hotspot Setup](hotspot-setup.md)
- [TAK Integration](../integration/tak-integration.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
