# Detection Capabilities

This document details the drone detection capabilities of the WarDragon platform across the current product lineup — **WarDragon Pro** (Mobile or Drop-In Kit), **WarDragon Elite** (Mobile or Drop-In Kit), and the legacy **WarDragon Pro v3**.

## Detection Overview

WarDragon detects drones through multiple complementary technologies:

| Technology | Protocol | Hardware | Pro | Elite | Pro v3 |
|------------|----------|----------|:---:|:-----:|:------:|
| DJI DroneID | OcuSync 2 / 3 / 4+ | DragonSDR | Yes | Yes | Yes |
| WiFi Remote ID | IEEE 802.11 | Alfa dual-band card (Pro / Elite), Panda + ESP32 (Pro v3) | Yes | Yes | Yes |
| Bluetooth Remote ID | BT5 LR | TI-based board (Pro / Elite), Sonoff DragonTooth (Pro v3) | Yes | Yes | Yes |
| Analog FPV video | 5 GHz race bands | BladeRF + [DragonSig](dragonsig.md) | — | Yes | Legacy via [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) |
| RFD900 + MAVLink decode | 900 MHz | BladeRF + DragonSig | — | Yes | — |
| ELRS *(coming soon)* | Multi-band | BladeRF + DragonSig | — | Yes | — |

## DJI DroneID Detection

### Supported Protocols

| Protocol | DJI Models | Frequency | Coverage |
|----------|------------|-----------|----------|
| OcuSync 2 | Mavic Air 2, Mini 2, Air 2S | 2.4 / 5.8 GHz | Full telemetry |
| OcuSync 3 (standard) | Mavic 3, Mini 3 / 3 Pro, Air 3 | 2.4 / 5.8 GHz | Full telemetry |
| OcuSync 3 Pro / OcuSync 4+ | Mini 5, current generation | 2.4 / 5.8 GHz | Activity detection out of the box; full telemetry with [DragonScope](dragonscope.md) |

### Coverage Tiers (Current OcuSync Generations)

| Coverage Tier | What You Get | Requirements |
|---------------|--------------|--------------|
| **Detection only** | Hash ID (e.g. `drone-alert-{hash}`), detection frequency, RSSI | Standard DragonSDR (default; included with all current kits) |
| **Full telemetry** | Serial, drone GPS, pilot GPS, home point, altitude, speed, RSSI | [DragonScope Drone ID Service](dragonscope.md) — annual subscription, requires data connectivity |

OcuSync 2 / 3 standard detection is **unaffected** by DragonScope state and continues to work fully offline.

> DJI drones only broadcast DroneID while motors are spinning. Power-on alone activates the OcuSync control link but does not start the DroneID broadcast.

### Data Extracted

From DJI DroneID signals, WarDragon extracts:

- **Drone Position**: Latitude, longitude, altitude
- **Drone Velocity**: Speed, heading, vertical speed
- **Pilot Position**: Latitude, longitude (operator location)
- **Home Point**: Takeoff/return location
- **Identification**: Serial number, drone type
- **Signal Data**: Frequency, RSSI

### Hardware: DragonSDR

**Repository**: [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid)

The DragonSDR runs custom firmware optimized for DJI DroneID detection:

- Frequency range: ~70 MHz to 6 GHz
- Dual-channel reception
- Real-time decoding
- Network output via `dji_receiver.py`

### Performance Factors

| Factor | Impact | Optimization |
|--------|--------|--------------|
| Antenna gain | Higher gain = longer range | Use 6+ dBi directional |
| Line of sight | Clear LoS dramatically improves range | Elevate antenna |
| RF environment | Urban noise reduces range | Use filtering |
| Drone altitude | Higher drones detected further | N/A |

## WiFi Remote ID Detection

### Standard Support

- **ASTM F3411** - Remote ID standard
- **ASD-STAN 4709-002** - EU standard
- Broadcast on 2.4 GHz and 5 GHz bands

### Data Extracted

Per ASTM F3411 specification:

- **Basic ID**: UAS ID (serial number, registration, UTM ID)
- **Location/Vector**: Position, altitude, speed, heading
- **Operator**: Operator ID and location
- **System**: Timestamp, area count, category/class

### Hardware: Panda Wireless + ESP32

**Panda Wireless PAU0D**:
- Dual-band 2.4/5 GHz
- Monitor mode capable
- External antenna support

**ESP32 Module**:
- Dedicated WiFi Remote ID scanning
- Low-power continuous monitoring
- May be removed in future versions

### Range Expectations

| Environment | Typical Range |
|-------------|---------------|
| Open field | 300-500m |
| Suburban | 150-300m |
| Urban | 50-150m |

## Bluetooth 5 Long Range Remote ID

### Protocol Support

- **Bluetooth 5 Long Range** (LE Coded PHY)
- Extended advertising packets
- ASTM F3411 Bluetooth broadcast format

### Data Extracted

Same as WiFi Remote ID (ASTM F3411 specification)

### Hardware: DragonTooth Dongle

Based on Sonoff hardware with Sniffle-compatible firmware:

