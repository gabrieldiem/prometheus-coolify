#!/bin/sh
set -e

DASHBOARD_ID=$1
OUTPUT_FILE=$2
NEW_TITLE=$3

if [ -z "$DASHBOARD_ID" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <DASHBOARD_ID> <OUTPUT_FILE> [NEW_TITLE]"
    exit 1
fi

echo "Downloading dashboard $DASHBOARD_ID..."
curl -s -L "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download" -o "$OUTPUT_FILE"

echo "Configuring datasource..."
# Replace datasource placeholders
sed -i 's/\${ds_prometheus}/prometheus/g' "$OUTPUT_FILE"
sed -i 's/DS_PROMETHEUS/prometheus/g' "$OUTPUT_FILE"

if [ -n "$NEW_TITLE" ]; then
    echo "Renaming dashboard to '$NEW_TITLE'..."
    # Use a temporary file for jq processing
    tmp=$(mktemp)
    jq --arg title "$NEW_TITLE" '.title = $title' "$OUTPUT_FILE" > "$tmp" && mv "$tmp" "$OUTPUT_FILE"
fi

echo "Setting permissions..."
chown 472:472 "$OUTPUT_FILE"

echo "Dashboard $DASHBOARD_ID saved to $OUTPUT_FILE"
echo ""
