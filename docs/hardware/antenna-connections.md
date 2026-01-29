# Antenna Connections

This guide details all antenna connections on the WarDragon Pro v3, their purposes, and recommended antennas.

## Port Map

### Left Side (Back to Front)

| Port # | Label | Connected To | Purpose | Connector | Status |
|--------|-------|--------------|---------|-----------|--------|
| 1 | TX | ANTSDR E200 TX | Transmit (not used) | SMA Female | Unused |
| 2 | RX (E200) | ANTSDR E200 RX | DJI DroneID Detection | SMA Female | Primary |
| 3 | RX (Panda) | Panda Wireless | WiFi Remote ID | RP-SMA Female | Active |
| 4 | ESP32 | ESP32 Module | WiFi Remote ID | SMA Female | Active* |

*ESP32 port may be removed in future versions

### Right Side (Back to Front)

| Port # | Label | Connected To | Purpose | Connector | Status |
|--------|-------|--------------|---------|-----------|--------|
| 1 | GPS | GPS Module | External GPS Antenna | SMA Female | Optional |
| 2 | BT5 | DragonTooth | Bluetooth 5 LR Remote ID | SMA Female | Active |

## Visual Reference

```
┌────────────────────────────────────────────────────────────────────────┐
│                          WARDRAGON PRO V3                              │
│                              TOP VIEW                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   LEFT SIDE                                              RIGHT SIDE    │
│   ─────────                                              ──────────    │
│                                                                        │
│   [1] TX ──────── Not Used                    GPS ANT ──────── [1]    │
│       (SMA-F)                                   (SMA-F)                │
│                                                   │                    │
│   [2] RX ──────── ANTSDR E200                     └── Optional        │
│       (SMA-F)     DJI DroneID                         External GPS    │
│                   Primary Detection                                    │
│                                                                        │
│   [3] RX ──────── Panda Wireless               BT5 LR ──────── [2]    │
│       (RP-SMA-F)  WiFi Remote ID                (SMA-F)               │
│                   2.4/5 GHz                        │                   │
│                                                    └── DragonTooth    │
│   [4] ESP32 ───── ESP32 Module                        Sonoff Dongle   │
│       (SMA-F)     WiFi Remote ID                      BT5 Long Range  │
│                   (Future removal)                                     │
│                                                                        │
│                           ───── FRONT ─────                            │
└────────────────────────────────────────────────────────────────────────┘
```

## Antenna Recommendations

### DJI DroneID (ANTSDR E200 RX)
- **Frequency**: 2.4 GHz / 5.8 GHz dual-band
- **Type**: Omnidirectional whip or panel antenna
- **Polarization**: Vertical
- **Gain**: 3-6 dBi recommended
- **Connector**: SMA Male

### WiFi Remote ID (Panda Wireless)
- **Frequency**: 2.4 GHz / 5 GHz dual-band
- **Type**: Omnidirectional dual-band
- **Gain**: 5 dBi typical
- **Connector**: RP-SMA Male (note: reversed polarity)

### Bluetooth 5 LR (DragonTooth)
- **Frequency**: 2.4 GHz
- **Type**: High-gain omnidirectional or directional
- **Gain**: 6-9 dBi for extended range
- **Connector**: SMA Male

### GPS (Optional External)
- **Frequency**: 1575.42 MHz (L1)
- **Type**: Active GPS antenna
- **Gain**: 25-35 dB LNA
- **Connector**: SMA Male

## Installation Notes

### Connector Types
- **SMA Female**: Standard SMA connector on the unit; use SMA Male antenna or cable
- **RP-SMA Female**: Reversed polarity SMA on Panda port; use RP-SMA Male antenna

### Cable Considerations
- Use low-loss coax (LMR-240 or better) for cable runs over 3 feet
- Every 10 feet of RG-58 loses approximately 3 dB at 2.4 GHz
- Weatherproof connections for outdoor installations

### Antenna Placement
- Mount antennas with clear line of sight to sky (for drone detection)
- Separate antennas by at least one wavelength (~12 cm at 2.4 GHz) to reduce coupling
- Avoid metal surfaces directly behind antennas

## Quick Setup

For initial testing, the included antennas can be connected directly to the unit:

1. Connect dual-band antenna to **RX (E200)** port - Left side, port 2
2. Connect dual-band antenna to **RX (Panda)** port - Left side, port 3
3. Connect 2.4 GHz antenna to **BT5** port - Right side, port 2
4. GPS antenna (if using external) to **GPS** port - Right side, port 1

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| No DJI detections | Wrong port or loose connection | Verify antenna on E200 RX port |
| No WiFi RID | RP-SMA vs SMA mismatch | Ensure RP-SMA antenna on Panda port |
| Weak BT5 range | Low gain antenna | Use higher gain 2.4 GHz antenna |
| No GPS lock | Internal antenna blocked | Connect external GPS antenna |

## Related Documentation

- [Hardware Overview](pro-v3-overview.md)
- [Detection Capabilities](../software/detection-capabilities.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
