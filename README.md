# Prometheus Coolify - Monitoring Stack

A comprehensive monitoring solution using Prometheus, Node Exporter, cAdvisor, and optional Grafana visualization. This project provides both production and development Docker Compose configurations for different deployment scenarios.

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
  - [Prerequisites](#prerequisites)
  - [Environment Setup](#environment-setup)
- [🏗️ Architecture Overview](#-architecture-overview)
  - [Core Components](#core-components)
  - [Network Architecture](#network-architecture)
- [📦 Production Deployment](#-production-deployment)
  - [Capabilities](#capabilities)
  - [Services](#services)
  - [Deployment](#deployment)
- [🛠️ Development Deployment](#-development-deployment)
  - [Additional Capabilities](#additional-capabilities)
  - [Additional Services](#additional-services)
  - [Deployment](#deployment-1)
- [🔐 Password Hash Generation](#-password-hash-generation)
  - [Method 1: Make Command (Recommended)](#method-1-make-command-recommended)
  - [Method 2: Docker (Manual)](#method-2-docker-manual)
  - [Method 3: Online Tools](#method-3-online-tools)
  - [Using the Hash](#using-the-hash)
- [📡 Pushgateway](#-pushgateway)
- [🔧 Configuration Details](#-configuration-details)
  - [Prometheus Configuration](#prometheus-configuration)
  - [Environment Variables](#environment-variables)
  - [Data Persistence](#data-persistence)
- [📊 Metrics Overview](#-metrics-overview)
- [🔄 Maintenance](#-maintenance)
  - [Data Retention](#data-retention)

---

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed

### Environment Setup

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your credentials:

   ```env
   PROM_USER=your_username
   PROM_PASS=your_secure_password
   PROM_PASS_HASH=your_bcrypt_hash

   PUSHGW_USER=your_pushgateway_username
   PUSHGW_PASS=your_pushgateway_password
   PUSHGW_PASS_HASH=your_pushgateway_bcrypt_hash
   ```

3. **Generate bcrypt password hashes** (see [Password Hash Generation](#-password-hash-generation) below) — required for both `PROM_PASS_HASH` and `PUSHGW_PASS_HASH`

## 🏗️ Architecture Overview

### Core Components

- **Prometheus** - Time-series database and monitoring server
- **Node Exporter** - System metrics collector
- **cAdvisor** - Container metrics collector
- **Pushgateway** - Metrics push endpoint for ephemeral or batch jobs
- **Grafana** - Visualization and dashboards *(development only — not included in production)*
- **init-dashboards** - One-shot container that downloads Grafana dashboards before Grafana starts *(development only)*

### Network Architecture

All services run in the `monitoring` bridge network, enabling secure inter-service communication.

---

## 📦 Production Deployment

**File: `docker-compose.yaml`**

### Capabilities

- **Prometheus v3.9.1** with web authentication
- **Node Exporter** for system metrics (CPU, memory, disk, network)
- **cAdvisor** for Docker container metrics
- **Pushgateway** with mandatory basic auth
- **Data persistence** via named volumes
- **Secure authentication** using bcrypt password hashing
- **Restart policies** for high availability

### Services

#### Prometheus

- **Port:** 9090
- **Features:**
  - Web UI with basic authentication
  - 20-day data retention
  - 8GB storage limit
  - Configurable scrape intervals
  - Lifecycle API enabled

#### Node Exporter

- **Purpose:** Collects host system metrics
- **Access:** Shared within monitoring network
- **Metrics:** CPU, memory, disk, network, filesystem

#### cAdvisor

- **Port:** 9110
- **Purpose:** Monitors Docker containers
- **Privileged:** Yes (for container stats collection)

#### Pushgateway

- **Port:** 9091 (bound to `127.0.0.1` in production)
- **Purpose:** Accepts metrics pushed by external jobs (e.g. SeaweedFS)
- **Auth:** Basic auth enforced — credentials required at startup

### Deployment

```bash
# Start production stack
docker compose up -d

# View logs
docker compose logs -f

# Stop stack
docker compose down
```

---

## 🛠️ Development Deployment

**File: `docker-compose-dev.yaml`**

Extends the production stack with Grafana and automatic dashboard provisioning.

### Additional Capabilities

- **Grafana OSS** for visualization and dashboards
- **init-dashboards** one-shot service that downloads dashboards before Grafana starts
- **Health checks** for service reliability
- **Extended data persistence** with dedicated Grafana volumes

### Additional Services

#### Grafana

- **Port:** 3000
- **Features:**
  - Pre-configured data source connection to Prometheus (auto-provisioned)
  - Dashboards auto-provisioned from the `grafana-dashboards` volume
  - Health monitoring

#### init-dashboards

- **Image:** `alpine:3.23`
- **Purpose:** Downloads dashboard JSON files into the `grafana-dashboards` volume before Grafana starts
- **Sources:** `dashboards.conf` (base dashboards) + `DASHBOARDS` env var (additional dashboards)
- Runs once and exits; Grafana waits on `service_completed_successfully`

### Deployment

```bash
# Start development stack (includes Grafana)
docker compose -f docker-compose-dev.yaml up -d

# Access services
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (dev only)
# cAdvisor: http://localhost:9110
```

---

## 🔐 Password Hash Generation

### Using bcrypt

The system uses bcrypt hashing for secure password authentication. You can generate hashes using various methods:

### Method 1: Make Command (Recommended)

Run the following command in the project root:

```bash
make hash <your_password>
```

Example usage:

```bash
make hash supersecretpassword123
```

**Important:** The generated hash must have every dollar sign (`$`) immediately followed by a digit (e.g., `$2b$12$3...`). This command automatically retries generation until a compliant hash is found to satisfy script requirements.

### Method 2: Docker (Manual)

```bash
# Generate bcrypt hash for your password
docker run --rm -it python:3-alpine sh -c "
  pip install bcrypt && \
  python -c \"
import bcrypt
password = b'your_password'
salt = bcrypt.gensalt()
hashed = bcrypt.hashpw(password, salt)
print('Password:', password.decode())
print('Hash:', hashed.decode())
print('Verified:', bcrypt.checkpw(password, hashed))
\"
"
```

### Method 3: Online Tools

Use online bcrypt generators (like https://bcrypt-generator.com/) (ensure you're in a secure environment):

```bash
# Example hash format:
$2a$12$voKWceUKhMCZMYGRKZ1tue4BNBzyJKawE5TETfu0Jws5JMv6Xl3RO
```

### Using the Hash

1. Generate your bcrypt hash using any method above
2. Update your `.env` file:
   ```env
   PROM_USER=admin
   PROM_PASS=your_actual_password
   PROM_PASS_HASH=your_generated_bcrypt_hash
   ```

**Security Note:** The `PROM_PASS_HASH` / `PUSHGW_PASS_HASH` are used for web UI/API authentication (bcrypt), while `PROM_PASS` / `PUSHGW_PASS` (plaintext) are used for service-to-service scrape authentication in the Prometheus configuration.

---

## 📡 Pushgateway

The Pushgateway allows external services to push metrics into Prometheus. Basic auth is **mandatory** — both the Pushgateway and Prometheus require credentials at startup and will exit immediately if any are missing.

### Required Variables

| Variable           | Used by        | Description                         |
| ------------------ | -------------- | ----------------------------------- |
| `PUSHGW_USER`      | Both           | Username for Pushgateway auth       |
| `PUSHGW_PASS`      | Prometheus     | Plaintext password (scrape auth)    |
| `PUSHGW_PASS_HASH` | Pushgateway    | Bcrypt hash (web/API auth)          |

### Setup

1. Generate a bcrypt hash for the Pushgateway password:

   ```bash
   make hash <your_pushgateway_password>
   ```

2. Set all three variables in `.env`:

   ```env
   PUSHGW_USER=pushgateway_user
   PUSHGW_PASS=your_pushgateway_password
   PUSHGW_PASS_HASH=$2b$12$...
   ```

3. Restart the stack. Verify auth is enforced:

   ```bash
   # Should return 401
   curl http://localhost:9091/metrics

   # Should return 200
   curl -u pushgateway_user:your_pushgateway_password http://localhost:9091/metrics
   ```

### Pushing Metrics to Pushgateway

Clients must include credentials in the push URL:

```
http://<user>:<pass>@<host>:9091
```

---

## 🔧 Configuration Details

### Prometheus Configuration

The `start-prometheus.sh` script dynamically generates:

- **`/etc/prometheus/web.yml`** - Web UI authentication config
- **`/etc/prometheus/prometheus.yml`** - Scrape targets and service discovery

### Environment Variables

| Variable           | Description                              | Required |
| ------------------ | ---------------------------------------- | -------- |
| `PROM_USER`        | Prometheus username                      | Yes      |
| `PROM_PASS`        | Prometheus password (plaintext)          | Yes      |
| `PROM_PASS_HASH`   | Bcrypt hash of Prometheus password       | Yes      |
| `PUSHGW_USER`      | Pushgateway username                     | Yes      |
| `PUSHGW_PASS`      | Pushgateway password (plaintext)         | Yes      |
| `PUSHGW_PASS_HASH` | Bcrypt hash of Pushgateway password      | Yes      |
| `TZ`               | Timezone (default: America/Buenos_Aires) | Optional |
| `DASHBOARDS`       | JSON array of extra Grafana dashboards to download (dev only, see [Grafana Dashboards](#-grafana-dashboards)) | Optional |

### Data Persistence

| Volume              | Stack       | Contents                        |
| ------------------- | ----------- | ------------------------------- |
| `prometheus-data`   | Both        | Prometheus TSDB (20 days / 8GB) |
| `grafana-data`      | Dev only    | Grafana state and settings      |
| `grafana-dashboards`| Dev only    | Downloaded dashboard JSON files |

---

## 📊 Metrics Overview

### Node Exporter Metrics

- CPU, memory, disk, network usage
- Filesystem statistics
- System load and uptime

### cAdvisor Metrics

- Container resource usage
- Docker image statistics
- Container lifecycle events

### Prometheus Self-Metrics

- Configuration reloads
- Query performance
- Storage usage

---

## 📊 Grafana Dashboards

Dashboard provisioning is a development-only feature. The `init-dashboards` service downloads dashboard JSON files into the `grafana-dashboards` volume before Grafana starts. It processes two sources in order:

1. **`dashboards.conf`** — base dashboards, always downloaded (committed to the repo)
2. **`DASHBOARDS` env var** — additional dashboards, appended on top (useful for per-deploy extras or Coolify deployments where mounting files is impractical)

### `dashboards.conf` format

```
# grafana entries — downloaded from grafana.com by ID
grafana <id> <output_filename> [title]

# url entries — fetched from a raw URL (e.g. GitHub raw content)
url <raw_url> <output_filename> [title]
```

Lines starting with `#` and blank lines are ignored. Titles are optional — if omitted, the dashboard's original title is preserved.

### `DASHBOARDS` env var format

A single-line JSON array. Each entry must have `type`, `file`, and either `id` (for `grafana` type) or `url` (for `url` type). `title` is optional.

```env
DASHBOARDS=[{"type":"grafana","id":"12345","file":"my-dashboard.json","title":"My Dashboard"},{"type":"url","url":"https://example.com/dash.json","file":"dash.json","title":"Example"}]
```

### Base dashboards (dashboards.conf)

| Dashboard | ID |
|---|---|
| Node Exporter: Linux Info | 1860 |
| cAdvisor: General [CPU absolute] | 19908 |
| cAdvisor: General [Memory + IO + CPU aggregate] | 14282 |
| cAdvisor: Per Container Info | 19792 |

### Adding a Grafana.com dashboard

Find the dashboard ID on [grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards) and add a line to `dashboards.conf`:

```
grafana 12345 my-dashboard.json "My Dashboard Title"
```

Or as a `DASHBOARDS` entry:

```env
DASHBOARDS=[{"type":"grafana","id":"12345","file":"my-dashboard.json","title":"My Dashboard Title"}]
```

### Adding a URL-based dashboard

Add a `url` entry to `dashboards.conf`:

```
url https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/other/metrics/grafana_seaweedfs.json seaweedfs.json "SeaweedFS"
```

Or as a `DASHBOARDS` entry:

```env
DASHBOARDS=[{"type":"url","url":"https://raw.githubusercontent.com/seaweedfs/seaweedfs/master/other/metrics/grafana_seaweedfs.json","file":"seaweedfs.json","title":"SeaweedFS"}]
```

### Applying changes

Restart only the `init-dashboards` service to re-download dashboards without restarting the full stack:

```bash
docker compose -f docker-compose-dev.yaml up init-dashboards --force-recreate
```

---

## 🔄 Maintenance

### Data Retention

- **Time-based:** 20 days
- **Size-based:** 2GB
- **Configurable** in `start-prometheus.sh`
