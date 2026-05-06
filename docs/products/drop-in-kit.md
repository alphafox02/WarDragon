# WarDragon v1 Drop-In Detection Kit

A compact drone detection module designed for integration into existing enclosures, supporting Remote ID and DJI signal detection with no subscription required for the base kit. Like all WarDragon kits, the Drop-In is intended to run as a **headless sensor** — the integrator provides whatever local management interface (if any) is needed.

**Purchase**: [cemaxecuter.com](https://cemaxecuter.com/?product=wardragon-v1-drop-in-detection-kit)
**Price**: $5,000 (no subscription required for base kit)

## Compute Variants

The Drop-In ships in the same two compute variants as the Pro v5 — same detection stack, same software, just packaged in a DIN-rail-mountable metal enclosure instead of the Pelican-style mobility case.

| | **Drop-In ARM64** | **Drop-In x86_64** |
|--|-------------------|---------------------|
| Compute | WD ARM Processor (DragonOS) | x86_64 platform |
| Power profile | Lower power, more efficient | Higher draw, supports the additional 2nd SDR + processing |
| 2nd SDR | — | **Yes** — built-in wideband 70 MHz – 6 GHz 2nd SDR for [DragonSig](../software/dragonsig.md) |
| Antennas | DragonSDR + WiFi + BT antennas | Same, **plus** mission-specific antenna(s) for the 2nd SDR (e.g. 5 GHz for FPV, 900 MHz for RFD900) |
| FPV / 900 MHz monitoring | Not available | Available via DragonSig |
| Best for | Power-conscious panel / integrator installs | Integrator installs needing FPV / RFD900 detection |

> Variant selection isn't always exposed on the storefront. Contact us when ordering to specify ARM64 or x86_64.

## Who It's For

Integrators and technical users embedding drone detection into existing infrastructure:

- CCTV / video surveillance platforms
- License Plate Recognition (LPR) systems
- Surveillance trailers and mobile command vehicles
- Sensor enclosures, equipment cabinets, and industrial racks
- Custom mast / aerostat / fixed-site installations

The Drop-In ships in a DIN-rail-mountable metal enclosure so it can be added to existing rack or panel installations without a separate case design.

## What's in the Kit (Both Variants)

| Component | Description |
|-----------|-------------|
| WD compute | DragonOS preloaded — ARM (ARM64 variant) or x86_64 (x86_64 variant) |
| WarDragon SDR ([DragonSDR](../hardware/dragonsdr.md)) | DJI DroneID detection — OcuSync 2 / 3 / 4 activity |
| WiFi Dongle | Dual-band 2.4 / 5 GHz Remote ID detection |
| Bluetooth Dongle | Bluetooth 5 Long Range Remote ID detection |
| Metal Enclosure | DIN-rail mounting clip and mounting hardware included |
| 6-inch DIN-rail Strip | Included for installations without an existing rail |

### Additional on the x86_64 Variant

- Greater compute capacity for parallel signal processing and analytics workloads
- Built-in **wideband 70 MHz – 6 GHz 2nd SDR** running [DragonSig](../software/dragonsig.md) — the wideband signal-detection service
- DragonSig retunes the 2nd SDR via software for one mission at a time:
  - Analog FPV video (5.x GHz)
  - RFD900 / 900 MHz monitoring
  - Additional missions can be added over time (the SDR is wideband — no hardware change required)

## Form Factor

- **Compact, small footprint** — designed for enclosure integration
- **Metal enclosure** with DIN-rail clip
- **DIN-rail strip** included if you don't already have one in the enclosure
- Not weatherproof on its own — mount inside a weatherproof secondary enclosure or order the **Rapid Deployment Kit** add-on for outdoor use

## Power & Connectivity

| Spec | Value |
|------|-------|
| Power input | 12 / 24 V DC |
| Network | Requires DHCP WAN connection for network access |

Bring your own power supply and uplink — the Drop-In is intended to drop into existing infrastructure that already has both.

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
| **[DragonScope Drone ID Service](../software/dragonscope.md)** | $2,500 / yr | ARM64 + x86_64 | Decodes full DroneID telemetry across current OcuSync generations including OcuSync 4+. Annual subscription, requires data connectivity. |
| **Upgraded Antenna Packages** | Contact us | ARM64 + x86_64 | Mission-specific antennas — including 5 GHz and 900 MHz packages for the x86_64 variant's 2nd SDR. Omni-directional and directional options. |
| **Rapid Deployment Kit** | Contact us | ARM64 + x86_64 | Converts the Drop-In into a standalone field system with weatherproof housing, tripod, travel case, and modem / antenna options |

> The x86_64 variant's wideband 2nd SDR + DragonSig is **built in** — there are no separate "FPV SDR" or "900 MHz SDR" SKUs. Mission selection is software-driven; antenna packages are sold separately for whichever band you intend to monitor.

## Software Stack

Same software as the WarDragon Pro v5 — see [Pro v5 software stack](wardragon-pro-v5.md#software-stack) for the full list. DragonSig is x86_64-only (requires the 2nd SDR slot).

CoT, MQTT, Lattice, and HTTP API output is identical to a packaged Pro v5 — companion apps, ATAK plugins, and analytics dashboards work the same way.

## Relationship to Pro v5

The Drop-In runs the **same compute options and the same software stack** as the WarDragon Pro v5 Mobile Detection Kit — only the form factor differs:

| | Pro v5 Mobile | Drop-In |
|--|--------------|---------|
| Compute variants | ARM64 / x86_64 | ARM64 / x86_64 |
| DragonSDR | Yes | Yes |
| WiFi + BT dongles | Yes | Yes |
| Form factor | Pelican-style mobility case | DIN-rail metal enclosure |
| Antennas | Paddle, external SMA | Bring your own / upgrade kit |
| GPS | Integrated, external SMA | Bring your own (depending on integration) |
| Power | 12/24 V DC + 120 V AC | 12 / 24 V DC |
| Use case | Mobile / vehicle / field | Integrator / fixed-site / panel |

## Considerations for Integrators

### Power
- Plan for 12 / 24 V DC input from your existing rail or supply
- Plan additional capacity for the x86_64 variant's wideband 2nd SDR + DragonSig if specifying that variant

### Thermal
- Metal enclosure provides some thermal mass. For confined or hot environments, plan for forced-air or conducted cooling — especially for the x86_64 variant under sustained load.

### Internal Networking
- DragonSDR uses a dedicated internal Ethernet link to the compute (`172.31.100.1` / `172.31.100.2`). This is preserved automatically — don't disturb it during integration.

### RF Isolation
- Co-locating WiFi (RX / TX), Bluetooth (RX / TX), DragonSDR (RX), and any 2nd-SDR add-on can cause interference if antennas are too close. Recommend at least one wavelength of separation at 2.4 GHz (~12 cm) between antennas where practical.

### Outdoor Deployment
- The metal enclosure is not weatherproof on its own. For outdoor installations, mount inside a weatherproof secondary enclosure or order the **Rapid Deployment Kit** add-on.

## Getting Started

If you're working with a pre-imaged Drop-In Kit, the standard WarDragon setup applies:

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [WarDragon Pro v5](wardragon-pro-v5.md) — Mobile-case sibling product (same compute variants)
- [DragonSDR](../hardware/dragonsdr.md)
- [DragonScope](../software/dragonscope.md)
- [DragonSig](../software/dragonsig.md)
- [System Architecture](../architecture/overview.md)
