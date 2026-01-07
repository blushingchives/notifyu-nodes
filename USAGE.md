# NotifyU THORChain Node - Usage Guide

This guide explains how to operate the NotifyU THORChain node infrastructure, including how to perform restarts, start the snapshot container, and deploy a new service with a fresh snapshot.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [How to Start the Snapshot Container](#how-to-start-the-snapshot-container)
- [How to Start a New Service with a New Snapshot](#how-to-start-a-new-service-with-a-new-snapshot)
- [How to Perform a Restart](#how-to-perform-a-restart)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Service Architecture](#service-architecture)
- [Configuration Files](#configuration-files)

## Overview

This project runs a complete THORChain node infrastructure using Docker Compose with the following components:

- **Snapshot Service**: Downloads and extracts blockchain snapshots from Nine Realms
- **THORNode**: Main blockchain node running Tendermint/CometBFT consensus
- **Load Balancer**: HAProxy routing traffic to RPC and API endpoints
- **Nginx Proxy**: Reverse proxy for HTTP traffic and domain routing

## Prerequisites

- Docker and Docker Compose installed
- SSH keys configured (for git operations during deployment)
- Sufficient disk space for blockchain data (snapshots are several GB)
- Network access to https://snapshots.ninerealms.com

## Quick Start

For a fresh deployment with a new snapshot:

```bash
# Step 1: Start snapshot download
docker compose --profile snapshot up -d --build

# Step 2: Monitor snapshot progress
docker compose logs snapshot --follow

# Step 3: Once complete, start the node services
docker compose --profile node up -d --build
```

## How to Start the Snapshot Container

The snapshot container downloads the latest blockchain state from Nine Realms and prepares it for the THORNode.

### Step-by-Step Process

1. **Start the snapshot service:**

```bash
docker compose --profile snapshot up -d --build
```

2. **Monitor the download and extraction:**

```bash
docker compose logs snapshot --follow
```

### What Happens During Snapshot

The snapshot service performs the following operations:

1. **Fetch Latest Snapshot**: Queries `https://snapshots.ninerealms.com/snapshots?prefix=thornode` to find the newest snapshot
2. **Download**: Uses aria2 with 16 parallel connections for faster download
3. **Extract**: Decompresses the tar.gz file to `/shared-volume/data`
4. **Cleanup**: Removes the tar file after extraction
5. **Complete**: Creates `priv_validator_state.json` as a completion marker

### Snapshot Location

Downloaded snapshots are extracted to:
- **Container path**: `/data`
- **Host path**: `./shared-volume`

The THORNode service monitors this location and waits for the snapshot to be ready before starting.

## How to Start a New Service with a New Snapshot

This is the complete process for deploying a fresh node with the latest blockchain state.

### Complete Deployment Process

```bash
# Step 1: Start snapshot download
docker compose --profile snapshot up -d --build

# Step 2: Wait for snapshot to complete (monitor logs)
docker compose logs snapshot --follow

# Step 3: Start all node services
docker compose --profile node up -d --build
```

### Service Startup Sequence

Once you start the node profile, services initialize in this order:

1. **Proxy (Nginx)**: Starts immediately, listens on port 80
2. **Load Balancer (HAProxy)**: Starts immediately, listens on ports 11111 and 11112
3. **THORNode**: Waits for snapshot, then:
   - Checks for `priv_validator_state.json` in shared volume
   - Initializes node with `thornode init docker-node --chain-id=thorchain-1`
   - Downloads genesis file from Google Cloud Storage
   - Copies snapshot data to `/root/.thornode/data`
   - Copies configuration files (`app.toml`, `config.toml`)
   - Starts the blockchain node

### Verifying Startup

Check all services are running:

```bash
docker compose ps
```

Expected output should show:
- `notifyu-node-proxy-1` - running
- `notifyu-node-load-balancer-1` - running
- `notifyu-node-thornode-1` - running

Check THORNode logs:

```bash
docker compose logs thornode --follow
```

Look for:
- "Setting up node..."
- "Downloading genesis..."
- "Copying snapshot into thornode directory..."
- "Starting thornode..."

## How to Perform a Restart

There are several restart scenarios depending on your needs.

### Basic Restart (Keeps Existing Data)

Restart services without downloading a new snapshot:

```bash
docker compose --profile node restart
```

### Full Restart with Rebuild

Rebuild containers and restart (useful after configuration changes):

```bash
docker compose --profile node up -d --build --force-recreate
```

### Restart with SSH Keys (For Git Operations)

If you need to pull latest code changes:

```bash
eval `ssh-agent -s` && ssh-add ~/nodekey
docker compose --profile node up -d --build --force-recreate
```

### Complete Restart with Git Pull

Pull latest code, rebuild, and restart:

```bash
eval `ssh-agent -s` && ssh-add ~/keypair.pub && git pull && docker compose up -d --build --force-recreate
```

### Fresh Restart with New Snapshot

To start completely fresh with a new snapshot:

```bash
# Step 1: Stop all services
docker compose down

# Step 2: (Optional) Remove old snapshot data
rm -rf ./shared-volume/*

# Step 3: Start snapshot download
docker compose --profile snapshot up -d --build

# Step 4: Wait for completion, then start node services
docker compose logs snapshot --follow
docker compose --profile node up -d --build
```

### Important Notes on Restart Behavior

- The snapshot service clears `/data` before downloading to ensure a fresh state
- THORNode will skip initialization if `genesis.json` already exists in the persistent volume
- Configuration files (`app.toml`, `config.toml`) are always copied from mounted volumes on startup
- The `thornode-volume-1` persistent volume maintains blockchain data between restarts

## Monitoring and Troubleshooting

### Viewing Logs

View logs for all services:
```bash
docker compose logs --follow
```

View logs for a specific service:
```bash
docker compose logs snapshot --follow
docker compose logs thornode --follow
docker compose logs load-balancer --follow
docker compose logs proxy --follow
```

### Common Issues

**Snapshot download fails:**
- Check internet connectivity
- Verify access to https://snapshots.ninerealms.com
- Check disk space in `./shared-volume`

**THORNode stuck at "Waiting for snapshot":**
- Verify snapshot container completed successfully
- Check that `./shared-volume/data/priv_validator_state.json` exists
- Review snapshot logs: `docker compose logs snapshot`

**Services won't start:**
- Ensure correct profile is used (`--profile node` or `--profile snapshot`)
- Check port conflicts (80, 11111, 11112, 26657, 1317)
- Review service logs for specific error messages

### Checking Service Status

```bash
# List all containers
docker compose ps

# Check resource usage
docker stats

# Inspect a specific service
docker compose logs thornode --tail 100
```

### Accessing Services

- **RPC Endpoint**: http://localhost:11111 or http://your-domain
- **API Endpoint**: http://localhost:11112 or http://lcd-thornode.capybaralabs.com
- **Direct THORNode RPC**: http://localhost:26657
- **Direct THORNode API**: http://localhost:1317

## Service Architecture

### Docker Compose Profiles

The project uses two profiles:

- **snapshot**: Isolated snapshot downloader (runs independently)
- **node**: Main operational services (proxy, load-balancer, thornode)

### Network Flow

```
Internet → Nginx Proxy (port 80)
              ↓
          HAProxy Load Balancer
              ↓
          THORNode (RPC: 26657, API: 1317)
```

### Volumes

- **thornode-volume-1**: Persistent blockchain data (managed by Docker)
- **./shared-volume**: Temporary snapshot transfer location
- **./proxy**: Nginx configuration (read-only)
- **./load-balancer**: HAProxy configuration (read-only)
- **./thornode**: THORNode configuration files (read-only)

### Port Mapping

| Port | Service | Purpose |
|------|---------|---------|
| 80 | Nginx Proxy | HTTP entry point |
| 11111 | Load Balancer | RPC frontend |
| 11112 | Load Balancer | API frontend |
| 26657 | THORNode | Tendermint RPC (internal) |
| 26656 | THORNode | P2P networking (internal) |
| 1317 | THORNode | REST API (internal) |

## Configuration Files

### Key Configuration Files

| File | Purpose | Mount Location |
|------|---------|----------------|
| `docker-compose.yml` | Service orchestration | Project root |
| `thornode/config.toml` | CometBFT consensus config | `/root/.thornode/config/config.toml` |
| `thornode/app.toml` | Cosmos SDK application config | `/root/.thornode/config/app.toml` |
| `load-balancer/haproxy.cfg` | Load balancer routing rules | `/usr/local/config/haproxy.cfg` |
| `proxy/nginx.conf` | Reverse proxy configuration | `/etc/nginx/nginx.conf` |

### Modifying Configuration

Configuration files are mounted as read-only volumes. To modify:

1. Edit the file in the host directory (e.g., `./thornode/app.toml`)
2. Restart the service: `docker compose --profile node restart thornode`

Note: Configuration changes are applied on container startup.

## Maintenance

### Updating to Latest THORNode Version

1. Edit `thornode/Dockerfile` to update the version
2. Rebuild and restart:
```bash
docker compose --profile node up -d --build --force-recreate
```

### Cleaning Up Old Data

Remove unused Docker resources:
```bash
docker system prune -a --volumes
```

Remove snapshot data:
```bash
rm -rf ./shared-volume/*
```

### Backup

The persistent blockchain data is stored in the Docker volume `thornode-volume-1`. To backup:

```bash
docker run --rm -v notifyu-node_thornode-volume-1:/data -v $(pwd):/backup alpine tar czf /backup/thornode-backup.tar.gz -C /data .
```

To restore:

```bash
docker run --rm -v notifyu-node_thornode-volume-1:/data -v $(pwd):/backup alpine tar xzf /backup/thornode-backup.tar.gz -C /data
```

## Support

For issues or questions:
- Review logs: `docker compose logs --follow`
- Check Docker status: `docker compose ps`
- Verify configuration files are correctly mounted
- Ensure sufficient disk space and system resources
