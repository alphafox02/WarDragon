# Detection Capabilities

This document details the drone detection capabilities of the WarDragon Pro v3, including supported protocols, hardware requirements, and expected performance.

## Detection Overview

WarDragon detects drones through multiple complementary technologies:

| Technology | Protocol | Hardware | Range | Best For |
|------------|----------|----------|-------|----------|
| DJI DroneID | Ocusync 2/3/4 | ANTSDR E200 | 1-5+ km | DJI drones |
| WiFi Remote ID | IEEE 802.11 | Panda Wireless | 100-500m | Compliant drones |
| Bluetooth Remote ID | BT5 LR | DragonTooth | 500m-1+ km | Compliant drones |
| FPV Detection | Analog video | Optional SDR | Varies | Racing/custom drones |

## DJI DroneID Detection

### Supported Protocols

| Protocol | DJI Models | Frequency | Status |
|----------|------------|-----------|--------|
| Ocusync 2 | Mavic Air 2, Mini 2, etc. | 2.4/5.8 GHz | Full support |
| Ocusync 3 | Mavic 3, Mini 3/Pro, Air 3 | 2.4/5.8 GHz | Full support |
| Ocusync 4 | Recent DJI models | 2.4/5.8 GHz | Activity detection |

### Data Extracted

From DJI DroneID signals, WarDragon extracts:

- **Drone Position**: Latitude, longitude, altitude
- **Drone Velocity**: Speed, heading, vertical speed
- **Pilot Position**: Latitude, longitude (operator location)
- **Home Point**: Takeoff/return location
- **Identification**: Serial number, drone type
- **Signal Data**: Frequency, RSSI

### Hardware: ANTSDR E200

**Repository**: [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid)

The ANTSDR E200 runs custom firmware optimized for DJI DroneID detection:

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

**Repository**: DroneID integration via [DroneID](https://github.com/alphafox02/DroneID)

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

## FPV Analog Detection (Experimental)

**Repository**: [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect)

### Overview

Detects analog FPV video transmitters commonly used on racing and custom-built drones. This is an optional capability requiring additional SDR hardware.

### Supported Frequencies

| Band | Frequency Range | Common Use |
|------|-----------------|------------|
| 5.8 GHz | 5645-5945 MHz | Most FPV |
| 2.4 GHz | 2400-2483 MHz | Long range FPV |
| 1.2 GHz | 1240-1300 MHz | Rare, long range |

### Requirements

- Second SDR (RTL-SDR, HackRF, etc.)
- Appropriate antenna for target band
- Additional software configuration

### Detection Method

1. Scans known FPV frequencies
2. Detects video carrier signal characteristics
3. Identifies active transmitters
4. Reports frequency, signal strength, and modulation type

### Limitations

- **No position data** - Analog FPV doesn't broadcast location
- **Direction only** - Requires direction-finding antenna for bearing
- **Cannot identify drone** - Only detects presence of transmission

## Multi-Protocol Detection

WarDragon detects drones across multiple protocols simultaneously. Each detection source feeds into DragonSync:

```
┌─────────────────────────────────────────────────────────────┐
│                  Detection Sources                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DJI DroneID ─────┐                                        │
│  (ANTSDR E200)    │                                        │
│                   ├──► DragonSync ──► TAK / MQTT / Lattice │
│  WiFi Remote ID ──┤                                        │
│  (Panda/ESP32)    │                                        │
│                   │                                        │
│  BT5 Remote ID ───┘                                        │
│  (DragonTooth)                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Note**: A DJI drone may broadcast both DJI DroneID and standard Remote ID (WiFi/BT). These currently appear as separate tracks. Future versions may correlate detections by serial number to merge them into a single track.

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
