# Antenna Connections

This guide details all antenna connections on the WarDragon Pro v3, their purposes, and recommended antennas.

## Port Map

When the case is open and you're looking down at the unit, the **front** is nearest to you.

### Left Side (Front to Back)

| Port # | Label | Connected To | Purpose | Connector | Status |
|--------|-------|--------------|---------|-----------|--------|
| 1 | ESP32 | ESP32 Module | WiFi Remote ID | SMA Female | Active* |
| 2 | RX (Panda) | Panda Wireless | WiFi Remote ID | SMA Female | Active |
| 3 | RX (E200) | ANTSDR E200 RX | DJI DroneID Detection | SMA Female | Primary |
| 4 | TX | ANTSDR E200 TX | Transmit (not used) | SMA Female | Unused |

*ESP32 port may be removed in future versions

### Right Side (Front to Back)

| Port # | Label | Connected To | Purpose | Connector | Status |
|--------|-------|--------------|---------|-----------|--------|
| 1 | BT5 | DragonTooth | Bluetooth 5 LR Remote ID | SMA Female | Active |
| 2 | GPS | GPS Module | External GPS Antenna | SMA Female | Optional |

## Visual Reference

```
┌────────────────────────────────────────────────────────────────────────┐
│                          WARDRAGON PRO V3                              │
│                     TOP VIEW (Case Open, Looking Down)                 │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│                            ───── BACK ─────                            │
│                                                                        │
│   LEFT SIDE                                              RIGHT SIDE    │
│   ─────────                                              ──────────    │
│                                                                        │
│   [4] TX ──────── Not Used                    GPS ANT ──────── [2]    │
│       (SMA-F)                                   (SMA-F)                │
│                                                   │                    │
│   [3] RX ──────── ANTSDR E200                     └── Optional        │
│       (SMA-F)     DJI DroneID                         External GPS    │
│                   Primary Detection                                    │
│                                                                        │
│   [2] RX ──────── Panda Wireless               BT5 LR ──────── [1]    │
│       (SMA-F)     WiFi Remote ID                (SMA-F)               │
│                   2.4/5 GHz                        │                   │
│                                                    └── DragonTooth    │
│   [1] ESP32 ───── ESP32 Module                        Sonoff Dongle   │
│       (SMA-F)     WiFi Remote ID                      BT5 Long Range  │
│                   (Future removal)                                     │
│                                                                        │
│                           ───── FRONT ─────                            │
└────────────────────────────────────────────────────────────────────────┘
```

## Included Antennas

The WarDragon Pro v3 kit includes **four dual-band 2.4/5 GHz 8 dBi omnidirectional antennas** for all RF ports (E200 RX, Panda, ESP32, DragonTooth/BT5). These antennas cover all required frequencies for DJI DroneID, WiFi Remote ID, and Bluetooth Remote ID detection.

| Specification | Value |
|---------------|-------|
| Frequency | 2.4 GHz / 5 GHz dual-band |
| Gain | 8 dBi |
| Type | Omnidirectional whip |
| Polarization | Vertical |
| Connector | SMA Male |

## Upgrade Options

For extended range, consider upgrading to higher-gain or directional antennas:

### DJI DroneID (ANTSDR E200 RX)
- **Upgrade**: 9+ dBi panel antenna for 2-3x range
- **Note**: Directional antennas require aiming toward expected drone activity

### WiFi Remote ID (Panda Wireless)
- **Upgrade**: Higher gain omnidirectional (10+ dBi) for increased range
- **Note**: Dual-band required (2.4/5 GHz)

### Bluetooth 5 LR (DragonTooth)
- **Upgrade**: 9 dBi Yagi for directional long-range detection
- **Note**: BT5 Long Range benefits significantly from high-gain antennas

### GPS (Optional External)
- **Frequency**: 1575.42 MHz (L1)
- **Type**: Active GPS antenna
- **Gain**: 25-35 dB LNA
- **Connector**: SMA Male

## Installation Notes

### Connector Types

All external antenna ports use SMA Female pass-through adapters. Use antennas with SMA Male connectors (center pin).

### Cable Considerations
- Use low-loss coax (LMR-240 or better) for cable runs over 3 feet
- Every 10 feet of RG-58 loses approximately 3 dB at 2.4 GHz
- Weatherproof connections for outdoor installations

### Antenna Placement
- Mount antennas with clear line of sight to sky (for drone detection)
- Separate antennas by at least one wavelength (~12 cm at 2.4 GHz) to reduce coupling
- Avoid metal surfaces directly behind antennas

## Quick Setup

Connect the four included dual-band 8 dBi antennas to the unit:

1. Connect antenna to **RX (E200)** port - Left side, port 3
2. Connect antenna to **RX (Panda)** port - Left side, port 2
3. Connect antenna to **ESP32** port - Left side, port 1
4. Connect antenna to **BT5 (DragonTooth)** port - Right side, port 1
5. (Optional) GPS antenna to **GPS** port - Right side, port 2

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| No DJI detections | Wrong port or loose connection | Verify antenna on E200 RX port |
| No WiFi RID | Loose connection | Check antenna firmly connected |
| Weak BT5 range | Low gain antenna | Use higher gain 2.4 GHz antenna |
| No GPS lock | Internal antenna blocked | Connect external GPS antenna |

## Related Documentation

- [Hardware Overview](pro-v3-overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
