# WarDragon Documentation Hub

> **Work in Progress**: This documentation is actively being developed. Some information may be incomplete, outdated, or contain errors. If you find mistakes, please open an issue or submit a pull request. We appreciate your patience as we continue to improve these docs.

The official documentation and user manual for WarDragon drone detection systems.

## What is WarDragon?

WarDragon is a compact, headless, SDR-driven RF sensing and data integration appliance designed for comprehensive drone detection and situational awareness. It combines dedicated radios, software-defined radio capabilities, GPS, and purpose-built software workflows to detect drones via multiple protocols and integrate seamlessly with TAK ecosystems.

## Products

| Product | Price | Description |
|---------|------:|-------------|
| [WarDragon Pro v5 Mobile Detection Kit](docs/products/wardragon-pro-v5.md) | $6,500 | Current-gen mobile kit, Pelican-style case with built-in maintenance screen. **ARM64** (power-efficient) or **x86_64** (additional 2nd SDR for DragonSig) compute variants. |
| [WarDragon v1 Drop-In Detection Kit](docs/products/drop-in-kit.md) | $5,000 | Same compute variants and detection stack as Pro v5, in a DIN-rail integrator form factor (no Pelican case) |
| [WarDragon Pro v3](docs/products/wardragon-pro-v3.md) | — | Previous-generation NUC kit, still fully supported |

### Optional Add-ons

| Add-on | Price | Compatible With |
|--------|------:|-----------------|
| [DragonScope Drone ID Service](docs/software/dragonscope.md) | $2,500 / yr | Pro v5 (both variants), Drop-In (both variants) |
| 4G Cellular Upgrade (Semtech RV55) | Contact us | Pro v5 |
| Upgraded Antenna Packages (5 GHz / 900 MHz / etc.) | Contact us | Pro v5, Drop-In |
| Rapid Deployment Kit | Contact us | Drop-In |

> **About the x86_64 variant**: the Pro v5 / Drop-In x86_64 variants ship with a **wideband 70 MHz – 6 GHz 2nd SDR built in**, running [DragonSig](docs/software/dragonsig.md). Mission selection (FPV 5 GHz, RFD900 900 MHz, future profiles) is software-configurable on that single SDR — there's no separate FPV-SDR or 900-MHz-SDR product to add. Mission-specific antennas may be sold separately.

## Quick Navigation

### Getting Started
- [Unboxing & First Boot](docs/getting-started/unboxing.md)
- [Network Configuration](docs/getting-started/network-setup.md)
- [Hotspot Setup](docs/getting-started/hotspot-setup.md)

### Hardware
- [Pro v3 Hardware Overview](docs/hardware/pro-v3-overview.md)
- [DragonSDR](docs/hardware/dragonsdr.md) — DJI DroneID detection radio
- [Antenna Connections](docs/hardware/antenna-connections.md)
- [LED Indicators & Status](docs/hardware/led-indicators.md)

### Software & Architecture
- [System Architecture](docs/architecture/overview.md)
- [ZMQ Data Flows](docs/architecture/zmq-dataflows.md)
- [DragonSync Core Application](docs/software/dragonsync.md)
- [DragonScope](docs/software/dragonscope.md) — Optional service for full DJI DroneID decode (current OcuSync generations)
- [DragonSig](docs/software/dragonsig.md) — Wideband signal detection (FPV / 900 MHz, runs on optional 2nd SDR)
- [Detection Capabilities](docs/software/detection-capabilities.md)

### Integration
- [TAK Integration (ATAK/iTAK/WinTAK)](docs/integration/tak-integration.md)
- [MQTT & Home Assistant](docs/integration/mqtt-homeassistant.md)
- [ADS-B / 978 Integration](docs/integration/adsb-setup.md)
- [Lattice Export](docs/integration/lattice.md)
- [Analytics Dashboard](docs/integration/analytics.md)

### Tutorials & Guides
- [Video Tutorials](docs/tutorials/video-index.md)
- [Setup Guides](docs/tutorials/setup-guides.md)
- [Troubleshooting](docs/troubleshooting/common-issues.md)

## Detection Capabilities

WarDragon detects drones through multiple protocols:

