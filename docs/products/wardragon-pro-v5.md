# WarDragon Pro v5 Mobile Detection Kit

The WarDragon Pro v5 Mobile Detection Kit is the current-generation mobile platform — an RF sensing and data-integration appliance designed primarily for **headless sensor operation**, with all detection radios, antennas, GPS, and power options included for field or vehicle deployment. It ships in a redesigned, rugged Pelican-style mobility case (a new, larger case design vs. prior generations) with a **built-in small maintenance/status screen** for on-the-spot configuration and health checks when needed.

> **Headless by design**: All WarDragon kits are intended to run as headless sensors — the built-in screen is for occasional maintenance, status verification, and field troubleshooting, not as a primary operator interface.

**Purchase**: [cemaxecuter.com](https://cemaxecuter.com/?product=wardragon-pro-kit-v5-w-advanced-drone-detection)
**Price**: $6,500 (no subscription required for base kit)

## Compute Variants

Pro v5 ships in two compute variants. **Both use the same v5 Pelican-style mobility case** — same external dimensions, built-in maintenance screen, base detection radios (DragonSDR, WiFi, Bluetooth), and software stack. The two v5 variants share the case and the base detection stack; the x86_64 variant additionally includes the wideband 2nd SDR for DragonSig, with additional mission-specific antennas (5 GHz / 900 MHz) attached to it. The variant difference is the internal compute and the 2nd-SDR / antenna complement.

| | **Pro v5 ARM64** | **Pro v5 x86_64** |
|--|------------------|-------------------|
| Case / form factor | Same v5 Pelican-style mobility case | Same v5 Pelican-style mobility case |
| Built-in maintenance screen | Yes | Yes |
| Compute | WD ARM Processor (DragonOS) | x86_64 platform |
| Power profile | Lower power, more efficient | Higher draw, supports the additional 2nd SDR + processing |
| 2nd SDR | — | **Yes** — built-in wideband 70 MHz – 6 GHz 2nd SDR for [DragonSig](../software/dragonsig.md) |
| Antennas | DragonSDR + WiFi + BT antennas | DragonSDR + WiFi + BT antennas, **plus** mission-specific antenna(s) for the 2nd SDR (e.g. 5 GHz for FPV, 900 MHz for RFD900) |
| FPV / 900 MHz monitoring | Not available | Available via DragonSig |
| Best for | Power-conscious / extended-runtime deployments | Deployments needing FPV / RFD900 detection |

> The case itself is identical between variants; the antenna count differs because the x86_64 variant carries additional antennas for its 2nd SDR. Contact us when ordering to specify ARM64 or x86_64.

## What's in the Kit (Both Variants)

| Component | Description |
|-----------|-------------|
| WD compute | DragonOS preloaded — ARM (ARM64 variant) or x86_64 (x86_64 variant) |
| WarDragon SDR ([DragonSDR](../hardware/dragonsdr.md)) | DJI DroneID detection — OcuSync 2 / 3 / 4 activity |
| WiFi Dongle | Dual-band 2.4 / 5 GHz Remote ID detection |
| Bluetooth Dongle | Bluetooth 5 Long Range Remote ID detection |
| GPS | Integrated module, external SMA antenna connection on case |
| Mobility Case | Rugged, Pelican-style enclosure (briefcase-sized) |
| External SMA antenna ports | Paddle antennas included |
| Cooling | Integrated external cooling fans |
| Power | Locking external connector, 12 / 24 V DC vehicle adapter, 120 V AC connector |
| External I/O | USB and HDMI on case exterior |

### Additional on the x86_64 Variant

- Greater compute capacity for parallel signal processing and analytics workloads
- Built-in **wideband 70 MHz – 6 GHz 2nd SDR** running [DragonSig](../software/dragonsig.md) — the wideband signal-detection service
- DragonSig retunes the 2nd SDR via software for one mission at a time:
  - Analog FPV video (5.x GHz)
  - RFD900 / 900 MHz monitoring
  - Additional missions can be added over time (the SDR is wideband — no hardware change required)

## Form Factor

- **Case**: Pelican-style mobility case (briefcase-sized) — for vehicle deployment, mobile command, or field operations
- **Antennas**: External SMA connections with included paddle antennas
- **Cooling**: Integrated external fans for sustained operation in enclosed spaces
- **Power**: Locking external power connector accepts 12 / 24 V DC (vehicle) or 120 V AC

## Detection Capabilities (Base Kit)

| Protocol | Coverage | ARM64 | x86_64 |
|----------|----------|:-----:|:------:|
| DJI DroneID — OcuSync 2 / 3 | Full telemetry | Yes | Yes |
| DJI DroneID — OcuSync 4+ | Activity detection out of the box; full decode with **DragonScope** add-on | Yes | Yes |
| WiFi Remote ID (ASTM F3411) | 2.4 / 5 GHz | Yes | Yes |
| Bluetooth 5 LR Remote ID | Bluetooth Long Range | Yes | Yes |
| Analog FPV (via DragonSig) | 5.x GHz | — | Yes (built-in 2nd SDR) |
| RFD900 / 900 MHz (via DragonSig) | 900 MHz | — | Yes (built-in 2nd SDR) |

## Optional Add-ons

| Add-on | Price | Compatible Variant | What It Adds |
|--------|------:|--------------------|-------------|
| **[DragonScope Drone ID Service](../software/dragonscope.md)** | $2,500 / yr | ARM64 + x86_64 | Decodes the full DroneID telemetry stream across all current OcuSync generations including OcuSync 4+. Annual subscription, requires data connectivity. |
| **4G Cellular Upgrade** | Contact us | ARM64 + x86_64 | Semtech RV55 router (North America or Global variant) for cellular WAN |
| **Upgraded Antenna Packages** | Contact us | ARM64 + x86_64 | Mission-specific antennas — including 5 GHz and 900 MHz packages for the x86_64 variant's 2nd SDR. Magnetic-mount omni-directional and directional options. |

> The x86_64 variant's wideband 2nd SDR + DragonSig is **built in** — there are no separate "FPV SDR" or "900 MHz SDR" SKUs. Mission selection is software-driven; antenna packages are sold separately for whichever band you intend to monitor.

## Software Stack

| Component | Purpose | ARM64 | x86_64 |
|-----------|---------|:-----:|:------:|
| DragonOS | Base operating system | Yes | Yes |
| [droneid-go](https://github.com/alphafox02/droneid-go) | Unified Open Drone ID receiver (WiFi + BLE + UART). Runs as `zmq-decoder`. | Yes | Yes |
| [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid) | DJI DroneID receiver via DragonSDR. Runs as `dji-receiver`. | Yes | Yes |
| [DragonSync](https://github.com/alphafox02/DragonSync) | Aggregates all detection streams → TAK / MQTT / Lattice / HTTP API | Yes | Yes |
| [DragonScope](../software/dragonscope.md) *(optional subscription)* | Full DroneID decode for current OcuSync generations | Yes | Yes |
| [DragonSig](../software/dragonsig.md) *(x86_64 only)* | Wideband signal detection — FPV (5 GHz) or RFD900 (900 MHz), software-switchable on the built-in 2nd SDR | — | Yes |

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

## Power & Connectivity

| Spec | Value |
|------|-------|
| Power input | 12 / 24 V DC (locking connector, vehicle adapter included) or 120 V AC |
| External I/O | USB + HDMI on case exterior |
| Network | Onboard networking; optional Semtech RV55 4G upgrade for cellular WAN |

## Choosing Between Variants

| If you need... | Choose |
|---------------|--------|
| Smallest power footprint, longest battery runtime | Pro v5 ARM64 |
| Multi-site distributed sensor network (low SWaP per site) | Pro v5 ARM64 (per site) |
| Analog FPV detection capability | Pro v5 x86_64 (built-in DragonSig + 2nd SDR) |
| RFD900 / 900 MHz telemetry visibility | Pro v5 x86_64 (built-in DragonSig + 2nd SDR) |
| Headroom for analytics or future signal classes | Pro v5 x86_64 |
| Persistent simultaneous FPV **and** 900 MHz coverage | Pro v5 x86_64 — contact us about a multi-SDR configuration |

## Use Cases

- Mobile / vehicle drone detection
- Field operations and rapid deployment
- Command-post or temporary fixed-site installation
- Multi-kit distributed sensor networks (per-kit deployment, central [WarDragonAnalytics](../integration/analytics.md))

## Getting Started

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio
- [DragonScope](../software/dragonscope.md) — Optional full-decode service
- [DragonSig](../software/dragonsig.md) — Optional wideband signal detection (x86_64 variant)
- [WarDragon v1 Drop-In Detection Kit](drop-in-kit.md) — Same detection stack and variant split, integrator form factor
- [System Architecture](../architecture/overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
