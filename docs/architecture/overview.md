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
│           │ dji_receiver.py    │ DroneID            │ Sniffle               │
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

#### 2. DroneID (WiFi/BT Remote ID)
- **Repository**: [DroneID](https://github.com/alphafox02/DroneID)
- **Function**: OpenDroneID sniffer for Bluetooth and WiFi broadcasts
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
3. ZMQ publishes JSON message:
   {
     "type": "dji_droneid",
     "serial": "ABC123...",
     "lat": 40.7128,
     "lon": -74.0060,
     "alt": 100,
     "speed": 15,
     "heading": 270,
     "pilot_lat": 40.7130,
     "pilot_lon": -74.0055,
     ...
   }
           │
           ▼
4. DragonSync receives message
   └─► Checks for duplicates
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

DragonSync is configured via `config.yaml`:

```yaml
# Input sources
inputs:
  dji_droneid:
    enabled: true
    zmq_address: "tcp://127.0.0.1:5556"

  droneid:
    enabled: true
    zmq_address: "tcp://127.0.0.1:5557"

# Output destinations
outputs:
  tak:
    enabled: true
    multicast: true
    address: "239.2.3.1"
    port: 6969

  mqtt:
    enabled: true
    broker: "192.168.1.100"
    port: 1883
    homeassistant_discovery: true

  lattice:
    enabled: false
```

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
