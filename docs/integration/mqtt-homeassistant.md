# MQTT & Home Assistant Integration

This guide covers configuring WarDragon to publish drone detections to MQTT brokers and integrate with Home Assistant for dashboards and automation.

## Overview

WarDragon can publish drone detections to MQTT in two formats:

1. **Standard JSON** - Per-drone topic with full telemetry
2. **Home Assistant Discovery** - Auto-configured entities in Home Assistant

## MQTT Configuration

### DragonSync Configuration

In `config.yaml`:

```yaml
outputs:
  mqtt:
    enabled: true
    broker: "192.168.1.100"      # Your MQTT broker IP
    port: 1883                    # Default MQTT port (8883 for TLS)
    username: ""                  # Optional authentication
    password: ""

    # Topic structure
    base_topic: "wardragon/drones"

    # Home Assistant auto-discovery
    homeassistant_discovery: true
    discovery_prefix: "homeassistant"

    # Optional TLS
    tls_enabled: false
    tls_ca: ""
```

### Topic Structure

When a drone is detected, WarDragon publishes to:

```
wardragon/drones/<drone_id>/state
wardragon/drones/<drone_id>/attributes
```

### Message Format

**State Topic** (`wardragon/drones/<id>/state`):
```json
{
  "state": "detected",
  "last_seen": "2024-01-15T14:30:00Z"
}
```

**Attributes Topic** (`wardragon/drones/<id>/attributes`):
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
  "last_seen": "2024-01-15T14:30:00Z"
}
```

## Home Assistant Integration

### Auto-Discovery

When `homeassistant_discovery: true`, DragonSync automatically:

1. Publishes discovery messages to `homeassistant/device_tracker/...`
2. Creates device entities for each detected drone
3. Updates state and attributes in real-time

### Discovered Entities

For each drone, Home Assistant creates:

| Entity | Type | Description |
|--------|------|-------------|
| `device_tracker.drone_<id>` | Device Tracker | Drone location on map |
| `sensor.drone_<id>_altitude` | Sensor | Current altitude |
| `sensor.drone_<id>_speed` | Sensor | Current speed |
| `sensor.drone_<id>_rssi` | Sensor | Signal strength |

### Manual Configuration

If not using auto-discovery, add to `configuration.yaml`:

```yaml
mqtt:
  device_tracker:
    - name: "Drone ABC123"
      state_topic: "wardragon/drones/ABC123/state"
      json_attributes_topic: "wardragon/drones/ABC123/attributes"
      payload_home: "detected"
      payload_not_home: "lost"

  sensor:
    - name: "Drone ABC123 Altitude"
      state_topic: "wardragon/drones/ABC123/attributes"
      value_template: "{{ value_json.drone_alt }}"
      unit_of_measurement: "m"

    - name: "Drone ABC123 Speed"
      state_topic: "wardragon/drones/ABC123/attributes"
      value_template: "{{ value_json.speed }}"
      unit_of_measurement: "m/s"
```

## Dashboard Setup

### Lovelace Map Card

Display drones on a map:

```yaml
type: map
entities:
  - device_tracker.drone_abc123
  - device_tracker.drone_def456
default_zoom: 15
dark_mode: true
```

### Drone Status Card

Create a custom card for drone details:

```yaml
type: entities
title: Detected Drones
entities:
  - entity: device_tracker.drone_abc123
    name: DJI Mavic 3
    secondary_info: last-changed
  - entity: sensor.drone_abc123_altitude
    name: Altitude
  - entity: sensor.drone_abc123_speed
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
      attributes:
        source: wardragon
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
        topic: "wardragon/drones/+/state"
        payload: "detected"
    action:
      - service: notify.mobile_app
        data:
          title: "Drone Detected!"
          message: "A drone has been detected by WarDragon"
```

### Log All Detections

```yaml
automation:
  - alias: "Log Drone Detections"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones/+/attributes"
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
        topic: "wardragon/drones/+/attributes"
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
mosquitto_sub -h <broker> -t "wardragon/drones/ABC123/#" -v
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

```yaml
outputs:
  mqtt:
    enabled: true
    broker: "192.168.1.100"
    port: 8883
    tls_enabled: true
    tls_ca: "/path/to/ca.crt"
```

## Troubleshooting

### No Messages in Home Assistant

1. **Check MQTT broker connectivity**:
   ```bash
   mosquitto_pub -h <broker> -t "test" -m "hello"
   mosquitto_sub -h <broker> -t "test"
   ```

2. **Verify DragonSync MQTT config**:
   ```bash
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

3. **Verify `homeassistant_discovery: true`** in DragonSync config

### Authentication Failed

1. Verify username/password in DragonSync config match broker
2. Check broker logs for authentication errors
3. Test with mosquitto_pub/sub using same credentials

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](analytics.md)
- [TAK Integration](tak-integration.md)
