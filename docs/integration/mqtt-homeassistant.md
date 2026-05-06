# MQTT & Home Assistant Integration

This guide documents every MQTT topic DragonSync publishes, the exact JSON schema on each topic, and how Home Assistant auto-discovery maps those payloads to entities.

There are two distinct audiences for this document:

- **Plain MQTT consumers** (Node-RED, custom dashboards, scripts, third-party apps): use the [Topic Reference](#topic-reference) and [Payload Reference](#payload-reference) sections — you only need the JSON schemas.
- **Home Assistant users**: use the [Home Assistant Reference](#home-assistant-reference) section — covers what discovery publishes, which entities appear, and how JSON fields back each sensor.

The two are independent. HA discovery is opt-in (`mqtt_ha_enabled`), and the underlying JSON payloads are the same regardless of whether HA is involved.

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

## Topic Reference

Every topic DragonSync may publish to. `<id>` is the drone serial / MAC / ID (e.g. `drone-F6Q8D244C00CL2KF`). `<seen_by>` is the WarDragon kit ID, slugified.

| Topic | Direction | Retained | Description |
|-------|-----------|----------|-------------|
| `wardragon/service/availability` | publish | yes | LWT — `online` while DragonSync is running, `offline` if it dies or shuts down cleanly |
| `wardragon/drones` | publish | configurable | Aggregate drone state (all detected drones, one JSON message per update) |
| `wardragon/drone/<id>` | publish | configurable | Per-drone state — full JSON, same schema as aggregate |
| `wardragon/drone/<id>/availability` | publish | yes | `online` when drone has a real position, `offline` when aged out or unknown |
| `wardragon/drone/<id>/state` | publish | yes | HA device_tracker textual state (`None` initially) |
| `wardragon/drone/<id>/pilot_attrs` | publish | yes | Pilot location attributes (`latitude`, `longitude`, `gps_accuracy`) for HA pilot tracker |
| `wardragon/drone/<id>/pilot_state` | publish | yes | HA pilot tracker textual state |
| `wardragon/drone/<id>/pilot_availability` | publish | yes | `online` when pilot location is known, `offline` otherwise |
| `wardragon/drone/<id>/home_attrs` | publish | yes | Home location attributes for HA home tracker |
| `wardragon/drone/<id>/home_state` | publish | yes | HA home tracker textual state |
| `wardragon/drone/<id>/home_availability` | publish | yes | `online` when home location is known, `offline` otherwise |
| `wardragon/aircraft` | publish | no | ADS-B aircraft state (one message per update; not retained — too high-volume) |
| `wardragon/signals` | publish | configurable | Aggregate FPV/RF signal alerts |
| `wardragon/signals/<seen_by>` | publish | configurable | Per-sensor signal feed (only when `mqtt_ha_signal_tracker = true`) |
| `wardragon/signals/<seen_by>/state` | publish | configurable | HA signal tracker textual state |
| `wardragon/signals/<seen_by>/availability` | publish | yes | `online` whenever a signal arrives |
| `wardragon/signals/availability` | publish | yes | Marks signals offline at shutdown |
| `wardragon/system/attrs` | publish | no | WarDragon kit telemetry (CPU, mem, GPS, SDR temps) |
| `wardragon/system/state` | publish | no | Kit textual state (`online` while publishing) |
| `wardragon/system/availability` | publish | yes | `online` while DragonSync publishes status, `offline` at shutdown |
| `homeassistant/sensor/<unique_id>/config` | publish | yes | HA sensor discovery configs (only when `mqtt_ha_enabled = true`) |
| `homeassistant/device_tracker/<unique_id>/config` | publish | yes | HA device_tracker discovery configs |

---

## Payload Reference

### Drone payload — `wardragon/drones` and `wardragon/drone/<id>`

Both topics carry **identical JSON**. The aggregate topic (`wardragon/drones`) emits one message per drone update; the per-drone topic carries only that drone's most recent state. Both are produced by `_drone_to_state` in `sinks/mqtt_sink.py`.

| Field | Type | Always present | Notes |
|-------|------|-----------------|-------|
| `id` | string | yes | Drone identifier (e.g. `drone-F6Q8D244C00CL2KF`, `drone-AABBCCDDEEFF` for BLE MAC, `drone-alert` for unknown OcuSync) |
| `description` | string | yes (may be empty) | Self-reported description, e.g. `DJI Mini 5 (O4)`, `DJI Mini 2 (O2)`, operator self-ID text |
| `track_type` | string | yes | Always `"drone"` |
| `lat` | float | yes | Latitude (degrees). `0.0` when no fix |
| `lon` | float | yes | Longitude (degrees) |
| `latitude` | float | yes | Mirror of `lat` (for HA `device_tracker` compatibility) |
| `longitude` | float | yes | Mirror of `lon` |
| `gps_accuracy` | float | yes | HA-style accuracy (meters); sourced from `horizontal_accuracy` |
| `alt` | float | yes | Altitude HAE / geodetic (meters) |
| `height` | float | yes | Altitude AGL (meters) |
| `pressure_altitude` | float \| null | no | Pressure altitude (when present in RID) |
| `speed` | float | yes | Ground speed (m/s) |
| `vspeed` | float | yes | Vertical speed (m/s) |
| `speed_multiplier` | float \| null | no | RID speed multiplier flag |
| `direction` | float | yes | Heading / course (degrees, 0–360) |
| `rssi` | float | yes | Received signal strength (dBm) |
| `pilot_lat` | float | yes | Pilot latitude. `0.0` when not detected |
| `pilot_lon` | float | yes | Pilot longitude |
| `home_lat` | float | yes | Home point latitude. `0.0` when not detected |
| `home_lon` | float | yes | Home point longitude |
| `mac` | string | yes (may be empty) | BLE/WiFi MAC address. Empty for OcuSync (RF-only) |
| `id_type` | string | yes (may be empty) | RID ID type, e.g. `Serial Number (ANSI/CTA-2063-A)`, `CAA Assigned Registration ID` |
| `ua_type` | int \| null | no | Numeric UA category (0–15 per ASTM F3411) |
| `ua_type_name` | string | yes (may be empty) | Human-readable UA category, e.g. `Helicopter or Multirotor` |
| `caa_id` | string | yes (may be empty) | CAA Assigned Registration ID, when present in a separate Basic ID |
| `operator_id_type` | string | yes (may be empty) | Operator ID type from RID Operator ID Message |
| `operator_id` | string | yes (may be empty) | Operator ID value |
| `op_status` | string | yes (may be empty) | RID operational status flag |
| `height_type` | string | yes (may be empty) | RID height reference type |
| `ew_dir` | string | yes (may be empty) | RID E/W direction segment flag |
| `timestamp` | string | yes (may be empty) | RID timestamp (typically seconds past hour) |
| `rid_timestamp` | string | yes | Mirrors `timestamp` if no separate value |
| `observed_at` | float \| null | no | Unix epoch seconds when DragonSync first received this update |
| `index` | int | yes | RID page index (BT/WiFi only) |
| `runtime` | int | yes | RID runtime counter |
| `seen_by` | string \| null | no | WarDragon kit ID that observed this drone |
| `last_update_time` | float \| null | no | Internal timestamp (seconds since epoch) of most recent update |
| `horizontal_accuracy` | string | yes (may be empty) | RID-spec accuracy string |
| `vertical_accuracy` | string | yes (may be empty) | RID-spec accuracy string |
| `baro_accuracy` | string | yes (may be empty) | RID-spec accuracy string |
| `speed_accuracy` | string | yes (may be empty) | RID-spec accuracy string |
| `timestamp_accuracy` | string | yes (may be empty) | RID-spec accuracy string |
| `freq` | float \| null | no | Detection frequency. May be Hz or MHz depending on source |
| `freq_mhz` | float \| null | no | Always MHz, normalised from `freq` |
| `transport` | string | yes (may be empty) | Link layer (`BT5`, `WiFi-NAN`, `ISM-FHSS`, etc.). Empty for OcuSync — receiver doesn't tag link layer |
| `rid_make` | string \| null | no | FAA RID lookup result: manufacturer |
| `rid_model` | string \| null | no | FAA RID lookup result: model |
| `rid_status` | string \| null | no | FAA RID lookup result: registration status |
| `rid_tracking` | string \| null | no | FAA RID lookup result: tracking ID |
| `rid_source` | string \| null | no | FAA RID lookup result: source (e.g. `local-cache`, `faa-api`) |
| `rid_lookup_attempted` | bool | yes | Whether FAA RID lookup was attempted |
| `rid_lookup_success` | bool | yes | Whether FAA RID lookup succeeded |

**Example payload** (DJI O4 detected by dji-receiver):

```json
{
  "id": "drone-F6Q8D244C00CL2KF",
  "description": "DJI Mini 5 (O4)",
  "track_type": "drone",
  "lat": 27.8002846,
  "lon": -82.6686196,
  "latitude": 27.8002846,
  "longitude": -82.6686196,
  "gps_accuracy": 0.0,
  "alt": 65531.0,
  "height": 0.0,
  "speed": 0.0,
  "vspeed": 0.0,
  "direction": 270.0,
  "rssi": -117.0,
  "pilot_lat": 27.8003992,
  "pilot_lon": -82.668568,
  "home_lat": 27.8002961,
  "home_lon": -82.6685738,
  "mac": "",
  "id_type": "Serial Number (ANSI/CTA-2063-A)",
  "ua_type": 0,
  "ua_type_name": "",
  "caa_id": "",
  "operator_id_type": "",
  "operator_id": "",
  "freq": 5756.5,
  "freq_mhz": 5756.5,
  "transport": "",
  "seen_by": "wardragon-G6PA14100J63",
  "rid_lookup_attempted": false,
  "rid_lookup_success": false
}
```

---

### Pilot location — `wardragon/drone/<id>/pilot_attrs`

Smaller JSON, only published when a pilot location is known. Used by HA's pilot device_tracker.

```json
{
  "latitude": 27.8003992,
  "longitude": -82.668568,
  "gps_accuracy": 0.0
}
```

### Home location — `wardragon/drone/<id>/home_attrs`

Same shape as pilot_attrs.

```json
{
  "latitude": 27.8002961,
  "longitude": -82.6685738,
  "gps_accuracy": 0.0
}
```

---

### System payload — `wardragon/system/attrs`

WarDragon kit telemetry. Produced by `publish_system` in `sinks/mqtt_sink.py`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Kit ID, e.g. `wardragon-G6PA14100J63` |
| `latitude` | float | Kit GPS latitude |
| `longitude` | float | Kit GPS longitude |
| `hae` | float | Kit altitude HAE (meters) |
| `cpu_usage` | float | CPU percent |
| `memory_total_mb` | float | Total RAM (MB) |
| `memory_available_mb` | float | Available RAM (MB) |
| `disk_total_mb` | float | Total disk (MB) |
| `disk_used_mb` | float | Used disk (MB) |
| `temperature_c` | float | Mainboard temperature (°C) |
| `uptime_s` | float | System uptime (seconds) |
| `pluto_temp_c` | float \| null | DragonSDR PlutoSDR temperature (°C) |
| `zynq_temp_c` | float \| null | DragonSDR Zynq SoC temperature (°C) |
| `speed_mps` | float | Kit ground speed (GPS) |
| `track_deg` | float | Kit course (degrees) |
| `gps_fix` | bool | GPS fix valid |
| `time_source` | string \| null | e.g. `gpsd`, `system` |
| `gpsd_time_utc` | string \| null | UTC time from gpsd |
| `updated` | int | Unix epoch seconds when published |

**Example:**

```json
{
  "id": "wardragon-G6PA14100J63",
  "latitude": 27.8003,
  "longitude": -82.6686,
  "hae": 5.2,
  "cpu_usage": 12.4,
  "memory_total_mb": 16384.0,
  "memory_available_mb": 9821.5,
  "disk_total_mb": 953869.7,
  "disk_used_mb": 142051.2,
  "temperature_c": 51.0,
  "uptime_s": 432189.0,
  "pluto_temp_c": 47.5,
  "zynq_temp_c": 53.0,
  "speed_mps": 0.0,
  "track_deg": 0.0,
  "gps_fix": true,
  "time_source": "gpsd",
  "gpsd_time_utc": "2026-04-30T19:38:55.000Z",
  "updated": 1746040735
}
```

---

### Aircraft payload — `wardragon/aircraft`

ADS-B aircraft. Produced by `_aircraft_to_state` in `sinks/mqtt_sink.py`. **Not retained** (aircraft turn over rapidly; one message per update).

| Field | Type | Notes |
|-------|------|-------|
| `icao` | string | ICAO 24-bit hex address |
| `callsign` | string | Flight number / callsign (may be empty) |
| `registration` | string | Tail / registration (may be empty) |
| `lat` | float | Latitude |
| `lon` | float | Longitude |
| `latitude` | float | Mirror of `lat` |
| `longitude` | float | Mirror of `lon` |
| `alt` | float | Altitude (feet, geometric preferred, falls back to barometric) |
| `altitude_ft` | float | Mirror of `alt` |
| `speed` | float | Ground speed (knots) |
| `speed_kt` | float | Mirror of `speed` |
| `track` | float | True track (degrees) |
| `heading` | float | Mirror of `track` |
| `vertical_rate` | float \| null | Barometric vertical rate (ft/min) |
| `squawk` | string | Mode A squawk code |
| `category` | string | ADS-B emitter category |
| `on_ground` | bool | Ground state |
| `nac_p` | float \| null | NACp (positional accuracy) |
| `nac_v` | float \| null | NACv (velocity accuracy) |
| `rssi` | float \| null | Receiver signal strength (dBFS) |
| `seen_by` | string \| null | WarDragon kit ID |
| `track_type` | string | Always `"aircraft"` |

---

### Signal payload — `wardragon/signals`

FPV / RF signal detections. Produced by `_signal_to_state`.

| Field | Type | Notes |
|-------|------|-------|
| `uid` | string | Stable detection UID |
| `signal_type` | string | e.g. `fpv`, `analog-video`, `digital-fhss` |
| `source` | string \| null | Source identifier (e.g. SDR name) |
| `callsign` | string \| null | Display name |
| `description` | string \| null | Free-text description |
| `center_hz` | float \| null | Centre frequency (Hz) |
| `bandwidth_hz` | float \| null | Bandwidth (Hz) |
| `pal` | float \| null | PAL detection confidence |
| `ntsc` | float \| null | NTSC detection confidence |
| `rssi` | float \| null | Signal strength (dBm) |
| `sensor_lat` | float \| null | Sensor latitude |
| `sensor_lon` | float \| null | Sensor longitude |
| `sensor_alt` | float \| null | Sensor altitude |
| `lat` | float | Detection latitude (sensor by default) |
| `lon` | float | Detection longitude |
| `latitude` | float | Mirror of `lat` |
| `longitude` | float | Mirror of `lon` |
| `alt` | float | Detection altitude |
| `gps_accuracy` | float | Detection radius (meters) — used as HA accuracy |
| `radius_m` | float | Mirror of `gps_accuracy` |
| `seen_by` | string \| null | WarDragon kit ID |
| `observed_at` | float \| null | Unix epoch seconds |

---

### Availability topics

All availability topics carry the literal string `online` or `offline` (no JSON). They use MQTT's retain flag so subscribers see the current state immediately on connect.

| Topic | Meaning |
|-------|---------|
| `wardragon/service/availability` | DragonSync process is running |
| `wardragon/system/availability` | Kit telemetry is being published |
| `wardragon/drone/<id>/availability` | Drone has a real (non-zero) position |
| `wardragon/drone/<id>/pilot_availability` | Pilot location known |
| `wardragon/drone/<id>/home_availability` | Home location known |
| `wardragon/signals/availability` | Signal feed active |
| `wardragon/signals/<seen_by>/availability` | Per-sensor signal feed active |

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

- For OcuSync drones: `transport` is intentionally empty (the receiver doesn't tag link layer for OcuSync). `description` should be populated with the detected DJI model and OcuSync generation (e.g. `DJI Mini 2 (O2)`, `DJI Mavic 3 (O3)`, `DJI Mini 5`). If empty, your `dji-receiver` may be on an older version — pull the latest from `alphafox02/antsdr_dji_droneid`.
- For BLE / WiFi RID drones: `description` carries the operator's self-ID text and may be empty if they didn't set one.
- `rid_make` / `rid_model` / `rid_status` only populate when FAA RID lookup succeeds (requires `rid_enabled = true` and a working RID database / API).

---

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](analytics.md)
- [TAK Integration](tak-integration.md)
