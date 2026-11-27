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
- Authored: pg_trgm, optional vector files, pinned pg_textsearch/PGMQ/vector source checks, synthetic role/schema/RLS and native search negative tests, transaction rollback and same-DB outbox relay fixture.
- Not proven: real login/connection permissions and role provisioning, cross-tenant graph/BM25/vector and PGMQ enforcement, pool exhaustion, cross-session LISTEN/NOTIFY, committed outbox retry/idempotency, abrupt crash and WAL recovery, migration/upgrade/restore, consuming Nuxt test host. These remain mandatory subsequent Phase 2 acceptance work (backup/PITR integration Phase 5).
- Exact image/apt and AGE source pinning outstanding; AGE RC retained, pg_textsearch and PGMQ existing candidates retained pending compatibility review. No production readiness.
