# Lattice Integration

This guide covers integrating WarDragon with Anduril Lattice for enterprise-grade situational awareness.

> **Note**: This documentation is based on the config.ini parameters. Actual Lattice API behavior and entity formats should be verified against the DragonSync source code.

## Overview

WarDragon can export drone detection data directly to Anduril Lattice, enabling:

- Real-time drone visualization in Lattice
- Integration with other Lattice-connected sensors
- Unified command and control interface

## Prerequisites

- Active Anduril Lattice instance
- Lattice API credentials (token)
- Network connectivity to Lattice endpoint
- DragonSync configured with Lattice output enabled

## Configuration

### DragonSync Configuration

In `/home/dragon/DragonSync/config.ini`:

```ini
[SETTINGS]
# Enable Lattice integration
lattice_enabled = true

# API authentication token
lattice_token = your_api_token

# Either specify base URL directly
lattice_base_url = https://your.env.anduril.cloud

# Or specify endpoint host (https:// will be prefixed)
lattice_endpoint = your.env.anduril.cloud

# Sandbox token (can also set via SANDBOXES_TOKEN environment variable)
lattice_sandbox_token =

# Source identifier for this DragonSync instance
lattice_source_name = DragonSync

# Rate limiting (seconds between updates)
lattice_drone_rate = 1.0    # Drone entity updates
lattice_wd_rate = 0.2       # WarDragon status updates
```

### Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `lattice_enabled` | false | Enable/disable Lattice output |
| `lattice_token` | (empty) | API authentication token |
| `lattice_base_url` | (empty) | Full base URL (e.g., https://your.env.anduril.cloud) |
| `lattice_endpoint` | (empty) | Endpoint host (https:// added automatically) |
| `lattice_sandbox_token` | (empty) | Sandbox token (or use SANDBOXES_TOKEN env var) |
| `lattice_source_name` | DragonSync | Identifier for this data source |
| `lattice_drone_rate` | 1.0 | Minimum seconds between drone updates |
| `lattice_wd_rate` | 0.2 | Minimum seconds between WarDragon status updates |

### Environment Variables

The sandbox token can be set via environment variable:

```bash
export SANDBOXES_TOKEN="your_sandbox_token"
```

## Multi-WarDragon Deployment

When multiple WarDragon units report to the same Lattice instance, use unique `lattice_source_name` values to identify each unit:

```ini
[SETTINGS]
lattice_source_name = WarDragon-Site-Alpha
```

## Troubleshooting

### Connection Issues

1. **Check DragonSync logs**:
   ```bash
   journalctl -u dragonsync | grep -i lattice
   ```

2. **Verify network connectivity** to your Lattice endpoint

3. **Confirm token is valid** and has appropriate permissions

### Entities Not Appearing

1. Verify `lattice_enabled = true` in config.ini
2. Check that either `lattice_base_url` or `lattice_endpoint` is set
3. Confirm `lattice_token` is configured
4. Review DragonSync logs for errors

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [System Architecture](../architecture/overview.md)
- [TAK Integration](tak-integration.md)
