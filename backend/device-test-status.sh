#!/usr/bin/env bash
set -euo pipefail
set +x

REMOTE_HOST="${HOOKAHBOSS_DEVICE_HOST:-timeweb_bm}"
REMOTE_DIR="${HOOKAHBOSS_DEVICE_DIR:-/opt/hookahboss}"
PROJECT="${HOOKAHBOSS_DEVICE_PROJECT:-hookahboss}"
ENV_FILE="${HOOKAHBOSS_DEVICE_ENV_FILE:-.env}"
TUNNEL_SERVICE="${HOOKAHBOSS_TUNNEL_SERVICE:-hookahboss-test-tunnel.service}"

ssh "$REMOTE_HOST" bash -s -- "$REMOTE_DIR" "$PROJECT" "$ENV_FILE" "$TUNNEL_SERVICE" <<'REMOTE'
set -euo pipefail
dir="$1"; project="$2"; env_file="$3"; tunnel_service="$4"
cd "$dir"
compose=(docker compose -p "$project" --env-file "$env_file" -f compose.device-test.yaml)
"${compose[@]}" ps
printf 'health='
curl -fsS --max-time 5 http://127.0.0.1:3010/health || true
echo
printf 'tunnel_service='
systemctl is-active "$tunnel_service" 2>/dev/null || true
url="$(journalctl -u "$tunnel_service" --no-pager -n 200 2>/dev/null | sed -nE 's#.*(https://[a-zA-Z0-9.-]+\.trycloudflare\.com).*#\1#p' | tail -1)"
printf 'tunnel_url=%s\n' "${url:-unavailable}"
REMOTE
