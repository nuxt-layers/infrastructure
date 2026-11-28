# Infrastructure Build Plan

Authority: [nuxt-layers/architecture](https://github.com/nuxt-layers/architecture), master reviewed `e9dac240c16891fcbed9669228dac6cd5cde9c3c`; governing PR #6 merged. Infrastructure is not a software artefact or Nuxt Layer. Zero additional local spend; no Hetzner account or paid activation before explicit owner-approved local MVP acceptance.

## Phase 1 — Requirements and reconciliation
- [x] Establish [requirements](docs/REQUIREMENTS.md), [93-artefact traceability](docs/ARTEFACT-TRACEABILITY.md), [technology and environment inventory](docs/TECHNOLOGY.md), [acceptance specification](docs/ACCEPTANCE.md).
- [x] Record approved SeaweedFS, Apache Jena, restic, pgBackRest and Stripe Sandbox choices.
- [x] Phase 1 PRs #6 (architecture) and #7 (infrastructure) merged; no operational acceptance claimed.

## Phase 2 — PostgreSQL
- [x] Existing PostgreSQL 18 application image, AGE/pg_textsearch/PGMQ/pg_cron build/enable definitions, PowerShell start/stop/verify/reset, functional smoke fixtures (PR #3).
- [x] Author pg_trgm enablement, optional pgvector image support and immutable checks for AGE/pg_textsearch/PGMQ/pgvector.
- [x] Author configurable digest-qualified base/exact cron package inputs, runtime build evidence and controlled upgrade procedure.
- [x] Record tested base digest, direct source commits and observed PostgreSQL/pg_cron package versions; pin cron package.
- [x] Rebuild with exact cron pin and verify runtime package versions.
- [ ] Verify complete apt/build provenance and execute approved upgrade path when selected; no release upgrade assumed. Retain tested local baseline; production activation remains blocked.
- [x] Author per-owner provisioning template and isolated negative RLS/schema/role, search and outbox fixtures; no global app cache schema.
- [x] Author real TCP login, denied unscoped extension access, committed outbox retry/deduplication, cross-session LISTEN/NOTIFY and isolated abrupt crash fixtures.
- [x] Author scoped extension candidate fixtures and role connection-limit refusal/recovery.
- [x] Author consuming host restricted diagnostics/client pool in infrastructure-test PR #2.
- [x] Owner executed all seven Phase 2 harness stages across local runs; restricted graph, notification, role pressure, committed outbox and abrupt crash passed. See docs/POSTGRES-PHASE-2.md.
- [x] Owner ran all eight stages together on exact cron-pinned build (1396af5), including functional cron and clean restart; all passed.
- [x] Consuming Nuxt host acceptance passed on 27 November 2026: restricted login, private data denial and bounded client-pool recovery; automated launcher b5269ea.
- [ ] Search inference resistance and controlled upgrade remain separate gates.

## Phase 3 — Temporal
- [x] Owner full Phase 3 SDK regression (`-Stage All`) passed 28 November 2026 at 2ece4a9, including both restart paths, separate workflow IDs, persisted results and cleanup. H1/H2 independently passed in the preceding combined run at 77f4262.
- [x] Owner H2 passed 28 November 2026 at 1acdc14: trusted mTLS, plaintext and invalid certificate rejection, missing/invalid/expired JWT denial, scoped read/write denial, authenticated worker execution, historical retrieval and cleanup.
- [x] Owner H3 WorkerCrash passed 28 November 2026 at 67e005a: durable attempt-one checkpoint, forced active worker termination, replacement attempt-two recovery, exactly one completed activity, graceful drain and cleanup.
- [x] Owner H1 persistence hardening passed 28 November 2026 at 62fb18f: explicit fresh schema migrations, independent runtime TCP logins, denied DDL/metadata writes/SET ROLE/cross-database connections, disabled migration login, explicit namespace bootstrap, real workflow/visibility and cleanup (docs/TEMPORAL-HARDENING.md).
- [x] Owner Functional package passed 28 November 2026 at 0cadd87: automatic single scheduled dispatch, heartbeat checkpoint recovery, SQL visibility, namespace/queue routing, abrupt server and database termination, replay and cleanup.
- [x] Author standalone disposable acceptance stack and selectable startup/execution/recovery harness; see docs/TEMPORAL-PHASE-3.md. Owner Startup passed 27 November 2026; execution and visibility schema versions recorded.
- [x] Pin verified disposable Temporal image digest; owner Recovery passed on 28 November 2026 at 504fe23: bounded retry, graceful worker drain, ordered restart, changed loopback port rediscovery, history retrieval and suspended workflow resumption without repeat activity.
- [x] Existing optional auto-setup development server/UI, separate PG18 volumes and SDK acceptance harness/lockfile (PR #5), connection contract (PR #6).
- [ ] Confirm current supported server/PG18 compatibility, pin immutable images; controlled server/schema migration jobs, advanced visibility, private network, TLS, scoped namespaces/queues, graceful worker lifecycle.
- [ ] Verify controlled upgrade and published temporal-gateway contract; active worker-process crash, clean restart, abrupt server/database crash, heartbeat and worker/history acceptance passed. Never reuse PG16 volume unmodified.

## Phase 4 — Hosting environment
- [ ] Provision production-representative local Linux VM using existing equipment, Coolify/Traefik, private networking, host security, resource budgets, secrets, UTC/NTP/NTS and qualified status.
- [ ] Prepare Hetzner installation/production manifests without activating paid services; separate profiles, no dev credentials/override, exact provider assurance and region evidence.
- [ ] Crypto inventory, approved profiles and negative isolation parity; capacity and no-cost verification.

## Phase 5 — Recovery
- [ ] pgBackRest separate app/Temporal DB backup/PITR; restic file/config/eligible volumes, separate protected target, no live DB directory copying or application S3 backup target.
- [ ] Independent recovery scripts, RPO/RTO, restore tests, crash recovery, cache rebuild, erasure replay, key recovery; evidence and runbooks.

## Phase 6 — Supporting infrastructure
- [x] Author SeaweedFS scoped bucket negative tests and restart persistence fixture; owner execution pending.
- [ ] SeaweedFS single-node local S3, repeatable buckets/credentials and same Storage adapter tests; Hetzner S3 configuration only.
- [x] Owner reported OIDC, HTTP fault simulation, DNS and local TLS acceptance passed at baseline 9e8be93; exact commands/evidence remain in the fixture references. No Coolify or ACME acceptance implied.
- [ ] Local DNS/CA/ACME and Site Hosting multi-site route/TLS reconciliation.
- [ ] SMTP/OIDC/API/fault fixtures, Stripe sandbox and offline simulator; connector implementation coordinated with artefact owners.
- [ ] Isolated Apache Jena bounded ontology/SHACL, selected processing/conditional collaboration and solver facilities; verify exact builds and licences.

## Phase 7 — Observability
- [ ] Bounded logs, resource metrics, qualified readiness/time quality, alerts and optional collection/tracing profiles.
- [ ] Operator access exclusively explicitly authorised host super-admins; no tenant business browsing. Optional GUI never prerequisite for recovery.

## Phase 8 — Acceptance
- [ ] Execute A01–A12 locally; record unresolved/failed gates, production-specific differences, deployment/recovery instructions and resource budgets.
- [ ] Agree platform MVP separately; verify integrated user journeys and obtain explicit owner approval before Hetzner account/activation. Run production-specific acceptance afterwards.

Existing technical documents remain the current local command/fixture references; historical acceptance claims are not newly verified. No assistant test/build execution; CI or owner validates.
