#!/usr/bin/env bash
set -euo pipefail
set +x

REMOTE_HOST="${HOOKAHBOSS_DEVICE_HOST:-timeweb_bm}"
REMOTE_DIR="${HOOKAHBOSS_DEVICE_DIR:-/opt/hookahboss}"
PROJECT="${HOOKAHBOSS_DEVICE_PROJECT:-hookahboss}"
ENV_FILE="${HOOKAHBOSS_DEVICE_ENV_FILE:-.env}"
TUNNEL_SERVICE="${HOOKAHBOSS_TUNNEL_SERVICE:-hookahboss-test-tunnel.service}"
RESTART_TUNNEL=false
case "${1:-}" in
  "") ;;
  --restart-tunnel) RESTART_TUNNEL=true ;;
  *) echo "usage: $0 [--restart-tunnel]" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo "usage: $0 [--restart-tunnel]" >&2; exit 2; }

command -v docker >/dev/null
command -v ssh >/dev/null
command -v rsync >/dev/null
command -v scp >/dev/null

IMAGE_ARCHIVE="$(mktemp -t hookahboss-device-image.XXXXXX.tar)"
trap 'rm -f "$IMAGE_ARCHIVE"' EXIT

echo "Building linux/amd64 device-test image..."
docker buildx build --platform linux/amd64 --output "type=docker,dest=${IMAGE_ARCHIVE}" -t hookahboss-api:device-test backend

echo "Checking remote configuration..."
ssh "$REMOTE_HOST" "test -s '$REMOTE_DIR/$ENV_FILE' && mkdir -p '$REMOTE_DIR/backend'"
rsync -a --delete --exclude node_modules --exclude reports backend/ "$REMOTE_HOST:$REMOTE_DIR/backend/"
rsync -a compose.device-test.yaml "$REMOTE_HOST:$REMOTE_DIR/compose.device-test.yaml"
scp "$IMAGE_ARCHIVE" "$REMOTE_HOST:$REMOTE_DIR/hookahboss-api-device-test.tar"

echo "Loading image, migrating and seeding..."
ssh "$REMOTE_HOST" bash -s -- "$REMOTE_DIR" "$PROJECT" "$ENV_FILE" <<'REMOTE'
set -euo pipefail
set +x
dir="$1"; project="$2"; env_file="$3"
cd "$dir"
compose=(docker compose -p "$project" --env-file "$env_file" -f compose.device-test.yaml)
docker load -i hookahboss-api-device-test.tar >/dev/null
rm -f hookahboss-api-device-test.tar
"${compose[@]}" up -d --no-build postgres
postgres_id="$("${compose[@]}" ps -q postgres)"
[[ -n "$postgres_id" ]]
for _ in $(seq 1 40); do
  state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$postgres_id")"
  [[ "$state" == healthy ]] && break
  [[ "$state" == unhealthy || "$state" == exited || "$state" == dead ]] && { echo "PostgreSQL failed: $state" >&2; exit 1; }
  sleep 2
done
[[ "$(docker inspect --format '{{.State.Health.Status}}' "$postgres_id")" == healthy ]]
for command in \
  'node dist/src/db/migrate.js' \
  'node dist/src/db/importCatalogSeed.js' \
  'node dist/src/db/importMixSeed.js' \
  'node dist/src/db/importArticleSeed.js'; do
  "${compose[@]}" run --rm --no-deps api sh -c "$command"
done
"${compose[@]}" up -d --no-build api
for _ in $(seq 1 30); do
  if curl -fsS --max-time 3 http://127.0.0.1:3010/health >/dev/null; then break; fi
  sleep 2
done
curl -fsS --max-time 5 http://127.0.0.1:3010/health
echo
"${compose[@]}" exec -T postgres psql -U hookahboss -d hookahboss -Atc \
  "SELECT 'brands='||count(*) FROM brands WHERE status='published' UNION ALL SELECT 'products='||count(*) FROM tobacco_products WHERE status='published' UNION ALL SELECT 'mixes='||count(*) FROM official_mixes WHERE status='published' UNION ALL SELECT 'articles='||count(*) FROM articles WHERE status='published';"
REMOTE

if [[ "$RESTART_TUNNEL" == true ]]; then
  echo "Explicitly restarting tunnel service; its public URL may change..."
  ssh "$REMOTE_HOST" "sudo systemctl restart '$TUNNEL_SERVICE'"
else
  echo "Tunnel was not restarted. Use --restart-tunnel explicitly only when a changed URL is acceptable."
fi
