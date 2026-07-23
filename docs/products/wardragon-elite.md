# WarDragon Elite

The WarDragon Elite is the top-tier kit. It uses the same detection radio stack as the [WarDragon Pro](wardragon-pro-v5.md) (DragonSDR, TI-based Bluetooth board, Alfa dual-band WiFi card) but pairs it with **x86_64 NUC-class compute** and adds a **second SDR — a BladeRF — running [DragonSig](../software/dragonsig.md)** for analog FPV, RFD900 + MAVLink decode, mLRS + MAVLink extraction (active work), and ELRS detection (planned).

It ships as two distinct SKUs that share the same compute and detection stack — they differ only in form factor:

| SKU | Form Factor | Store Link |
|-----|-------------|-----------|
| **WarDragon Elite Mobile Kit** | Pelican-style transport case with built-in maintenance screen | [Purchase](https://cemaxecuter.com/?product=wardragon-elite-mobile-kit) |
| **WarDragon Elite Drop-In Kit** | DIN-rail-mountable metal enclosure for integrator installs | [Purchase](https://cemaxecuter.com/?product=wardragon-elite-drop-in-kit) |

**Architecture**: x86_64 NUC + BladeRF (2nd SDR)
**Subscription required for base kit**: No

> **Headless by design**: Like all WarDragon kits, the Elite is intended to run as a headless sensor. The Mobile Kit includes a small built-in maintenance screen for on-the-spot configuration and status checks.

## What Elite Has Over Pro

Elite uses a different compute platform and adds a second SDR for additional signal classes. It does **not** include the ARM compute used in the Pro line — Elite is a separate compute architecture.

| | **WarDragon Pro** | **WarDragon Elite** |
|--|-------------------|---------------------|
| Compute | ARM64 | **x86_64 NUC-class** |
| DragonSDR (DJI DroneID) | Yes | Yes |
| TI-based BT5 LR board | Yes | Yes |
| Alfa dual-band WiFi card | Yes | Yes |
| GPS | Yes | Yes |
| **2nd SDR (BladeRF)** | — | **Yes** |
| **DragonSig** | — | **Yes** (pre-installed binary) |
| DragonScope eligible | Yes | Yes |
| Form factors | Mobile + Drop-In | Mobile + Drop-In |

## SKU Comparison

| | **Elite Mobile Kit** | **Elite Drop-In Kit** |
|--|---------------------|------------------------|
| Enclosure | Rugged, Pelican-style mobility case | DIN-rail-mountable metal enclosure |
| Built-in maintenance screen | Yes | — |
| Use case | Field / vehicle / mobile command with full RF coverage | Integrator install with full RF coverage |
| Power | 12 / 24 V DC + 120 V AC | 12 / 24 V DC |
| Antennas | External SMA, paddle antennas for the base stack **plus** mission-specific antennas for the BladeRF (5 GHz, 900 MHz) | Bring your own / upgrade kit |
| GPS | Integrated module, external SMA antenna connection on case | Bring your own (per integration) |
| Cooling | Integrated external cooling fans | Passive (metal enclosure) — plan for active cooling |

Both SKUs run identical software and produce identical output downstream.

## Detection Hardware (Both SKUs)

| Component | Purpose |
|-----------|---------|
| **DragonSDR** | DJI DroneID detection — OcuSync 2 / 3 / 4 activity. Internal SDR with external SMA antenna. |
| **TI-based Bluetooth Long Range board** | Bluetooth 5 LR Remote ID detection. Sniffle-compatible firmware. |
| **Alfa dual-band WiFi card** | WiFi Remote ID detection — 2.4 GHz and 5 GHz. |
| **GPS module** | Position and timing. Integrated on Mobile; bring-your-own on Drop-In. |
| **BladeRF (2nd SDR)** | Wideband SDR dedicated to [DragonSig](../software/dragonsig.md) — analog FPV, RFD900 + MAVLink, mLRS + MAVLink (active), ELRS (planned). |
| **WD x86_64 NUC compute** | DragonOS preloaded. Higher processing headroom for the BladeRF pipeline and analytics workloads. |

## Detection Capabilities

### Base Stack (same coverage as Pro)

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
| **mLRS** *(active work)* | Multi-band | Detect the mLRS link and **extract MAVLink telemetry** (GPS / heading) from it |
| **ELRS** *(planned / on roadmap)* | Multi-band | Detect and characterize ExpressLRS control links |

> DragonSig is proprietary — the binary ships pre-installed on the Elite kit. Source is not currently open.

## Optional Add-ons

| Add-on | Compatible SKU | What It Adds |
|--------|---------------|-------------|
| [DragonScope Drone ID Service](../software/dragonscope.md) | Mobile + Drop-In | Detect + decode coverage for current OcuSync generations including OcuSync 4. Annual subscription, requires data connectivity. |
| 4G Cellular Upgrade | Mobile | Cellular WAN backhaul |
| Upgraded Antenna Packages | Mobile + Drop-In | Mission-specific antennas — including 5 GHz FPV and 900 MHz RFD900 antennas for the BladeRF |
| Rapid Deployment Kit | Drop-In | Converts the Drop-In into a standalone field system with weatherproof housing, tripod, travel case |

Contact us via [cemaxecuter.com](https://cemaxecuter.com) for current pricing and availability.

## Software Stack

Same as Pro (DragonOS, droneid-go, dragonsdr_dji_droneid, DragonSync, optional DragonScope) **plus**:

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

## When to Choose Elite vs. Pro

| If you need... | Choose |
|---------------|--------|
| Remote ID + DJI DroneID only — power-efficient ARM platform | [WarDragon Pro](wardragon-pro-v5.md) |
| Above plus analog FPV detection | Elite |
| Above plus RFD900 + MAVLink decode | Elite |
| mLRS link detection + MAVLink extraction (active) | Elite |
| ELRS detection when available (planned) | Elite |
| Most compute headroom for analytics / future signals | Elite |

## Getting Started

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [WarDragon Pro](wardragon-pro-v5.md) — the ARM64 sibling kit (same detection stack, different compute, no BladeRF)
- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio (same as Pro)
- [DragonScope](../software/dragonscope.md) — Optional full-decode service for current OcuSync generations
- [DragonSig](../software/dragonsig.md) — The BladeRF-driven signal-detection service unique to Elite
- [System Architecture](../architecture/overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
