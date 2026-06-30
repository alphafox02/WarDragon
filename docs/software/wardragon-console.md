# WarDragon Console

The WarDragon Console is a small **local web app** that runs on the kit and answers two questions: **is this kit healthy, and what is it seeing right now?** It also lets an operator with physical access (HDMI/keyboard, USB-tethered tablet, or SSH tunnel) edit a curated subset of DragonSync and DragonScope configuration without ever touching the raw INI / JSON files by hand.

**Repository**: [github.com/alphafox02/wardragon-console](https://github.com/alphafox02/wardragon-console)
**License**: MIT
**Default URL on the kit**: `http://127.0.0.1:4280/` (loopback) — plus a tether listener when a phone / tablet is connected.

> **Headless model**: All WarDragon kits are intended to run headless. The Console is the on-kit operator interface for checking health, viewing live detections, and adjusting configuration. It's complementary to the [WarDragon ATAK Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin) (which runs on an ATAK device and consumes DragonSync's HTTP API).

## What It Does

| Capability | Notes |
|------------|-------|
| Health dashboard | Pulls cached snapshots from kit-internal ZMQ ports — `wardragon_monitor` (4225), `droneid-go` health (4227), DragonSig health (4228) |
| Live detection summaries | Queries DragonSync's HTTP API: `/status`, `/drones`, `/signals` |
| Curated config editing | Schema-validated form for `config.ini` and `gps.ini`; secrets masked on non-loopback listeners |
| DragonScope config | Edits `dragonscope.cfg` (remote URL, license key, listen). DragonScope re-reads every ~30 s — no restart needed after save. |
| TAK cert upload | Stores PKCS#12 / PEM / key / CA files under `<DragonSync>/certs/` and writes absolute paths into `config.ini` |
| Restart DragonSync | One-button restart via a narrow sudoers rule (the console itself runs as `dragon`, not root) |
| Update check | Read-only — tells you when there's a newer Console or DragonSync version on GitHub. **Does not auto-apply.** |

### What it deliberately **doesn't** do

- It does **not** subscribe to the high-rate raw drone or signal ZMQ streams — the in-tab counts come from DragonSync's HTTP API instead.
- It does **not** query systemd for individual service state.
- It does **not** auto-update code. Surfacing "an update is available" is as far as it goes.

## Tabs

The console has nine tabs. Each tab is a single page — the topbar shows current drone count, signal count, and an overall health dot regardless of which tab you're on.

