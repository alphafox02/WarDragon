# DragonSync

DragonSync (Community Edition) is a lightweight gateway that converts drone detection signals into Cursor on Target (CoT) format for TAK/ATAK systems, with optional MQTT publishing for Home Assistant integration.

**Repository**: [github.com/alphafox02/DragonSync](https://github.com/alphafox02/DragonSync)

## Overview

DragonSync performs these key functions:

1. **Subscribes** to ZMQ detection sources (DJI DroneID, WiFi RID, BT5 RID, FPV signals)
2. **Manages** drone tracking with two-tier capacity (verified vs unverified)
3. **Queries** FAA RID database for drone registration information
4. **Transforms** data into CoT XML for TAK, JSON for MQTT, and Lattice format
5. **Rate-limits** output to prevent flooding TAK networks
6. **Serves** read-only HTTP API for companion applications (ATAK plugin)
7. **Supports** ADS-B aircraft ingestion via dump1090/readsb

## Installation

DragonSync comes pre-installed on WarDragon Pro v3. For manual installation:

```bash
git clone https://github.com/alphafox02/DragonSync.git
cd DragonSync
pip install -r requirements.txt
```

## Configuration

DragonSync is configured via `config.ini`. The default location is:

```
/home/dragon/DragonSync/config.ini
```

### Complete Configuration Reference

```ini
[SETTINGS]

# ────────── ZMQ Configuration ──────────
zmq_host = 127.0.0.1
zmq_port = 4224
zmq_status_port = 4225

# ────────── TAK Server Configuration (optional) ──────────
tak_host =
tak_port =
# TCP or UDP (leave blank to ignore if host/port unset)
tak_protocol =
# TLS (TCP only): set EITHER PKCS#12 OR PEM files, not both
tak_tls_p12 =
tak_tls_p12_pass =
# PEM files (client cert + key; optional CA)
tak_tls_certfile =
tak_tls_keyfile =
tak_tls_cafile =
tak_tls_skip_verify = true

# ────────── Multicast Configuration (optional) ──────────
tak_multicast_addr = 239.2.3.1
tak_multicast_port = 6969
enable_multicast = true
tak_multicast_interface = 0.0.0.0
multicast_ttl = 1

# ────────── Operational Parameters ──────────
# Minimum seconds between CoT sends per drone
rate_limit = 2.0

# ────────── Drone Tracking Capacity ──────────
# Two-tier system (DEFAULT - prioritizes FAA RID-verified drones):
# Verified drones (passed FAA RID database check) are evicted last
# This helps filter out spoofed drone broadcasts
max_verified_drones = 70
max_unverified_drones = 30

# Legacy single-tier mode (uncomment to disable RID priority):
# Use this if you want all drones treated equally (no verification priority)
#max_drones = 60

# Inactivity timeout applies to both tiers
inactivity_timeout = 60.0
enable_receive = false

# ────────── DragonSync API (optional) ──────────
# Enables the read-only HTTP API used by the ATAK plugin.
api_enabled = true
api_host = 0.0.0.0
api_port = 8088

# ────────── FAA RID API Fallback (optional; local DB always used) ──────────
# By default, only the bundled FAA RID database is used for lookups (no network).
# Set to true to allow online FAA API fallback when a serial is not found locally.
rid_api_enabled = false

# ────────── MQTT Configuration (optional) ──────────
mqtt_enabled = false
mqtt_host = 127.0.0.1
mqtt_port = 1883
# Drone topics
mqtt_topic = wardragon/drones
mqtt_per_drone_enabled = false
mqtt_per_drone_base = wardragon/drone
# Aircraft topics (ADS-B)
mqtt_aircraft_enabled = false
mqtt_aircraft_topic = wardragon/aircraft
# Signal alerts
mqtt_signals_enabled = false
mqtt_signals_topic = wardragon/signals
# Home Assistant discovery (disabled by default)
mqtt_ha_enabled = false
mqtt_ha_prefix = homeassistant
mqtt_ha_device_base = wardragon_drone
mqtt_ha_signal_tracker = false
mqtt_ha_signal_id = signal_latest
# Authentication / TLS
mqtt_username =
mqtt_password =
mqtt_tls = false
mqtt_ca_file =
mqtt_certfile =
mqtt_keyfile =
mqtt_tls_insecure = false
# Retain messages by default (good for HA dashboards)
mqtt_retain = true

# ────────── Lattice (optional) ──────────
lattice_enabled = false
lattice_token =
# Either base URL, e.g. https://your.env.anduril.cloud
lattice_base_url =
# Or an endpoint host to build base_url (we'll prefix https://)
lattice_endpoint =
# Sandbox token (or set env SANDBOXES_TOKEN)
lattice_sandbox_token =
lattice_source_name = DragonSync
lattice_drone_rate = 1.0
lattice_wd_rate = 0.2

# ────────── ADS-B / dump1090 Integration (optional) ──────────
adsb_enabled = false
adsb_json_url = http://127.0.0.1:8080/?all_with_pos
adsb_uid_prefix = adsb-
adsb_cot_stale = 15
adsb_cache_ttl = 120
adsb_rate_limit = 3.0
adsb_min_alt = 0
adsb_max_alt = 0

# ────────── FPV signal ingest (optional) ──────────
fpv_enabled = false
fpv_zmq_host = 127.0.0.1
fpv_zmq_port = 4226
fpv_stale = 60
fpv_radius_m = 15
fpv_rate_limit = 2.0
fpv_max_signals = 200
fpv_confirm_only = true

# ────────── Kismet (optional) ──────────
kismet_enabled = false
kismet_host = http://127.0.0.1:2501
kismet_apikey =
```

## Key Configuration Sections

### ZMQ Input

DragonSync receives detection data via ZMQ:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `zmq_host` | 127.0.0.1 | Host for ZMQ subscriptions |
| `zmq_port` | 4224 | Main detection data port |
| `zmq_status_port` | 4225 | System status port |

### Multicast Output

Default multicast settings for ATAK:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `tak_multicast_addr` | 239.2.3.1 | SA multicast address |
| `tak_multicast_port` | 6969 | SA multicast port |
| `enable_multicast` | true | Enable multicast output |
| `tak_multicast_interface` | 0.0.0.0 | Interface to send on (0.0.0.0 = all) |
| `multicast_ttl` | 1 | TTL for multicast packets |

**Note:** When `tak_multicast_interface` is `0.0.0.0`, DragonSync sends multicast on ALL active interfaces and checks for new interfaces approximately every 30 seconds. This is useful for dynamic setups like USB Ethernet tethering.

### TAK Server (TCP/TLS)

For direct TAK Server connections:

```ini
tak_host = tak.example.com
tak_port = 8089
tak_protocol = TCP

# Using PKCS#12 certificate
tak_tls_p12 = /path/to/client.p12
tak_tls_p12_pass = password

# OR using PEM files
tak_tls_certfile = /path/to/client.crt
tak_tls_keyfile = /path/to/client.key
tak_tls_cafile = /path/to/ca.crt
```

### Drone Tracking Capacity

DragonSync uses a two-tier tracking system to prioritize verified drones:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_verified_drones` | 70 | Capacity for FAA RID-verified drones |
| `max_unverified_drones` | 30 | Capacity for unverified drones |
| `inactivity_timeout` | 60.0 | Seconds before removing inactive drone |
| `rate_limit` | 2.0 | Minimum seconds between CoT sends per drone |

**Why two tiers?** Verified drones (those that pass FAA RID database lookup) are evicted last. This helps filter out spoofed drone broadcasts while preserving legitimate detections.

For legacy single-tier mode (all drones treated equally):
```ini
# Comment out max_verified_drones and max_unverified_drones
max_drones = 60
```

### FAA RID Database

DragonSync includes a bundled FAA RID database for offline lookups:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `rid_api_enabled` | false | Enable online FAA API fallback |

The local database is always used first. Online fallback only occurs if enabled AND the serial is not found locally.

### HTTP API

The read-only API is used by the WarDragon ATAK Plugin:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `api_enabled` | true | Enable HTTP API |
| `api_host` | 0.0.0.0 | Listen address |
| `api_port` | 8088 | Listen port |

### MQTT / Home Assistant

For home automation integration:

```ini
mqtt_enabled = true
mqtt_host = 192.168.1.100
mqtt_port = 1883
mqtt_username = wardragon
mqtt_password = yourpassword

# Per-drone topics (wardragon/drone/<serial>)
mqtt_per_drone_enabled = true
mqtt_per_drone_base = wardragon/drone

# Home Assistant auto-discovery
mqtt_ha_enabled = true
mqtt_ha_prefix = homeassistant
mqtt_ha_device_base = wardragon_drone
```

### ADS-B Integration

Ingest aircraft tracks from dump1090/readsb:

```ini
adsb_enabled = true
adsb_json_url = http://127.0.0.1:8080/?all_with_pos
adsb_uid_prefix = adsb-
adsb_cot_stale = 15
adsb_rate_limit = 3.0
adsb_min_alt = 0    # 0 = no minimum
adsb_max_alt = 0    # 0 = no maximum
```

### FPV Signal Detection

Ingest FPV drone signals from wardragon-fpv-detect:

```ini
fpv_enabled = true
fpv_zmq_host = 127.0.0.1
fpv_zmq_port = 4226
fpv_stale = 60
fpv_radius_m = 15
fpv_rate_limit = 2.0
fpv_max_signals = 200
fpv_confirm_only = true
```

### Lattice (Anduril)

For Anduril Lattice integration:

```ini
lattice_enabled = true
lattice_token = your_api_token
lattice_base_url = https://your.env.anduril.cloud
lattice_source_name = DragonSync
lattice_drone_rate = 1.0
lattice_wd_rate = 0.2
```

### Kismet Integration

Enable Kismet device tracking:

```ini
kismet_enabled = true
kismet_host = http://127.0.0.1:2501
kismet_apikey = your_kismet_api_key
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
python dragonsync.py
```

## HTTP API

When enabled, DragonSync provides a read-only HTTP API on port 8088. This API is used by the WarDragon ATAK Plugin and WarDragonAnalytics.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/status` | GET | System health and kit info |
| `/drones` | GET | Current active drone/aircraft tracks |
| `/signals` | GET | Current signal alerts (FPV, etc.) |
| `/config` | GET | Sanitized configuration |
| `/update/check` | GET | Git update availability |

### Rate Limiting

The API implements rate limiting (100 requests per 60 seconds per IP address) to prevent abuse.

## Data Attribution Fields

DragonSync adds metadata fields for multi-kit tracking scenarios:

| Field | Description |
|-------|-------------|
| `observed_at` | Timestamp when kit processed the detection |
| `rid_timestamp` | Timestamp from the airframe (if provided) |
| `seen_by` | Identifier of the detecting kit |

## CoT Message Format

DragonSync generates Cursor on Target (CoT) XML messages for TAK:

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

## Troubleshooting

### No Detections Reaching TAK

1. Check DragonSync is running:
   ```bash
   sudo systemctl status dragonsync
   ```

2. Check multicast is enabled:
   ```bash
   grep enable_multicast /home/dragon/DragonSync/config.ini
   ```

3. Verify multicast interface:
   ```bash
   grep tak_multicast_interface /home/dragon/DragonSync/config.ini
   ```

4. Check logs for errors:
   ```bash
   journalctl -u dragonsync -f
   ```

### Drones Not Being Tracked

- Check `max_verified_drones` and `max_unverified_drones` capacity
- Verify `inactivity_timeout` isn't too short
- Check ZMQ connection to detection sources

### High CPU Usage

- Increase `rate_limit` value (default 2.0 seconds)
- Reduce `max_*_drones` capacity if tracking too many

### MQTT Connection Issues

DragonSync features async MQTT with automatic retries. If the broker is unavailable, CoT output and other features continue working normally.

## Related Documentation

- [System Architecture](../architecture/overview.md)
- [ZMQ Data Flows](../architecture/zmq-dataflows.md)
- [TAK Integration](../integration/tak-integration.md)
- [MQTT Integration](../integration/mqtt-homeassistant.md)
- [FPV Detection](https://github.com/alphafox02/wardragon-fpv-detect)
