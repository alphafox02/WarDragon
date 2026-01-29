# ZMQ Data Flows

WarDragon uses ZeroMQ (ZMQ) as the message transport layer between detection components and the central DragonSync application. This document details the message formats and data flows.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ZMQ Message Bus                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│    Publishers                              Subscribers                  │
│    ──────────                              ───────────                  │
│                                                                         │
│    dji_receiver.py ────┐                                               │
│    (tcp://*:5556)      │                                               │
│                        │                                               │
│    DroneID ────────────┼──────────────────► DragonSync                 │
│    (tcp://*:5557)      │                    (Subscribes to all)        │
│                        │                                               │
│    Sniffle/BT5 ────────┘                                               │
│    (tcp://*:5558)                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## ZMQ Pattern

WarDragon uses the **PUB/SUB** (Publisher/Subscriber) pattern:

- **Publishers**: Detection sources (dji_receiver, DroneID, etc.)
- **Subscribers**: DragonSync, external tools, analytics

This pattern allows:
- Multiple subscribers to the same data stream
- Decoupled components that can start/stop independently
- Easy addition of new detection sources or consumers

## Default Ports

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| DJI DroneID | 5556 | TCP | ANTSDR E200 DJI detections |
| DroneID | 5557 | TCP | WiFi/BT Remote ID |
| Sniffle BT5 | 5558 | TCP | Bluetooth 5 LR detections |
| DragonSync API | 8080 | HTTP | REST API (when enabled) |

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

# Subscribe to DJI DroneID
socket = context.socket(zmq.SUB)
socket.connect("tcp://127.0.0.1:5556")
socket.setsockopt_string(zmq.SUBSCRIBE, "")  # Subscribe to all

while True:
    message = socket.recv_string()
    data = json.loads(message)
    print(f"Received: {data['type']} - {data['data'].get('serial_number', 'N/A')}")
```

### Multi-Source Subscription

```python
import zmq
import json

context = zmq.Context()
poller = zmq.Poller()

# Subscribe to multiple sources
sources = {
    "dji": ("tcp://127.0.0.1:5556", context.socket(zmq.SUB)),
    "wifi": ("tcp://127.0.0.1:5557", context.socket(zmq.SUB)),
    "bt5": ("tcp://127.0.0.1:5558", context.socket(zmq.SUB)),
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

## Related Documentation

- [System Architecture](overview.md)
- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](../integration/analytics.md) - Subscribe to ZMQ for analytics
