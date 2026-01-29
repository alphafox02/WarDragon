# LED Indicators

The WarDragon Pro v3 has minimal visible LEDs.

## Visible Indicators

| LED | Location |
|-----|----------|
| Power Button | PC power button - indicates system is on |
| ANTSDR E200 | Internal, may be partially visible |
| E200 Ethernet | Internal, standard link/activity lights |
| GPS Module | Internal, indicates GPS status |

## Verifying System Status

Since WarDragon is a headless system, verify status via:

- **Monitor + Keyboard** - Direct local access
- **Ping** - `ping <wardragon-ip>` (confirms network connectivity)
- **SSH** - Requires OpenSSH to be installed
- **Remote Desktop** - Requires RustDesk or similar to be installed

## Related Documentation

- [Hardware Overview](pro-v3-overview.md)
- [Troubleshooting](../troubleshooting/common-issues.md)
