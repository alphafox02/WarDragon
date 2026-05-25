# MQTT & Home Assistant Integration

This guide covers operator-facing MQTT setup: broker configuration, Home Assistant auto-discovery, dashboards, automations, and troubleshooting.

> **Looking for the JSON schema or full topic list?** See the canonical reference: [DragonSync MQTT Payload Schema](https://github.com/alphafox02/DragonSync/blob/main/docs/mqtt-schema.md). It documents every topic and field and is updated alongside the code. This guide covers everything *around* the wire format — config, HA, broker setup, automations.

HA discovery is opt-in (`mqtt_ha_enabled`); the underlying JSON payloads are the same regardless of whether HA is involved.

---

## Configuration

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

# Aggregate drone topic (all drones, single topic)
mqtt_topic = wardragon/drones

# Per-drone topics (wardragon/drone/<id>)
mqtt_per_drone_enabled = true
mqtt_per_drone_base = wardragon/drone

# ADS-B aircraft (when adsb_enabled = true)
mqtt_aircraft_enabled = false
mqtt_aircraft_topic = wardragon/aircraft

# FPV/RF signal alerts (when fpv_enabled = true)
mqtt_signals_enabled = false
mqtt_signals_topic = wardragon/signals

# Home Assistant auto-discovery (requires mqtt_per_drone_enabled = true)
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

# Retain published state messages
mqtt_retain = true
```

> **Note:** Per-drone topics are required for Home Assistant discovery. The aggregate topic alone is sufficient for plain MQTT consumers but cannot back HA entities (one entity needs a stable, dedicated topic).

---

## Topics & Payloads at a Glance

> **Breaking change for MQTT subscribers (DragonSync v2.0+):** kit-level
> system and service topics are now **kit-scoped** so multiple kits can
> share one broker without colliding. The unscoped legacy forms
> (`wardragon/system/attrs`, `wardragon/service/availability`, etc.) are
> no longer published. If you subscribe to MQTT from a custom dashboard,
> Node-RED, scripts, or any tool, see the [Subscription Migration](#subscription-migration)
> section below. Drone, aircraft, and signal subscribers are unaffected.

Most useful topics for operators:

| Topic | Purpose |
|-------|---------|
| `wardragon/drones` | Aggregate drone stream — every drone update lands here |
| `wardragon/drone/<id>` | Per-drone state (required for HA discovery) |
| `wardragon/system/<kit_id>/attrs` | Kit telemetry (CPU, mem, GPS, SDR temps), scoped per kit |
| `wardragon/system/<kit_id>/availability` | `online`/`offline` per kit |
| `wardragon/aircraft` | ADS-B aircraft (when enabled) |
| `wardragon/signals` | FPV/RF signal alerts (when enabled) |
| `wardragon/service/<kit_id>/availability` | DragonSync process online/offline (LWT), scoped per kit |
| `homeassistant/...` | HA auto-discovery configs (when `mqtt_ha_enabled`) |

`<kit_id>` is the WarDragon kit's identifier (e.g. `wardragon-G6PA14100J63`). One kit per broker → one set of these topics. Multiple kits on the same broker → one set per kit, no collisions.

### Subscription Migration

Three ways to subscribe to kit-level topics after the v2.0 schema change:

**Wildcard (recommended for most consumers)** — works for any number of kits, today or in the future:

```
wardragon/system/+/attrs           (was: wardragon/system/attrs)
wardragon/system/+/state           (was: wardragon/system/state)
wardragon/system/+/availability    (was: wardragon/system/availability)
wardragon/service/+/availability   (was: wardragon/service/availability)
```

The `+` matches any single topic segment. Single-kit operators see one stream of messages (same as before); multi-kit operators see one message per kit cleanly distinguished by the kit ID in the topic path.

**Pin a specific kit** — when you only care about one:

```
wardragon/system/wardragon-G6PA14100J63/attrs
```

**Catch-all `wardragon/#`** — receives every topic the kit publishes. If your consumer was already on `wardragon/#`, **no change is needed**. Best for logging, archival, debug tools, and any consumer that already filters by topic in its own code.

Drone, aircraft, and signal topics are **unchanged** from v1 — no subscription updates needed for those.

A drone payload looks like:

```json
{
  "id": "drone-F6Q8D244C00CL2KF",
  "description": "DJI O4 (Decrypted)",
  "lat": 27.8002846,
  "lon": -82.6686196,
  "alt": 65531.0,
  "speed": 0.0,
  "direction": 270.0,
  "rssi": -117.0,
  "id_type": "Serial Number (ANSI/CTA-2063-A)",
  "freq_mhz": 5756.5,
  "transport": "",
  "seen_by": "wardragon-G6PA14100J63",
  "track_type": "drone"
}
```

> **Full schema reference:** every topic, every field, types, always-present vs. conditional notes, plus signal/aircraft/system payloads — see [DragonSync MQTT Payload Schema](https://github.com/alphafox02/DragonSync/blob/main/docs/mqtt-schema.md). That doc lives alongside the code that produces these payloads and is the source of truth.

---

## Home Assistant Reference

When `mqtt_ha_enabled = true` and `mqtt_per_drone_enabled = true`, DragonSync publishes [MQTT discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery) configs that auto-create entities in HA. The state topics are the same JSON topics documented above; HA discovery adds the metadata HA needs to render entities.

### Discovery topic structure

| Topic pattern | Purpose |
|---------------|---------|
| `homeassistant/device_tracker/wardragon_drone_<id>/config` | Main drone tracker |
| `homeassistant/device_tracker/wardragon_drone_<id>_pilot/config` | Pilot location tracker |
| `homeassistant/device_tracker/wardragon_drone_<id>_home/config` | Home location tracker |
| `homeassistant/sensor/wardragon_drone_<id>_<suffix>/config` | Per-drone telemetry sensors |
| `homeassistant/device_tracker/wardragon_drone_system/config` | WarDragon kit GPS tracker |
| `homeassistant/sensor/wardragon_drone_system_<suffix>/config` | WarDragon kit telemetry sensors |
| `homeassistant/device_tracker/wardragon_signal_signal_latest_<seen_by>/config` | Signal alert tracker (when `mqtt_ha_signal_tracker = true`) |

All discovery messages are retained, so HA picks them up immediately on (re)connect.

### Per-drone entities created

For each detected drone, HA creates a single device with these entities:

| Entity | Class | Source field | Notes |
|--------|-------|--------------|-------|
| `device_tracker.<id>` | device_tracker | `latitude`, `longitude` | Drone position on map |
| `device_tracker.pilot-<tail>` | device_tracker | pilot_attrs JSON | Pilot location |
| `device_tracker.home-<tail>` | device_tracker | home_attrs JSON | Home location |
| `sensor.<id>_lat` | sensor (°) | `lat` | |
| `sensor.<id>_lon` | sensor (°) | `lon` | |
| `sensor.<id>_alt` | sensor (m, distance) | `alt` | Altitude HAE |
| `sensor.<id>_speed` | sensor (m/s, speed) | `speed` | |
| `sensor.<id>_vspeed` | sensor (m/s) | `vspeed` | Vertical speed |
| `sensor.<id>_height` | sensor (m) | `height` | AGL |
| `sensor.<id>_dir` | sensor (°) | `direction` | Course |
| `sensor.<id>_pilot_lat` | sensor (°) | `pilot_lat` | |
| `sensor.<id>_pilot_lon` | sensor (°) | `pilot_lon` | |
| `sensor.<id>_home_lat` | sensor (°) | `home_lat` | |
| `sensor.<id>_home_lon` | sensor (°) | `home_lon` | |
| `sensor.<id>_rssi` | sensor (dBm, signal_strength) | `rssi` | |
| `sensor.<id>_freq` | sensor (MHz) | `freq_mhz` | |
| `sensor.<id>_ua_type` | sensor | `ua_type_name` | |
| `sensor.<id>_op_id` | sensor | `operator_id` | |
| `sensor.<id>_transport` | sensor | `transport` | Link layer (empty for OcuSync) |
| `sensor.<id>_description` | sensor | `description` | Self-ID text |
| `sensor.<id>_main` | sensor | `description` | Friendly device label |

> **Tail convention:** `<tail>` is the drone ID with any leading `drone-` stripped. So a drone with `id = drone-ABC123` produces a pilot entity named `pilot-ABC123`.

### WarDragon kit entities created

A single device named "WarDragon System" with these entities:

| Entity | Class | Source field |
|--------|-------|--------------|
| `device_tracker.wardragon_pro` | device_tracker | system/attrs JSON |
| `sensor.cpu_usage` | sensor (%) | `cpu_usage` |
| `sensor.memory_available` | sensor (MB) | `memory_available_mb` |
| `sensor.memory_total` | sensor (MB) | `memory_total_mb` |
| `sensor.disk_used` | sensor (MB) | `disk_used_mb` |
| `sensor.disk_total` | sensor (MB) | `disk_total_mb` |
| `sensor.system_temp` | sensor (°C, temperature) | `temperature_c` |
| `sensor.uptime` | sensor (h) | `uptime_s` (converted from seconds) |
| `sensor.ground_speed` | sensor (m/s, speed) | `speed_mps` |
| `sensor.course` | sensor (°) | `track_deg` |
| `sensor.pluto_temp` | sensor (°C, temperature) | `pluto_temp_c` |
| `sensor.zynq_temp` | sensor (°C, temperature) | `zynq_temp_c` |

### Signal alert entities

Only published when `mqtt_signals_enabled = true` **and** `mqtt_ha_signal_tracker = true`. One device_tracker per source sensor (`<seen_by>`):

| Entity | Source |
|--------|--------|
| `device_tracker.signal_alert_<seen_by>` | `wardragon/signals/<seen_by>` JSON |

ADS-B aircraft do **not** get HA entities — too high-volume. Subscribe to `wardragon/aircraft` directly if you need them.

### Manual configuration (without auto-discovery)

If you prefer manual control, here's an example referencing the real field names:

```yaml
mqtt:
  device_tracker:
    - name: "Drone F6Q8D244C00CL2KF"
      state_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF/state"
      json_attributes_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF"
      payload_home: "home"
      payload_not_home: "not_home"
      availability_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF/availability"
      payload_available: "online"
      payload_not_available: "offline"

  sensor:
    - name: "Drone Altitude"
      state_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF"
      value_template: "{{ value_json.alt }}"
      unit_of_measurement: "m"

    - name: "Drone Speed"
      state_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF"
      value_template: "{{ value_json.speed }}"
      unit_of_measurement: "m/s"

    - name: "Drone Description"
      state_topic: "wardragon/drone/drone-F6Q8D244C00CL2KF"
      value_template: "{{ value_json.description }}"
```

---

## Dashboard Setup

### Lovelace Map Card

```yaml
type: map
entities:
  - device_tracker.drone_f6q8d244c00cl2kf
  - device_tracker.pilot_f6q8d244c00cl2kf
default_zoom: 15
dark_mode: true
```

### Drone Status Card

```yaml
type: entities
title: Detected Drone
entities:
  - entity: sensor.drone_f6q8d244c00cl2kf_main
    name: Description
  - entity: sensor.drone_f6q8d244c00cl2kf_alt
    name: Altitude
  - entity: sensor.drone_f6q8d244c00cl2kf_speed
    name: Speed
  - entity: sensor.drone_f6q8d244c00cl2kf_rssi
    name: Signal
  - entity: sensor.drone_f6q8d244c00cl2kf_freq
    name: Frequency
```

### Auto-Entities Card (Recommended)

Show all detected drones dynamically:

```yaml
type: custom:auto-entities
card:
  type: entities
  title: Active Drones
filter:
  include:
    - domain: device_tracker
      entity_id: "*drone*"
sort:
  method: last_changed
  reverse: true
```

---

## Automation Examples

The field names below match the real JSON schema documented above.

### Alert on drone detection

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
            {{ trigger.payload_json.description or 'Unknown drone' }}
            ({{ trigger.payload_json.id }})
            at {{ trigger.payload_json.lat }}, {{ trigger.payload_json.lon }}
```

### Alert only on DJI drones

```yaml
automation:
  - alias: "DJI Drone Alert"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    condition:
      - condition: template
        value_template: >
          {{ 'DJI' in (trigger.payload_json.description or '') }}
    action:
      - service: notify.mobile_app
        data:
          title: "DJI Drone Detected"
          message: "{{ trigger.payload_json.description }} ({{ trigger.payload_json.id }})"
```

### Geofence alert

```yaml
automation:
  - alias: "Drone in Restricted Zone"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    condition:
      - condition: template
        value_template: >
          {{ trigger.payload_json.lat | float > 40.710 and
             trigger.payload_json.lat | float < 40.715 and
             trigger.payload_json.lon | float > -74.010 and
             trigger.payload_json.lon | float < -74.005 }}
    action:
      - service: notify.all
        data:
          title: "ALERT: Drone in Restricted Zone"
          message: >
            {{ trigger.payload_json.description or 'Unknown' }}
            at {{ trigger.payload_json.lat }}, {{ trigger.payload_json.lon }}
```

### FAA RID-verified alert

```yaml
automation:
  - alias: "RID Verified Drone"
    trigger:
      - platform: mqtt
        topic: "wardragon/drones"
    condition:
      - condition: template
        value_template: "{{ trigger.payload_json.rid_lookup_success == true }}"
    action:
      - service: notify.mobile_app
        data:
          title: "RID Verified"
          message: >
            {{ trigger.payload_json.rid_make }} {{ trigger.payload_json.rid_model }}
            ({{ trigger.payload_json.id }})
```

---

## MQTT Broker Setup

### Mosquitto

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

1. Settings → Add-ons → Install "Mosquitto broker"
2. Configure users in the add-on configuration
3. Start the add-on

---

## Testing MQTT

### Subscribe to topics

```bash
# Watch every WarDragon message
mosquitto_sub -h <broker> -u <user> -P <pass> -t "wardragon/#" -v

# Watch a specific drone
mosquitto_sub -h <broker> -t "wardragon/drone/drone-F6Q8D244C00CL2KF" -v

# Watch the aggregate drone feed
mosquitto_sub -h <broker> -t "wardragon/drones" -v

# Watch the kit
mosquitto_sub -h <broker> -t "wardragon/system/#" -v
```

### Verify Home Assistant discovery

```bash
mosquitto_sub -h <broker> -t "homeassistant/#" -v
```

---

## TLS / SSL

### Broker (Mosquitto)

```
listener 8883
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key
require_certificate false
```

### DragonSync

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

---

## Connection Resilience

DragonSync uses async MQTT connect with automatic retry. If the broker is temporarily unavailable:

- CoT output continues normally
- Other outputs (Lattice, HTTP API) remain operational
- MQTT reconnects in the background (2–30s backoff)
- Messages **are not queued** during disconnection — anything published while offline is dropped

---

## Troubleshooting

### No messages appear in Home Assistant

1. Verify broker connectivity:
   ```bash
   mosquitto_pub -h <broker> -t "test" -m "hello"
   mosquitto_sub -h <broker> -t "test"
   ```

2. Check DragonSync MQTT config:
   ```bash
   grep mqtt /home/dragon/DragonSync/config.ini
   journalctl -u dragonsync | grep -i mqtt
   ```

3. Check the HA MQTT integration: Settings → Devices & Services → MQTT.

### Discovery entities don't appear

1. Verify `mqtt_ha_enabled = true` **and** `mqtt_per_drone_enabled = true` (HA discovery requires per-drone topics).
2. Watch the discovery topic:
   ```bash
   mosquitto_sub -h <broker> -t "homeassistant/#" -v
   ```
3. Restart Home Assistant after the first discovery message.

### Authentication failed

1. Verify username/password in DragonSync config match broker.
2. Check broker logs for auth errors.
3. Test credentials with `mosquitto_pub` / `mosquitto_sub`.

### Drone shown but no description / transport / RID metadata

- For OcuSync drones: `transport` is intentionally empty (the receiver doesn't tag link layer for OcuSync). `description` should be populated with the detected DJI model and OcuSync generation (e.g. `DJI Mini 2 (O2)`, `DJI Mavic 3 (O3)`, `DJI Mini 5`). If empty, your `dji-receiver` may be on an older version — pull the latest from `alphafox02/dragonsdr_dji_droneid`.
- For BLE / WiFi RID drones: `description` carries the operator's self-ID text and may be empty if they didn't set one.
- `rid_make` / `rid_model` / `rid_status` only populate when FAA RID lookup succeeds (requires `rid_enabled = true` and a working RID database / API).

---

## Related Documentation

- [DragonSync MQTT Payload Schema](https://github.com/alphafox02/DragonSync/blob/main/docs/mqtt-schema.md) — canonical wire-format reference (every topic, every field)
- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](analytics.md)
- [TAK Integration](tak-integration.md)
