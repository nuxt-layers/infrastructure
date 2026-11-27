# PostgreSQL Phase 2 — foundation and acceptance

Architecture master reviewed `e9dac240c16891fcbed9669228dac6cd5cde9c3c`. A02/A06 and INF-R10–R26/R123–R131 apply. The isolated eight-stage harness passed locally on 1396af5; see final evidence below.

## Run locally (PowerShell 7 / Docker Desktop)
```powershell
.\scripts\test-postgres-phase2.ps1
```
A unique Compose project creates disposable volumes without publishing host ports. Cleanup targets only that project. Do not run on production. Existing smoke suite remains separate; see POSTGRES-ACCEPTANCE.md. Record revision, image digest, server/extension versions and pass/fail evidence.

## Owner provisioning
Execute postgres/provision/owner.sql as operator with psql -v owner_schema=<schema> -v migration_role=<unique nl_ role> -v runtime_role=<unique nl_ role> -v diagnostic_role=<unique nl_ role>. Creates NOLOGIN roles deliberately; enable login and set independent credentials securely as a separate reviewed operator action. Existing roles/schema fail closed; do not overwrite. Runtime gets schema USAGE only; owner migrations grant exact data operations, RLS, and scoped functions. Review database PUBLIC CONNECT/TEMP, public schema and extension schema/function privileges before enabling application access. No blanket PGMQ access: owner queue isolation requires a scoped adapter or separate database and negative tests. Custom GUC tenant context is trusted host input, not defence against arbitrary SQL execution by a stolen runtime credential. Use parameterised queries, server-side authorisation, and transaction-local context reset. Do not expose runtime SQL.

## Acceptance state
- Authored: pg_trgm, optional vector, pinned pg_textsearch/PGMQ/vector, owner provisioning and real TCP login fixtures, cross-schema/RLS and native search, deny-by-default graph/queue access, committed outbox rollback/retry/deduplication, cross-session LISTEN/NOTIFY and isolated SIGKILL recovery.
- Not proven: production adapter isolation and inference resistance, client pool exhaustion, migration/upgrade/restore, consuming Nuxt test host. Backup/PITR integration Phase 5. The deny-by-default graph/queue tests do not prove tenant-safe graph or queue access; owner-specific adapter grants and positive/negative acceptance remain mandatory.
- Direct base/source/cron pins verified locally; complete apt provenance and production readiness outstanding.

The harness uses synthetic passwords only, authenticates via TCP and disposes of its dedicated project and volumes. SIGKILL is deliberately restricted to that project. The source/consumer receipt tables are fixtures, not shared platform schemas. Notification is a wake-up signal, not durable delivery.

## Scoped extension candidates and pressure

Fixtures 19–24 exercise real runtime login, RLS-filtered BM25/vector results and fixed-scope graph/queue functions under dedicated NOLOGIN owners. They are deliberately fail-closed candidates, not production adapters. Graph execution may require further AGE privilege/load compatibility work; PGMQ signatures and nested helper grants have been reconciled with pinned source; table privileges and actual behaviour still require execution. No arbitrary Cypher or queue name is passed to a privileged function. BM25 corpus statistics, approximate vector recall and timing may leak information even when returned rows are scoped: separate tenant indexes/databases where confidentiality requires, and assess inference separately. A PostgreSQL role connection limit fixture proves refusal and recovery, not a consuming host's client-pool timeout/queue behaviour. These fixture results passed in the combined local run; production adapter assurance remains separate.

## Reproducibility and host integration

See [build and upgrade acceptance](POSTGRES-UPGRADE.md) for digest-qualified base and exact cron package inputs, observed runtime evidence and controlled upgrade procedure. Companion infrastructure-test PR #2 authors client-pool pressure/recovery and rejects privileged diagnostic logins. No exact release provenance, upgrade or host acceptance has been proven.

## Static review

AGE selected tag resolves to e43dc1a12b78fba4acef9835b2b10379b8d243b4; runtime fixture uses administrator-set role/database-scoped session preload, not global preload or elevated runtime privileges. PGMQ read includes the fourth conditional argument; fixed-scope send calls the four-argument implementation directly and grants its format helper. Connection jobs serialise Compose arguments explicitly and allow a bounded 30-second holder window; startup readiness and notification receipt remain verified by assertions. Crash injection checks the actual container project label. Shell overrides of fixture database credentials and Compose file/profile are refused. No runtime results are claimed.

## First local execution (27 November 2026)

Owner-provided Windows Docker Desktop output for the e56501a candidate: image built, isolated PostgreSQL healthy; fixtures 10–11, restricted TCP logins 15–18, BM25/vector 19–20 and scoped PGMQ 21–22 passed. AGE graph creation succeeded but fixture 24 failed on missing EXECUTE for ag_catalog.agtype_to_text(agtype); subsequent notification, pressure, committed outbox and crash fixtures were not reached. Disposable project cleanup succeeded. Corrected grant applies only to the dedicated NOLOGIN graph role, verified against pinned AGE sql/agtype_coercions.sql. Rerun required. Observed base digest sha256:e742a2668255221388004f3a42b6150a2103f5054ab3a4a93ae9e4f01e551c35; output manifest list sha256:30549d6ca750481aac7f92ae2305a87b04b9d1ad9f7739b85a8258d8ff090b4e. Exact apt package version and complete provenance not yet recorded.

