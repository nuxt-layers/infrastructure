# Local consuming-application infrastructure connection contract

**Status:** Local development integration contract. This repository is infrastructure, not a Nuxt capability, and does not implement the provider-neutral Temporal Gateway API.

## Boundaries

- Application hosts create and supply database clients to their composed capabilities, rather than capabilities discovering global connections.
- Temporal Gateway owns its provider-neutral public interfaces and Temporal adapter; infrastructure supplies network addresses, credentials and services, not duplicate gateway ports or SDK types.
- Application PostgreSQL 18 and Temporal's PostgreSQL 18 persistence run in distinct containers with independent volumes. **Never connect a consuming application directly to Temporal's persistence database.**
- Local-only diagnostics are not a public status API. The derived `nuxt-layers-test/infrastructure-test` harness must keep credentials server-side, operate on loopback and remain disabled by default.

## Addressing

| Consumer | Network context | Target |
| --- | --- | --- |
| Nuxt app on Windows | Host OS | PostgreSQL `127.0.0.1:5432` (or `APP_POSTGRES_PORT`) |
| Nuxt app on Windows | Host OS | Temporal frontend `127.0.0.1:7233` (or `TEMPORAL_GRPC_PORT`) |
| Docker Compose application | Shared Compose network | `postgres-app:5432` |
| Docker Compose application | Shared Compose network | `temporal:7233` |
| Operator browser | Host OS | Temporal UI `http://127.0.0.1:8080` |
| Temporal server | Compose private network | `postgres-temporal:5432` only |

Nuxt's default dev URL `http://localhost:3000` exists only after a Nuxt application is actually started. Port 5432 speaks PostgreSQL, and port 7233 speaks Temporal gRPC, not browser HTTP.

## Consuming app local environment

Use the *existing* `infrastructure/.env` for infrastructure bootstrapping. Supply **independent, host-only** configuration to the derived test application. Illustrative values below assume the default local development ports and the initial disposable superuser; the latter is only a transitional acceptance probe, **not** an approved application runtime role:

```dotenv
NUXT_INFRA_TEST_ENABLED=true
NUXT_INFRA_TEST_DATABASE_URL=postgresql://nuxt_layers_dev:<local-secret>@127.0.0.1:5432/nuxt_layers
NUXT_INFRA_TEST_TEMPORAL_ADDRESS=127.0.0.1:7233
```

Do not commit the real values, print secrets, or put URLs in Nuxt `public` runtime configuration. If credentials contain reserved URL characters, percent-encode them. Prefer dedicated least-privilege read-only diagnostic credentials once roles are provisioned. Host-supplied client setup, restricted grants, RLS and tenant isolation are still future work.

## Local verification

```powershell
# Within nuxt-layers/infrastructure:
.\scripts\start.ps1 -Temporal
.\scripts\verify.ps1 -Temporal
.\scripts\verify-extensions.ps1
```

Use `nuxt-layers-test/infrastructure-test` for the Nuxt test UI and its server-side connectivity probes. Its database check should be read-only (`SELECT current_user, current_database(), current_setting('server_version_num')`) and its Temporal check should query the frontend through the Temporal SDK. A successful connection is not equivalent to role isolation, authentication, gateway integration, workflow recovery or production acceptance.

## Production exclusions

Never deploy the test-mode Theme Manager, developer SQL users, loopback Compose overrides or unauthenticated diagnostic endpoints to Coolify. A separately reviewed production composition needs scoped roles, controlled database migrations, TLS, secrets, backups/restore testing and dedicated `temporalio/server` with managed schema upgrades. Hetzner application object storage is **only for application images and files**, not database or infrastructure backups.
