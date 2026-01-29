# LED Indicators & Status Lights

This guide explains the visible LED indicators on the WarDragon Pro v3.

## Visible LEDs

The WarDragon Pro v3 has minimal external indicators. The following lights may be visible:

| LED | Location | Purpose |
|-----|----------|---------|
| Power Button | PC | System power on |
| ANTSDR E200 | Internal (partially visible) | SDR status |
| E200 Ethernet | Internal (partially visible) | Network link/activity |
| GPS | Internal (partially visible) | GPS module status |

## Power Button LED

| State | Meaning |
|-------|---------|
| On | System is powered and running |
| Off | System is off or no power |

## ANTSDR E200 LED

The E200's LED may be partially visible through the case:

| State | Meaning |
|-------|---------|
| Solid | E200 powered and operational |
| Blinking | RF activity |

## E200 Ethernet Lights

The E200 has standard Ethernet LEDs:

| LED | State | Meaning |
|-----|-------|---------|
| Link | Solid | Network connected |
| Activity | Blinking | Network traffic |

## GPS LED

| State | Meaning |
|-------|---------|
| Blinking | Searching for satellites |
| Solid | GPS lock acquired |

## Verifying System Status

Since the WarDragon Pro v3 is a headless system, the primary way to verify status is via:

1. **SSH connection** - If you can SSH in, the system is running
2. **Web interface** - Access via browser
3. **Network scan** - Check if the device responds to ping

```bash
# Check if WarDragon is responding
ping <wardragon-ip>

# SSH to verify services
ssh dragon@<wardragon-ip>
sudo systemctl status dragonsync
```

## Related Documentation

- [Hardware Overview](pro-v3-overview.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
- [Unboxing Guide](../getting-started/unboxing.md)
