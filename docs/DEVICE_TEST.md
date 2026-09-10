# Repeatable device-test deployment

This workflow deploys only the Compose project `hookahboss` in `/opt/hookahboss` through the SSH alias `timeweb_bm`. It never runs `compose down`, removes a volume, or touches another Compose project.

## One-time VDS setup

Create `/opt/hookahboss/.env` on the VDS with permissions `0600`. It must contain strong, device-test-only values for `HOOKAHBOSS_POSTGRES_PASSWORD` and `HOOKAHBOSS_SESSION_TOKEN_SECRET`. Do not commit or print this file. `backend/compose.device-test.yaml` keeps Apple provider exchange disabled; authenticated Sign in with Apple is therefore unavailable in this device-test environment until real Apple provider credentials and an HTTPS callback-compatible configuration are supplied.

The optional Quick Tunnel service defaults to `hookahboss-test-tunnel.service`. Override names/paths with `HOOKAHBOSS_DEVICE_HOST`, `HOOKAHBOSS_DEVICE_DIR`, `HOOKAHBOSS_DEVICE_PROJECT`, `HOOKAHBOSS_DEVICE_ENV_FILE`, or `HOOKAHBOSS_TUNNEL_SERVICE`.

## Deploy

```sh
./backend/deploy-device-test.sh
```

The script builds `linux/amd64`, transfers the image and backend/Compose definitions, waits for the existing PostgreSQL volume to become healthy, applies ordered migrations, runs all three idempotent seed importers, starts only this project's API, and verifies health plus published brand/product/mix/article counts. It fails at the first error and suppresses command tracing so secrets are not echoed.

The tunnel is deliberately untouched. Only when changing its URL is acceptable:

```sh
./backend/deploy-device-test.sh --restart-tunnel
```

A Quick Tunnel restart can change the public URL and invalidate the `API_BASE_URL` embedded in an existing Debug build.

## Read-only status

```sh
./backend/device-test-status.sh
```

This prints only this Compose project's status, local API health, tunnel service state, and the latest public `trycloudflare.com` URL found in its journal. It does not restart or mutate services.

## Run the iOS client

Open `ios/HookahBoss.xcodeproj`, select the signed HookahBoss target and your connected iPhone, then Run. The iOS project is isolated under `ios/`; the device-test deployment and its Compose definition are backend-owned under `backend/`.
