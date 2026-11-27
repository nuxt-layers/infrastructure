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
- Exact image/apt pinning outstanding; AGE source commit verified; no production readiness.

The harness uses synthetic passwords only, authenticates via TCP and disposes of its dedicated project and volumes. SIGKILL is deliberately restricted to that project. The source/consumer receipt tables are fixtures, not shared platform schemas. Notification is a wake-up signal, not durable delivery.

## Scoped extension candidates and pressure

Fixtures 19–24 exercise real runtime login, RLS-filtered BM25/vector results and fixed-scope graph/queue functions under dedicated NOLOGIN owners. They are deliberately fail-closed candidates, not production adapters. Graph execution may require further AGE privilege/load compatibility work; PGMQ signatures and nested helper grants have been reconciled with pinned source; table privileges and actual behaviour still require execution. No arbitrary Cypher or queue name is passed to a privileged function. BM25 corpus statistics, approximate vector recall and timing may leak information even when returned rows are scoped: separate tenant indexes/databases where confidentiality requires, and assess inference separately. A PostgreSQL role connection limit fixture proves refusal and recovery, not a consuming host's client-pool timeout/queue behaviour. All results pending execution.

## Reproducibility and host integration

See [build and upgrade acceptance](POSTGRES-UPGRADE.md) for digest-qualified base and exact cron package inputs, observed runtime evidence and controlled upgrade procedure. Companion infrastructure-test PR #2 authors client-pool pressure/recovery and rejects privileged diagnostic logins. No exact release provenance, upgrade or host acceptance has been proven.

## Static review

AGE selected tag resolves to e43dc1a12b78fba4acef9835b2b10379b8d243b4; runtime fixture uses administrator-set role/database-scoped session preload, not global preload or elevated runtime privileges. PGMQ read includes the fourth conditional argument; fixed-scope send calls the four-argument implementation directly and grants its format helper. Connection jobs serialise Compose arguments explicitly and allow a bounded 30-second holder window; startup readiness and notification receipt remain verified by assertions. Crash injection checks the actual container project label. Shell overrides of fixture database credentials and Compose file/profile are refused. No runtime results are claimed.

## First local execution (27 November 2026)

Owner-provided Windows Docker Desktop output for the e56501a candidate: image built, isolated PostgreSQL healthy; fixtures 10–11, restricted TCP logins 15–18, BM25/vector 19–20 and scoped PGMQ 21–22 passed. AGE graph creation succeeded but fixture 24 failed on missing EXECUTE for ag_catalog.agtype_to_text(agtype); subsequent notification, pressure, committed outbox and crash fixtures were not reached. Disposable project cleanup succeeded. Corrected grant applies only to the dedicated NOLOGIN graph role, verified against pinned AGE sql/agtype_coercions.sql. Rerun required. Observed base digest sha256:e742a2668255221388004f3a42b6150a2103f5054ab3a4a93ae9e4f01e551c35; output manifest list sha256:30549d6ca750481aac7f92ae2305a87b04b9d1ad9f7739b85a8258d8ff090b4e. Exact apt package version and complete provenance not yet recorded.