### Topbar (always visible)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  WarDragon Console        [drones: N]  [signals: N]  [● healthy]         │
│  Kit: <kit-id / hostname>                                                │
└──────────────────────────────────────────────────────────────────────────┘
```

### 1. Overview

The default landing tab. Quick at-a-glance picture of the kit.

```
┌───────────────────┬───────────────────┬───────────────────┐
│ Kit               │ Receiver Health   │ Detection         │
│  hostname         │  WiFi    ●        │ Activity          │
│  uptime           │  BLE     ●        │  drones now: N    │
│  CPU / mem / disk │  DJI     ●        │  signals now: N   │
│  temps            │  DragonSig ●      │  last seen: ...   │
└───────────────────┴───────────────────┴───────────────────┘
┌──────────────────────────────────────────────────────────┐
│ Operator Notes                                            │
│  (status messages, tether URL, anything actionable)       │
└──────────────────────────────────────────────────────────┘
```

Tether URL (stable and dynamic) shows up in **Operator Notes** so an operator looking at the kit's display over HDMI immediately sees the current customer-facing URL.

### 2. GPS

Just position. Pulled from `wardragon_monitor` on ZMQ 4225.

```
┌──────────────────────────────────────────────────────────┐
│ Position                                                  │
│  lat / lon / alt                                          │
│  fix type, satellites, HDOP                               │
└──────────────────────────────────────────────────────────┘
```

### 3. System

System and network detail.

```
┌───────────────────────────┬───────────────────────────┐
│ System                    │ Network                   │
│  CPU usage                │  interfaces / IPs         │
│  memory                   │  active routes            │
│  disk                     │  tether status            │
│  temperatures             │  console URL(s)           │
└───────────────────────────┴───────────────────────────┘
```

### 4. Receivers

Per-source health for the detection pipeline. This is where the dot-per-source health view lives.

```
┌──────────────────────────────┬───────────────────────────┐
│ droneid-go                   │ DragonSig                 │
│  WiFi      ● up              │  SDR state                │
│  BLE       ● up              │  phase / mode             │
│  DJI       ● up              │  noise floor              │
│  UART      ○ down (legacy)   │  Elite-only — '-' on Pro  │
│  Sniffle   ○ down (legacy)   │                           │
└──────────────────────────────┴───────────────────────────┘
```

> **About UART and Sniffle sources**: These two `droneid-go` source slots are **legacy carry-overs**. On current WarDragon Pro and Elite kits, neither is wired up:
>
> - **UART** corresponds to the old **ESP32** WiFi Remote ID board that fed droneid-go over a serial UART. Current kits use the **Alfa dual-band WiFi card** through droneid-go's native WiFi support (`-g`), so the ESP32 / UART path is no longer used.
> - **Sniffle** corresponds to the older **`sniffle-receiver` Python BLE flow** that ran on the Sonoff DragonTooth dongle. Current kits use the **TI-based Bluetooth Long Range board** through droneid-go's native BLE support (`-ble auto`), so the standalone Python Sniffle receiver is no longer used.
>
> If you see these source dots staying **down** on a Pro or Elite kit, that's expected — they're shown for compatibility with kits that still run the legacy receivers (e.g. some Pro v3 deployments). The active sources on a current kit are **WiFi**, **BLE**, and **DJI**.

### 5. Drones

Live drone tracks from DragonSync's `/drones` endpoint.

```
┌──────────────────────────────────────────────────────────┐
│ Current Drones                                            │
│  ┌────────────┬────────┬─────────┬─────────┬───────────┐ │
│  │ ID         │ Model  │ Lat/Lon │ Alt     │ Last seen │ │
│  └────────────┴────────┴─────────┴─────────┴───────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 6. Signals

Live signal alerts from `/signals` — FPV / RFD900 / future DragonSig outputs.

