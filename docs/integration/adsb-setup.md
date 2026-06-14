# ADS-B / 978 Integration

WarDragon can ingest aircraft tracks from a local [readsb](https://github.com/wiedehopf/readsb) instance and forward them as CoT to TAK/ATAK and as JSON to MQTT alongside drone detections. This is useful for situational awareness (where are the commercial / GA aircraft relative to the drones we're tracking?) and is the same pipeline that powers the aircraft layer in [WarDragonAnalytics](analytics.md).

> **Status:** Experimental. Setup is a multi-step process and requires SDR planning — see [SDR Considerations](#sdr-considerations) before starting.

## Overview

```
Antenna → SDR (1090 / 978 MHz) → readsb → HTTP API → DragonSync → CoT / MQTT
```

DragonSync polls the local readsb HTTP API and, for each aircraft with a valid position, builds a CoT message with position, altitude, speed, track, and a `<remarks>` block containing hex code, callsign, squawk, registration, and category. Accuracy fields (CE/LE) are derived from NACp/NACv when readsb provides them.

## SDR Considerations

The base WarDragon kits include a single dedicated SDR — the [DragonSDR](../hardware/dragonsdr.md) — and that radio is reserved for DJI DroneID detection. ADS-B reception needs its own RF front-end, so you have two practical paths:

| Setup | Trade-off |
|-------|-----------|
| **Repurpose the DragonSDR for ADS-B temporarily** | You lose DJI DroneID detection while it's tuned to 1090/978 MHz. Useful for demos, lab work, or environments where DJI detection isn't required. |
| **Add a dedicated ADS-B SDR (recommended)** | Plug an additional USB SDR (RTL-SDR is the common choice for 1090 / 978 MHz) into the WarDragon. DJI detection on the DragonSDR continues uninterrupted. |

> **Note for WarDragon Elite kits**: the BladeRF is used by [DragonSig](../software/dragonsig.md) for FPV / RFD900 / ELRS monitoring — so even on Elite, ADS-B requires a separate USB SDR (an RTL-SDR is the common choice).

A purpose-built ADS-B antenna helps a lot. The stock dual-band antennas will pick up the strongest 1090 MHz returns but range is limited.

---

## Setup

### 1. Start readsb

#### RTL-SDR (Recommended)

The simplest configuration — plug an RTL-SDR into a free USB port and run:

```bash
sudo readsb \
  --device-type rtlsdr \
  --freq=1090000000 \
  --no-interactive \
  --write-json=/run/readsb \
  --write-json-every=1 \
  --json-location-accuracy=2 \
  --net-bind-address=0.0.0.0 \
  --net-api-port=8080
```

#### DragonSDR / Pluto-Compatible (via SoapySDR)

If you're repurposing the DragonSDR for ADS-B (and accepting the loss of DJI detection while it's tuned to 1090 MHz):

```bash
sudo readsb \
  --device-type soapysdr \
  --soapy-device="driver=plutosdr" \
  --freq=1090000000 \
  --no-interactive \
  --write-json=/run/readsb \
  --write-json-every=1 \
  --json-location-accuracy=2 \
  --net-bind-address=0.0.0.0 \
  --net-api-port=8080 \
  --soapy-enable-agc \
  --sdr-buffer-size=128
```

> Before doing this, stop the dji-receiver service so it doesn't conflict for the DragonSDR:
> ```bash
> sudo systemctl stop dji-receiver
> ```

#### Key Options

| Option | Description |
|--------|-------------|
| `--freq=1090000000` | 1090 MHz for standard ADS-B (worldwide) |
| `--freq=978000000` | 978 MHz for UAT (US only) |
| `--net-api-port=8080` | HTTP API port DragonSync polls |
| `--device-type` | `soapysdr`, `rtlsdr`, etc. |
| `--soapy-device` | SoapySDR device string |
| `--write-json=/run/readsb` | Where readsb writes its JSON state |

### 2. Verify readsb

Test the HTTP API:

```bash
curl -s http://127.0.0.1:8080/?all_with_pos | jq '.aircraft | length'
```

You should see a count of aircraft with positions. `0` or an error means readsb isn't receiving data — check the antenna and SDR connection.

### 3. Configure DragonSync

Add to `/home/dragon/DragonSync/config.ini`:

```ini
[SETTINGS]

# ADS-B / UAT aircraft ingestion
adsb_enabled = true
adsb_json_url = http://127.0.0.1:8080/?all_with_pos

# How frequently to fetch from readsb (seconds)
adsb_rate_limit = 3.0

# How long after last seen before CoT goes stale (seconds)
adsb_cot_stale = 15

# Internal track cache time-to-live (seconds)
adsb_cache_ttl = 120

# UID prefix for ADS-B CoT events
adsb_uid_prefix = adsb-

# Optional altitude gates (feet). 0 = disabled.
adsb_min_alt = 0
adsb_max_alt = 0
```

Then restart DragonSync:

```bash
sudo systemctl restart dragonsync
```

#### Altitude Filtering

```ini
# Only show aircraft below 10,000 feet
adsb_max_alt = 10000

# Only show aircraft above 1,000 feet (ignore ground traffic)
adsb_min_alt = 1000

# Both: 1,000 to 10,000 feet
adsb_min_alt = 1000
adsb_max_alt = 10000
```

Set either to `0` to disable that side of the filter.

---

## How It Works

1. DragonSync polls `adsb_json_url` at the cadence set by `adsb_rate_limit`
2. Expects readsb-style JSON with an `aircraft` array
3. For each aircraft with a valid position:
   - Builds a CoT message with position, altitude, speed, track
   - Includes hex code, callsign, squawk, registration, category in remarks
   - Derives accuracy (CE/LE) from NACp/NACv when available
4. Outputs CoT via the configured TAK server or multicast — same pipeline as drone detections

### CoT Mapping

| readsb Field | CoT Element |
|--------------|-------------|
| `hex` | UID suffix (with `adsb_uid_prefix`) |
| `lat`, `lon` | Point position |
| `alt_geom` or `alt_baro` | HAE (converted to meters) |
| `gs` | Speed (converted to m/s) |
| `track` | Course |
| `flight` | Callsign in remarks |
| `squawk` | Squawk in remarks |
| `category` | Aircraft category in remarks |
| `nac_p`, `nac_v` | CE/LE accuracy |

---

## MQTT Output

To publish aircraft data to MQTT, enable aircraft publishing in `config.ini`:

```ini
mqtt_enabled = true
mqtt_aircraft_enabled = true
mqtt_aircraft_topic = wardragon/aircraft
```

Aircraft tracks publish to the configured topic (default: `wardragon/aircraft`):

```json
{
  "icao": "A12345",
  "callsign": "UAL123",
  "registration": "N12345",
  "lat": 39.1234,
  "lon": -77.5678,
  "alt": 35000,
  "speed": 450,
  "track": 270,
  "squawk": "1200",
  "category": "A3",
  "on_ground": false,
  "rssi": -8.5,
  "track_type": "aircraft"
}
```

For Home Assistant integration and field-by-field schema details see [MQTT & Home Assistant](mqtt-homeassistant.md).

### Signal Strength (RSSI)

The `rssi` field on aircraft tracks contains signal strength from readsb, measured in **dBFS** (decibels relative to full scale), not dBm.

| Value | Meaning |
|-------|---------|
| 0 dBFS | Maximum signal (ADC saturation) |
| -10 dBFS | Very strong signal |
| -20 dBFS | Good signal |
| -30 dBFS | Weak signal |

- dBFS is relative to the SDR's ADC, not absolute power
- Values depend on SDR gain settings
- For multi-kit triangulation, all kits should use similar gain settings
- `rssi` may be `null` if readsb doesn't provide it (older versions or certain configurations)

---

## Running readsb as a Service

For persistent operation, run readsb under systemd. Create `/etc/systemd/system/readsb.service`:

```ini
[Unit]
Description=readsb ADS-B receiver
After=network.target

[Service]
ExecStart=/usr/bin/readsb \
  --device-type rtlsdr \
  --freq=1090000000 \
  --no-interactive \
  --write-json=/run/readsb \
  --write-json-every=1 \
  --json-location-accuracy=2 \
  --net-bind-address=0.0.0.0 \
  --net-api-port=8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable readsb
sudo systemctl start readsb
sudo systemctl status readsb
```

Adjust `ExecStart` for your SDR — replace the `--device-type` and `--soapy-device` arguments as needed.

---

## Troubleshooting

| Issue | Diagnosis | Resolution |
|-------|-----------|-----------|
| No aircraft in ATAK | `curl http://127.0.0.1:8080/?all_with_pos` returns empty / error | readsb isn't receiving — check SDR, antenna, line of sight |
| readsb won't start | Permission denied on SDR device | Add udev rules for RTL-SDR; verify user can access `/dev/bus/usb/*` |
| SoapySDR device not found | `SoapySDRUtil --find` shows no devices | Reinstall SoapySDR modules for your SDR vendor |
| Only some aircraft appear | Endpoint URL wrong | Use `/?all_with_pos` (not just `/?`) — many endpoints require positions |
| High CPU on DragonSync | Polling too often | Increase `adsb_rate_limit` (in seconds between polls) |
| Conflicts with DJI detection | DragonSDR repurposed | Stop `dji-receiver` while DragonSDR is on 1090 MHz; restart it when reverting |

### Common readsb Issues

**Permission denied on SDR:**

```bash
# Add udev rules for RTL-SDR
sudo cp rtl-sdr.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**SoapySDR device discovery:**

```bash
SoapySDRUtil --find
SoapySDRUtil --probe="driver=plutosdr"
```

---

## Frequency Reference

| Frequency | Service | Region |
|-----------|---------|--------|
| 1090 MHz | ADS-B (Mode S) | Worldwide |
| 978 MHz | UAT (ADS-B) | United States only, below 18,000 ft |

International flights and high-altitude traffic use 1090 MHz exclusively. 978 MHz UAT is a US-only General Aviation band — ignore it outside the US.

---

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md) — full `adsb_*` parameter reference
- [TAK Integration](tak-integration.md) — where the CoT goes
- [MQTT & Home Assistant](mqtt-homeassistant.md) — aircraft topic / field reference
- [WarDragonAnalytics](analytics.md) — visualizes aircraft alongside drones in the multi-kit dashboard
- Upstream: [DragonSync ADS-B Setup](https://github.com/alphafox02/DragonSync/blob/main/docs/adsb-setup.md)
- Upstream: [readsb](https://github.com/wiedehopf/readsb)