**Repository**: [droneid-go](https://github.com/alphafox02/droneid-go)

| Feature | Specification |
|---------|---------------|
| BT Version | Bluetooth 5.2 |
| PHY Support | LE 1M, LE 2M, LE Coded (S2, S8) |
| Sensitivity | -95 dBm (LE Coded) |
| Antenna | External SMA |

### Range Expectations

Bluetooth 5 Long Range significantly extends detection:

| PHY Mode | Typical Range | Notes |
|----------|---------------|-------|
| LE 1M | 100-200m | Standard BT range |
| LE Coded S2 | 300-500m | 2x range vs 1M |
| LE Coded S8 | 500m-1+ km | 4x range, slower |

## DragonSig — FPV / RFD900 / ELRS Detection (Elite Only)

[DragonSig](dragonsig.md) is the signal-detection service that runs on the **BladeRF** included with the **WarDragon Elite** kit. Pro doesn't include a 2nd SDR, so DragonSig isn't available there.

DragonSig retunes the BladeRF via software to whichever mission you've configured. Today's mission set:

- **Analog FPV video** — 5 GHz race bands
- **RFD900 / 900 MHz telemetry** — includes **MAVLink decode** for SiK / RFD900 links
- **ELRS** *(coming soon)* — ExpressLRS control-link detection / characterization

The BladeRF is dedicated to whichever mission DragonSig is configured for at any given time — it isn't sweeping multiple bands simultaneously on a single radio. If you need persistent multi-band coverage, contact us about kit options with multiple 2nd SDRs.

DragonSig runs on the BladeRF, so DJI DroneID detection on the DragonSDR continues uninterrupted regardless of which DragonSig mission is active.

> DragonSig is proprietary — the binary ships pre-installed on Elite kits. Source is not currently open.

### FPV Analog — Frequency Coverage

The DragonSig sweep covers the standard 5 GHz FPV race bands and adjacent channels:

| Band | Frequency Range | Channels |
|------|-----------------|----------|
| A | 5725-5865 MHz | 8 |
| B | 5733-5866 MHz | 8 |
| E | 5645-5945 MHz | 8 |
| F | 5740-5880 MHz | 8 |
| R (Race) | 5658-5917 MHz | 8 |
| L | 5333-5613 MHz | 8 |
| X | 4990-5200 MHz | 8 |

### Detection Method

1. Wideband FFT energy detector with adaptive thresholding
2. FM envelope check filters out WiFi / OFDM signals
3. PAL / NTSC comb-filter classifier confirms analog video
4. ML-assisted classification (YOLO / ONNX) extends to additional signal types over time
5. Alerts publish on ZMQ port `4226` in the same JSON envelope as the legacy detector — DragonSync ingests without changes

### Limitations

- **FPV analog** — no native position data (uses WarDragon GPS as the location)
- **RFD900 / 900 MHz** — position is included when telemetry from the link is decoded; otherwise WarDragon GPS is used
- **Requires WarDragon Elite** — the BladeRF and DragonSig binary ship on Elite kits only. Pro and Pro v3 don't include a 2nd SDR.

### Legacy FPV Flow (Pro v3)

The earlier `wardragon-fpv-detect` flow ([repo](https://github.com/alphafox02/wardragon-fpv-detect)) used GNU Radio with gr-inspector and the `suscli fpvdet` plugin. It remains documented for Pro v3 and other single-SDR deployments — see the upstream repository.

## Multi-Protocol Detection

WarDragon detects drones across multiple protocols simultaneously. Each detection source feeds into DragonSync:

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Detection Sources                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DJI DroneID ─────┐                                                │
│  (DragonSDR)      │  ◄── DragonScope (optional subscription)       │
│                   │      decodes O3 Pro / O4+                      │
│  WiFi Remote ID ──┤                                                 │
│  (WiFi dongle)    ├──► DragonSync ──► TAK / MQTT / Lattice / API   │
│                   │                                                 │
│  BT5 Remote ID ───┤                                                 │
│  (BT dongle)      │                                                 │
│                   │                                                 │
│  FPV / 900MHz / ELRS ──┘ ◄── DragonSig (Elite only, BladeRF)       │
│  (1 mission at a time)                                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Note**: DragonSync tracks drones by their serial number (ID). If a DJI drone broadcasts both DJI DroneID and standard Remote ID using the **same serial number**, they will be merged into a single track. However, if the serial numbers differ between protocols (which can happen), they will appear as separate tracks.

## Detection Coverage Map

Approximate detection ranges with standard antennas:

```
                            │
                       1 km │     ★ DJI DroneID (directional)
                            │
                     500m   │  ●─────● BT5 Long Range
                            │
                     200m   │  ○───○ WiFi Remote ID
                            │
                       0    │  ◉ WarDragon
                            └─────────────────────────────
```

## Improving Detection Range

### Antenna Upgrades

| Protocol | Upgrade | Expected Improvement |
|----------|---------|---------------------|
| DJI DroneID | 9 dBi panel antenna | 2-3x range |
| WiFi RID | 6 dBi omni | 1.5-2x range |
| BT5 LR | 9 dBi Yagi | 2-3x range |

### Site Selection

- Elevate WarDragon for better line of sight
- Minimize obstructions between unit and sky
- Avoid metal structures that cause reflections
- Consider RF environment (avoid high-interference areas)

### External SDR Integration

WarDragon supports external SDRs for extended capabilities:

- **KrakenSDR**: Direction finding
- **RTL-SDR**: Additional spectrum monitoring
- **HackRF**: Wide frequency coverage

## Related Documentation

- [Antenna Connections](../hardware/antenna-connections.md)
- [System Architecture](../architecture/overview.md)
- [DragonSync Configuration](dragonsync.md)
