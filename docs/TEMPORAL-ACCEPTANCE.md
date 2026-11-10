# Temporal local PostgreSQL 18 acceptance

**Development/CI only.** The separate Temporal persistence database is upgraded from PostgreSQL 16 to PostgreSQL 18 as a *new installation target*, not an in-place migration. PostgreSQL 18 is not present in the published Temporal actively-tested PostgreSQL matrix. The local acceptance outcome determines whether it is viable for this Temporal release; do not claim upstream certification.

## Existing database caution

If `postgres-temporal` has ever been started with PostgreSQL 16 and contains data, **do not start PostgreSQL 18 against that data volume**. PostgreSQL major versions require `pg_upgrade` or a dump/restore migration. Back up and investigate the existing volume first. Do not use `reset.ps1`, which also deletes application PostgreSQL data.

PostgreSQL 18 uses a Docker volume mounted at `/var/lib/postgresql` with a versioned data subdirectory. Application PostgreSQL retains its separate volume and extension image.

## Local workflow acceptance

Requires Windows 11, PowerShell 7, Docker Desktop with Linux containers, Node 26 and Corepack/pnpm, and a local development `.env`.

```powershell
git switch master
git fetch origin --prune
git pull --ff-only
# Check out PR #5 before running these commands.
.\scripts\start.ps1 -Temporal
.\scripts\verify.ps1 -Temporal
.\scripts\test-temporal.ps1
```

`test-temporal.ps1` brings up the Temporal profile, asserts the Temporal PostgreSQL major version, checks the default namespace, installs the isolated TypeScript SDK acceptance harness, runs an actual workflow with a worker, restarts the Temporal server and verifies the completed workflow result is still retrievable from persistence.

The acceptance harness deliberately uses exact SDK version numbers and provides an explicit `pnpm-workspace.yaml` build allowlist for `@swc/core`, `esbuild` and `protobufjs`. pnpm 12 rejects these otherwise with `ERR_PNPM_IGNORED_BUILDS`. Do not disable `strictDepBuilds` or approve all dependency scripts. The generated `tests/temporal/pnpm-lock.yaml` is committed. The acceptance script installs dependencies using `corepack pnpm install --frozen-lockfile` so unexpected resolution changes fail rather than rewriting the lockfile. CI/local machine must resolve and lock dependencies before production acceptance. The harness runs locally and connects to `127.0.0.1:7233` rather than deploying its own worker service. It creates an individually named workflow and does not delete other data.

Successful completed-workflow retrieval after a clean Temporal restart is **not** proof of in-flight workflow recovery, worker crash recovery, nontrivial activity retries, backup/restore or HA. Those need later tests.

## Development-only limitations

The current `temporalio/auto-setup` service remains development-only. Production requires a separately configured Temporal server, explicit schema migration jobs, controlled startup ordering, secrets and TLS. No runtime test has been executed by the assistant. Tests and validation belong exclusively to the user or CI.
