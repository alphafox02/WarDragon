# System Architecture Overview

The WarDragon system is built on a modular, message-driven architecture that allows flexible integration with multiple detection sources and output destinations.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DETECTION LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   ANTSDR E200   │  │  Panda Wireless │  │   DragonTooth   │             │
│  │                 │  │                 │  │                 │             │
│  │  DJI DroneID    │  │  WiFi Remote ID │  │  BT5 LR RID     │             │
│  │  Ocusync 2/3/4  │  │  2.4/5 GHz      │  │  Bluetooth 5    │             │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘             │
│           │                    │                    │                       │
│           │ dji_receiver.py    │ droneid-go         │ Sniffle               │
│           │                    │                    │                       │
│           ▼                    ▼                    ▼                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ZMQ MESSAGE BUS                             │   │
│  │                                                                     │   │
│  │   • JSON-formatted messages                                         │   │
│  │   • Publisher/Subscriber pattern                                    │   │
│  │   • Decoupled components                                            │   │
│  └─────────────────────────────────┬───────────────────────────────────┘   │
│                                    │                                        │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PROCESSING LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ┌─────────────────────┐                            │
│                         │     DragonSync      │                            │
│                         │                     │                            │
│                         │  • Stream Merging   │                            │
│                         │  • Deduplication    │                            │
│                         │  • Rate Limiting    │                            │
│                         │  • Data Transform   │                            │
│                         │  • Track Management │                            │
│                         │                     │                            │
│                         └──────────┬──────────┘                            │
│                                    │                                        │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            OUTPUT LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  TAK/ATAK    │  │    MQTT      │  │   Lattice    │  │  HTTP API    │   │
│  │              │  │              │  │              │  │              │   │
│  │ CoT Messages │  │ JSON + HA    │  │   Anduril    │  │ Companion    │   │
│  │ Multicast    │  │ Discovery    │  │ Integration  │  │ Apps         │   │
│  │ TAK Server   │  │              │  │              │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### Detection Sources

#### 1. ANTSDR E200 - DJI DroneID
- **Repository**: [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid)
- **Function**: Detects DJI proprietary DroneID signals (Ocusync 2, 3, 4)
- **Output**: Decoded drone telemetry via `dji_receiver.py`
- **Transport**: ZMQ Publisher

#### 2. droneid-go (WiFi/BT Remote ID)
- **Repository**: [droneid-go](https://github.com/alphafox02/droneid-go)
- **Function**: High-performance Open Drone ID receiver for WiFi and Bluetooth Remote ID
- **Output**: JSON-formatted Remote ID data
- **Transport**: ZMQ Publisher

#### 3. DragonTooth (Sniffle)
- **Function**: Bluetooth 5 Long Range detection
- **Firmware**: Sniffle-compatible
- **Output**: BT5 LR Remote ID packets
- **Transport**: ZMQ Publisher

### Processing - DragonSync

**Repository**: [DragonSync](https://github.com/alphafox02/DragonSync)

DragonSync is the central orchestration application that:

1. **Subscribes** to all ZMQ detection sources
2. **Merges** detections from multiple sources
3. **Deduplicates** overlapping detections
4. **Rate-limits** output to prevent flooding
5. **Transforms** data into output formats
6. **Manages** track state and history
7. **Publishes** to configured outputs

### Output Destinations

#### TAK Ecosystem
- **Protocol**: Cursor on Target (CoT) XML
- **Transports**:
  - UDP Multicast (default: 239.2.3.1:6969)
  - TCP to TAK Server
  - TLS encrypted connections
- **Clients**: ATAK, iTAK, WinTAK, TAK Server

#### MQTT
- **Format**: JSON per drone
- **Features**: Home Assistant auto-discovery
- **Use Case**: Dashboards, automation, Home Assistant

#### Lattice
- **Format**: Anduril Lattice protocol
- **Use Case**: Anduril ecosystem integration

#### HTTP API
- **Type**: Read-only REST API
- **Purpose**: Companion app data source
- **Endpoints**: Status, tracks, configuration

## Data Flow Example

```
1. DJI Mavic 3 flies within range
           │
           ▼
2. ANTSDR E200 detects Ocusync 3 signal
   └─► dji_receiver.py decodes DroneID
           │
           ▼
3. ZMQ publishes JSON message (ASTM F3411 format):
   [
     {"Basic ID": {"id": "1581F...", "id_type": "Serial Number (ANSI/CTA-2063-A)"}},
     {"Location/Vector Message": {"latitude": 40.7128, "longitude": -74.0060,
       "geodetic_altitude": 100, "speed": 15, "direction": 270}},
     {"System Message": {"operator_latitude": 40.7130, "operator_longitude": -74.0055}},
     {"Frequency Message": {"frequency_mhz": 2437.5, "rssi_dbm": -45}}
   ]
           │
           ▼
4. DragonSync receives message
   └─► Parses ASTM F3411 message blocks
   └─► Checks for duplicates (by serial/ID)
   └─► Updates track state
   └─► Applies rate limiting
           │
           ▼
5. DragonSync outputs:
   ├─► CoT XML to ATAK multicast
   ├─► JSON to MQTT broker
   └─► Lattice format to Anduril
           │
           ▼
6. ATAK displays drone on map
   Home Assistant updates dashboard
   Lattice shows in sandbox
```

## Configuration

DragonSync is configured via `config.ini`:

```ini
[SETTINGS]
# ────────── ZMQ Input Sources ──────────
# droneid-go unified output (WiFi + BLE + UART + DJI) on port 4224
# DJI DroneID (dji_receiver.py / ANTSDR E200) on port 4221
zmq_host = 127.0.0.1
zmq_recv_timeout_ms = 500

# ────────── TAK Output ──────────
tak_enabled = true
tak_multicast_addr = 239.2.3.1
tak_multicast_port = 6969

# ────────── MQTT Output ──────────
mqtt_enabled = false
mqtt_host = 192.168.1.100
mqtt_port = 1883
mqtt_ha_enabled = true
mqtt_ha_prefix = homeassistant

# ────────── Lattice Output ──────────
lattice_enabled = false

# ────────── HTTP API ──────────
api_enabled = true
api_host = 0.0.0.0
api_port = 8088
```

See [DragonSync Configuration](../software/dragonsync.md) for the full configuration reference.

## Extending the System

The modular architecture allows for:

1. **Adding detection sources** - Implement ZMQ publisher with standard JSON schema
2. **Adding outputs** - Subscribe to DragonSync's internal bus
3. **External SDRs** - KrakenSDR, RTL-SDR with appropriate software
4. **Custom processing** - Tap into ZMQ streams for custom analysis

## Related Documentation

- [ZMQ Data Flows](zmq-dataflows.md) - Detailed ZMQ message formats
- [DragonSync Configuration](../software/dragonsync.md) - Full configuration reference
- [TAK Integration](../integration/tak-integration.md) - TAK setup guide
- [Analytics Dashboard](../integration/analytics.md) - WarDragonAnalytics setup
