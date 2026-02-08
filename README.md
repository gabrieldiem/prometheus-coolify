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
   ```

3. **Generate bcrypt password hash** (see [Password Hash Generation](#-password-hash-generation) below)

## 🏗️ Architecture Overview

### Core Components

- **Prometheus** - Time-series database and monitoring server
- **Node Exporter** - System metrics collector
- **cAdvisor** - Container metrics collector
- **Grafana** - Visualization and dashboards (development only)

### Network Architecture

All services run in the `monitoring` bridge network, enabling secure inter-service communication.

---

## 📦 Production Deployment

**File: `docker-compose.yaml`**

### Capabilities

- **Prometheus v3.7.3** with web authentication
- **Node Exporter** for system metrics (CPU, memory, disk, network)
- **cAdvisor** for Docker container metrics
- **Data persistence** via named volumes
- **Secure authentication** using bcrypt password hashing
- **Restart policies** for high availability

### Services

#### Prometheus

- **Port:** 9090
- **Features:**
  - Web UI with basic authentication
  - 20-day data retention
  - 2GB storage limit
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

### Additional Capabilities

- **Grafana OSS** for visualization and dashboards
- **Enhanced monitoring** with graphical interface
- **Health checks** for service reliability
- **Extended data persistence** with dedicated Grafana volume

### Additional Services

#### Grafana

- **Port:** 3000
- **Features:**
  - Pre-configured data source connection to Prometheus (auto-provisioned)
  - Default admin credentials (change in production)
  - Health monitoring
  - Dashboard management

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
make pass <your_password>
```

Example usage:

```bash
make pass supersecretpassword123
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

**Security Note:** The `PROM_PASS_HASH` is used for web UI authentication, while `PROM_PASS` is used for service-to-service authentication in the Prometheus configuration.

---

## 🔧 Configuration Details

### Prometheus Configuration

The `start-prometheus.sh` script dynamically generates:

- **`/etc/prometheus/web.yml`** - Web UI authentication config
- **`/etc/prometheus/prometheus.yml`** - Scrape targets and service discovery

### Environment Variables

| Variable         | Description                              | Required |
| ---------------- | ---------------------------------------- | -------- |
| `PROM_USER`      | Prometheus username                      | Yes      |
| `PROM_PASS`      | Prometheus password (plaintext)          | Yes      |
| `PROM_PASS_HASH` | Bcrypt hash of password                  | Yes      |
| `TZ`             | Timezone (default: America/Buenos_Aires) | Optional |

### Data Persistence

- **Production:** `prometheus-data` volume for Prometheus metrics
- **Development:** `prometheus-data` + `grafana-data` volumes

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

## 🔄 Maintenance

### Data Retention

- **Time-based:** 20 days
- **Size-based:** 2GB
- **Configurable** in `start-prometheus.sh`
