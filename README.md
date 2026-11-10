# Nuxt Layers Infrastructure

Infrastructure deployment and local acceptance support for Nuxt Layers. **This is not a Nuxt capability layer.**

Governed by `nuxt-layers/architecture-rules` (reviewed master: `3436b1cc2a33401a7c3f08d5bc9ee9fe11ea93d2`). Infrastructure choices must not leak provider-specific implementations into capability contracts.

## Current implementation status

**Phase 2 — extension image candidate (local development only).** This branch provides a PostgreSQL 18 application server, an independently persisted PostgreSQL 16 Temporal database, a local Temporal development server and Web UI, plus PowerShell commands. **The application PostgreSQL image is now defined to build AGE, pg_textsearch and pgmq from versioned source tags and install pg_cron from apt; compilation and installation passed initial Windows testing; functional acceptance is pending.** Do not use this development stack in production. Follow `PLAN.md` for extension builds, production-ready Temporal schema management, security and backup acceptance.

## Windows 11 quick start

Requires Docker Desktop with Linux containers, PowerShell 7 and Docker Compose v2. Docker Desktop must be running.

```powershell
Copy-Item .env.example .env
.\scripts\start.ps1
.\scripts\verify.ps1
```

After cloning the PR, build and enable extensions with `docker compose --env-file .env -f compose/compose.yaml -f compose/compose.dev.yaml build postgres-app`, then `.\\scripts\\install-extensions.ps1` and `.\\scripts\\verify-extensions.ps1`. Full instructions: [PostgreSQL extensions](docs/POSTGRES-EXTENSIONS.md). Run the [functional acceptance suite](docs/POSTGRES-ACCEPTANCE.md) with `.\scripts\test-postgres.ps1` on an isolated local development stack.

Application PostgreSQL: `127.0.0.1:5432` (database `nuxt_layers`). Temporal services are optional:

```powershell
.\scripts\start.ps1 -Temporal
.\scripts\verify.ps1 -Temporal
```

Temporal gRPC: `127.0.0.1:7233`; Temporal Web UI: <http://127.0.0.1:8080>. PostgreSQL used by Temporal is accessible only on the private Compose network. If ports are already in use, set `APP_POSTGRES_PORT`, `TEMPORAL_GRPC_PORT`, or `TEMPORAL_UI_PORT` in `.env`.

```powershell
.\scripts\stop.ps1
.\scripts\reset.ps1 -Confirm
```

`stop.ps1` preserves volumes. `reset.ps1` destroys **both** local PostgreSQL data volumes and requires PowerShell confirmation. Do not reuse local development passwords elsewhere.

## Design boundaries

- The application host supplies all database clients to capabilities; it owns connection setup and credentials.
- The application database and Temporal persistence have separate volumes, database roles and lifecycle management.
- The development Temporal container uses upstream `auto-setup`; production MUST use `temporalio/server` and a controlled, versioned schema migration job.
- A local cache may use UNLOGGED tables only for regenerable data; permanent session, authorisation and outbox records require durable storage.
- `pgmq` transport and LISTEN/NOTIFY signalling must not be mistaken for Temporal persistence or business workflow ownership.
- Do not route infrastructure backups to the Hetzner application object-storage bucket; that bucket is reserved for application files and images.
- Production access to PostgreSQL and Temporal must be private, with credential isolation, TLS across trust boundaries, tested backups and explicit deployment approval.

See `PLAN.md` and `RESOURCES.md`. No CI/runtime acceptance has been claimed for this initial commit.
