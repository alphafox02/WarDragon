# DragonScope Drone ID Service

DragonScope is an optional service that **extends DJI DroneID coverage to all current OcuSync generations**, including OcuSync 4+. With DragonScope active, DJI drones that the standard receiver can only detect at the link level — those broadcasting on current OcuSync generations — appear in the WarDragon stack with the same telemetry as earlier generations: drone position, pilot location, home point, altitude, speed, and serial number.

> DragonScope **decodes** the full DroneID telemetry stream for current OcuSync generations. O2 and earlier OcuSync 3 variants are unaffected and continue to operate fully offline regardless of DragonScope state.

**Purchase**: [cemaxecuter.com](https://cemaxecuter.com)
**Model**: Annual subscription (contact us for current pricing and availability)

## Why DragonScope

Out of the box, the [DragonSDR](../hardware/dragonsdr.md) detects current-generation OcuSync drones at the link level — it can confirm "an OcuSync 4 drone is in the area," with a hash-based identifier, the operating frequency, and RSSI. What it cannot do alone is recover the position telemetry that's broadcast over the link.

DragonScope closes that gap. Once configured, current-generation DJI detections come through the same pipeline as OcuSync 2 / 3 detections — same CoT messages, same MQTT topics, same Lattice entities, same Home Assistant sensors.

## Coverage

| OcuSync Generation | Without DragonScope | With DragonScope |
|---------------------|----------------------|------------------|
| OcuSync 2 | Full telemetry | Full telemetry (no change) |
| OcuSync 3 (standard) | Full telemetry | Full telemetry (no change) |
| OcuSync 3 Pro / OcuSync 4+ | Hash ID + frequency + RSSI (detection only) | **Full telemetry** — serial, drone GPS, pilot, home, altitude, speed |

What "full telemetry" includes:

- **Drone identification** — serial / aircraft ID
- **Drone position** — latitude, longitude, altitude
- **Pilot / operator location** — where the controller is
- **Home / takeoff location** — return-to-home point
- **Drone vector** — speed, heading, vertical speed
- **Per-flight correlation** — multiple detections of the same airframe link to the same track

## Subscription & Connectivity

DragonScope is delivered as an **annual subscription add-on**. It requires:

1. **A compatible WarDragon system** — Pro v5 (Mobile or Drop-In) or WarDragon Elite (Mobile or Drop-In)
2. **Active data connectivity** — the service operates with cloud-side resolution; the WarDragon needs ongoing network access to use it
3. **Provided activation materials** — firmware / config / key are provided with the subscription

> To purchase DragonScope or check kit compatibility, **contact us** or order through the [cemaxecuter.com store](https://cemaxecuter.com).

## Operating Modes

### Without DragonScope (Default)

OcuSync 4+ detections are published as alert tracks with a hash-based identifier (e.g. `drone-alert-{hash}`), the detection frequency, and RSSI. No position data is included — but you still know a current-generation OcuSync drone is operating in the area, and the alert is timestamped, deduplicated, and propagated to TAK / MQTT / Lattice along with everything else.

### With DragonScope (Subscribed)

Current-generation OcuSync detections include drone serial, drone GPS, pilot GPS, home point, altitude, and speed — the same fields produced for OcuSync 2 / 3. Once DragonScope is set up and running, full telemetry flows automatically through the existing pipeline.

## Architectural Position

```
DragonSDR  ──► dji-receiver (port 4221, ZMQ)  ──► droneid-go (port 4224)  ──► DragonSync
       │                ▲
       │                │ telemetry resolution (current OcuSync)
       └──► DragonScope ┘
                ▲
                └──── data connectivity ──── DragonScope service
```

DragonScope runs as a service on the WarDragon. The DragonSDR forwards current-generation detections to it; DragonScope resolves them into full telemetry and feeds the resolved data back into the dji-receiver pipeline. From DragonSync's perspective downstream, an OcuSync 4 drone is just a drone — same CoT type, same MQTT format.

## Compatibility

| Kit | DragonScope Support |
|-----|---------------------|
| WarDragon Pro v5 (Mobile or Drop-In) | Yes |
| WarDragon Elite (Mobile or Drop-In) | Yes |
| Older WarDragon kits (e.g. Pro v3) | Contact us |

## Privacy / Network

DragonScope contacts the resolution service over your active data connection. No raw RF samples leave the WarDragon. If your deployment requires fully offline operation, DragonScope is not appropriate — you'll still see current-generation OcuSync alerts at the hash-ID level via the standard DragonSDR firmware.

## Frequently Asked

**Does DragonScope replace anything in the base kit?** No — it's purely additive. OcuSync 2 / 3 telemetry continues to come from the standard receiver path; DragonScope only kicks in for the generations that need it.

**What happens if the subscription lapses?** Coverage reverts to the base kit behavior — current-generation OcuSync drones appear as `drone-alert-{hash}` alerts with frequency / RSSI but no position telemetry. O2 / O3 detection is unaffected.

**Is the subscription per-kit or per-account?** Contact us for current licensing terms.

## Related Documentation

- [DragonSDR](../hardware/dragonsdr.md) — Detection radio that DragonScope sits behind
- [Detection Capabilities](detection-capabilities.md)
- [System Architecture](../architecture/overview.md)
- [DragonSync Configuration](dragonsync.md)
- Upstream receiver: [dragonsdr_dji_droneid](https://github.com/alphafox02/dragonsdr_dji_droneid)
