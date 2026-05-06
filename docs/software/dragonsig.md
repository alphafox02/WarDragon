# DragonSig

> **Status**: Coming Soon. DragonSig source is not currently public. The service ships pre-installed on **x86_64-variant** WarDragon kits — contact us for availability.

DragonSig is a wideband signal-detection service that runs on the **2nd SDR built into the x86_64 variant** of the WarDragon Pro v5 and v1 Drop-In kits. It complements the base detection stack ([DragonSDR](../hardware/dragonsdr.md) for DJI DroneID, [droneid-go](https://github.com/alphafox02/droneid-go) for WiFi / BLE Remote ID) by covering signal categories that aren't broadcast as Remote ID.

## What the 2nd SDR Is

The x86_64 variant ships with a **wideband 70 MHz – 6 GHz SDR** dedicated to DragonSig. It's the same class of capability as the [DragonSDR](../hardware/dragonsdr.md), but reserved for signal classes outside DJI DroneID. Because it's a wideband SDR, **DragonSig retunes it via software** to whichever mission you've configured — there's no mission-specific SDR hardware to swap.

## How It Works

DragonSig is a single service. It runs on the kit's wideband 2nd SDR and **targets one mission at a time**. Today it ships with two mission profiles:

| Mission | Frequency | What's Detected |
|---------|-----------|-----------------|
| **Analog FPV video** | 5.x GHz | Analog video transmitters used on racing / custom drones |
| **RFD900 / 900 MHz monitoring** | 900 MHz | Telemetry from SiK / RFD900-class radios used for long-range fixed-wing / VTOL drones |

> Because the SDR is wideband, **DragonSig's mission set can expand** to additional signal classes over time without replacing hardware. Switching missions is a software reconfiguration, not a hardware swap.

The 2nd SDR is dedicated to whichever mission you've configured at any given time — DragonSig isn't sweeping FPV and 900 MHz simultaneously on a single radio. If you need persistent coverage of multiple bands at once, contact us about a kit configuration with multiple 2nd SDRs.

## What DragonSig Detects

### Analog FPV Video (5.x GHz)

Many racing and custom-built drones use analog 5 GHz video transmitters that are invisible to Remote ID detection. DragonSig:

- Sweeps the 5 GHz FPV band
- Identifies signals matching the FM envelope characteristic of analog video
- Classifies as PAL or NTSC where possible
- Emits the same alert envelope as the legacy FPV detector — DragonSync ingests without changes

This replaces the older `wardragon-fpv-detect` Python flow on supported kits.

### RFD900 / 900 MHz Monitoring

For the 900 MHz mission DragonSig monitors the 902–928 MHz ISM band typically used by SiK / RFD900-class radios that carry MAVLink telemetry between long-range fixed-wing or VTOL drones and their ground stations.

DragonSig **decodes telemetry from supported radio modems** when present and forwards it through the same WarDragon pipeline as everything else.

### Future Missions

Because the 2nd SDR covers 70 MHz – 6 GHz, DragonSig can be extended to additional signal classes over time as new mission profiles are added. The base architecture (wideband SDR + software-defined missions + ZMQ output to DragonSync) accommodates new missions without requiring kit changes.

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

When telemetry is recovered from a 900 MHz detection, position fields are populated in the `Location/Vector Message` block instead of falling back to the WarDragon's own GPS.

| Source tag | Meaning |
|------------|---------|
| `energy` | Initial energy-based detection (lower confidence) |
| `confirm` | Confirmed via classifier (higher confidence) |

## Pipeline Position

```
2nd SDR (wideband)  ──►  DragonSig  ──►  ZMQ port 4226  ──►  DragonSync  ──►  TAK / MQTT / Lattice
                                                                  ▲
                                         droneid-go (4224) ───────┤
                                         dji-receiver (4221) ─────┘
```

DragonSig publishes alerts on ZMQ port `4226` so DragonSync's `fpv_*` configuration applies directly:

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

Switching DragonSig from FPV to 900 MHz monitoring (or vice versa) is a software reconfiguration on the wideband 2nd SDR — no hardware swap. The appropriate antenna for the target band needs to be connected. Contact support for the switching procedure on your kit.

## Service Management

```bash
# Status
sudo systemctl status dragonsig

# Logs
journalctl -u dragonsig -f

# Restart
sudo systemctl restart dragonsig
```

The service runs as `User=dragon` so it can access USB SDR devices.

## Compatibility

| Kit / Variant | DragonSig Support |
|---------------|-------------------|
| Pro v5 Mobile **x86_64** | Yes — wideband 2nd SDR + DragonSig built in |
| Pro v5 Mobile **ARM64** | — (no 2nd SDR slot on ARM64 variant) |
| v1 Drop-In **x86_64** | Yes — wideband 2nd SDR + DragonSig built in |
| v1 Drop-In **ARM64** | — (no 2nd SDR slot on ARM64 variant) |
| Pro v3 / v4 | Contact us — older single-SDR architecture, see [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect) for the legacy path |

## Related Documentation

- [DragonSDR](../hardware/dragonsdr.md) — DJI DroneID detection radio (separate from DragonSig's 2nd SDR)
- [Detection Capabilities](detection-capabilities.md)
- [System Architecture](../architecture/overview.md)
- [DragonSync Configuration](dragonsync.md) — `fpv_*` settings apply
- Older single-SDR FPV flow: [wardragon-fpv-detect](https://github.com/alphafox02/wardragon-fpv-detect)
