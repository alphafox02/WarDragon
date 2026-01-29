# TAK Integration

This guide covers integrating WarDragon with the TAK (Team Awareness Kit) ecosystem, including ATAK, iTAK, WinTAK, and TAK Server.

## Overview

WarDragon outputs drone detections as Cursor on Target (CoT) messages, the standard format for TAK situational awareness. Detections appear as icons on the TAK map with full telemetry data.

## Integration Options

| Method | Use Case | Complexity | Requirements |
|--------|----------|------------|--------------|
| Multicast | Local network, no server | Simple | Same network segment |
| TAK Server | Distributed teams | Medium | TAK Server infrastructure |
| Direct TCP/UDP | Point-to-point | Simple | Network connectivity |
| WarDragon ATAK Plugin | Enhanced features | Simple | ATAK + Plugin |

## Multicast Configuration (Default)

Multicast is the simplest integration method for devices on the same network.

### WarDragon Configuration

In DragonSync `config.yaml`:

```yaml
outputs:
  tak:
    enabled: true
    mode: multicast
    multicast_address: "239.2.3.1"
    multicast_port: 6969
    multicast_interface: ""  # Empty = default, or specify IP
    rate_limit: 1.0
```

### ATAK Configuration

1. Open ATAK → Settings → Network Preferences
2. Select **SA Multicast**
3. Configure:
   - Input: `239.2.3.1:6969`
   - Output: `239.2.3.1:6969`
4. Ensure your device is on the same network as WarDragon

### Verifying Multicast

On WarDragon, confirm multicast traffic:

```bash
# Install tcpdump if needed
sudo apt install tcpdump

# Monitor multicast
sudo tcpdump -i any host 239.2.3.1 and port 6969
```

You should see CoT XML packets when drones are detected.

## TAK Server Configuration

For distributed teams or persistent data, connect WarDragon to a TAK Server.

### WarDragon Configuration

```yaml
outputs:
  tak:
    enabled: true
    mode: tcp                    # or udp
    server_address: "tak.example.com"
    server_port: 8089            # Default TAK Server port

    # Optional TLS (recommended for production)
    tls_enabled: false
    tls_cert: "/path/to/client.pem"
    tls_key: "/path/to/client.key"
    tls_ca: "/path/to/ca.pem"
```

### TAK Server Setup

On your TAK Server, ensure:

1. Streaming input is enabled on the configured port
2. Firewall allows connections from WarDragon
3. If using TLS, client certificates are enrolled

### Testing Connection

```bash
# Test TCP connectivity
nc -zv tak.example.com 8089

# Watch DragonSync logs
journalctl -u dragonsync -f | grep -i tak
```

## TLS/SSL Configuration

For secure connections to TAK Server:

### Generate Client Certificate

If using TAK Server certificate enrollment:

1. Export enrollment package from TAK Server
2. Place certificates on WarDragon:
   ```bash
   mkdir -p /home/dragon/certs
   cp client.pem client.key ca.pem /home/dragon/certs/
   chmod 600 /home/dragon/certs/*.key
   ```

3. Configure DragonSync:
   ```yaml
   outputs:
     tak:
       tls_enabled: true
       tls_cert: "/home/dragon/certs/client.pem"
       tls_key: "/home/dragon/certs/client.key"
       tls_ca: "/home/dragon/certs/ca.pem"
   ```

## WarDragon ATAK Plugin

The WarDragon ATAK Plugin provides enhanced integration beyond basic CoT.

**Repository**: [WarDragon-ATAK-Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin)

### Features

- Native ATAK UI for WarDragon status
- Enhanced drone track visualization
- Pilot location display
- System health monitoring
- Direct configuration access

### Installation

1. Download the plugin APK from GitHub releases
2. Install on your ATAK device:
   ```
   Settings → Tool Preferences → Manage Plugins → Import Plugin
   ```
3. Enable the WarDragon plugin

### Configuration

1. Open ATAK → Tools → WarDragon
2. Configure connection:
   - **WarDragon IP**: Your WarDragon's IP address
   - **API Port**: 8080 (default)
