# MQTT & Home Assistant Integration

This guide covers configuring WarDragon to publish drone detections to MQTT brokers and integrate with Home Assistant for dashboards and automation.

## Overview

WarDragon can publish drone detections to MQTT in multiple formats:

1. **Standard Topics** - All drones published to a single topic
2. **Per-Drone Topics** - Individual topic per drone serial
3. **Home Assistant Discovery** - Auto-configured entities in Home Assistant
4. **Aircraft Topics** - ADS-B aircraft data (if enabled)
5. **Signal Topics** - FPV/signal alerts (if enabled)

## MQTT Configuration

### DragonSync Configuration

In `config.ini`:

```ini
[SETTINGS]
# Enable MQTT output
mqtt_enabled = true
mqtt_host = 192.168.1.100
mqtt_port = 1883

# Authentication (optional)
mqtt_username = wardragon
mqtt_password = yourpassword

# Main drone topic
mqtt_topic = wardragon/drones

# Per-drone topics (wardragon/drone/<serial>)
mqtt_per_drone_enabled = true
mqtt_per_drone_base = wardragon/drone

# Aircraft topics (ADS-B, if adsb_enabled = true)
mqtt_aircraft_enabled = false
mqtt_aircraft_topic = wardragon/aircraft

# Signal alerts (FPV, if fpv_enabled = true)
mqtt_signals_enabled = false
mqtt_signals_topic = wardragon/signals

# Home Assistant auto-discovery
mqtt_ha_enabled = true
mqtt_ha_prefix = homeassistant
mqtt_ha_device_base = wardragon_drone
mqtt_ha_signal_tracker = false
mqtt_ha_signal_id = signal_latest

# TLS (optional)
mqtt_tls = false
mqtt_ca_file =
mqtt_certfile =
mqtt_keyfile =
mqtt_tls_insecure = false

# Retain messages (good for HA dashboards)
mqtt_retain = true
```

### Topic Structure

When a drone is detected, WarDragon publishes to:

**Main Topic** (`wardragon/drones`):
All drone updates published here as JSON.

**Per-Drone Topics** (when `mqtt_per_drone_enabled = true`):
```
wardragon/drone/<serial_number>
```

### Message Format

**Main Drone Topic** (`wardragon/drones`):
```json
{
  "serial_number": "ABC123DEF456",
  "model": "Mavic 3",
  "drone_lat": 40.7128,
  "drone_lon": -74.006,
  "drone_alt": 100,
  "drone_height_agl": 50,
  "speed": 15,
  "heading": 270,
  "pilot_lat": 40.713,
  "pilot_lon": -74.0055,
  "home_lat": 40.713,
  "home_lon": -74.0055,
  "detection_source": "dji_droneid",
  "rssi": -65,
  "last_seen": "2024-01-15T14:30:00Z",
  "rid_verified": true
}
```

**Per-Drone Topic** (`wardragon/drone/<serial>`):
Same format, but dedicated topic per drone for easier subscriptions.

## Home Assistant Integration

### Auto-Discovery

When `mqtt_ha_enabled = true`, DragonSync automatically:

1. Publishes discovery messages to `homeassistant/device_tracker/...`
2. Creates device entities for each detected drone
3. Updates state and attributes in real-time

### Discovered Entities

For each drone, Home Assistant creates:

| Entity | Type | Description |
|--------|------|-------------|
| `device_tracker.wardragon_drone_<id>` | Device Tracker | Drone location on map |
| `sensor.wardragon_drone_<id>_altitude` | Sensor | Current altitude |
| `sensor.wardragon_drone_<id>_speed` | Sensor | Current speed |
| `sensor.wardragon_drone_<id>_rssi` | Sensor | Signal strength |

### Manual Configuration

If not using auto-discovery, add to Home Assistant `configuration.yaml`:

```yaml
mqtt:
  device_tracker:
    - name: "Drone ABC123"
      state_topic: "wardragon/drone/ABC123"
      json_attributes_topic: "wardragon/drone/ABC123"
      payload_home: "detected"
      payload_not_home: "lost"

  sensor:
    - name: "Drone ABC123 Altitude"
      state_topic: "wardragon/drone/ABC123"
      value_template: "{{ value_json.drone_alt }}"
      unit_of_measurement: "m"

    - name: "Drone ABC123 Speed"
      state_topic: "wardragon/drone/ABC123"
      value_template: "{{ value_json.speed }}"
      unit_of_measurement: "m/s"
```

## Dashboard Setup

### Lovelace Map Card

Display drones on a map:

```yaml
type: map
entities:
  - device_tracker.wardragon_drone_abc123
  - device_tracker.wardragon_drone_def456
default_zoom: 15
dark_mode: true
```

### Drone Status Card

Create a custom card for drone details:

```yaml
type: entities
title: Detected Drones
entities:
  - entity: device_tracker.wardragon_drone_abc123
    name: DJI Mavic 3
    secondary_info: last-changed
  - entity: sensor.wardragon_drone_abc123_altitude
    name: Altitude
  - entity: sensor.wardragon_drone_abc123_speed
    name: Speed
```

### Auto-Entities Card (Recommended)