## Second local execution

Owner-provided output for 6f0cda8: pinned base build/cache reuse and all preceding fixtures passed again. AGE progressed to missing EXECUTE on agtype_access_operator; fixed query uses p.name, which AGE implements through the variadic agtype[] accessor (verified in pinned sql/agtype_access.sql). Grant only this function to the dedicated non-login graph role; no runtime or PUBLIC grant. Remaining fixtures not reached; cleanup succeeded. Output manifest list sha256:c0b2e56f2f85302f88dd1292392a292cbafb095bbfbf2fa7bfe593fff2fcedac. Rerun required; no assertion that this exhausts all AGE internal privileges.

## Third local execution and targeted reruns

Owner-provided output for af353fb: all preceding fixtures passed again. Restricted AGE returned the correct unquoted text allowed-a; the assertion incorrectly expected embedded quotation marks. Corrected the expected text; negative graph access assertion was not reached in that run. Use `./scripts/test-postgres-phase2.ps1 -Stage Graph` for the graph fixture and its login prerequisites, or `-Stage Notifications`, `-Stage Pressure`, `-Stage Recovery`, `-Stage Relational`, `-Stage Search`, `-Stage Transport`. Default `All` still runs the complete harness. Every invocation creates and cleans its own disposable project. A selected-stage pass is not a complete acceptance pass.

## Targeted local acceptance results (5d825bb)

Owner supplied terminal evidence: Graph PASS (including direct cross-graph denial); Notifications PASS (listener receipt assertion); Pressure PASS (role connection limit refusal and successful reconnection); Recovery PASS (committed outbox rollback/retry, consumer deduplication, archive, SIGKILL restart, durable record retained and UNLOGGED cache reset). All four uniquely named projects cleaned up successfully. Relational, Search and Transport passed in earlier complete-prefix runs; seven stages have positive evidence across runs, not one combined final revision run.

Runtime package query returned PostgreSQL 18.7-1.pgdg12+5 and postgresql-18-cron 1.6.8-2.pgdg12+1. The latter is now pinned in image and Compose defaults; verify the new build. Observed PostgreSQL package version is evidence, not a complete apt snapshot. Recovery image manifest list sha256:bdd47fcfd8be3212bf8283491112e6c8a68f71904da0b8dcf79c4bab859ed2fa. Other stage manifest lists differ; no bitwise reproducibility claim. Functional cron and clean restart, final combined harness, client pool host, inference and upgrade gates remain outstanding.

## Combined local acceptance — 1396af5 (27 November 2026)

Owner executed Maintenance and All against exact cron package pin. Both passed. All eight stages passed in a single disposable project, including actual cron scheduling/execution/history/cleanup, clean restart, restricted logins, relational/RLS isolation, BM25/vector row isolation, scoped PGMQ and AGE, notification receipt, role pressure/recovery, committed outbox/redelivery/deduplication, SIGKILL recovery and UNLOGGED reset. Cleanup succeeded. Runtime packages: PostgreSQL 18.7-1.pgdg12+5; cron 1.6.8-2.pgdg12+1. Combined image manifest list sha256:c497b321fa65e47de3a42fd6079d50c0da689e48cbeef4b4e84a1be38f7edc60. This is the accepted local harness baseline, not complete production acceptance. Host diagnostics, inference, full build provenance and upgrades remain separate.

## Consuming application fixture

Run `./scripts/start-postgres-host-fixture.ps1 -ApplicationPath <local infrastructure-test repository>` after installing the companion PR #2 dependencies and stopping any existing Nuxt process on port 3000. The script starts a disposable database with a random loopback port, creates a restricted diagnostic role, and launches Nuxt in the supplied application directory with inherited process-only environment. Credentials are not printed or written to application files. Open http://127.0.0.1:3000/admin/infrastructure and check connections while the script is running. Quit Nuxt to trigger cleanup of only the disposable project. This replaces the manual two-terminal credential transfer; repeated user output showed the database was removed before application acceptance. New launcher requires local verification. The previously accepted eight-stage harness is unchanged.

## Consuming host acceptance — 27 November 2026

Owner screenshot at 20:38:52.081 UTC confirms PostgreSQL passed with restricted-role, private data denial and bounded pool recovery succeeded; Temporal not-configured as intended. Automated launcher b5269ea and companion infrastructure-test diagnostic implementation ae1d44d are the candidate baseline. Earlier owner terminal output confirms Nuxt typecheck passed. Final launcher cleanup after quitting, application lockfile/CI, complete build provenance, inference resistance and controlled upgrade remain unverified. No production acceptance claimed.

## Repository reconciliation

Companion lockfile inspected in full: pnpm 12 multi-document YAML includes application importer, pg 8.16.3 and Temporal client 1.24.0. Earlier missing-lockfile assertion was incorrect. Frozen install/build and protected-branch checks remain to be verified. Companion PR #3 changes only node-forge lock entries from 1.4.2 to 1.4.4; validate separately. No extension upgrade target has been selected; preserve the tested local baseline. Full apt provenance, production inference resistance and operational upgrade/restore are release gates, not evidence of failed local functionality. Backup/restore qualification belongs to Phase 5; do not waive it.
