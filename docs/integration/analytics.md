# WarDragonAnalytics

Centralized logging, analysis, and visualization platform for drone detection data from one or more WarDragon kits running DragonSync.

**Repository**: [github.com/alphafox02/WarDragonAnalytics](https://github.com/alphafox02/WarDragonAnalytics)

> **Important**: WarDragonAnalytics is designed to run on a separate server or workstation, not on the WarDragon kit itself. The resource overhead (TimescaleDB, Grafana) is better suited for a dedicated machine.

## Overview

WarDragonAnalytics aggregates DroneID/Remote ID drone detections, ADS-B aircraft tracks, and FPV signal detections from multiple WarDragon field kits into a single interface. It provides:

- **Real-time map display** of all drone and aircraft tracks across all kits
- **Time-series database** (TimescaleDB) with 30-day retention and 1-year aggregates
- **Pattern detection** to identify surveillance behavior, coordinated swarms, and anomalies
- **Pre-built Grafana dashboards** for tactical operations and analysis
- **REST API** for integration with other systems
- **CSV export** for reporting

## Architecture

```
WarDragon Kits (Field)     Analytics Server (Docker)      User Interfaces
+-----------------+        +----------------------+       +---------------+
| DragonSync API  |  --->  | Collector Service    |  ---> | Web UI :8090  |
| :8088           |        | TimescaleDB          |       | Grafana :3000 |
+-----------------+        +----------------------+       +---------------+
```

**Data collected from each kit:**
- Drones via DJI DroneID (OcuSync) and Remote ID (Bluetooth, Wi-Fi)
- Aircraft via ADS-B
- FPV signals (5.8GHz analog video)
- Kit system health (CPU, memory, disk, temperature, GPS position)

## Requirements

- Docker and Docker Compose
- 2GB RAM minimum
- 50GB storage (for ~1 month of data from 5 kits)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/alphafox02/WarDragonAnalytics.git
cd WarDragonAnalytics

# Run the quickstart script
./quickstart.sh
```

The quickstart script will:
1. Generate secure passwords and create `.env`
2. Build and start all Docker containers
3. Initialize the database schema
4. Configure Grafana with pre-built dashboards

## Access Interfaces

| Interface | URL | Purpose |
|-----------|-----|---------|
| Web UI | http://localhost:8090 | Interactive map, kit management |
| Grafana | http://localhost:3000 | Dashboards and analysis |

Default Grafana credentials are shown in the quickstart output.

## Adding WarDragon Kits

### Option A: Via Web UI (Recommended)

1. Open http://localhost:8090
2. Click "Kit Manager" in the sidebar
3. Enter the kit's API URL (e.g., `http://192.168.1.100:8088`)
4. Click "Add Kit" - the collector will start polling immediately

### Option B: Via Configuration File

Edit `config/kits.yaml`:

```yaml
kits:
  - api_url: "http://192.168.1.100:8088"
    name: "Field Kit Alpha"
    enabled: true
```

Restart the collector:

```bash
docker compose restart collector
```

## Web UI Features (Port 8090)

- Interactive Leaflet map with drone tracks
- Drone, pilot, and home location markers
- Track history trails
- Real-time updates (5-second refresh)
- Kit management interface
- CSV export

## Grafana Dashboards (Port 3000)

### Tactical Overview
- Active drone count and kit status grid
- Kit health (CPU, memory, disk, temperature)
- Drone detection timeline
- Top manufacturers detected
- Alert summary

### Pattern Analysis
- Repeated drone detections (surveillance indicators)
- Operator reuse across multiple drones
- Coordinated activity (potential swarms)
- Frequency reuse patterns

### Multi-Kit Correlation
- Drones detected by multiple kits (triangulation opportunities)
- Kit coverage data
- Detection density heatmap
- Kit handoff tracking

### Anomaly Detection
- Altitude anomalies (rapid climbs/descents)
- Speed anomalies
- Signal strength variations
- Out-of-pattern behavior

## Pattern Detection API

```bash
# Drones seen multiple times (surveillance pattern)
curl http://localhost:8090/api/patterns/repeated-drones?hours=24

# Coordinated activity (swarms)
curl http://localhost:8090/api/patterns/coordinated?hours=6

# Operator reuse across drones
curl http://localhost:8090/api/patterns/pilot-reuse?hours=12
```

## Deployment Options

### Centralized Server (Recommended)
- Deploy Analytics on a separate server, workstation, or cloud instance
- All field kits report to the central server
- Single pane of glass for all operations
- Best for multi-kit deployments and operations centers

### Hybrid
- Central server aggregates from multiple kits
- Individual operators access via Grafana/Web UI
- Field units use TAK with DragonSync for real-time situational awareness

## DragonSync Configuration

Ensure DragonSync's HTTP API is enabled on each kit in `config.ini`:

```ini
[SETTINGS]
api_enabled = true
api_host = 0.0.0.0
api_port = 8088
```

The Analytics collector polls each kit's API at regular intervals.

## Troubleshooting

### Kit Not Appearing

1. Verify DragonSync API is accessible:
   ```bash
   curl http://<kit-ip>:8088/
   ```

2. Check network connectivity from Analytics server to kit

3. Review collector logs:
   ```bash
   docker compose logs -f collector
   ```

### No Data in Dashboards

1. Verify kits are added in Kit Manager
2. Check that kits are detecting drones (view DragonSync logs on kit)
3. Confirm TimescaleDB is running:
   ```bash
   docker compose ps
   ```

## Related Documentation

- [DragonSync Configuration](../software/dragonsync.md)
- [ZMQ Data Flows](../architecture/zmq-dataflows.md)
- [TAK Integration](tak-integration.md)
