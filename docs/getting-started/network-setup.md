# Network Configuration

This guide covers network configuration options for your WarDragon Pro v3.

## Network Modes

WarDragon can operate in several network modes:

| Mode | Use Case | Description |
|------|----------|-------------|
| Hotspot | Field deployment | WarDragon creates its own WiFi network |
| Client | Home/office | WarDragon joins existing WiFi network |
| Ethernet | Fixed installation | Wired connection to network |
| Hybrid | Flexible | Hotspot + Ethernet simultaneously |

## Default Network Settings

Out of the box, WarDragon is configured with:

| Interface | Configuration |
|-----------|--------------|
| Ethernet (eth0) | DHCP client |
| WiFi (wlan0) | Hotspot mode (if enabled) |

## Ethernet Configuration

### DHCP (Default)

WarDragon requests an IP address from your network's DHCP server. To find the assigned IP:

1. Check your router's DHCP lease table
2. Look for hostname `wardragon` or the device's MAC address
3. Use network scanning: `nmap -sn 192.168.1.0/24`

### Static IP

To configure a static IP address:

1. SSH into WarDragon:
   ```bash
   ssh dragon@<current-ip>
   ```

2. Edit the network configuration:
   ```bash
   sudo nmcli connection modify "Wired connection 1" \
     ipv4.addresses "192.168.1.100/24" \
     ipv4.gateway "192.168.1.1" \
     ipv4.dns "8.8.8.8,8.8.4.4" \
     ipv4.method manual
   ```

3. Restart networking:
   ```bash
   sudo nmcli connection down "Wired connection 1"
   sudo nmcli connection up "Wired connection 1"
   ```

## WiFi Client Mode

To connect WarDragon to an existing WiFi network:

### Using nmcli

```bash
# List available networks
nmcli device wifi list

# Connect to a network
sudo nmcli device wifi connect "YourNetworkSSID" password "YourPassword"

# Verify connection
nmcli connection show --active
```

### Making Connection Persistent

The connection will automatically reconnect on boot. To verify:

```bash
nmcli connection show
```

## WiFi Hotspot Mode

See [Hotspot Setup](hotspot-setup.md) for detailed hotspot configuration.

Quick enable:

```bash
# Create hotspot
sudo nmcli device wifi hotspot ssid "WarDragon" password "your-password"

# Or use the pre-configured hotspot
sudo nmcli connection up WarDragon-Hotspot
```

## Hybrid Mode (Hotspot + Ethernet)

For maximum flexibility, run hotspot on WiFi while maintaining Ethernet connectivity:

```bash
# Ensure Ethernet is connected
nmcli device status

# Enable hotspot on WiFi
sudo nmcli connection up WarDragon-Hotspot

# Both interfaces now active
ip addr show
```

This allows:
- Field devices to connect via hotspot
- WarDragon to reach internet/TAK servers via Ethernet
- Data forwarding between interfaces

## Firewall Configuration

WarDragon uses `nftables` for firewall management. Default rules allow:

- SSH (port 22)
- HTTP/HTTPS (ports 80, 443)
- TAK multicast (port 6969)
- MQTT (port 1883)
- ZMQ ports (5556-5560)

### View Current Rules

```bash
sudo nft list ruleset
```

### Allow Additional Port

```bash
sudo nft add rule inet filter input tcp dport 8080 accept
```

### Persist Firewall Changes

```bash
sudo nft list ruleset > /etc/nftables.conf
```

## DNS Configuration

### Using Local DNS

```bash
sudo nmcli connection modify "Wired connection 1" ipv4.dns "192.168.1.1"
sudo nmcli connection up "Wired connection 1"
```

### Using Public DNS

```bash
sudo nmcli connection modify "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1"
sudo nmcli connection up "Wired connection 1"
```

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
ping -c 3 192.168.1.1

# Internet
ping -c 3 8.8.8.8

# DNS resolution
ping -c 3 google.com
```

### Monitor Network Traffic

```bash
# Interface statistics
ip -s link show eth0

# Real-time monitoring
sudo iftop -i eth0
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
# TCP connection test
nc -zv tak-server.example.com 8089

# Multicast test (if on same network)
# WarDragon sends to 239.2.3.1:6969 by default
```

## Troubleshooting

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| No IP address | `ip addr show` | Check cable/DHCP server |
| Can't reach gateway | `ping <gateway>` | Check IP/subnet config |
| DNS not working | `ping 8.8.8.8` works but names don't | Fix DNS configuration |
| Can't reach TAK Server | `nc -zv <server> <port>` | Check firewall/routing |

## Related Documentation

- [Hotspot Setup](hotspot-setup.md)
- [TAK Integration](../integration/tak-integration.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
