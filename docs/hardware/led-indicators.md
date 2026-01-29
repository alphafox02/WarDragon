# LED Indicators & Status Lights

This guide explains the LED indicators on the WarDragon Pro v3 and their meanings.

## LED Overview

The WarDragon Pro v3 has several status LEDs visible through the case:

| LED | Location | Purpose |
|-----|----------|---------|
| Power | Front panel | System power status |
| Activity | Front panel | Detection/processing activity |
| Network | Front panel | Network connectivity |
| GPS | Internal (may be visible) | GPS lock status |
| ANTSDR | Internal | SDR activity |

## Power LED

| State | Meaning |
|-------|---------|
| Off | No power / power supply disconnected |
| Solid Green | System powered and running |
| Blinking Green | Booting / shutting down |
| Solid Red | Power fault (check power supply) |

## Activity LED

| State | Meaning |
|-------|---------|
| Off | System idle or not running |
| Solid Blue | System starting / initializing |
| Slow Blink (1 Hz) | Running, no detections |
| Fast Blink (2-5 Hz) | Active drone detection |
| Rapid Blink | High detection activity |

## Network LED

| State | Meaning |
|-------|---------|
| Off | No network connection |
| Solid Green | Network connected |
| Blinking Green | Network activity (data transfer) |
| Solid Amber | Connection issue / limited connectivity |

## GPS LED

| State | Meaning |
|-------|---------|
| Off | GPS module not active |
| Blinking Red | Searching for satellites (no fix) |
| Blinking Green | Acquiring fix (partial lock) |
| Solid Green | Full GPS lock (3D fix) |

## ANTSDR E200 LEDs

The internal ANTSDR E200 has its own LEDs:

| LED | State | Meaning |
|-----|-------|---------|
| Power | Solid | E200 powered |
| TX | Off | Normal (TX not used on WarDragon) |
| RX | Blinking | Receiving RF data |
| Link | Solid | USB connected to host |

## Boot Sequence

During normal boot, LEDs progress through:

1. **Power on** → Power LED solid green
2. **BIOS/Bootloader** → Activity LED solid
3. **OS Loading** → Activity LED slow blink
4. **Services Starting** → Activity LED faster blink
5. **Ready** → Activity LED slow blink, Network LED indicates connectivity

Total boot time: ~60-90 seconds

## Shutdown Sequence

During graceful shutdown:

1. **Shutdown initiated** → Activity LED fast blink
2. **Services stopping** → Activity LED slowing
3. **Power down** → All LEDs off

## Troubleshooting by LED State

### All LEDs Off

- Check power supply connection
- Verify power outlet has power
- Try different power adapter
- Check for blown fuse

### Power LED Only

- System may be stuck in boot
- Wait 5 minutes for first boot
- Check for boot media issues
- May require re-imaging

### Network LED Off (Others Normal)

- No Ethernet cable connected
- WiFi not configured
- Network hardware issue
- Check `ip addr` output

### GPS Never Solid Green

- Antenna has no sky view
- Internal antenna obstructed
- Connect external GPS antenna
- Allow more time for initial lock (up to 15 min)

### Activity LED Never Blinks Fast

- No drones in range
- Detection services not running
- Antenna connection issue
- Check `systemctl status dragonsync`

## Custom LED Behavior

Advanced users can modify LED behavior through software. The default configuration uses LEDs to indicate:

```
Activity LED → /sys/class/leds/activity/brightness
Network LED → Controlled by NetworkManager
GPS LED → Controlled by gpsd status
```

## Related Documentation

- [Hardware Overview](pro-v3-overview.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
- [Unboxing Guide](../getting-started/unboxing.md)
