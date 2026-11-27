# PostgreSQL Phase 2 — foundation and acceptance

Architecture master reviewed `e9dac240c16891fcbed9669228dac6cd5cde9c3c`. A02/A06 and INF-R10–R26/R123–R131 apply. This change authors an isolated test harness and scoped owner provisioning; no execution evidence yet.

## Run locally (PowerShell 7 / Docker Desktop)
```powershell
.\scripts\test-postgres-phase2.ps1
```
A unique Compose project creates disposable volumes without publishing host ports. Cleanup targets only that project. Do not run on production. Existing smoke suite remains separate; see POSTGRES-ACCEPTANCE.md. Record revision, image digest, server/extension versions and pass/fail evidence.

## Owner provisioning
Execute postgres/provision/owner.sql as operator with psql -v owner_schema=<schema> -v migration_role=<unique nl_ role> -v runtime_role=<unique nl_ role> -v diagnostic_role=<unique nl_ role>. Creates NOLOGIN roles deliberately; enable login and set independent credentials securely as a separate reviewed operator action. Existing roles/schema fail closed; do not overwrite. Runtime gets schema USAGE only; owner migrations grant exact data operations, RLS, and scoped functions. Review database PUBLIC CONNECT/TEMP, public schema and extension schema/function privileges before enabling application access. No blanket PGMQ access: owner queue isolation requires a scoped adapter or separate database and negative tests. Custom GUC tenant context is trusted host input, not defence against arbitrary SQL execution by a stolen runtime credential. Use parameterised queries, server-side authorisation, and transaction-local context reset. Do not expose runtime SQL.

## Acceptance state
- Authored: pg_trgm, optional vector, pinned pg_textsearch/PGMQ/vector, owner provisioning and real TCP login fixtures, cross-schema/RLS and native search, deny-by-default graph/queue access, committed outbox rollback/retry/deduplication, cross-session LISTEN/NOTIFY and isolated SIGKILL recovery.
- Not proven: all runtime results; positive scoped graph/BM25/vector/PGMQ adapters and cross-tenant tests, pool exhaustion, migration/upgrade/restore, consuming Nuxt test host. Backup/PITR integration Phase 5. The deny-by-default graph/queue tests do not prove tenant-safe graph or queue access; owner-specific adapter grants and positive/negative acceptance remain mandatory.
- Exact image/apt and AGE source pinning outstanding; no production readiness.

The harness uses synthetic passwords only, authenticates via TCP and disposes of its dedicated project and volumes. SIGKILL is deliberately restricted to that project. The source/consumer receipt tables are fixtures, not shared platform schemas. Notification is a wake-up signal, not durable delivery.

## Scoped extension candidates and pressure

Fixtures 19–24 exercise real runtime login, RLS-filtered BM25/vector results and fixed-scope graph/queue functions under dedicated NOLOGIN owners. They are deliberately fail-closed candidates, not production adapters. Graph execution may require further AGE privilege/load compatibility work; PGMQ signatures and table grants must be validated against the pinned release. No arbitrary Cypher or queue name is passed to a privileged function. BM25 corpus statistics, approximate vector recall and timing may leak information even when returned rows are scoped: separate tenant indexes/databases where confidentiality requires, and assess inference separately. A PostgreSQL role connection limit fixture proves refusal and recovery, not a consuming host's client-pool timeout/queue behaviour. All results pending execution.

## Reproducibility and host integration

See [build and upgrade acceptance](POSTGRES-UPGRADE.md) for digest-qualified base and exact cron package inputs, observed runtime evidence and controlled upgrade procedure. Companion infrastructure-test PR #2 authors client-pool pressure/recovery and rejects privileged diagnostic logins. No exact release provenance, upgrade or host acceptance has been proven.
