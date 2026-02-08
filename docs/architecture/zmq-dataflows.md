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

All ZMQ messages are JSON-encoded. Messages follow the **ASTM F3411 Open Drone ID** structure with message blocks for different data types.

> **Note**: The exact message format depends on the upstream receiver (droneid-go, antsdr_dji_droneid). Refer to those repositories for authoritative field documentation.

### Two Input Formats

DragonSync's parser handles two formats:

1. **List format** (DJI/AntSDR): Array of message block dicts
2. **Dict format** (ESP32/Sniffle): Single dict with message blocks

## Message Blocks

Both formats contain these ASTM F3411-style message blocks:

### Basic ID

Drone identification information:

```json
{
  "Basic ID": {
    "id_type": "Serial Number (ANSI/CTA-2063-A)",
    "id": "ABC123DEF456",
    "ua_type": 2,
    "MAC": "AA:BB:CC:DD:EE:FF",
    "RSSI": -65
  }
}
```

| Field | Description |
|-------|-------------|
| id_type | "Serial Number (ANSI/CTA-2063-A)" or "CAA Assigned Registration ID" |
| id | Drone serial number or registration |
| ua_type | UAS type code (0-15, see ASTM spec) |
| MAC | Broadcast MAC address |
| RSSI | Signal strength (dBm) |

### Location/Vector Message

Position and movement data:

```json
{
  "Location/Vector Message": {
    "latitude": 40.7128,
    "longitude": -74.006,
    "geodetic_altitude": 100.5,
    "height_agl": 50.0,
    "speed": 15.2,
    "vert_speed": 0.5,
    "direction": 270,
    "op_status": "Airborne",
    "height_type": "Above Takeoff",
    "horizontal_accuracy": "< 3m",
    "vertical_accuracy": "< 15m",
    "timestamp": 1234
  }
}
```

### System Message

Operator/pilot location:

```json
{
  "System Message": {
    "latitude": 40.713,
    "longitude": -74.0055,
    "operator_lat": 40.713,
    "operator_lon": -74.0055,
    "home_lat": 40.713,
    "home_lon": -74.0055
  }
}
```

### Operator ID Message

Operator identification:

```json
{
  "Operator ID Message": {
    "operator_id_type": "Operator ID",
    "operator_id": "OP123456"
  }
}
```

### Self-ID Message

Free-text description:

```json
{
  "Self-ID Message": {
    "text": "Survey flight"
  }
}
```

### Frequency Message (DJI Only)

DJI-specific frequency information:

```json
{
  "Frequency Message": {
    "frequency": 2437000000
  }
}
```

## Example: Complete DJI Message (List Format)

```json
[
  {
    "MAC": "AA:BB:CC:DD:EE:FF",
    "RSSI": -65,
    "Basic ID": {
      "id_type": "Serial Number (ANSI/CTA-2063-A)",
      "id": "ABC123DEF456",
      "ua_type": 2
    },
    "Location/Vector Message": {
      "latitude": 40.7128,
      "longitude": -74.006,
      "geodetic_altitude": 100.5,
      "height_agl": 50.0,
      "speed": 15.2,
      "vert_speed": 0.5
    },
    "System Message": {
      "latitude": 40.713,
      "longitude": -74.0055,
      "home_lat": 40.713,
      "home_lon": -74.0055
    },
    "Frequency Message": {
      "frequency": 2437000000
    }
  }
]
```

## Example: BT5 Message (Dict Format with AUX_ADV_IND)

```json
{
  "index": 1,
  "runtime": 12345,
  "AUX_ADV_IND": {
    "rssi": -75
  },
  "aext": {
    "AdvA": "11:22:33:44:55:66 random"
  },
  "Basic ID": {
    "id_type": "Serial Number (ANSI/CTA-2063-A)",
    "id": "BT987654321",
    "ua_type": 2
  },
  "Location/Vector Message": {
    "latitude": 40.7128,
    "longitude": -74.006,
    "geodetic_altitude": 100.0,
    "height_agl": 50.0,
    "speed": 12.0
  }
}
```

## FPV Signal Messages

FPV detection (port 4226) uses the same message block structure. FPV alerts include a custom "Signal Info" block with detection-specific data.

**Repository**: [github.com/alphafox02/wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect)

> **Note**: FPV detection requires additional hardware (SDR) and the optional `suscli fpvdet` plugin for signal confirmation. This feature is experimental.

### FPV Message Structure

```json
[
  {
    "Basic ID": {
      "id_type": "Serial Number (ANSI/CTA-2063-A)",
      "id": "fpv-alert-5800.000MHz",
      "description": "FPV Signal"
    }
  },
  {
    "Location/Vector Message": {
      "latitude": 40.7128,
      "longitude": -74.006,
      "geodetic_altitude": 100.0,
      "height_agl": 0.0,
      "speed": 0.0,
      "vert_speed": 0.0
    }
  },
  {
    "Self-ID Message": {
      "text": "FPV alert (energy)"
    }
  },
  {
    "Frequency Message": {
      "frequency": 5800000000
    }
  },
  {
    "Signal Info": {
      "source": "energy",
      "center_hz": 5800000000,
      "bandwidth_hz": 6000000,
      "pal_conf": 85.5,
      "ntsc_conf": 12.3
    }
  }
]
```

### FPV-Specific Fields

| Field | Type | Description |
|-------|------|-------------|
| source | string | Detection source ("energy" or "confirm") |
| center_hz | float | Center frequency in Hz |
| bandwidth_hz | float | Detected signal bandwidth in Hz |
| pal_conf | float | PAL video confidence (0-100) |
| ntsc_conf | float | NTSC video confidence (0-100) |

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
    # Data is a list of message blocks
    for block in data:
        if "Basic ID" in block:
            print(f"Drone ID: {block['Basic ID'].get('id', 'unknown')}")
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
    "fpv": ("tcp://127.0.0.1:4226", context.socket(zmq.SUB)),
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
            # Extract drone ID from Basic ID block
            for block in data:
                if "Basic ID" in block:
                    print(f"[{name}] ID: {block['Basic ID'].get('id')}")
```

## Repository References

- **droneid-go**: [github.com/alphafox02/droneid-go](https://github.com/alphafox02/droneid-go) - WiFi/BT Remote ID receiver
- **antsdr_dji_droneid**: [github.com/alphafox02/antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid) - DJI firmware and dji_receiver
- **DragonSync**: [github.com/alphafox02/DragonSync](https://github.com/alphafox02/DragonSync) - Main application
- **wardragon-fpv-detect**: [github.com/alphafox02/wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) - FPV signal detection

## Related Documentation

- [System Architecture](overview.md)
- [DragonSync Configuration](../software/dragonsync.md)
- [WarDragonAnalytics](../integration/analytics.md) - Subscribe to ZMQ for analytics
