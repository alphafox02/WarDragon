# WarDragon Elite

The WarDragon Elite is the top-tier kit — it includes everything in the [Pro v5](wardragon-pro-v5.md) plus an **x86_64 NUC-class compute** and a **second SDR (BladeRF)** running [DragonSig](../software/dragonsig.md). It ships in the same two form-factor variants as the Pro v5: **Mobile** (Pelican-style transport case) and **Drop-In** (DIN-rail / integrator enclosure).

**Architecture**: ARM64 + x86_64 NUC + BladeRF (2nd SDR)
**Subscription required for base kit**: No
**Purchase**: [cemaxecuter.com](https://cemaxecuter.com)

> **Headless by design**: Like all WarDragon kits, the Elite is intended to run as a headless sensor. The Mobile variant includes a small built-in maintenance screen for on-the-spot configuration and status checks.

## What Elite Adds Over Pro v5

Everything in the [Pro v5](wardragon-pro-v5.md) — DragonSDR, TI-based Bluetooth Long Range board, Alfa dual-band WiFi card, GPS, DragonOS, full DragonSync output pipeline — **plus**:

| Addition | Purpose |
|----------|---------|
| **x86_64 NUC-class compute** | Higher processing headroom for the 2nd SDR signal pipeline and analytics workloads |
| **BladeRF (2nd SDR)** | Wideband SDR dedicated to [DragonSig](../software/dragonsig.md) — runs analog FPV detection, RFD900 / MAVLink monitoring, and future signal classes |
| **DragonSig** *(proprietary, ships pre-installed)* | Service that drives the BladeRF for FPV / 900 MHz / ELRS detection. Binary ships on the kit — source is not currently open. |

## Form-Factor Variants

| | **Elite Mobile** | **Elite Drop-In** |
|--|------------------|---------------------|
| Enclosure | Rugged, Pelican-style mobility case | DIN-rail-mountable metal enclosure |
| Built-in maintenance screen | Yes | — |
| Use case | Field / vehicle / mobile command with full RF coverage | Integrator install with full RF coverage |
| Power | 12 / 24 V DC + 120 V AC | 12 / 24 V DC |
| Antennas | External SMA, paddle antennas included for the base stack **plus** mission-specific antennas for the 2nd SDR (5 GHz, 900 MHz, etc.) | Bring your own / upgrade kit |
| GPS | Integrated module, external SMA antenna connection on case | Bring your own (per integration) |
| Cooling | Integrated external cooling fans | Passive (metal enclosure) — plan for active cooling |

Both variants run identical software and produce identical output downstream.

## Detection Capabilities

### Base Stack (same as Pro v5)

| Protocol | Frequency | Coverage |
|----------|-----------|----------|
| DJI DroneID — OcuSync 2 / 3 | 2.4 / 5.8 GHz | **Detect and decode** — full telemetry |
| DJI DroneID — OcuSync 4 | 2.4 / 5.8 GHz | **Detect only** out of the box; full decode with [DragonScope](../software/dragonscope.md) |
| WiFi Remote ID (ASTM F3411) | 2.4 / 5 GHz | Dual-band Remote ID |
| Bluetooth 5 LR Remote ID | 2.4 GHz | BT5 LR Remote ID |

### DragonSig (Elite-only)

The BladeRF on the Elite runs [DragonSig](../software/dragonsig.md). DragonSig targets one mission at a time — software-switchable on the same SDR:

| Mission | Frequency | What It Does |
|---------|-----------|--------------|
| **Analog FPV video** | 5 GHz race bands | Detect analog FPV transmitters; partial decoding capability |
| **RFD900 telemetry** | 900 MHz | Detect SiK / RFD900-class radios and **decode MAVLink** telemetry |
| **ELRS** *(coming soon)* | Multi-band | Detect and characterize ExpressLRS control links |

> DragonSig is proprietary — the binary ships pre-installed on the Elite kit. Source is not currently open.

## Optional Add-ons

| Add-on | Compatible Variant | What It Adds |
|--------|-------------------|-------------|
| [DragonScope Drone ID Service](../software/dragonscope.md) | Mobile + Drop-In | Detect + decode coverage for current OcuSync generations including OcuSync 4. Annual subscription, requires data connectivity. |
| 4G Cellular Upgrade | Mobile | Cellular WAN backhaul |
| Upgraded Antenna Packages | Mobile + Drop-In | Mission-specific antennas — including 5 GHz FPV and 900 MHz RFD900 antennas for the BladeRF |
| Rapid Deployment Kit | Drop-In | Converts the Drop-In into a standalone field system with weatherproof housing, tripod, travel case |

Contact us for current pricing and availability.

## Software Stack

Same as Pro v5 (DragonOS, droneid-go, dragonsdr_dji_droneid, DragonSync, optional DragonScope) **plus**:

- **DragonSig** — runs on the BladeRF, processes 5 GHz FPV / 900 MHz RFD900 / future signal classes. Publishes alerts on ZMQ port 4226; DragonSync ingests via its `fpv_*` configuration.

See [DragonSig](../software/dragonsig.md) for the full pipeline and configuration.

## Output & Integration

All detections — DJI DroneID, WiFi RID, Bluetooth RID, FPV alerts, RFD900 telemetry — flow through the same DragonSync pipeline:

| Output | Description |
|--------|-------------|
| TAK Ecosystem | CoT via multicast or TAK Server (TCP / UDP, TLS) |
| MQTT | Per-drone JSON + Home Assistant discovery; aircraft + signal topics for the additional Elite detections |
| Lattice | Anduril Lattice integration |
| HTTP API | Read-only REST API for companion apps |

## When to Choose Elite vs. Pro v5

| If you need... | Choose |
|---------------|--------|
| Remote ID + DJI DroneID only — power-efficient | [Pro v5](wardragon-pro-v5.md) |
| Above plus analog FPV detection | Elite |
| Above plus RFD900 + MAVLink decode | Elite |
| ELRS detection when available | Elite |
| Most compute headroom for analytics / future signals | Elite |

## Getting Started

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [WarDragon Pro v5](wardragon-pro-v5.md) — the base kit Elite is built on
- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio (same as Pro v5)
- [DragonScope](../software/dragonscope.md) — Optional full-decode service for current OcuSync generations
- [DragonSig](../software/dragonsig.md) — The BladeRF-driven signal-detection service unique to Elite
- [System Architecture](../architecture/overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
