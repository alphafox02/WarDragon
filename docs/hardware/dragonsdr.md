# DragonSDR

The DragonSDR is the dedicated software-defined radio used in WarDragon kits for DJI DroneID detection. It runs custom firmware that detects DJI's proprietary OcuSync downlink and forwards parsed telemetry to the WarDragon software stack.

**Receiver software**: [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid) — the `dji_receiver.py` host service and supporting firmware.

## What It Detects

| OcuSync Generation | Examples | Coverage |
|--------------------|----------|----------|
| OcuSync 2 | Mini 2, Mavic Air 2, Air 2S | Full telemetry — serial, drone GPS, pilot GPS, home point, altitude, speed, RSSI |
| OcuSync 3 | Mavic 3, Mini 3 / 3 Pro, Air 3 | Full telemetry |
| OcuSync 4 | Mini 5 and current generation | Detection out of the box (hash ID, frequency, RSSI). Full telemetry available with [DragonScope](../software/dragonscope.md). |

> **Note**: DJI drones only broadcast DroneID while motors are spinning. Powering on the drone alone activates the OcuSync control link but not the DroneID broadcast.

## Hardware

| Spec | Value |
|------|-------|
| Frequency range | ~70 MHz – 6 GHz |
| Connection | Internal Ethernet (kit-internal subnet) |
| Antenna | External SMA (kit dual-band 2.4/5 GHz 8 dBi included) |
| Boot modes | SD card mode (run firmware) / QSPI mode (configure boot env) |
| Default IP (WarDragon) | `172.31.100.2` |

## Internal Network

The DragonSDR communicates with the WarDragon compute over a dedicated internal Ethernet link. **Do not modify "Wired connection 1"** on the WarDragon — it carries this traffic.

| Device | IP | Notes |
|--------|----|----|
| WarDragon (Wired connection 1) | 172.31.100.1 | Internal interface to DragonSDR |
| DragonSDR | 172.31.100.2 | SD card mode default |

If the DragonSDR's IP needs to change, both ends must be updated together — see [Network Configuration](../getting-started/network-setup.md#dragonsdr-internal-network) and the [dragonsdr_dji_droneid README](https://github.com/alphafox02/dragonsdr_dji_droneid) for the boot-env procedure.

## Firmware Variants

The DragonSDR ships with one of two firmware lineages depending on configuration:

### Standard Firmware

- Decodes OcuSync 2 / 3 fully and detects OcuSync 4 presence (hash ID + frequency + RSSI)
- Output: text CSV protocol over a TCP connection to the WarDragon (port 52002)
- Suitable for the majority of deployments — no internet required, works fully offline

### Extended Firmware (DragonScope-Capable)

- Adds full OcuSync 4 telemetry coverage (serial, drone GPS, pilot, home, altitude, speed)
- Requires the [DragonScope](../software/dragonscope.md) service running on the WarDragon, a license key, and an internet connection
- Provided separately to qualifying customers — contact us

> O2 / O3 detection is unaffected and continues to work fully offline regardless of which firmware lineage is loaded.

## Host-Side Service: dji-receiver

The `dji-receiver` systemd service runs `dji_receiver.py`, which:

1. Accepts TCP connections from the DragonSDR on port `52002`
2. Parses incoming DroneID frames
3. Publishes JSON over ZMQ on port `4221`
4. Subscribes to WarDragon Monitor (port `4225`) to attach sensor GPS to detections

```bash
# Service control
sudo systemctl status dji-receiver
sudo systemctl restart dji-receiver
journalctl -u dji-receiver -f
```

## Pipeline Position

```
DragonSDR  ──►  dji-receiver (port 4221, ZMQ)
                       │
                       ▼
              droneid-go / zmq-decoder (port 4224)  ◄── WiFi RID, BLE RID, ESP32 UART
                       │
                       ▼
                  DragonSync  ──►  TAK / MQTT / Lattice / HTTP API
```

The dji-receiver feeds the unified droneid-go output, which DragonSync subscribes to. See [ZMQ Data Flows](../architecture/zmq-dataflows.md) for the full picture.

## Antenna & Port

The DragonSDR's RX line is on **Left Side - Port 3** (RX DragonSDR) of the Pro v3 enclosure. The kit includes a dual-band 2.4 / 5 GHz 8 dBi omnidirectional antenna for this port. For extended range, a 9+ dBi panel antenna can be substituted — see [Antenna Connections](antenna-connections.md).

## Available On

| Kit | Included? |
|-----|----------|
| WarDragon Pro v3 | Yes |
| WarDragon Pro v5 (Mobile or Drop-In) | Yes |
| WarDragon Elite (Mobile or Drop-In) | Yes |

## Related Documentation

- [Antenna Connections](antenna-connections.md)
- [Network Configuration](../getting-started/network-setup.md)
- [DragonScope](../software/dragonscope.md) — Extended OcuSync 4 coverage
- [Detection Capabilities](../software/detection-capabilities.md)
- [ZMQ Data Flows](../architecture/zmq-dataflows.md)
- Upstream: [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid)
