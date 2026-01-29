# WarDragon Pro v3 Hardware Overview

This document details the physical layout, internal components, and external connections of the WarDragon Pro v3.

## External Layout

### Case Design
- Machined aluminum base plate for heat dissipation
- ACM (Aluminum Composite Material) top plate
- Ruggedized protective transport case included

### Port Layout

The WarDragon Pro v3 has antenna ports accessible from the sides of the unit. When looking at the unit with the front facing you:

```
                    ┌─────────────────────────────────────┐
                    │           WarDragon Pro v3          │
                    │                FRONT                │
                    └─────────────────────────────────────┘

    LEFT SIDE                                           RIGHT SIDE
    (Back to Front)                                     (Back to Front)
    ┌──────────┐                                        ┌──────────┐
    │ 1. TX    │ ← Not used                             │ 1. GPS   │ ← Optional GPS Antenna
    │          │                                        │   ANT    │
    ├──────────┤                                        ├──────────┤
    │ 2. RX    │ ← ANTSDR E200                          │ 2. BT5   │ ← DragonTooth Dongle
    │ (E200)   │   DJI DroneID (Primary)                │   LR     │   Bluetooth Remote ID
    ├──────────┤                                        └──────────┘
    │ 3. RX    │ ← Panda Wireless
    │ (Panda)  │   WiFi Remote ID
    ├──────────┤
    │ 4. ESP32 │ ← WiFi Remote ID
    │          │   (May be removed in future)
    └──────────┘
```

## Internal Components

### Compute Platform
| Component | Specification |
|-----------|---------------|
| Processor | Intel N150 |
| Memory | 16 GB DDR5 RAM |
| Storage | 512 GB NVMe SSD |
| WiFi | WiFi 6 (802.11ax) |
| Bluetooth | Bluetooth 5.2 |

### Detection Hardware

#### ANTSDR E200
- **Purpose**: DJI DroneID detection (Ocusync 2/3/4)
- **Frequency Range**: ~70 MHz to 6 GHz
- **Connection**: Internal USB, external SMA antenna port
- **Firmware**: Custom [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid)

#### Panda Wireless PAU0D
- **Purpose**: WiFi Remote ID detection
- **Bands**: Dual-band 2.4 GHz / 5 GHz
- **Connection**: Internal USB, external RP-SMA antenna port
- **Driver**: Native Linux support

#### ESP32 Module
- **Purpose**: WiFi Remote ID detection (secondary)
- **Status**: May be removed in future versions
- **Connection**: Internal USB

#### DragonTooth Dongle (Sonoff)
- **Purpose**: Bluetooth 5 Long Range Remote ID
- **Protocol**: BT5 LR (Long Range mode)
- **Firmware**: Sniffle-compatible
- **Connection**: Internal USB, external antenna

#### GPS Module
- **Purpose**: Unit position/timing
- **Connection**: Internal, optional external antenna port

## LED Indicators

| LED | Color | Status |
|-----|-------|--------|
| Power | Green | System powered on |
| Activity | Blue (blinking) | Detection activity |
| Network | Green | Network connected |
| GPS | Green (solid) | GPS lock acquired |
| GPS | Green (blinking) | Searching for satellites |

## Power Requirements

- **Input**: 12V DC
- **Consumption**: ~25W typical
- **Connector**: Barrel jack (5.5mm x 2.1mm)

## Thermal Management

The machined aluminum base plate serves as a passive heatsink. The unit is designed for continuous operation but should have adequate airflow around the base.

**Operating Temperature**: 0°C to 40°C (32°F to 104°F)

## Mounting Options

The base plate includes mounting holes compatible with:
- Standard RAM mounts
- AMPS pattern
- Custom vehicle mounts

## Next Steps

- [Antenna Connections](antenna-connections.md) - Detailed antenna port mapping
- [LED Indicators](led-indicators.md) - Status light reference
- [Getting Started](../getting-started/unboxing.md) - First boot guide
