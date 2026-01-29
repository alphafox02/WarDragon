# WarDragon Documentation Hub

> **Work in Progress**: This documentation is actively being developed. Some information may be incomplete, outdated, or contain errors. If you find mistakes, please open an issue or submit a pull request. We appreciate your patience as we continue to improve these docs.

The official documentation and user manual for WarDragon drone detection systems.

## What is WarDragon?

WarDragon is a compact, headless, SDR-driven RF sensing and data integration appliance designed for comprehensive drone detection and situational awareness. It combines dedicated radios, software-defined radio capabilities, GPS, and purpose-built software workflows to detect drones via multiple protocols and integrate seamlessly with TAK ecosystems.

## Products

| Product | Description | Status |
|---------|-------------|--------|
| [WarDragon Pro v3](docs/products/wardragon-pro-v3.md) | Full-featured drone detection kit with multi-protocol support | Current |

## Quick Navigation

### Getting Started
- [Unboxing & First Boot](docs/getting-started/unboxing.md)
- [Network Configuration](docs/getting-started/network-setup.md)
- [Hotspot Setup](docs/getting-started/hotspot-setup.md)

### Hardware
- [Pro v3 Hardware Overview](docs/hardware/pro-v3-overview.md)
- [Antenna Connections](docs/hardware/antenna-connections.md)
- [LED Indicators & Status](docs/hardware/led-indicators.md)

### Software & Architecture
- [System Architecture](docs/architecture/overview.md)
- [ZMQ Data Flows](docs/architecture/zmq-dataflows.md)
- [DragonSync Core Application](docs/software/dragonsync.md)
- [Detection Capabilities](docs/software/detection-capabilities.md)

### Integration
- [TAK Integration (ATAK/iTAK/WinTAK)](docs/integration/tak-integration.md)
- [MQTT & Home Assistant](docs/integration/mqtt-homeassistant.md)
- [Lattice Export](docs/integration/lattice.md)
- [Analytics Dashboard](docs/integration/analytics.md)

### Tutorials & Guides
- [Video Tutorials](docs/tutorials/video-index.md)
- [Setup Guides](docs/tutorials/setup-guides.md)
- [Troubleshooting](docs/troubleshooting/common-issues.md)

## Detection Capabilities

WarDragon detects drones through multiple protocols:

| Protocol | Hardware | Frequency | Range |
|----------|----------|-----------|-------|
| DJI DroneID (Ocusync 2/3/4) | ANTSDR E200 | 2.4/5.8 GHz | Extended |
| Bluetooth Remote ID | DragonTooth Dongle | 2.4 GHz | Bluetooth 5 LR |
| WiFi Remote ID | Panda Wireless + ESP32 | 2.4/5 GHz | Standard WiFi |
| FPV Analog | ANTSDR E200 | Various | In Testing |

## Ecosystem & Related Projects

WarDragon integrates with a broader ecosystem of open-source tools:

### Core Software
| Repository | Description |
|------------|-------------|
| [DragonSync](https://github.com/alphafox02/DragonSync) | Main application - merges detection streams, outputs CoT to TAK, MQTT, and Lattice |
| [DroneID](https://github.com/alphafox02/DroneID) | OpenDroneID sniffer for Bluetooth + WiFi Remote ID with ZMQ output |
| [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid) | ANTSDR E200 firmware for DJI DroneID detection |

### Mobile & Companion Apps
| Repository | Description |
|------------|-------------|
| [WarDragon-ATAK-Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin) | Native ATAK plugin for WarDragon integration |
| [DragonSync-iOS](https://github.com/Root-Down-Digital/DragonSync-iOS) | iOS companion app |
| [DragonSync-Android](https://github.com/lukeswitz/DragonSync-Android) | Android companion app |

### Analytics & Visualization
| Repository | Description |
|------------|-------------|
| [WarDragonAnalytics](https://github.com/alphafox02/WarDragonAnalytics) | Analytics dashboard and data visualization stack |

### Additional Capabilities
| Repository | Description |
|------------|-------------|
| [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) | FPV analog drone detection (optional, requires second SDR) |

### Related Tools
| Repository | Description |
|------------|-------------|
| [flightview_gui](https://github.com/alphafox02/flightview_gui) | GUI for aircraft info and ADS-B visualization |
| [dumphfdl-grafana-stack](https://github.com/alphafox02/dumphfdl-grafana-stack) | Grafana-based aviation data visualization |

## Data Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           WarDragon Pro v3                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │  ANTSDR     │  │   Panda     │  │   ESP32     │  │ DragonTooth │   │
│  │   E200      │  │  Wireless   │  │   Module    │  │   Dongle    │   │
│  │             │  │             │  │             │  │             │   │
│  │ DJI DroneID │  │ WiFi RID    │  │ WiFi RID    │  │  BT5 LR RID │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │          │
│         └────────────────┴────────────────┴────────────────┘          │
│                                   │                                    │
│                                   ▼                                    │
│                          ┌───────────────┐                            │
│                          │   ZMQ Bus     │                            │
│                          └───────┬───────┘                            │
│                                  │                                     │
│                                  ▼                                     │
│                          ┌───────────────┐                            │
│                          │  DragonSync   │                            │
│                          │               │                            │
│                          │ • Merge       │                            │
│                          │ • Rate Limit  │                            │
│                          │ • Transform   │                            │
│                          └───────┬───────┘                            │
│                                  │                                     │
└──────────────────────────────────┼─────────────────────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
   ┌─────────────┐         ┌─────────────┐         ┌─────────────┐
   │  TAK/ATAK   │         │    MQTT     │         │   Lattice   │
   │             │         │             │         │             │
   │ CoT via     │         │ Home        │         │ Anduril     │
   │ Multicast   │         │ Assistant   │         │ Integration │
   │ or Server   │         │ Dashboards  │         │             │
   └─────────────┘         └─────────────┘         └─────────────┘
```

## Support & Resources

- **Purchase**: [cemaxecuter.com](https://cemaxecuter.com/?product=wardragon-pro-kit)
- **DragonOS**: [DragonOS Official](https://cemaxecuter.com)
- **Community**: Join the DragonOS Discord for support and discussion

## License

This documentation is provided for WarDragon customers and the drone detection community.
