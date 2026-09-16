#!/usr/bin/env bash
set -euo pipefail
set +x

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_HOST="${HOOKAHBOSS_PRODUCTION_HOST:-timeweb_bm}"
REMOTE_DIR="${HOOKAHBOSS_PRODUCTION_DIR:-/opt/hookahboss}"
PROJECT="${HOOKAHBOSS_PRODUCTION_PROJECT:-hookahboss}"
ENV_FILE="${HOOKAHBOSS_PRODUCTION_ENV_FILE:-.env.production}"

command -v docker >/dev/null
command -v ssh >/dev/null
command -v rsync >/dev/null
command -v scp >/dev/null

IMAGE_ARCHIVE="$(mktemp -t hookahboss-production-image.XXXXXX.tar)"
trap 'rm -f "$IMAGE_ARCHIVE"' EXIT

docker buildx build --platform linux/amd64 \
  --output "type=docker,dest=${IMAGE_ARCHIVE}" \
  -t hookahboss-api:production "$SCRIPT_DIR"

ssh "$REMOTE_HOST" "test -s '$REMOTE_DIR/$ENV_FILE' && mkdir -p '$REMOTE_DIR/backend'"
rsync -a --delete --exclude node_modules --exclude reports "$SCRIPT_DIR/" "$REMOTE_HOST:$REMOTE_DIR/backend/"
scp "$IMAGE_ARCHIVE" "$REMOTE_HOST:$REMOTE_DIR/backend/hookahboss-api-production.tar"

ssh "$REMOTE_HOST" bash -s -- "$REMOTE_DIR/backend" "$PROJECT" "$REMOTE_DIR/$ENV_FILE" <<'REMOTE'
set -euo pipefail
set +x
dir="$1"; project="$2"; env_file="$3"
cd "$dir"
compose=(docker compose -p "$project" --env-file "$env_file" -f compose.production.yaml)
docker load -i hookahboss-api-production.tar >/dev/null
rm -f hookahboss-api-production.tar
"${compose[@]}" up -d --no-build postgres
postgres_id="$("${compose[@]}" ps -q postgres)"
[[ -n "$postgres_id" ]]
for _ in $(seq 1 40); do
  state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$postgres_id")"
  [[ "$state" == healthy ]] && break
  [[ "$state" == unhealthy || "$state" == exited || "$state" == dead ]] && exit 1
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
"${compose[@]}" up -d --no-build --force-recreate api
for _ in $(seq 1 30); do
  curl -fsS --max-time 3 http://127.0.0.1:3010/health >/dev/null && break
  sleep 2
done
curl -fsS --max-time 5 http://127.0.0.1:3010/health
echo
REMOTE
