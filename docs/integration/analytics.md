# WarDragonAnalytics

WarDragonAnalytics provides a dashboard and data visualization stack for analyzing drone detection data over time.

**Repository**: [github.com/alphafox02/WarDragonAnalytics](https://github.com/alphafox02/WarDragonAnalytics)

## Overview

WarDragonAnalytics ingests drone detection data from WarDragon and provides:

- Real-time dashboards
- Historical analysis
- Detection statistics
- Geographic visualization
- Trend analysis

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        WarDragon                                │
│                                                                 │
│  DragonSync ──► ZMQ ──► WarDragonAnalytics                     │
│                  │                                              │
│                  └──► MQTT ──► InfluxDB/TimescaleDB            │
│                                      │                          │
│                                      ▼                          │
│                                  Grafana                        │
│                               (Dashboards)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Installation

### Docker Deployment (Recommended)

```bash
# Clone the repository
git clone https://github.com/alphafox02/WarDragonAnalytics.git
cd WarDragonAnalytics

# Configure environment
cp .env.example .env
nano .env

# Start the stack
docker-compose up -d
```

### Environment Configuration

Edit `.env`:

```bash
# WarDragon Connection
WARDRAGON_ZMQ_ADDRESS=tcp://192.168.1.10:5556
WARDRAGON_MQTT_BROKER=192.168.1.10
WARDRAGON_MQTT_PORT=1883

# Database
INFLUXDB_ADMIN_USER=admin
INFLUXDB_ADMIN_PASSWORD=secure_password
INFLUXDB_BUCKET=wardragon

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_password
```

## Components

### Data Ingestion

WarDragonAnalytics can ingest data via:

| Method | Use Case |
|--------|----------|
| ZMQ Subscription | Direct, real-time |
| MQTT Subscription | Via broker, distributed |
| HTTP API | Pull-based, periodic |

### Time-Series Database

Detection data is stored in InfluxDB or TimescaleDB:

**InfluxDB Schema**:

```
Measurement: drone_detections
Tags:
  - drone_id
  - drone_model
  - detection_source
  - protocol
Fields:
  - lat (float)
  - lon (float)
  - altitude (float)
  - speed (float)
  - heading (float)
  - rssi (float)
  - pilot_lat (float)
  - pilot_lon (float)
Timestamp: detection time
```

### Grafana Dashboards

Pre-configured dashboards include:

| Dashboard | Description |
|-----------|-------------|
| Real-Time | Current detections and status |
| Historical | Detection trends over time |
| Geographic | Map-based visualization |
| Statistics | Detection counts and patterns |
| Alerts | Active alerts and thresholds |

## Accessing Dashboards

After deployment:

1. Open browser to `http://<wardragon-ip>:3000`
2. Login with configured credentials
3. Navigate to Dashboards

### Real-Time Dashboard

Shows:
- Currently active drones
- Live map with drone positions
- Detection rate graph
- System health status

### Historical Dashboard

Shows:
- Total detections over time
- Unique drones seen
- Detection by protocol
- Peak activity times

### Geographic Dashboard

Shows:
- Heat map of detection locations
- Pilot location clusters
- Flight path reconstruction
- Geofence violations

## Configuration

### Data Retention

Configure how long data is retained:

**InfluxDB**:
```bash
# Create retention policy
influx -execute "CREATE RETENTION POLICY one_year ON wardragon DURATION 365d REPLICATION 1 DEFAULT"
```

**Docker Compose** (in `docker-compose.yml`):
```yaml
services:
  influxdb:
    environment:
      - INFLUXDB_DB=wardragon
      - INFLUXDB_RETENTION_POLICY_ENABLED=true
      - INFLUXDB_RETENTION_POLICY_DURATION=365d
```

### Alert Configuration

Configure Grafana alerts for:

1. **New drone detection**:
   - Alert when new serial number seen
   - Notify via email, Slack, webhook

2. **Geofence violation**:
   - Alert when drone enters defined area
   - High-priority notification

3. **Repeat offender**:
   - Alert when same drone returns
   - Track patterns

### Grafana Alert Example

```yaml
# In Grafana UI or provisioning
alert:
  name: "Drone in Restricted Zone"
  conditions:
    - query: A
      reducer: count
      evaluator: { type: gt, params: [0] }
  for: 0m
  frequency: 10s
  query:
    - refId: A
      datasource: InfluxDB
      query: |
        SELECT count("lat") FROM "drone_detections"
        WHERE lat > 40.710 AND lat < 40.715
        AND lon > -74.010 AND lon < -74.005
        AND time > now() - 1m
```

## Integration with DragonSync

### ZMQ Direct Subscription

WarDragonAnalytics can subscribe directly to DragonSync's ZMQ streams:

```python
# In analytics configuration
inputs:
  zmq:
    enabled: true
    endpoints:
      - address: "tcp://192.168.1.10:5556"
        type: dji_droneid
      - address: "tcp://192.168.1.10:5557"
        type: droneid
```

### MQTT Subscription

Or subscribe via MQTT broker:

```python
inputs:
  mqtt:
    enabled: true
    broker: "192.168.1.10"
    port: 1883
    topic: "wardragon/drones/#"
```

## Custom Queries

### InfluxDB Query Examples

**Detections per day**:
```sql
SELECT count("lat") FROM "drone_detections"
WHERE time > now() - 30d
GROUP BY time(1d)
```

**Unique drones this week**:
```sql
SELECT count(distinct("drone_id")) FROM "drone_detections"
WHERE time > now() - 7d
```

**Average flight altitude by model**:
```sql
SELECT mean("altitude") FROM "drone_detections"
WHERE time > now() - 30d
GROUP BY "drone_model"
```

**Most active hours**:
```sql
SELECT count("lat") FROM "drone_detections"
WHERE time > now() - 30d
GROUP BY time(1h)
```

## Backup and Export

### Export Data

```bash
# InfluxDB export
influxd backup -portable /backup/wardragon

# Or export specific timerange
influx -execute "SELECT * FROM drone_detections WHERE time > '2024-01-01'" -format csv > detections.csv
```

### Import Data

```bash
# Restore from backup
influxd restore -portable /backup/wardragon
```

## Troubleshooting

### No Data in Dashboards

1. **Check data ingestion**:
   ```bash
   docker-compose logs -f ingest
   ```

2. **Verify InfluxDB has data**:
   ```bash
   influx -execute "SELECT count(*) FROM drone_detections"
   ```

3. **Check Grafana datasource connection**

### High Memory Usage

1. Reduce retention period
2. Downsample old data
3. Increase container memory limits

### Slow Queries

1. Add indexes to frequently queried tags
2. Use continuous queries for aggregations
3. Optimize time range selections

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [MQTT Integration](mqtt-homeassistant.md)
- [System Architecture](../architecture/overview.md)
