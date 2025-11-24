#!/bin/sh
set -e

PROM_USER=$1
PROM_PASS=$2
PROM_PASS_HASH=$3

CONFIG_DIR="/etc/prometheus"

if [ -z "$PROM_USER" ] || [ -z "$PROM_PASS" ] || [ -z "$PROM_PASS_HASH" ]; then
  echo "Usage: /start-prometheus.sh <PROM_USER> <PROM_PASS> <PROM_PASS_HASH>"
  exit 1
fi

# echo "=================================================="
# echo ">>> Starting Prometheus bootstrap script"
# echo ">>> Received arguments:"
# echo "User:        ${PROM_USER:-<empty>}"
# echo "Password:    [hidden] (len=$PROM_PASS)"
# echo "Pass hash:   [hidden] (len=$PROM_PASS_HASH)"
# echo "=================================================="

mkdir -p "$CONFIG_DIR"

# web.yml – controls Prometheus UI login
{
  echo "basic_auth_users:"
  printf "  %s: %s\n" "$PROM_USER" "$PROM_PASS_HASH"
} > "${CONFIG_DIR}/web.yml"

# prometheus.yml – defines scrape targets with basic_auth
cat > "${CONFIG_DIR}/prometheus.yml" <<EOF
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: "prometheus"
    scrape_interval: 5s
    static_configs:
      - targets: ["localhost:9090"]
    basic_auth:
      username: "$PROM_USER"
      password: "$PROM_PASS"

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]
EOF

echo ">>> Configs generated successfully, starting Prometheus..."

exec prometheus \
  --config.file="${CONFIG_DIR}/prometheus.yml" \
  --web.config.file="${CONFIG_DIR}/web.yml" \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=20d \
  --storage.tsdb.retention.size=2GB \
  --web.enable-lifecycle
