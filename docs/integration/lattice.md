# Lattice Integration

This guide covers integrating WarDragon with Anduril Lattice for enterprise-grade situational awareness.

## Overview

WarDragon can export drone detection data directly to Anduril Lattice, enabling:

- Real-time drone visualization in Lattice sandbox
- Integration with other Lattice-connected sensors
- Unified command and control interface
- Advanced analytics and correlation

## Prerequisites

- Active Anduril Lattice instance
- Lattice API credentials
- Network connectivity to Lattice endpoint
- DragonSync with Lattice output enabled

## Configuration

### DragonSync Configuration

In `config.yaml`:

```yaml
outputs:
  lattice:
    enabled: true
    endpoint: "https://lattice.example.com/api/v1"
    api_key: "your-api-key-here"

    # Optional settings
    batch_size: 10           # Detections per batch
    batch_interval: 1.0      # Seconds between batches
    retry_attempts: 3
    retry_delay: 5
```

### Authentication

Lattice requires API key authentication:

1. Obtain API credentials from your Lattice administrator
2. Store securely (consider using environment variables):

```yaml
outputs:
  lattice:
    enabled: true
    endpoint: "${LATTICE_ENDPOINT}"
    api_key: "${LATTICE_API_KEY}"
```

Or via environment:

```bash
export LATTICE_ENDPOINT="https://lattice.example.com/api/v1"
export LATTICE_API_KEY="your-api-key"
```

## Data Format

DragonSync formats detections for Lattice's entity model:

### Entity Structure

```json
{
  "entityId": "wardragon-drone-ABC123",
  "entityType": "UAS",
  "timestamp": "2024-01-15T14:30:00Z",
  "location": {
    "latitude": 40.7128,
    "longitude": -74.006,
    "altitude": 100,
    "altitudeReference": "MSL"
  },
  "velocity": {
    "speed": 15.0,
    "heading": 270,
    "verticalSpeed": 0.5
  },
  "attributes": {
    "serialNumber": "ABC123DEF456",
    "model": "DJI Mavic 3",
    "protocol": "ocusync3",
    "pilotLocation": {
      "latitude": 40.713,
      "longitude": -74.0055
    },
    "signalStrength": -65,
    "source": "wardragon-pro-v3"
  },
  "classification": "UNKNOWN",
  "confidence": 0.95
}
```

### Field Mapping

| DragonSync Field | Lattice Field | Notes |
|------------------|---------------|-------|
| drone_id | entityId | Prefixed with "wardragon-drone-" |
| drone_lat/lon | location.latitude/longitude | WGS84 |
| drone_alt | location.altitude | MSL or AGL based on source |
| speed | velocity.speed | m/s |
| heading | velocity.heading | degrees |
| serial_number | attributes.serialNumber | |
| model | attributes.model | |
| pilot_lat/lon | attributes.pilotLocation | When available |

## Lattice Visualization

### Entity Display

In Lattice sandbox, WarDragon drones appear as:

- UAS entity type
- Custom icon (if configured)
- Real-time position updates
- Track history

### Track Management

Lattice maintains tracks for detected drones:

- **Active**: Currently being detected
- **Coasting**: Lost signal, estimated position
- **Stale**: No updates, track aging out

## Advanced Configuration

### Filtering

Control which detections go to Lattice:

```yaml
outputs:
  lattice:
    enabled: true
    # Only send high-confidence detections
    min_confidence: 0.8

    # Only send specific drone types
    include_types:
      - dji_droneid
      - open_drone_id

    # Exclude certain protocols
    exclude_protocols:
      - fpv_analog
```

### Rate Limiting

Prevent overwhelming the Lattice API:

```yaml
outputs:
  lattice:
    rate_limit:
      max_per_second: 10
      burst: 50
```

### Batching

Optimize API calls by batching:

```yaml
outputs:
  lattice:
    batch:
      enabled: true
      size: 20           # Max entities per request
      interval: 2.0      # Seconds
      flush_on_change: true  # Send immediately on significant updates
```

## Multi-WarDragon Deployment

When multiple WarDragon units report to the same Lattice instance:

### Source Identification

Each WarDragon should have a unique source identifier:

```yaml
system:
  unit_id: "wardragon-site-alpha"

outputs:
  lattice:
    source_prefix: "site-alpha"
```

### Deconfliction

Lattice correlates detections from multiple sources:

- Same drone detected by multiple WarDragons
- Track fusion in Lattice
- Position averaging/selection

## Security Considerations

### API Key Protection

- Never commit API keys to version control
- Use environment variables or secrets management
- Rotate keys periodically

### Network Security

- Use TLS (HTTPS) for all Lattice connections
- Consider VPN or private network
- Implement proper firewall rules

### Data Classification

Configure handling based on data sensitivity:

```yaml
outputs:
  lattice:
    classification: "UNCLASSIFIED"
    handling_caveats: []
```

## Troubleshooting

### Connection Failed

1. **Verify endpoint URL**:
   ```bash
   curl -v https://lattice.example.com/api/v1/health
   ```

2. **Check API key**:
   ```bash
   curl -H "Authorization: Bearer $LATTICE_API_KEY" \
        https://lattice.example.com/api/v1/entities
   ```

3. **Check firewall/network**:
   ```bash
   nc -zv lattice.example.com 443
   ```

### Entities Not Appearing

1. **Check DragonSync logs**:
   ```bash
   journalctl -u dragonsync | grep -i lattice
   ```

2. **Verify data format** matches Lattice schema

3. **Check Lattice filters** aren't excluding WarDragon data

### High Latency

1. Reduce batch interval
2. Check network latency to Lattice endpoint
3. Enable flush_on_change for critical updates

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [System Architecture](../architecture/overview.md)
- [TAK Integration](tak-integration.md)