3. Connect

The plugin communicates with DragonSync's HTTP API while CoT messages continue via multicast/server.

## iTAK Configuration

For iOS devices with iTAK:

1. Ensure iTAK and WarDragon on same network
2. Configure SA Multicast in iTAK:
   - Input: `239.2.3.1:6969`
3. Drone detections appear on map

## WinTAK Configuration

For Windows devices:

1. Open WinTAK → Settings → Network
2. Add Multicast input: `239.2.3.1:6969`
3. Or configure TAK Server connection

## CoT Message Details

WarDragon generates CoT messages with drone-specific data:

### Message Structure

```xml
<event version="2.0"
       uid="drone-ABC123"
       type="a-u-G-U-U-D"
       time="2024-01-15T14:30:00Z"
       start="2024-01-15T14:30:00Z"
       stale="2024-01-15T14:31:00Z"
       how="m-g">
  <point lat="40.7128" lon="-74.006" hae="100" ce="10" le="10"/>
  <detail>
    <contact callsign="DJI-ABC123"/>
    <track course="270" speed="15"/>
    <remarks>DJI Mavic 3 | Serial: ABC123DEF456</remarks>
    <__drone>
      <serial>ABC123DEF456</serial>
      <model>Mavic 3</model>
      <pilot_lat>40.713</pilot_lat>
      <pilot_lon>-74.0055</pilot_lon>
      <home_lat>40.713</home_lat>
      <home_lon>-74.0055</home_lon>
      <height_agl>50</height_agl>
    </__drone>
  </detail>
</event>
```

### CoT Type Codes

| Type Code | Meaning | Display |
|-----------|---------|---------|
| a-u-G-U-U-D | Unknown UAS | Yellow drone icon |
| a-f-G-U-U-D | Friendly UAS | Blue drone icon |
| a-h-G-U-U-D | Hostile UAS | Red drone icon |
| a-n-G-U-U-D | Neutral UAS | Green drone icon |

### Icon Customization

TAK uses the CoT type code to display icons. Custom drone icons can be added to ATAK's icon set for better visualization.

## Pilot Location Display

When pilot/operator location is available (DJI DroneID), WarDragon can send a separate CoT for the pilot:

```yaml
outputs:
  tak:
    pilot_cot_enabled: true
    pilot_cot_type: "a-u-G"  # Ground unit
```

This displays both the drone and operator on the TAK map.

## Rate Limiting

To prevent flooding TAK networks:

```yaml
outputs:
  tak:
    rate_limit: 1.0  # Minimum seconds between updates per track
```

Adjust based on your network capacity and update frequency needs.

## Troubleshooting

### Drones Not Appearing in ATAK

1. **Check network connectivity**:
   ```bash
   ping <ATAK device IP>
   ```

2. **Verify multicast routing**:
   ```bash
   # On WarDragon
   sudo tcpdump -i any host 239.2.3.1
   ```

3. **Check ATAK multicast settings** are correct

4. **Verify DragonSync is running**:
   ```bash
   sudo systemctl status dragonsync
   ```

### TAK Server Connection Failed

1. **Test network connectivity**:
   ```bash
   nc -zv <server> <port>
   ```

2. **Check firewall rules** on both WarDragon and server

3. **Verify certificates** if using TLS

4. **Check server logs** for authentication issues

### CoT Messages Malformed

1. Enable DragonSync debug logging:
   ```bash
   journalctl -u dragonsync -f
   ```

2. Check for XML encoding issues with special characters

### Plugin Not Connecting

1. Verify WarDragon HTTP API is enabled and accessible:
   ```bash
   curl http://<wardragon-ip>:8080/api/status
   ```

2. Check firewall allows port 8080

3. Ensure ATAK has network permissions

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [Network Configuration](../getting-started/network-setup.md)
- [Hotspot Setup](../getting-started/hotspot-setup.md)
- [MQTT Integration](mqtt-homeassistant.md)