| Protocol | Hardware | Frequency | Coverage |
|----------|----------|-----------|----------|
| DJI DroneID — OcuSync 2 / 3 | DragonSDR | 2.4 / 5.8 GHz | Full telemetry |
| DJI DroneID — OcuSync 3 Pro / 4+ | DragonSDR | 2.4 / 5.8 GHz | Detection-only by default; **full telemetry with [DragonScope](docs/software/dragonscope.md)** |
| Bluetooth Remote ID | Bluetooth dongle | 2.4 GHz | BT5 Long Range |
| WiFi Remote ID | WiFi dongle | 2.4 / 5 GHz | Dual-band Remote ID |
| Analog FPV video | Built-in 2nd SDR via [DragonSig](docs/software/dragonsig.md) | 5.x GHz | x86_64 variant of Pro v5 / Drop-In |
| RFD900 / 900 MHz telemetry | Built-in 2nd SDR via [DragonSig](docs/software/dragonsig.md) | 900 MHz | x86_64 variant of Pro v5 / Drop-In |

## Ecosystem & Related Projects

WarDragon integrates with a broader ecosystem of open-source tools:

### Core Software
| Repository | Description |
|------------|-------------|
| [DragonSync](https://github.com/alphafox02/DragonSync) | Main application — merges detection streams, outputs CoT to TAK, MQTT, and Lattice |
| [droneid-go](https://github.com/alphafox02/droneid-go) | Unified Open Drone ID receiver (WiFi + BLE + UART) with ZMQ output |
| [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid) | DragonSDR receiver for DJI DroneID detection |

### Extended Capabilities (provided with add-on purchase)
| Component | Description |
|-----------|-------------|
| **DragonScope Drone ID Service** | Optional annual subscription that extends DJI DroneID coverage to all current OcuSync generations including OcuSync 4+. Requires data connectivity. $2,500 / yr. [Docs](docs/software/dragonscope.md) |
| **DragonSig** *(Coming Soon, source not public)* | Wideband signal-detection service running on the **wideband 70 MHz – 6 GHz 2nd SDR built into the x86_64 variant** of Pro v5 / Drop-In kits. Software-configurable for analog FPV (5 GHz), RFD900 / 900 MHz, and additional missions over time — one mission at a time per SDR. [Docs](docs/software/dragonsig.md) |

### Mobile & Companion Apps
| Repository | Description |
|------------|-------------|
| [WarDragon-ATAK-Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin) | Native ATAK plugin for WarDragon integration |
| [DragonSync-iOS](https://github.com/Root-Down-Digital/DragonSync-iOS) | iOS companion app (third-party) |
| [DragonSync-Android](https://github.com/lukeswitz/DragonSync-Android) | Android companion app (third-party) |

> **Note**: The iOS and Android companion apps are developed by third-party contributors. Features and compatibility may vary.

### Analytics & Visualization
| Repository | Description |
|------------|-------------|
| [WarDragonAnalytics](https://github.com/alphafox02/WarDragonAnalytics) | Analytics dashboard and data visualization stack |

### Additional Capabilities
| Repository | Description |
|------------|-------------|
| [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) | Legacy single-SDR FPV analog drone detection (Pro v3). Pro v5 / Drop-In **x86_64** variants use DragonSig on the built-in wideband 2nd SDR instead. |

## Data Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            WarDragon (Pro v5 / Drop-In)                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ DragonSDR   │  │  WiFi       │  │ Bluetooth   │  │ 2nd SDR     │   │
│  │             │  │  Dongle     │  │   Dongle    │  │ (optional)  │   │
│  │             │  │             │  │             │  │ FPV / 900MHz│   │
│  │ DJI DroneID │  │ WiFi RID    │  │ BT5 LR RID  │  │ DragonSig   │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │          │
│  + DragonScope (opt)     │                │                │          │
│  decodes O3 Pro / O4+    │                │                │          │
│         │                                                              │
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

- **Pro v5 Mobile Detection Kit**: [Purchase](https://cemaxecuter.com/?product=wardragon-pro-kit-v5-w-advanced-drone-detection)
- **v1 Drop-In Detection Kit**: [Purchase](https://cemaxecuter.com/?product=wardragon-v1-drop-in-detection-kit)
- **DragonScope Drone ID Service**: [Subscribe](https://cemaxecuter.com/?product=dragonscope-drone-id-service)
- **All Products**: [cemaxecuter.com store](https://cemaxecuter.com/?post_type=product)
- **DragonOS**: [DragonOS Official](https://cemaxecuter.com)
- **Community**: Join the DragonOS Discord for support and discussion

## License

This documentation is provided for WarDragon customers and the drone detection community.