```
┌──────────────────────────────────────────────────────────┐
│ Current Signals                                           │
│  ┌──────────┬────────┬────────┬──────┬────────────────┐ │
│  │ Type     │ Freq   │ Source │ RSSI │ Last seen      │ │
│  └──────────┴────────┴────────┴──────┴────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 7. Config

Curated editor for `DragonSync/config.ini` and `DragonSync/gps.ini`. Schema-validated — unknown keys are preserved but not exposed unless deliberately added to the schema. Kismet and ADS-B sections are intentionally not exposed (yet).

```
┌──────────────────────────────────────────────────────────┐
│  DragonSync Config        [Restart DragonSync] [R/W]     │
│  (status / save banner)                                   │
├──────────────────────────────────────────────────────────┤
│  TAK Certificate Upload                                   │
│   type: [PKCS#12 / PEM cert / PEM key / CA]               │
│   password: [….….]                                        │
│   file:    [Choose file]  [Upload]                        │
├──────────────────────────────────────────────────────────┤
│  config.ini / gps.ini sections (folded forms)             │
│   [SETTINGS]  zmq, tak, mqtt, dragonsync, …               │
│   [GPS]       serial / baud / etc.                        │
└──────────────────────────────────────────────────────────┘
```

- **Restart DragonSync** uses the narrow sudoers rule — works from loopback always; works from tether when `WARDRAGON_CONSOLE_REMOTE_RESTART=1` (the packaged default).
- **Read/Write toggle** lets you flip between read-only browsing and editable forms.
- **Save model**: writes are atomic and create a timestamped backup beside the edited file. No-op saves short-circuit.
- **Secrets masking**: password / token / key fields are masked on non-loopback listeners. Save the masked placeholder to keep the existing secret; type a new value to replace; clear the field to remove.

### 8. DragonScope

Editor for the [DragonScope](dragonscope.md) `dragonscope.cfg` file.

```
┌──────────────────────────────────────────────────────────┐
│  DragonScope                                  [Save]     │
│  (status banner)                                          │
├──────────────────────────────────────────────────────────┤
│  dragonscope.cfg  (path)                                  │
│   remote URL                                              │
│   license key      (masked on non-loopback)               │
│   listen address                                          │
│   listen port                                             │
└──────────────────────────────────────────────────────────┘
```

DragonScope re-reads its config every ~30 s, so saves take effect without restarting any service.

### 9. Version

Version info and read-only update check.

```
┌───────────────────────────┬───────────────────────────┐
│ Version                   │ Updates                   │
│  Console version          │             [Check]       │
│  DragonSync version       │  (results: "up to date"   │
│  DragonScope version      │   or "vX.Y.Z available")  │
└───────────────────────────┴───────────────────────────┘
```

The **Check for updates** button hits GitHub and tells you when there's a newer Console or DragonSync available. It does not pull or apply.

## Install on a Kit

The console is not shipped pre-installed by default — install it on the kit after first boot:

```bash
cd ~/WarDragon
git clone https://github.com/alphafox02/wardragon-console.git
cd wardragon-console
sudo packaging/install.sh
```

`install.sh` is idempotent — re-run any time you change packaging files or pull a new version. It:

- apt-installs runtime packages (`python3-zmq`, `rsync`, `avahi-daemon`, `python3-dbus`, etc.)
- Copies source to `/opt/wardragon-console` and creates a `/usr/local/bin/wardragon-console` wrapper
- Installs `wardragon-console.service` (runs as the `dragon` user, not root)
- Installs `/etc/sudoers.d/wardragon-console` with two narrow rules (restart DragonSync, manage the tether-alias helper)
- Publishes `wardragon.local` on the LAN via Avahi
- Creates `<DragonSync>/certs/` (mode 0700) for TAK certificate uploads

See the [Console README](https://github.com/alphafox02/wardragon-console/blob/main/README.md) for installer environment overrides if your layout differs from the default (`/home/dragon/WarDragon/DragonSync`).

### Optional helpers (operator-run)

These are intentionally **not** invoked by `install.sh` — they touch system-wide config and the call is yours:

| Helper | What It Does |
|--------|-------------|
| `packaging/setup-time-sync.sh` | Installs chrony + gpsd, uses GPS as a fallback time source when internet NTP is unreachable |
| `packaging/setup-sddm-status.sh` | Adds a small status widget to the SDDM login screen (Lubuntu base) |
| `packaging/setup-pi-status-overlay.sh` | Pi OS Trixie counterpart — adds a waybar status overlay to the LightDM greeter |

## Access — Tablet / Tether

The console binds to `127.0.0.1:4280` by default. When `WARDRAGON_CONSOLE_TETHER_ENABLED=1` (the packaged default) and a USB-tethered phone or tablet appears, the console starts a second HTTP listener **on the tether interface IP only** — never `0.0.0.0`, so it never accidentally exposes itself on the LAN.

### Reaching the console from the tablet

| Tablet | Path |
|--------|------|
| **iPhone / iPad** (USB tether or WiFi) | Safari resolves `.local` natively — open `http://wardragon.local:4280/` |
| **Android over WiFi** | Firefox (handles `.local`) or a discovery app like *Service Browser* |
| **Android over USB tether** (the shipping case) | mDNS doesn't work tablet→kit on Android. Type the **stable URL** — with the default claim profile, that's `http://10.152.47.250:4280/` |

The **stable URL** comes from the `WARDRAGON_CONSOLE_TETHER_CLAIM_PROFILES` mechanism: when a tether interface comes up with an IP in a configured subnet (e.g. `10.152.47.0/24` for the Samsung tablet shipping convention), the console adds a secondary IP (e.g. `10.152.47.250`) on that interface and opens a listener bound to it. The URL stays fixed across replugs and reboots, regardless of which DHCP lease the tablet hands out.

### Trust model

Physical access to the kit = full trust. The packaged service enables remote config writes **and** remote DragonSync restart from any tether listener; the assumption is that whoever is plugged into the USB tether path has physical control. To lock down further, set `WARDRAGON_CONSOLE_REMOTE_CONFIG_WRITE=0` or `WARDRAGON_CONSOLE_REMOTE_RESTART=0` to require SSH-tunneled loopback for those operations.

## Environment Overrides

Set in `packaging/wardragon-console.service`. Useful ones:

| Variable | Default | Purpose |
|----------|---------|---------|
| `WARDRAGON_DRAGONSYNC_DIR` | `/home/dragon/WarDragon/DragonSync` | Where to read/write `config.ini`, `gps.ini` |
| `WARDRAGON_DRAGONSYNC_URL` | `http://127.0.0.1:8088` | DragonSync HTTP API endpoint |
| `WARDRAGON_DRAGONSCOPE_DIR` | auto-detected | `dragonscope.cfg` location (current convention: `dragonsdr_dji_droneid`; legacy: `antsdr_dji_droneid`) |
| `WARDRAGON_CONSOLE_HOST` | `127.0.0.1` | Loopback bind |
| `WARDRAGON_CONSOLE_PORT` | `4280` | Listener port |
| `WARDRAGON_CONSOLE_CONFIG_WRITE` | `1` | Allow loopback config writes |
| `WARDRAGON_CONSOLE_REMOTE_CONFIG_WRITE` | `1` | Allow tether config writes |
| `WARDRAGON_CONSOLE_REMOTE_RESTART` | `1` | Allow tether-triggered DragonSync restart |
| `WARDRAGON_CONSOLE_TETHER_ENABLED` | `1` | Auto-start tether listener when a phone/tablet shows up |
| `WARDRAGON_CONSOLE_TETHER_CLAIM_PROFILES` | `10.152.47.0/24=10.152.47.250` | Stable-URL profile (Samsung tablet convention) |

## Updating

```bash
cd ~/WarDragon/wardragon-console
git pull
sudo packaging/install.sh
```

Each run apt-installs anything new, rsyncs source to `/opt/wardragon-console/src/`, re-templates the systemd unit + sudoers, and restarts the service. The **Check for updates** button on the Version tab tells you when there's something to pull — read-only.

## Relationship to Other WarDragon Components

```
┌─────────────────────────────────────────────────────────────────┐
│                       WarDragon Console (port 4280)             │
│                                                                 │
│   - Reads ZMQ: 4225 (monitor), 4227 (droneid-go), 4228          │
│     (DragonSig)                                                 │
│   - Reads HTTP: DragonSync /status, /drones, /signals (8088)    │
│   - Writes: DragonSync config.ini + gps.ini, DragonScope cfg    │
│   - Restarts: dragonsync.service (via sudoers)                  │
└──────────┬────────────┬────────────┬────────────┬───────────────┘
           │            │            │            │
           ▼            ▼            ▼            ▼
       monitor    droneid-go    DragonSig     DragonSync
       (4225)      (4227)        (4228)        (8088 HTTP)
```

The Console doesn't replace anything — it observes the same data the [WarDragon ATAK Plugin](https://github.com/alphafox02/WarDragon-ATAK-Plugin) and [WarDragonAnalytics](../integration/analytics.md) consume, and gives a local on-kit operator a place to read it and tweak a curated set of settings.

## Related Documentation

- [DragonSync Configuration](dragonsync.md) — the underlying config fields the Console exposes
- [DragonScope](dragonscope.md) — the service whose config is edited from the DragonScope tab
- [DragonSig](dragonsig.md) — the Elite-only service whose health appears in the Receivers tab
- [DragonSDR](../hardware/dragonsdr.md) — the radio whose temperature / state shows up under System
- Upstream: [github.com/alphafox02/wardragon-console](https://github.com/alphafox02/wardragon-console)
