#!/bin/sh
set -e

: "${PUSHGW_USER:?PUSHGW_USER is required}"
: "${PUSHGW_PASS_HASH:?PUSHGW_PASS_HASH is required}"

mkdir -p /tmp/pushgateway

{
  echo "basic_auth_users:"
  printf "  %s: %s\n" "$PUSHGW_USER" "$PUSHGW_PASS_HASH"
} > /tmp/pushgateway/web.yml

echo ">>> Config generated, starting Pushgateway..."
exec /bin/pushgateway --web.config.file=/tmp/pushgateway/web.yml
