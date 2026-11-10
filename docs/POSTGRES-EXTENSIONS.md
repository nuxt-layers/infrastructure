# PostgreSQL 18 extension image — development installation

This Dockerfile builds Apache AGE 1.8.0 (PostgreSQL 18 tag), pg_textsearch 1.5.1 and pgmq 1.13.0 against PostgreSQL 18. It installs pg_cron from the PostgreSQL 18 package repository used by the official Debian image.

## Local install / upgrade

From Windows PowerShell 7, with Docker Desktop running and your development `.env` present:

```powershell
docker compose --env-file .env -f compose/compose.yaml -f compose/compose.dev.yaml build postgres-app
.\scripts\start.ps1
.\scripts\install-extensions.ps1
.\scripts\verify-extensions.ps1
```

Building the image alone **does not migrate databases**. The entrypoint script enables extensions only for fresh database volumes; `install-extensions.ps1` is the explicit reconciliation path for existing volumes. Never delete an existing volume as an installation step. Before upgrading extensions on important data, take and restore-test a backup. `CREATE EXTENSION IF NOT EXISTS` does not upgrade an already-installed extension.

AGE must **not** be in the global `shared_preload_libraries` for this mixed-database instance. Its installed version can access `ag_catalog` while handling PostgreSQL utility statements even in databases without AGE; this affected the `postgres` maintenance database when running `TRUNCATE`. Instead, graph sessions use `LOAD 'age'` followed by an explicit `ag_catalog` search path. AGE is installed only in databases that require graphs; `postgres` remains reserved for pg_cron. AGE functions often require `LOAD 'age'` and an explicit `ag_catalog` search path on each applicable session. The host-supplied connection adapter is responsible for this; do not globally put `ag_catalog` ahead of all other schemas without reviewing isolation and permissions.

`pg_cron` is installed in the `postgres` maintenance database only, with the worker configured by `shared_preload_libraries`. Database maintenance jobs are distinct from application Scheduler and Temporal workflows.

Only migration/admin roles should create extensions or queues. These examples use the initial development superuser for bootstrap, not as a runtime-role recommendation.

## Verification boundaries

The PowerShell verification script checks installed extension records and preload settings. It is **not** proof that Cypher traversals, BM25 index concurrency, queue visibility/archiving, pg_cron workers or database recovery work. Those acceptance tests, supported platform architectures, source commit SHA pinning, output image digests, CVE scanning, and dependency/runtime compatibility are required before production release.

This image is still **development-only**. It has not been built or smoke-tested in this assistant session.
