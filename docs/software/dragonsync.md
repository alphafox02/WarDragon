# DragonSync

DragonSync is the core application that orchestrates all detection streams on WarDragon, transforming raw drone detections into actionable intelligence for TAK, MQTT, Lattice, and other outputs.

**Repository**: [github.com/alphafox02/DragonSync](https://github.com/alphafox02/DragonSync)

## Overview

DragonSync performs these key functions:

1. **Subscribes** to ZMQ detection sources (DJI DroneID, WiFi RID, BT5 RID)
2. **Merges** detections from multiple sources
3. **Deduplicates** overlapping detections of the same drone
4. **Rate-limits** output to prevent flooding TAK networks
5. **Transforms** data into CoT XML, MQTT JSON, Lattice format
6. **Manages** track state, history, and aging
7. **Serves** HTTP API for companion applications

## Installation

DragonSync comes pre-installed on WarDragon Pro v3. For manual installation:

```bash
git clone https://github.com/alphafox02/DragonSync.git
cd DragonSync
pip install -r requirements.txt
```

## Configuration

DragonSync is configured via `config.yaml`. The default location is:

```
/home/dragon/DragonSync/config.yaml
```

### Configuration Structure

```yaml
# =============================================================================
# DragonSync Configuration
# =============================================================================

# System Settings
system:
  log_level: INFO              # DEBUG, INFO, WARNING, ERROR
  gps_source: gpsd             # gpsd, static, none
  static_lat: 0.0              # If gps_source: static
  static_lon: 0.0

# =============================================================================
# Input Sources - ZMQ Subscriptions
# =============================================================================

inputs:
  dji_droneid:
    enabled: true
    zmq_address: "tcp://127.0.0.1:5556"

  droneid_wifi:
    enabled: true
    zmq_address: "tcp://127.0.0.1:5557"

  droneid_bt:
    enabled: true
    zmq_address: "tcp://127.0.0.1:5558"

  # Optional: Aircraft data from readsb
  aircraft:
    enabled: false
    readsb_url: "http://127.0.0.1:8080/data/aircraft.json"
    poll_interval: 5

# =============================================================================
# Output Destinations
# =============================================================================

outputs:
  # TAK/ATAK Output
  tak:
    enabled: true
    mode: multicast           # multicast, tcp, udp

    # Multicast settings
    multicast_address: "239.2.3.1"
    multicast_port: 6969
    multicast_interface: ""   # Empty = default interface

    # TAK Server settings (if mode: tcp or udp)
    server_address: ""
    server_port: 8089

    # TLS settings (if using TAK Server with TLS)
    tls_enabled: false
    tls_cert: ""
    tls_key: ""
    tls_ca: ""

    # Rate limiting
    rate_limit: 1.0           # Seconds between updates per track

  # MQTT Output
  mqtt:
    enabled: false
    broker: "192.168.1.100"
    port: 1883
    username: ""
    password: ""

    # Topic structure
    base_topic: "wardragon/drones"

    # Home Assistant auto-discovery
    homeassistant_discovery: true
    discovery_prefix: "homeassistant"

  # Anduril Lattice Output
  lattice:
    enabled: false
    endpoint: ""
    api_key: ""

  # HTTP API for companion apps
  api:
    enabled: true
    host: "0.0.0.0"
    port: 8080

# =============================================================================
# Track Management
# =============================================================================

tracks:
  # How long to keep a track without updates (seconds)
  stale_timeout: 60

  # How long until track is removed entirely
  delete_timeout: 300

  # Deduplication window (seconds)
  dedup_window: 5

  # Merge detections within this distance (meters)
  merge_distance: 50
```

## Running DragonSync

### As a Service (Default)

```bash
# Check status
sudo systemctl status dragonsync

# Start/Stop/Restart
sudo systemctl start dragonsync
sudo systemctl stop dragonsync
sudo systemctl restart dragonsync

# View logs
journalctl -u dragonsync -f
```

### Manual Execution

```bash
cd /home/dragon/DragonSync
python dragonsync.py -c config.yaml
```

### Debug Mode

```bash
python dragonsync.py -c config.yaml --log-level DEBUG
```

## HTTP API

When enabled, DragonSync provides a read-only HTTP API for companion applications like the WarDragon ATAK Plugin.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/status` | GET | System status and health |
| `/api/tracks` | GET | Current active tracks |
| `/api/tracks/{id}` | GET | Single track details |
| `/api/config` | GET | Sanitized configuration |
| `/api/stats` | GET | Detection statistics |

### Example Responses

**GET /api/status**
```json
{
  "status": "running",
  "uptime": 3600,
  "gps": {
    "fix": true,
    "lat": 40.7128,
    "lon": -74.0060,
    "satellites": 12
  },
  "inputs": {
    "dji_droneid": "connected",
    "droneid_wifi": "connected",
    "droneid_bt": "connected"
  },
  "outputs": {
    "tak": "active",
    "mqtt": "disabled"
  }
}
```

**GET /api/tracks**
```json
{
  "tracks": [
    {
      "id": "abc123",
      "type": "dji",
      "drone": {
        "serial": "ABC123DEF456",
        "model": "Mavic 3",
        "lat": 40.7128,
        "lon": -74.006,
        "alt": 100,
        "speed": 15,
        "heading": 270
      },
      "pilot": {
        "lat": 40.713,
        "lon": -74.0055
      },
      "last_seen": "2024-01-15T14:30:00Z",
      "source": "antsdr_e200"
    }
  ],
  "count": 1
}
```

## CoT Message Format

DragonSync generates Cursor on Target (CoT) XML messages for TAK integration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<event version="2.0"
       uid="drone-ABC123DEF456"
       type="a-f-G-U-U-D"
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
    </__drone>
  </detail>
</event>
```

### CoT Type Codes

| Drone Type | CoT Type |
|------------|----------|
| DJI (detected) | a-f-G-U-U-D |
| Remote ID (unknown intent) | a-u-G-U-U-D |
| Friendly (if tagged) | a-f-G-U-U-D |
| Hostile (if tagged) | a-h-G-U-U-D |

## Integration with Detection Sources

### DJI DroneID

DragonSync subscribes to `dji_receiver.py` output:

```
ANTSDR E200 → dji_receiver.py → ZMQ (5556) → DragonSync
```

### WiFi/BT Remote ID

DragonSync subscribes to DroneID output:

```
Panda/ESP32 → DroneID → ZMQ (5557) → DragonSync
DragonTooth → Sniffle → ZMQ (5558) → DragonSync
```

## Troubleshooting

### No Detections Reaching TAK

1. Check input sources:
   ```bash
   # Test ZMQ connection
   python -c "import zmq; c=zmq.Context(); s=c.socket(zmq.SUB); s.connect('tcp://127.0.0.1:5556'); s.setsockopt_string(zmq.SUBSCRIBE,''); print(s.recv_string())"
   ```

2. Verify TAK output config:
   ```bash
   # Test multicast
   echo "test" | nc -u 239.2.3.1 6969
   ```

3. Check DragonSync logs:
   ```bash
   journalctl -u dragonsync -f
   ```

### High CPU Usage

- Reduce log level from DEBUG to INFO
- Increase rate_limit for TAK output
- Check for network issues causing retries

### Tracks Not Merging

- Increase `merge_distance` in config
- Check GPS accuracy on WarDragon
- Verify time synchronization

## Related Documentation

- [System Architecture](../architecture/overview.md)
- [ZMQ Data Flows](../architecture/zmq-dataflows.md)
- [TAK Integration](../integration/tak-integration.md)
- [MQTT Integration](../integration/mqtt-homeassistant.md)
