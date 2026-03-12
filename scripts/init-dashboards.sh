#!/bin/sh
# Downloads Grafana dashboards into the dashboards directory before Grafana starts.
#
# Sources (both are processed; env var is additive):
#   1. conf file argument  — plain-text dashboards.conf (base dashboards, always loaded)
#   2. DASHBOARDS env var  — JSON array of extra dashboards (Coolify / per-deploy overrides)
#
# Usage: init-dashboards.sh [conf_file] [dashboard_dir]
#   conf_file     — path to dashboards.conf (default: /dashboards.conf)
#   dashboard_dir — directory to write JSON files into (default: /dashboards)
#
# DASHBOARDS JSON format (compact, single line for .env compatibility):
#   [
#     {"type":"grafana","id":"1860","file":"node-exporter.json","title":"Node Exporter"},
#     {"type":"url","url":"https://example.com/dash.json","file":"dash.json","title":"My Dashboard"}
#   ]
set -e

CONF_FILE="${1:-/dashboards.conf}"
DASHBOARD_DIR="${2:-/dashboards}"
DOWNLOAD_SCRIPT="/download_dashboard.sh"  # companion script for grafana.com downloads

# ----------------------------------------------------------------------------
# process_entry <type> <id_or_url> <filename> <title>
#   Shared handler called by both the JSON and conf-file code paths below.
# ----------------------------------------------------------------------------
process_entry() {
  _type="$1"
  _arg2="$2"
  _filename="$3"
  _title="$4"

  case "$_type" in
    grafana)
      # Delegate to download_dashboard.sh which fetches from grafana.com by ID
      "$DOWNLOAD_SCRIPT" "$_arg2" "$DASHBOARD_DIR/$_filename" "$_title"
      ;;
    url)
      # Fetch dashboard JSON directly from the given URL
      echo "Downloading $_arg2..."
      curl -sL "$_arg2" -o "$DASHBOARD_DIR/$_filename"

      # Patch the downloaded JSON: normalise the time range, set auto-refresh,
      # and optionally override the title — all via a single jq pass
      tmp=$(mktemp)
      if [ -n "$_title" ]; then
        jq --arg t "$_title" '.time = {from:"now-1h",to:"now"} | .refresh = "5s" | .title = $t' \
          "$DASHBOARD_DIR/$_filename" > "$tmp"
      else
        jq '.time = {from:"now-1h",to:"now"} | .refresh = "5s"' \
          "$DASHBOARD_DIR/$_filename" > "$tmp"
      fi
      mv "$tmp" "$DASHBOARD_DIR/$_filename"
      chown 472:472 "$DASHBOARD_DIR/$_filename"  # 472 is the Grafana container UID
      echo "Saved to $DASHBOARD_DIR/$_filename"
      ;;
    *)
      echo "Unknown type '$_type', skipping."
      ;;
  esac
}

# ----------------------------------------------------------------------------
# Source 1: conf file (base dashboards, always processed)
# ----------------------------------------------------------------------------
if [ -f "$CONF_FILE" ]; then
  echo "Loading base dashboards from $CONF_FILE..."

  # Process each non-empty, non-comment line in the conf file.
  # Line format: <type> <id_or_url> <filename> [title]
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac  # skip blank lines and comments

    # Parse whitespace-delimited fields; title is everything after the third field
    type=$(echo "$line" | awk '{print $1}')
    arg2=$(echo "$line" | awk '{print $2}')
    filename=$(echo "$line" | awk '{print $3}')
    title=$(echo "$line" | awk '{$1=$2=$3=""; sub(/^[[:space:]]+/,""); print}')

    process_entry "$type" "$arg2" "$filename" "$title"
  done < "$CONF_FILE"
else
  echo "No dashboards.conf found at $CONF_FILE, skipping base dashboards."
fi

# ----------------------------------------------------------------------------
# Source 2: DASHBOARDS env var (JSON array, additional dashboards)
# ----------------------------------------------------------------------------
if [ -n "$DASHBOARDS" ]; then
  echo "Loading additional dashboards from DASHBOARDS env var..."

  # Convert each JSON object to a tab-separated line: type \t id_or_url \t file \t title
  # (.id // .url) picks whichever field is present for the second column.
  echo "$DASHBOARDS" \
    | jq -r '.[] | [.type, (.id // .url), .file, (.title // "")] | @tsv' \
    | while IFS=$(printf '\t') read -r type arg2 filename title; do
        process_entry "$type" "$arg2" "$filename" "$title"
      done
fi
