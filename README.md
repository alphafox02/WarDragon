# WarDragon Documentation Hub

> **Work in Progress**: This documentation is actively being developed. Some information may be incomplete, outdated, or contain errors. If you find mistakes, please open an issue or submit a pull request. We appreciate your patience as we continue to improve these docs.

The official documentation and user manual for WarDragon drone detection systems.

## What is WarDragon?

WarDragon is a compact, headless, SDR-driven RF sensing and data integration appliance designed for comprehensive drone detection and situational awareness. It combines dedicated radios, software-defined radio capabilities, GPS, and purpose-built software workflows to detect drones via multiple protocols and integrate seamlessly with TAK ecosystems.

## Products

The current lineup is built around two kit lines — **WarDragon Pro** (ARM64) and **WarDragon Elite** (x86_64 NUC + BladeRF) — each available as a **Mobile Kit** (Pelican-style transport case) or a **Drop-In Kit** (DIN-rail / integrator enclosure). Pricing and store availability change periodically; check the [cemaxecuter.com store](https://cemaxecuter.com/?post_type=product) for current numbers.

| Product Line | Compute | Detection Stack | Use For |
|--------------|---------|-----------------|---------|
| [WarDragon Pro](docs/products/wardragon-pro-v5.md) | ARM64 | DragonSDR (DJI DroneID) + TI-based BT5 LR board + Alfa dual-band WiFi card + GPS | Remote ID + DJI DroneID detection in a power-efficient ARM64 platform |
| [WarDragon Elite](docs/products/wardragon-elite.md) | x86_64 NUC | Same as Pro **plus** a BladeRF running [DragonSig](docs/software/dragonsig.md) | Pro detection coverage **plus** analog FPV, RFD900 + MAVLink decode, and (coming soon) ELRS detection |
| [WarDragon Pro v3](docs/products/wardragon-pro-v3.md) *(legacy)* | Intel NUC | Single-SDR (Sonoff BT, Panda WiFi, ESP32) | Still supported. New deployments should use the current Pro or Elite. |

### Current SKUs

| SKU | Form Factor | Store Link |
|-----|-------------|-----------|
| WarDragon Pro Mobile Kit | Pelican case, built-in maintenance screen | [Purchase](https://cemaxecuter.com/?product=wardragon-pro-kit-v5-w-advanced-drone-detection) |
| WarDragon Pro Drop-In Kit | DIN-rail metal enclosure | [Purchase](https://cemaxecuter.com/?product=wardragon-v1-drop-in-detection-kit) |
| WarDragon Elite Mobile Kit | Pelican case, built-in maintenance screen | [Purchase](https://cemaxecuter.com/?product=wardragon-elite-mobile-kit) |
| WarDragon Elite Drop-In Kit | DIN-rail metal enclosure | [Purchase](https://cemaxecuter.com/?product=wardragon-elite-drop-in-kit) |

### Optional Add-ons

| Add-on | Compatible With | Description |
|--------|-----------------|-------------|
| [DragonScope Drone ID Service](docs/software/dragonscope.md) | Pro, Elite (Mobile + Drop-In Kits) | Annual subscription. Extends DJI DroneID coverage to **detect and decode** current OcuSync generations including OcuSync 4+. Requires data connectivity. [Store listing](https://cemaxecuter.com/?product=dragonscope-drone-id-service) |
| 4G Cellular Upgrade | Mobile Kits | Cellular WAN backhaul |
| Upgraded Antenna Packages | Pro, Elite | Mission-specific antennas — including 5 GHz FPV and 900 MHz RFD900 packages for Elite's BladeRF |
| Rapid Deployment Kit | Drop-In Kits | Converts the Drop-In into a standalone field system with weatherproof housing, tripod, travel case |

Visit the [cemaxecuter.com store](https://cemaxecuter.com/?post_type=product) for current pricing and availability.

## Quick Navigation

### Getting Started
- [Unboxing & First Boot](docs/getting-started/unboxing.md)
- [Network Configuration](docs/getting-started/network-setup.md)
- [Hotspot Setup](docs/getting-started/hotspot-setup.md)

### Hardware
- [DragonSDR](docs/hardware/dragonsdr.md) — DJI DroneID detection radio (used across all current kits)
- [Pro v3 Hardware Overview](docs/hardware/pro-v3-overview.md) — legacy reference
- [Antenna Connections](docs/hardware/antenna-connections.md)
- [LED Indicators & Status](docs/hardware/led-indicators.md)

### Software & Architecture
- [System Architecture](docs/architecture/overview.md)
- [ZMQ Data Flows](docs/architecture/zmq-dataflows.md)
- [DragonSync Core Application](docs/software/dragonsync.md)
- [DragonScope](docs/software/dragonscope.md) — Optional service for full DJI DroneID decode (current OcuSync generations)
- [DragonSig](docs/software/dragonsig.md) — Wideband signal detection on Elite's BladeRF (FPV / RFD900 / ELRS-soon)
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

| Protocol | Hardware | Frequency | Pro | Elite |
|----------|----------|-----------|:---:|:-----:|
| DJI DroneID — OcuSync 2 / 3 | DragonSDR | 2.4 / 5.8 GHz | Detect + decode | Detect + decode |
| DJI DroneID — OcuSync 4 | DragonSDR | 2.4 / 5.8 GHz | Detect only (decode with [DragonScope](docs/software/dragonscope.md)) | Detect only (decode with DragonScope) |
| WiFi Remote ID (ASTM F3411) | Alfa dual-band card | 2.4 / 5 GHz | Yes | Yes |
| Bluetooth 5 LR Remote ID | TI-based BT board | 2.4 GHz | Yes | Yes |
| Analog FPV video | BladeRF + [DragonSig](docs/software/dragonsig.md) | 5 GHz race bands | — | Yes |
| RFD900 + MAVLink decode | BladeRF + DragonSig | 900 MHz | — | Yes |
| ELRS *(coming soon)* | BladeRF + DragonSig | Multi-band | — | Yes |

## Ecosystem & Related Projects

### Core Software
| Repository | Description |
|------------|-------------|
| [DragonSync](https://github.com/alphafox02/DragonSync) | Main application — merges detection streams, outputs CoT to TAK, MQTT, and Lattice |
| [droneid-go](https://github.com/alphafox02/droneid-go) | Unified Open Drone ID receiver (WiFi + BLE + UART) with ZMQ output |
| [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid) | DragonSDR receiver for DJI DroneID detection |

### Extended Capabilities (provided with add-on purchase or Elite kit)
| Component | Description |
|-----------|-------------|
| **DragonScope Drone ID Service** | Optional annual subscription. Extends DJI DroneID coverage to **detect + decode** current OcuSync generations including OcuSync 4+. Requires data connectivity. [Docs](docs/software/dragonscope.md) · [Store](https://cemaxecuter.com/?product=dragonscope-drone-id-service) |
| **DragonSig** *(Elite-only, proprietary)* | Signal-detection service that drives the BladeRF on the Elite kit. Today: analog FPV (5 GHz) and RFD900 + MAVLink decode (900 MHz). Coming soon: ELRS detection. Binary ships pre-installed on Elite kits. [Docs](docs/software/dragonsig.md) |

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
| [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) | Legacy single-SDR FPV analog drone detection (Pro v3). Elite kits use DragonSig on the BladeRF instead. |

## Data Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       WarDragon Pro / Elite                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ DragonSDR   │  │  Alfa WiFi  │  │ TI BT5 LR   │  │  BladeRF    │   │
│  │             │  │  Dual-band  │  │   Board     │  │ (Elite only)│   │
│  │             │  │             │  │             │  │             │   │
│  │ DJI DroneID │  │ WiFi RID    │  │ BT5 LR RID  │  │ DragonSig   │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │          │
│  + DragonScope (opt)     │                │                │          │
│  decodes O3+/O4          │                                            │
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

- **Store**: [cemaxecuter.com](https://cemaxecuter.com) — current pricing, availability, and store listings
- **DragonOS**: [DragonOS Official](https://cemaxecuter.com)
- **Community**: Join the DragonOS Discord for support and discussion

## License

This documentation is provided for WarDragon customers and the drone detection community.