Use auto-entities to show all detected drones dynamically:

```yaml
type: custom:auto-entities
card:
  type: entities
  title: Active Drones
filter:
  include:
    - domain: device_tracker
      entity_id: "*wardragon_drone*"
  exclude: []
sort:
  method: last_changed
  reverse: true
```

## Automation Examples

### Alert on Drone Detection

```yaml
automation:
  - alias: "Drone Detected Alert"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    action:
      - service: notify.mobile_app
        data:
          title: "Drone Detected!"
          message: >
            {{ trigger.payload_json.model }} detected
            ({{ trigger.payload_json.serial_number }})
```

### Log All Detections

```yaml
automation:
  - alias: "Log Drone Detections"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    action:
      - service: logbook.log
        data:
          name: "Drone Detection"
          message: >
            Drone {{ trigger.payload_json.model }}
            ({{ trigger.payload_json.serial_number }})
            at {{ trigger.payload_json.drone_lat }}, {{ trigger.payload_json.drone_lon }}
```

### Geofence Alert

Alert when a drone enters a defined area:

```yaml
automation:
  - alias: "Drone in Restricted Zone"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    condition:
      - condition: template
        value_template: >
          {{ trigger.payload_json.drone_lat | float > 40.710 and
             trigger.payload_json.drone_lat | float < 40.715 and
             trigger.payload_json.drone_lon | float > -74.010 and
             trigger.payload_json.drone_lon | float < -74.005 }}
    action:
      - service: notify.all
        data:
          title: "ALERT: Drone in Restricted Zone"
          message: >
            {{ trigger.payload_json.model }} detected in restricted area!
            Location: {{ trigger.payload_json.drone_lat }}, {{ trigger.payload_json.drone_lon }}
```

### RID Verification Alert

Alert only on FAA RID-verified drones:

```yaml
automation:
  - alias: "Verified Drone Alert"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    condition:
      - condition: template
        value_template: "{{ trigger.payload_json.rid_verified == true }}"
    action:
      - service: notify.mobile_app
        data:
          title: "Verified Drone"
          message: >
            FAA RID verified: {{ trigger.payload_json.serial_number }}
```

## MQTT Broker Setup

### Mosquitto (Recommended)

Install Mosquitto on a server or use Home Assistant's add-on:

```bash
# Install on Ubuntu/Debian
sudo apt install mosquitto mosquitto-clients

# Create password file
sudo mosquitto_passwd -c /etc/mosquitto/passwd wardragon

# Configure
sudo nano /etc/mosquitto/mosquitto.conf
```

Add to `mosquitto.conf`:

```
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

### Home Assistant Mosquitto Add-on

1. Go to Settings → Add-ons
2. Install "Mosquitto broker"
3. Configure users in the add-on configuration
4. Start the add-on

## Testing MQTT

### Subscribe to Topics

```bash
# Watch all WarDragon messages
mosquitto_sub -h <broker> -u <user> -P <pass> -t "wardragon/#" -v

# Watch specific drone
mosquitto_sub -h <broker> -t "wardragon/drone/ABC123" -v

# Watch all drones
mosquitto_sub -h <broker> -t "wardragon/drones" -v
```

### Verify Home Assistant Discovery

```bash
# Watch discovery messages
mosquitto_sub -h <broker> -t "homeassistant/#" -v
```

## TLS/SSL Configuration

For secure MQTT:

### Broker Configuration (Mosquitto)

```
listener 8883
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key
require_certificate false
```

### DragonSync Configuration

```ini
[SETTINGS]
mqtt_enabled = true
mqtt_host = 192.168.1.100
mqtt_port = 8883
mqtt_tls = true
mqtt_ca_file = /path/to/ca.crt
mqtt_certfile = /path/to/client.crt
mqtt_keyfile = /path/to/client.key
mqtt_tls_insecure = false
```

## Connection Resilience

DragonSync features async MQTT connection with automatic retries. If the MQTT broker is temporarily unavailable:

- CoT output continues working normally
- Other outputs (Lattice, HTTP API) remain operational
- MQTT connection automatically retries in the background
- Messages are not queued during disconnection

## Troubleshooting

### No Messages in Home Assistant

1. **Check MQTT broker connectivity**:
   ```bash
   mosquitto_pub -h <broker> -t "test" -m "hello"
   mosquitto_sub -h <broker> -t "test"
   ```

2. **Verify DragonSync MQTT config**:
   ```bash
   grep mqtt /home/dragon/DragonSync/config.ini
   journalctl -u dragonsync | grep -i mqtt
   ```

3. **Check Home Assistant MQTT integration**:
   - Settings → Devices & Services → MQTT → Configure

### Discovery Entities Not Appearing

1. **Restart Home Assistant** after first discovery
2. **Check discovery topic**:
   ```bash
   mosquitto_sub -h <broker> -t "homeassistant/device_tracker/#" -v
   ```

3. **Verify `mqtt_ha_enabled = true`** in DragonSync config

### Authentication Failed

1. Verify username/password in DragonSync config match broker
2. Check broker logs for authentication errors
3. Test with mosquitto_pub/sub using same credentials

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](analytics.md)
- [TAK Integration](tak-integration.md)
