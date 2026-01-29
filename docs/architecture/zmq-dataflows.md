# ZMQ Data Flows

WarDragon uses ZeroMQ (ZMQ) as the message transport layer between detection components and the central DragonSync application. This document details the message formats and data flows.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ZMQ Message Bus Architecture                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    Detection Sources              Decoder                 Application       │
│    ─────────────────              ───────                 ───────────       │
│                                                                             │
│    dji_receiver.py ──────┐                                                  │
│    (tcp://*:4221)        │                                                  │
│                          │                                                  │
│    bluetooth_receiver ───┼──────► zmq_decoder.py ──────► DragonSync        │
│    (tcp://*:4222)        │        (tcp://*:4224)         (subscribes)      │
│                          │                                                  │
│    wifi_receiver.py ─────┘                                                  │
│    (tcp://*:4223)                                                           │
│                                                                             │
│                                                                             │
│    FPV Detection ──────────────────────────────────────► DragonSync        │
│    (tcp://*:4226)                                        (fpv input)       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ZMQ Pattern

WarDragon uses the **PUB/SUB** (Publisher/Subscriber) pattern:

- **Publishers**: Detection sources (dji_receiver, bluetooth_receiver, wifi_receiver)
- **Decoder**: zmq_decoder.py collects from all sources and republishes unified data
- **Subscribers**: DragonSync, external tools, analytics applications

This pattern allows:
- Multiple subscribers to the same data stream
- Decoupled components that can start/stop independently
- Easy addition of new detection sources or consumers

## Port Assignments

### Detection Sources

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| DJI DroneID | 4221 | TCP | dji_receiver.py → ANTSDR E200 DJI detections |
| Bluetooth RID | 4222 | TCP | bluetooth_receiver.sh → DragonTooth/Sniffle BT5 LR |
| WiFi RID | 4223 | TCP | wifi_receiver.py → Panda Wireless detections |

### Decoder & Application

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| zmq_decoder.py | 4224 | TCP | Unified detection output (DragonSync subscribes here) |
| DragonSync Status | 4225 | TCP | System status messages |
| FPV Signals | 4226 | TCP | FPV drone signal detection (wardragon-fpv-detect) |
| DragonSync API | 8088 | HTTP | Read-only REST API for ATAK plugin |

## Data Flow

### Standard Detection Pipeline

1. **Detection Hardware** captures drone signals:
   - ANTSDR E200 → DJI Ocusync 2/3/4
   - Panda Wireless → WiFi Remote ID (802.11)
   - DragonTooth → Bluetooth 5 Long Range Remote ID

2. **Receiver Scripts** decode and publish raw detections:
   ```bash
   # DJI receiver
   python3 dji_receiver.py

   # Bluetooth receiver
   ./bluetooth_receiver.sh -b 2000000 -s /dev/ttyUSB0 --zmqsetting 127.0.0.1:4222

   # WiFi receiver
   ./wifi_receiver.py --interface wlan0 -z --zmqsetting 127.0.0.1:4223
   ```

3. **zmq_decoder.py** aggregates all sources:
   ```bash
   python3 zmq_decoder.py -z --zmqsetting 127.0.0.1:4224 \
     --zmqclients 127.0.0.1:4221,127.0.0.1:4222,127.0.0.1:4223 \
     --dji 127.0.0.1:4221
   ```

4. **DragonSync** subscribes to port 4224 and outputs to:
   - TAK multicast (239.2.3.1:6969)
   - TAK Server (TCP/TLS)
   - MQTT broker
   - Lattice API
   - HTTP API (port 8088)

## Message Format

All ZMQ messages are JSON-encoded strings. The general structure:

```json
{
  "type": "<detection_type>",
  "timestamp": "<ISO8601_timestamp>",
  "source": "<source_identifier>",
  "data": {
    // Type-specific fields
  }
}
```

## DJI DroneID Messages

Published by `dji_receiver.py` from ANTSDR E200 detections.

### Message Structure

```json
{
  "type": "dji_droneid",
  "timestamp": "2024-01-15T14:30:00Z",
  "source": "antsdr_e200",
  "data": {
    "serial_number": "ABC123DEF456",
    "drone_type": "Mavic 3",
    "drone_lat": 40.712800,
    "drone_lon": -74.006000,
    "drone_alt": 100.5,
    "drone_height": 50.0,
    "speed_horizontal": 15.2,
    "speed_vertical": 0.5,
    "heading": 270,
    "pilot_lat": 40.713000,
    "pilot_lon": -74.005500,
    "home_lat": 40.713000,
    "home_lon": -74.005500,
    "frequency": 2437000000,
    "rssi": -65,
    "protocol": "ocusync3"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| serial_number | string | Drone serial number |
| drone_type | string | Drone model/type |
| drone_lat | float | Drone latitude (WGS84) |
| drone_lon | float | Drone longitude (WGS84) |
| drone_alt | float | Altitude MSL (meters) |
| drone_height | float | Height AGL (meters) |
| speed_horizontal | float | Ground speed (m/s) |
| speed_vertical | float | Vertical speed (m/s) |
| heading | int | Heading (degrees, 0-359) |
| pilot_lat | float | Pilot/controller latitude |
| pilot_lon | float | Pilot/controller longitude |
| home_lat | float | Home point latitude |
| home_lon | float | Home point longitude |
| frequency | int | Detection frequency (Hz) |
| rssi | int | Signal strength (dBm) |
| protocol | string | Ocusync version |

## Open Drone ID Messages

Published by DroneID for WiFi and Bluetooth Remote ID broadcasts.

### Message Structure

```json
{
  "type": "open_drone_id",
  "timestamp": "2024-01-15T14:30:00Z",
  "source": "droneid_wifi",
  "data": {
    "mac_address": "AA:BB:CC:DD:EE:FF",
    "id_type": "serial_number",
    "uas_id": "SN123456789",
    "uas_type": "helicopter",
    "lat": 40.712800,
    "lon": -74.006000,
    "alt_geodetic": 150.0,
    "alt_baro": 148.5,
    "height": 50.0,
    "height_type": "above_takeoff",
    "horizontal_speed": 10.5,
    "vertical_speed": 0.0,
    "heading": 180,
    "horizontal_accuracy": 3,
    "vertical_accuracy": 5,
    "baro_accuracy": 2,
    "speed_accuracy": 1,
    "timestamp_accuracy": 0.1,
    "operator_id": "OP123456",
    "operator_lat": 40.713000,
    "operator_lon": -74.005500,
    "area_count": 1,
    "area_radius": 100,
    "area_ceiling": 200,
    "area_floor": 0,
    "category": "eu_open",
    "class": "eu_class_1",
    "rssi": -70,
    "channel": 6
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| mac_address | string | Broadcast MAC address |
| id_type | string | ID type (serial_number, registration_id, utm_id, etc.) |
| uas_id | string | UAS identifier |
| uas_type | string | UAS type (helicopter, multirotor, aeroplane, etc.) |
| lat/lon | float | Position (WGS84) |
| alt_geodetic | float | Geodetic altitude (meters) |
| alt_baro | float | Barometric altitude (meters) |
| height | float | Height above reference |
| height_type | string | Height reference (above_takeoff, agl) |
| horizontal_speed | float | Ground speed (m/s) |
| vertical_speed | float | Climb/descent rate (m/s) |
| heading | int | Track direction (degrees) |
| *_accuracy | int/float | Accuracy codes per ASTM spec |
| operator_id | string | Operator/pilot ID |
| operator_lat/lon | float | Operator position |
| category/class | string | EU drone category/class |
| rssi | int | Signal strength (dBm) |
| channel | int | WiFi channel (if WiFi source) |

## Bluetooth 5 LR Messages

Published by Sniffle-based detection for BT5 Long Range Remote ID.

### Message Structure

```json
{
  "type": "bt5_remote_id",
  "timestamp": "2024-01-15T14:30:00Z",
  "source": "sniffle_bt5",
  "data": {
    "mac_address": "11:22:33:44:55:66",
    "id_type": "serial_number",
    "uas_id": "BT987654321",
    "lat": 40.712800,
    "lon": -74.006000,
    "alt": 100.0,
    "height": 50.0,
    "speed": 12.0,
    "heading": 90,
    "operator_lat": 40.713000,
    "operator_lon": -74.005500,
    "rssi": -75,
    "phy": "LE_CODED_S8"
  }
}
```

### BT5-Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| phy | string | BT5 PHY type (LE_CODED_S8, LE_CODED_S2, LE_1M) |

## Subscribing to ZMQ Streams

### Python Example

```python
import zmq
import json

context = zmq.Context()

# Subscribe to unified detection output (zmq_decoder.py)
socket = context.socket(zmq.SUB)
socket.connect("tcp://127.0.0.1:4224")
socket.setsockopt_string(zmq.SUBSCRIBE, "")  # Subscribe to all

while True:
    message = socket.recv_string()
    data = json.loads(message)
    print(f"Received: {data['type']} - {data['data'].get('serial_number', 'N/A')}")
```

### Direct Source Subscription

For more granular control, subscribe directly to individual sources:

```python
import zmq
import json

context = zmq.Context()
poller = zmq.Poller()

# Subscribe to individual detection sources
sources = {
    "dji": ("tcp://127.0.0.1:4221", context.socket(zmq.SUB)),
    "bt5": ("tcp://127.0.0.1:4222", context.socket(zmq.SUB)),
    "wifi": ("tcp://127.0.0.1:4223", context.socket(zmq.SUB)),
}

for name, (addr, sock) in sources.items():
    sock.connect(addr)
    sock.setsockopt_string(zmq.SUBSCRIBE, "")
    poller.register(sock, zmq.POLLIN)

while True:
    socks = dict(poller.poll(timeout=1000))
    for name, (addr, sock) in sources.items():
        if sock in socks:
            message = sock.recv_string()
            data = json.loads(message)
            print(f"[{name}] {data['type']}: {json.dumps(data['data'], indent=2)}")
```

## Repository References

- **DroneID**: [github.com/alphafox02/DroneID](https://github.com/alphafox02/DroneID) - WiFi/BT receivers and zmq_decoder
- **antsdr_dji_droneid**: [github.com/alphafox02/antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid) - DJI firmware and dji_receiver
- **DragonSync**: [github.com/alphafox02/DragonSync](https://github.com/alphafox02/DragonSync) - Main application
- **wardragon-fpv-detect**: [github.com/alphafox02/wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) - FPV signal detection

## Related Documentation

- [System Architecture](overview.md)
- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](../integration/analytics.md) - Subscribe to ZMQ for analytics
