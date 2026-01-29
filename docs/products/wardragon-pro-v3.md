# WarDragon Pro v3

The WarDragon Pro v3 is a compact, headless, SDR-driven RF sensing and data integration appliance engineered for comprehensive drone detection. It combines dedicated radios, software-defined radio capability, GPS, and purpose-built software workflows in a ruggedized, portable package.

**Purchase**: [cemaxecuter.com](https://cemaxecuter.com/?product=wardragon-pro-kit)

## What's Included

- WarDragon Pro v3 unit with all internal components
- ANTSDR E200 (internal)
- Panda Wireless dual-band adapter (internal)
- ESP32 WiFi Remote ID module (internal)
- DragonTooth (Sonoff) BT5 LR dongle (internal)
- GPS module (internal)
- Pre-installed DragonOS with all software configured
- Protective transport case
- Antennas and necessary cables

## Hardware Specifications

| Component | Specification |
|-----------|---------------|
| Processor | Intel N150 |
| Memory | 16 GB RAM |
| Storage | 512 GB NVMe |
| WiFi | WiFi 6 |
| Bluetooth | Bluetooth 5.2 |
| GPS | Integrated module |
| Construction | Machined base plate, ACM top plate |

## Detection Capabilities

### DJI DroneID Detection
- **Hardware**: ANTSDR E200
- **Protocols**: Ocusync 2, Ocusync 3, Ocusync 4 (activity detection)
- **Frequency**: 2.4 GHz / 5.8 GHz
- **Software**: [antsdr_dji_droneid](https://github.com/alphafox02/antsdr_dji_droneid)

### Bluetooth Remote ID
- **Hardware**: DragonTooth Dongle (Sonoff-based)
- **Protocol**: Bluetooth 5 Long Range (LR)
- **Range**: Extended via BT5 LR specification
- **Software**: Sniffle-based detection via [DroneID](https://github.com/alphafox02/DroneID)

### WiFi Remote ID
- **Hardware**: Panda Wireless dual-band adapter + ESP32 module
- **Frequencies**: 2.4 GHz and 5 GHz
- **Note**: ESP32 module may be removed in future versions

### Additional Capabilities
- FPV analog drone detection (in testing)
- RF spectrum monitoring from ~70 MHz to 6 GHz
- Extensible architecture for external SDRs (KrakenSDR integration)

## Physical Layout

See [Hardware Overview](../hardware/pro-v3-overview.md) for detailed diagrams and [Antenna Connections](../hardware/antenna-connections.md) for port mapping.

### Port Layout
*Case open, looking down at the unit*

**Left Side (front to back):**
1. ESP32 Module - WiFi Remote ID (may be removed in future versions)
2. RX Port - Panda Wireless (WiFi Remote ID)
3. RX Port - ANTSDR E200 (DJI DroneID - Primary)
4. TX Port - Not currently used

**Right Side (front to back):**
1. DragonTooth Dongle - Sonoff BT5 LR for Bluetooth Remote ID
2. GPS Antenna Port - Optional external GPS antenna connection

## Software Stack

The Pro v3 comes pre-configured with:

- **DragonOS** - Base operating system
- **[DragonSync](https://github.com/alphafox02/DragonSync)** - Core application managing all detection streams
- **[DroneID](https://github.com/alphafox02/DroneID)** - OpenDroneID sniffer
- **Kismet** - Wireless network detection
- **Aircrack-NG** - Wireless analysis tools
- **Sparrow-WiFi** - WiFi analysis support

## Output & Integration

WarDragon Pro v3 can output detection data to:

| Output | Description |
|--------|-------------|
| TAK Ecosystem | CoT via multicast or TAK Server (TCP/UDP, TLS) |
| MQTT | Per-drone JSON + Home Assistant discovery |
| Lattice | Anduril Lattice integration |
| HTTP API | Read-only API for companion apps |

### Companion Applications

- **[WarDragon ATAK Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin)** - Native ATAK integration
- **[DragonSync-iOS](https://github.com/Root-Down-Digital/DragonSync-iOS)** - iOS companion app
- **[DragonSync-Android](https://github.com/lukeswitz/DragonSync-Android)** - Android companion app

## Getting Started

1. [Unboxing & First Boot](../getting-started/unboxing.md)
2. [Network Configuration](../getting-started/network-setup.md)
3. [Hotspot Setup](../getting-started/hotspot-setup.md)

## Related Documentation

- [Hardware Overview](../hardware/pro-v3-overview.md)
- [Antenna Connections](../hardware/antenna-connections.md)
- [System Architecture](../architecture/overview.md)
- [DragonSync Configuration](../software/dragonsync.md)
