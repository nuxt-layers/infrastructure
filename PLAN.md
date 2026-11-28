# Infrastructure Build Plan

Authority: [nuxt-layers/architecture](https://github.com/nuxt-layers/architecture), master reviewed `e9dac240c16891fcbed9669228dac6cd5cde9c3c`; governing PR #6 merged. Infrastructure is not a software artefact or Nuxt Layer. Zero additional local spend; no Hetzner account or paid activation before explicit owner-approved local MVP acceptance.

## Phase 1 — Requirements and reconciliation
- [x] Establish [requirements](docs/REQUIREMENTS.md), [93-artefact traceability](docs/ARTEFACT-TRACEABILITY.md), [technology and environment inventory](docs/TECHNOLOGY.md), [acceptance specification](docs/ACCEPTANCE.md).
- [x] Record approved SeaweedFS, Apache Jena, restic, pgBackRest and Stripe Sandbox choices.
- [x] Phase 1 PRs #6 (architecture) and #7 (infrastructure) merged; no operational acceptance claimed.

## Phase 2 — PostgreSQL
- [x] Capture complete builder and runtime dpkg package inventories in newly built extended image; rebuild and provenance review pending.
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
- [x] Author Linux host prerequisite/resource inspection and inactive private application database production candidate. No provisioning or operational acceptance claimed.
- [ ] Provision production-representative local Linux VM using existing equipment, Coolify/Traefik, private networking, host security, resource budgets, secrets, UTC/NTP/NTS and qualified status.
- [ ] Prepare Hetzner installation/production manifests without activating paid services; separate profiles, no dev credentials/override, exact provider assurance and region evidence.
- [ ] Crypto inventory, approved profiles and negative isolation parity; capacity and no-cost verification.

## Phase 5 — Recovery
- [x] Author dedicated Temporal hardened cluster backup/PITR and real suspended-workflow restore acceptance; owner passed at 27f03bf on 28 November 2026, including explicit schema migrations, encrypted backup and named WAL restore, frontend restart, resumed suspended workflow without repeated completed activity, historical result and cleanup. Non-fatal root group mapping warning remains. Independent disposable repository and restore volume; no production backup custody claim.
- [x] Author separate extended application image PITR overlay, extension catalogue and trigram restore query. Owner attempt at 27f03bf failed before execution with PowerShell parser error; corrected malformed validation and duplicated script content. Owner rerun passed at d4990b6 on 28 November 2026: extended image sha256:13df4cc27febe0c06d4b61bc5aa8e57025db7e176cd87a19aa9204321a415ac8, pgBackRest 2.60.1-1.pgdg12+1, encrypted full backup, WAL PITR, independent volume, restored five-extension catalogue and trigram query, 9.671001s observed recovery and cleanup. Non-fatal Docker ARG default and root group mapping warnings remain.
- [x] Author bounded generic PITR fixture, observed restore duration and encrypted restic wrong-password refusal. Owner restic acceptance passed at 872968d (image sha256:c907f4b76cf63e41517573a37b0319ff78b83db524aac3401a1cf54521d8f2a4, integrity, incorrect password refusal, exact restored hash, 1.2492453s observed restore); generic PITR owner acceptance passed at eb52007 with pgBackRest 2.60.1-1.pgdg12+1, encrypted full backup, named WAL recovery point preceding destructive transaction, independent restore volume, 8.7645416s observed recovery and cleanup. Non-fatal root group mapping warning requires production ownership review. Application and Temporal recovery fixtures passed as recorded above; production backup custody, source-owner consistency and recovery policy remain outstanding.
- [ ] pgBackRest separate app/Temporal DB backup/PITR; restic file/config/eligible volumes, separate protected target, no live DB directory copying or application S3 backup target.
- [ ] Independent recovery scripts, RPO/RTO, restore tests, crash recovery, cache rebuild, erasure replay, key recovery; evidence and runbooks.

## Phase 6 — Supporting infrastructure
- [x] Author opt-in advanced S3 presigned method/expiry, metadata and multipart completion/abort fixture; owner passed at 27f03bf on 28 November 2026, including presigned method/expiry denial, metadata roundtrip, multipart completion/abort and cleanup, baseline scope denial, SMTP and restart persistence. Existing baseline remains default.
- [x] Author network-disabled Apache Jena OWL Micro/SHACL acceptance with checksum-verified distribution and bounded JDK container; owner acceptance passed at fc03485 using Apache Jena 6.3.0 with published SHA-512 verified and Java 21 image sha256:8ad118b146aa92da815b576441acd6b42b38236797ad0b6edc8c200b85bb0734. OWL Micro inference and positive/negative SHACL passed under network isolation; non-fatal Log4j hostname lookup error observed. Distribution signature, licence and production security review remain pending.
- [x] Author actual Traefik file-provider multi-site TLS, forwarded-header and route withdrawal/reapplication acceptance; no Docker socket or ACME connection. Owner at 872968d passed initial TLS routes and forwarded-header protection on Traefik 3.8.0 (sha256:00c9734983e74ae35a1fc18eaee9e9da13f3dde95c4e45b3b8c3b60e0dbd2d17); withdrawal failed (stale route returned 200). Native Linux tmpfs route publication and corrected HTTP alias-header configuration: owner acceptance passed at 93fd39e for apply, withdraw, reapply, trusted TLS, forwarded-header boundary and cleanup. Alias-header-specific negative tests and Coolify/ACME remain outstanding.
- [x] Author offline payment lifecycle, merchant isolation, idempotency and signed callback model fixture. Owner acceptance passed at bbc161a: offline transitions, merchant scope, idempotency and callback replay/tamper/expiry. Not Stripe interoperability or connector acceptance.
- [x] Owner acceptance passed at 9f422b7: signed S3 CRUD, invalid/anonymous rejection, authorised bucket read/write, explicit cross-bucket read/list/write/delete denial, unchanged protected object and absent denied write, SMTP capture, restart persistence and cleanup. SeaweedFS digest 7ca46aeae2f223b37e5d91593c17ab37738eec6df6ab69b48a0487f7643342b9; Mailpit digest 23a2ef85bc50853ab3093645d1d64679afd8887e89da5e48a88940c172591a4e. Exact release/security review, adapter parity and remaining S3 gates pending.
- [ ] SeaweedFS single-node local S3, repeatable buckets/credentials and same Storage adapter tests; Hetzner S3 configuration only.
- [x] Owner reported OIDC, HTTP fault simulation, DNS and local TLS acceptance passed at baseline 9e8be93; exact commands/evidence remain in the fixture references. No Coolify or ACME acceptance implied.
- [ ] Local DNS/CA/ACME and Site Hosting multi-site route/TLS reconciliation.
- [ ] SMTP/OIDC/API/fault fixtures, Stripe sandbox and offline simulator; connector implementation coordinated with artefact owners.
- [ ] Isolated Apache Jena bounded ontology/SHACL, selected processing/conditional collaboration and solver facilities; verify exact builds and licences.

## Phase 7 — Observability
- [x] Author root-only local resource/time observation CLI; unknown statuses retained for unverified authentication, backups and application readiness. Host IAM integration and alerts remain outstanding.
- [ ] Bounded logs, resource metrics, qualified readiness/time quality, alerts and optional collection/tracing profiles.
- [ ] Operator access exclusively explicitly authorised host super-admins; no tenant business browsing. Optional GUI never prerequisite for recovery.

## Phase 8 — Acceptance
- [ ] Execute A01–A12 locally; record unresolved/failed gates, production-specific differences, deployment/recovery instructions and resource budgets.
- [ ] Agree platform MVP separately; verify integrated user journeys and obtain explicit owner approval before Hetzner account/activation. Run production-specific acceptance afterwards.

Existing technical documents remain the current local command/fixture references; historical acceptance claims are not newly verified. No assistant test/build execution; CI or owner validates.
