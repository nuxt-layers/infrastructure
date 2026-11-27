# Infrastructure Build Plan

Authority: [nuxt-layers/architecture](https://github.com/nuxt-layers/architecture), master reviewed `e9dac240c16891fcbed9669228dac6cd5cde9c3c`; governing PR #6 merged. Infrastructure is not a software artefact or Nuxt Layer. Zero additional local spend; no Hetzner account or paid activation before explicit owner-approved local MVP acceptance.

## Phase 1 — Requirements and reconciliation
- [x] Establish [requirements](docs/REQUIREMENTS.md), [93-artefact traceability](docs/ARTEFACT-TRACEABILITY.md), [technology and environment inventory](docs/TECHNOLOGY.md), [acceptance specification](docs/ACCEPTANCE.md).
- [x] Record approved SeaweedFS, Apache Jena, restic, pgBackRest and Stripe Sandbox choices.
- [x] Phase 1 PRs #6 (architecture) and #7 (infrastructure) merged; no operational acceptance claimed.

## Phase 2 — PostgreSQL
- [x] Existing PostgreSQL 18 application image, AGE/pg_textsearch/PGMQ/pg_cron build/enable definitions, PowerShell start/stop/verify/reset, functional smoke fixtures (PR #3).
- [x] Author pg_trgm enablement, optional pgvector image support and immutable checks for pg_textsearch/PGMQ/pgvector.
- [ ] Validate exact stable releases, AGE source SHA, base/apt/output digests, ABI and upgrades; no release upgrade assumed.
- [x] Author per-owner provisioning template and isolated negative RLS/schema/role, search and outbox fixtures; no global app cache schema.
- [x] Author real TCP login, denied unscoped extension access, committed outbox retry/deduplication, cross-session LISTEN/NOTIFY and isolated abrupt crash fixtures.
- [x] Author scoped extension candidate fixtures and role connection-limit refusal/recovery.
- [ ] Execute/review all fixtures; inference resistance, client pool pressure, upgrade and consuming-host acceptance remain outstanding.
- [ ] Execute isolated SQL/restart/crash tests and verify consuming test host connectivity; record evidence. Do not assume historic smoke tests prove isolation.

## Phase 3 — Temporal
- [x] Existing optional auto-setup development server/UI, separate PG18 volumes and SDK acceptance harness/lockfile (PR #5), connection contract (PR #6).
- [ ] Confirm current supported server/PG18 compatibility, pin immutable images; controlled server/schema migration jobs, advanced visibility, private network, TLS, scoped namespaces/queues, graceful worker lifecycle.
- [ ] Verify startup, real worker/history, restart, upgrade and recovery, published temporal-gateway contract. Never reuse PG16 volume unmodified.

## Phase 4 — Hosting environment
- [ ] Provision production-representative local Linux VM using existing equipment, Coolify/Traefik, private networking, host security, resource budgets, secrets, UTC/NTP/NTS and qualified status.
- [ ] Prepare Hetzner installation/production manifests without activating paid services; separate profiles, no dev credentials/override, exact provider assurance and region evidence.
- [ ] Crypto inventory, approved profiles and negative isolation parity; capacity and no-cost verification.

## Phase 5 — Recovery
- [ ] pgBackRest separate app/Temporal DB backup/PITR; restic file/config/eligible volumes, separate protected target, no live DB directory copying or application S3 backup target.
- [ ] Independent recovery scripts, RPO/RTO, restore tests, crash recovery, cache rebuild, erasure replay, key recovery; evidence and runbooks.

## Phase 6 — Supporting infrastructure
- [ ] SeaweedFS single-node local S3, repeatable buckets/credentials and same Storage adapter tests; Hetzner S3 configuration only.
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
