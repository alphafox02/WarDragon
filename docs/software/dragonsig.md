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
| **mLRS** *(active work)* | Multi-band | mLRS control links used on long-range drones | **Detection + MAVLink extraction** from the mLRS link (GPS, heading, telemetry) |
| **ELRS** *(planned / on roadmap)* | Multi-band | ExpressLRS control links used on FPV / racing drones | Detection and characterization |

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

### mLRS *(Active Work)*

**mLRS** is an open long-range LoRa-based control-link protocol used on custom and long-range drones (Matek mR900 and similar). Unlike SiK / RFD900, mLRS is a frequency-hopping LoRa link, so it requires a purpose-built detector — that's the mLRS piece of DragonSig.

DragonSig's mLRS work goes beyond just detecting the link — it **extracts MAVLink telemetry directly from the mLRS link** and forwards it through the same alert pipeline used for RFD900. When MAVLink position and heading data are recovered, they populate the track's `Location/Vector Message` block instead of falling back to the WarDragon's own GPS.

**Bands**: EU868 and FCC915 are both supported. On the shipping profile the mLRS phase runs at **915 MHz**, so it shares the same 900 MHz antenna as the RFD900 mission — no retune when switching between them.

**Two alert sources**. DragonSig separates link presence from verified position:

| Source | Meaning | Position included? |
|--------|---------|-------------------|
| `mlrs_confirm` | RF / link confirmed — a specific mLRS link is present in range | No (RF contact only) |
| `mlrs_reasm` | Reassembled MAVLink packet where all CRC checks pass **and** GPS coordinates pass sanity checks | **Yes** — full drone position |

Only `mlrs_reasm` events elevate an mLRS contact to a tracked drone in DragonSync (with a real lat / lon on the map). `mlrs_confirm` stays visible as an RF contact — you know something is there, just not where.

**Identity**. Each mLRS link is identified by a stable per-link 16-bit identifier that stays the same across every frequency hop, so one hopping aircraft produces one ATAK marker rather than one per channel. In DragonSync output the drone shows up as **`MLRS-LINK-<XXXX>`** where `<XXXX>` is the hex link ID.

### ELRS *(Planned)*

Detection and characterization of ExpressLRS control links is on the DragonSig roadmap.

## Output

DragonSig emits the same ASTM F3411-shaped JSON envelope for every mission — DragonSync subscribes on port `4226` and ingests without changes. The specific field values differ by mission.

### FPV alert envelope

```json
[
  {"Basic ID": {"id_type": "Serial Number (ANSI/CTA-2063-A)", "id": "fpv-alert-5945.200MHz", "description": "FPV Signal"}},
  {"Location/Vector Message": {"latitude": 35.123, "longitude": -78.456, "geodetic_altitude": 100.0}},
  {"Self-ID Message": {"text": "FPV alert (confirm)"}},
  {"Frequency Message": {"frequency": 5945200000}},
  {"Signal Info": {"source": "confirm", "center_hz": 5945200000, "bandwidth_hz": 4200000, "rssi": -90.5}}
]
```

Source tags for FPV:

| Source tag | Meaning |
|------------|---------|
| `energy` | Initial energy-based detection (lower confidence) |
| `confirm` | Confirmed via classifier (higher confidence) |

### mLRS alert envelope

For an mLRS link with a verified MAVLink-derived GPS position:

```json
[
  {"Basic ID": {
    "id_type": "Signal",
    "id": "MLRS-LINK-7C85",
    "transport": "LoRa-FHSS",
    "frequency_mhz": 920,
    "RSSI": 15
  }},
  {"Location/Vector Message": {
    "op_status": "Airborne",
    "latitude": "40.712800",
    "longitude": "-74.006000",
    "geodetic_altitude": "100.000000 m"
  }},
  {"Self-ID Message": {"text": "MAVLink drone Link 7C85 on mLRS FHSS"}},
  {"Signal Info": {
    "source": "mlrs_reasm",
    "signal_type": "lora_css",
    "has_mavlink": true,
    "center_hz": 920000000,
    "link_id": 31877,
    "rssi": 15.0
  }}
]
```

For a link that's been detected but has not yet produced a verified position, the shape is the same but `source` is `mlrs_confirm`, `has_mavlink` is `false`, and the `Location/Vector Message` is absent (the alert stays an RF contact rather than becoming a tracked drone).

Source tags for mLRS:

| Source tag | Meaning | Elevates to tracked drone? |
|------------|---------|:---:|
| `mlrs_confirm` | Link presence confirmed, no verified position yet | No — RF contact only |
| `mlrs_reasm` | CRC-clean MAVLink packet, GPS coordinates sanity-checked | **Yes** — track with real lat/lon |

DragonSync sees the `MLRS-LINK-<XXXX>` identity as the drone ID, so one hopping link produces one persistent track / one ATAK marker across every frequency hop and every reassembly cycle.

### RFD900 / SiK

The SiK / RFD900 mission uses the same envelope shape with a `signal_type` reflecting the SiK link and a stable `NETID`-based identity — see the mLRS layout above for the general structure.

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

Switching DragonSig between FPV, RFD900, mLRS, and (future) ELRS missions is a software reconfiguration on the BladeRF — no hardware swap. The appropriate antenna for the target band needs to be connected. Contact support for the switching procedure on your kit.

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
