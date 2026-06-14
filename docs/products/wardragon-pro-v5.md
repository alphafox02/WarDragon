# WarDragon Pro

The WarDragon Pro is the current-generation **ARM64-based** drone detection kit. It ships as two distinct SKUs that share the same compute, the same detection radios, and the same software stack — they differ only in form factor:

| SKU | Form Factor | Store Link |
|-----|-------------|-----------|
| **WarDragon Pro Mobile Kit** | Pelican-style transport case with built-in maintenance screen | [Purchase](https://cemaxecuter.com/?product=wardragon-pro-kit-v5-w-advanced-drone-detection) |
| **WarDragon Pro Drop-In Kit** | DIN-rail-mountable metal enclosure for integrator installs | [Purchase](https://cemaxecuter.com/?product=wardragon-v1-drop-in-detection-kit) |

**Architecture**: ARM64
**Subscription required for base kit**: No

> **Headless by design**: Like all WarDragon kits, the Pro is intended to run as a headless sensor. The Mobile Kit includes a small built-in maintenance screen for on-the-spot configuration and status checks.

## SKU Comparison

| | **Pro Mobile Kit** | **Pro Drop-In Kit** |
|--|------------------|---------------------|
| Enclosure | Rugged, Pelican-style mobility case | DIN-rail-mountable metal enclosure |
| Built-in maintenance screen | Yes | — |
| Use case | Field / vehicle / mobile command | Integrator installs — CCTV, LPR, surveillance trailers, equipment cabinets, fixed mounts |
| Power | 12 / 24 V DC + 120 V AC, locking external connector, vehicle adapter | 12 / 24 V DC (bring your own supply) |
| Antennas | External SMA, paddle antennas included | Bring your own / upgrade kit |
| GPS | Integrated module, external SMA antenna connection on case | Bring your own (per integration) |
| Cooling | Integrated external cooling fans | Passive (metal enclosure) — plan for active cooling in confined installs |

Both SKUs run identical software and produce identical CoT / MQTT / Lattice output downstream.

## Detection Hardware (Both SKUs)

| Component | Purpose |
|-----------|---------|
| **DragonSDR** | DJI DroneID detection — OcuSync 2 / 3 / 4 activity. Internal SDR with external SMA antenna. |
| **TI-based Bluetooth Long Range board** | Bluetooth 5 LR Remote ID detection. Sniffle-compatible firmware. |
| **Alfa dual-band WiFi card** | WiFi Remote ID detection — 2.4 GHz and 5 GHz. |
| **GPS module** | Position and timing. Internal patch on Mobile; bring-your-own on Drop-In. |
| **WD ARM compute** | DragonOS preloaded. |

## Detection Capabilities

| Protocol | Frequency | Coverage |
|----------|-----------|----------|
| DJI DroneID — OcuSync 2 / 3 | 2.4 / 5.8 GHz | **Detect and decode** — full telemetry (drone GPS, pilot, home, altitude, speed, serial) |
| DJI DroneID — OcuSync 4 | 2.4 / 5.8 GHz | **Detect only** out of the box; full decode available with [DragonScope](../software/dragonscope.md) |
| WiFi Remote ID (ASTM F3411) | 2.4 / 5 GHz | Dual-band Remote ID |
| Bluetooth 5 Long Range Remote ID | 2.4 GHz | BT5 LR Remote ID |

### Extending Coverage with DragonScope

The optional [DragonScope Drone ID Service](../software/dragonscope.md) extends DJI DroneID coverage to OcuSync 3+ generations (including OcuSync 4), adding **detect and decode** for those generations. It runs as an annual subscription on the WarDragon, requires data connectivity, and is eligible for both Pro SKUs.

## Optional Add-ons

| Add-on | Compatible SKU | What It Adds |
|--------|---------------|-------------|
| [DragonScope Drone ID Service](../software/dragonscope.md) | Mobile + Drop-In | Detect + decode coverage for current OcuSync generations including OcuSync 4. Annual subscription, requires data connectivity. |
| 4G Cellular Upgrade | Mobile | Cellular WAN backhaul |
| Upgraded Antenna Packages | Mobile + Drop-In | Mission-specific antennas, omni-directional and directional options |
| Rapid Deployment Kit | Drop-In | Converts the Drop-In into a standalone field system with weatherproof housing, tripod, travel case |

Contact us via [cemaxecuter.com](https://cemaxecuter.com) for current pricing and availability.

## Software Stack

| Component | Purpose |
|-----------|---------|
| DragonOS | Base operating system |
| [droneid-go](https://github.com/alphafox02/droneid-go) | Unified Open Drone ID receiver (WiFi + BLE + UART). Runs as `zmq-decoder`. |
| [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid) | DJI DroneID receiver via DragonSDR. Runs as `dji-receiver`. |
| [DragonSync](https://github.com/alphafox02/DragonSync) | Aggregates all detection streams → TAK / MQTT / Lattice / HTTP API. |
| [DragonScope](../software/dragonscope.md) *(optional subscription)* | Detect + decode coverage for current OcuSync generations including OcuSync 4. |

## Output & Integration

All detection data outputs through DragonSync to:

| Output | Description |
|--------|-------------|
| TAK Ecosystem | CoT via multicast or TAK Server (TCP / UDP, TLS) |
| MQTT | Per-drone JSON + Home Assistant discovery |
| Lattice | Anduril Lattice integration |
| HTTP API | Read-only REST API for companion apps |

### Companion Applications

- **[WarDragon ATAK Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin)** — Native ATAK integration
- **[DragonSync-iOS](https://github.com/Root-Down-Digital/DragonSync-iOS)** — iOS companion (third-party)
- **[DragonSync-Android](https://github.com/lukeswitz/DragonSync-Android)** — Android companion (third-party)

## When to Choose Pro vs. Elite

| If you need... | Choose |
|---------------|--------|
| Remote ID + DJI DroneID detection in a power-efficient ARM64 platform | WarDragon Pro (Mobile or Drop-In) |
| The above **plus** analog FPV video detection | [WarDragon Elite](wardragon-elite.md) |
| The above **plus** RFD900 / MAVLink telemetry intelligence | [WarDragon Elite](wardragon-elite.md) |
| Mobile / vehicle deployment | Pro Mobile (or Elite Mobile) |
| Integrator install — CCTV / LPR / sensor cabinet / panel | Pro Drop-In (or Elite Drop-In) |

## Getting Started

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [WarDragon Elite](wardragon-elite.md) — Pro base + x86_64 NUC + BladeRF + DragonSig
- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio
- [DragonScope](../software/dragonscope.md) — Optional full-decode service
- [System Architecture](../architecture/overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
