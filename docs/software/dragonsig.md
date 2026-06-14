# DragonSig

> **Status**: Proprietary. DragonSig source is not currently open. The service ships pre-installed as a binary on **WarDragon Elite** kits — contact us for availability.

DragonSig is the wideband signal-detection service that runs on the **BladeRF (2nd SDR) built into the WarDragon Elite kit**. It complements the base detection stack ([DragonSDR](../hardware/dragonsdr.md) for DJI DroneID, [droneid-go](https://github.com/alphafox02/droneid-go) for WiFi / BLE Remote ID) by covering signal categories that aren't broadcast as Remote ID.

## Where DragonSig Lives

DragonSig is **Elite-only**. The WarDragon Pro kit doesn't include a 2nd SDR, so DragonSig isn't available on Pro.

| Kit | DragonSig |
|-----|-----------|
| WarDragon Elite (Mobile or Drop-In) | **Yes** — runs on the included BladeRF |
| WarDragon Pro (Mobile or Drop-In Kit) | — (no 2nd SDR) |
| WarDragon Pro v3 | — (single-SDR legacy architecture; see [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) for the older flow) |

## How It Works

DragonSig drives the BladeRF and **targets one mission at a time**. Mission selection is a software choice — DragonSig retunes the SDR for whichever band/protocol you've configured.

Current mission set:

| Mission | Frequency | What's Detected | Decode |
|---------|-----------|-----------------|--------|
| **Analog FPV video** | 5 GHz race bands | Analog video transmitters on racing / custom drones | Partial — PAL/NTSC discrimination, frame capture where signal quality permits |
| **RFD900 / 900 MHz telemetry** | 902 – 928 MHz | SiK / RFD900-class radios used for long-range drone telemetry | **MAVLink decode** — extracts position, heading, and other fields where available |
| **ELRS** *(coming soon)* | Multi-band | ExpressLRS control links used on FPV / racing drones | Detection and characterization |

The BladeRF is dedicated to whichever mission DragonSig is configured for at any given time — DragonSig isn't sweeping multiple bands simultaneously on the same radio. The mission set is expected to grow over time without hardware changes.

## What DragonSig Detects

### Analog FPV Video (5 GHz)

Many racing and custom-built drones use analog 5 GHz video transmitters that are invisible to Remote ID detection. DragonSig:

- Sweeps the 5 GHz FPV band
- Identifies signals matching the FM envelope characteristic of analog video
- Classifies as PAL or NTSC where possible
- Captures grayscale video frames from the detected signal on a separate thread when signal quality permits
- Emits the same alert envelope as the legacy FPV detector — DragonSync ingests without changes

This replaces the older `wardragon-fpv-detect` Python flow on Elite kits.

### RFD900 / 900 MHz Telemetry Decode

For the 900 MHz mission DragonSig monitors the 902–928 MHz ISM band typically used by SiK / RFD900-class radios that carry MAVLink telemetry between long-range fixed-wing or VTOL drones and their ground stations.

DragonSig **detects the link and decodes MAVLink telemetry** — when MAVLink position / heading data is recovered from the link, it's forwarded as a track with real position rather than falling back to the WarDragon's own GPS.

### ELRS *(Coming Soon)*

Detection and characterization of ExpressLRS control links is on the DragonSig roadmap.

## Output

DragonSig emits the same JSON message envelope as the legacy FPV detector — DragonSync subscribes without changes:

```json
[
  {"Basic ID": {"id_type": "Serial Number (ANSI/CTA-2063-A)", "id": "fpv-alert-5945.200MHz", "description": "FPV Signal"}},
  {"Location/Vector Message": {"latitude": 35.123, "longitude": -78.456, "geodetic_altitude": 100.0}},
  {"Self-ID Message": {"text": "FPV alert (confirm)"}},
  {"Frequency Message": {"frequency": 5945200000}},
  {"Signal Info": {"source": "confirm", "center_hz": 5945200000, "bandwidth_hz": 4200000, "rssi": -90.5}}
]
```

When MAVLink telemetry is recovered from a 900 MHz detection, position fields are populated in the `Location/Vector Message` block instead of falling back to the WarDragon's own GPS.

| Source tag | Meaning |
|------------|---------|
| `energy` | Initial energy-based detection (lower confidence) |
| `confirm` | Confirmed via classifier (higher confidence) |

## Pipeline Position

```
BladeRF (Elite 2nd SDR)  ──►  DragonSig  ──►  ZMQ port 4226  ──►  DragonSync  ──►  TAK / MQTT / Lattice
                                                                       ▲
                                              droneid-go (4224) ───────┤
                                              dji-receiver (4221) ─────┘
```

DragonSig publishes alerts on ZMQ port `4226`, so DragonSync's `fpv_*` configuration applies directly:

```ini
[SETTINGS]
fpv_enabled = true
fpv_zmq_host = 127.0.0.1
fpv_zmq_port = 4226
fpv_stale = 60
fpv_radius_m = 15
fpv_rate_limit = 2.0
fpv_max_signals = 200
fpv_confirm_only = true
```

The same DragonSync pipeline handles output regardless of which mission DragonSig is configured for.

## Switching Missions

Switching DragonSig between FPV, RFD900, and (future) ELRS missions is a software reconfiguration on the BladeRF — no hardware swap. The appropriate antenna for the target band needs to be connected. Contact support for the switching procedure on your kit.

## Service Management

```bash
sudo systemctl status dragonsig
journalctl -u dragonsig -f
sudo systemctl restart dragonsig
```

The service runs as `User=dragon` so it can access USB SDR devices.

## Distribution

DragonSig is **not currently open source**. The binary is provided pre-installed on Elite kits at the factory. There's no source download or self-build path at this time — contact us if you have questions about Elite kit availability.

## Related Documentation

- [WarDragon Elite](../products/wardragon-elite.md) — the only kit that ships with DragonSig + BladeRF
- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio (separate from DragonSig's 2nd SDR)
- [Detection Capabilities](detection-capabilities.md)
- [System Architecture](../architecture/overview.md)
- [DragonSync Configuration](dragonsync.md) — `fpv_*` settings apply
- Older single-SDR FPV flow: [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect)
