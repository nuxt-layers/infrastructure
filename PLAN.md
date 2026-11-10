# Infrastructure Build Plan

Authority: `nuxt-layers/architecture-rules`, master `3436b1cc2a33401a7c3f08d5bc9ee9fe11ea93d2` reviewed 2026-11-10. This repository is infrastructure, not a Nuxt capability.

## Phase 1 — local baseline (this PR)
- [x] Separate PostgreSQL 18 application store and PostgreSQL 16 Temporal persistence.
- [x] Docker Compose with optional local Temporal and loopback-only ports.
- [x] Windows PowerShell start, stop, verify and guarded reset commands.
- [ ] Execute Docker Compose config, startup and SQL probes on Windows Docker Desktop.
- [ ] Verify Temporal UI and run an end-to-end workflow using a real worker.
- [ ] Pin deployed images by immutable digest after acceptance.

## Phase 2 — PostgreSQL extension image
- [x] Define a custom PostgreSQL 18 image using tagged upstream source inputs; build acceptance, source commit and image digest verification pending.
- [x] Configure AGE, pg_textsearch, pgmq and pg_cron installation/preloading; pending actual build and ABI/behaviour verification.
- [x] Add version manifest, bootstrap SQL and explicit existing-volume enablement path; CI build, upgrades/downgrades and production pinning outstanding.
- [ ] Add application cache schema with TTL expiry and tenant-aware keys; reserve UNLOGGED tables for regenerable content.
- [ ] Add durable outbox-to-pgmq acceptance, retry/idempotency and LISTEN/NOTIFY wakeup tests.
- [ ] Verify graph tenant bounds and search tenant filters.
- [ ] Test extension-upgrade recovery with persistent volume.

## Phase 3 — Temporal production
- [ ] Pin current compatible Temporal server, UI and admin-tool image digests.
- [ ] Replace auto-setup with temporalio/server and controlled SQL schema init/upgrade job.
- [ ] Configure SQL-backed advanced visibility and proper runtime health checks.
- [ ] Add private networks, scoped roles and secrets, TLS where crossing trust boundaries.
- [ ] Integrate temporal-gateway without exposing Temporal SDK or persistence internals to other capabilities.

## Phase 4 — Coolify / operating acceptance
- [ ] Separate development and production Compose projects; ensure local override cannot be deployed to production.
- [ ] Define Hetzner VPS resource budgets and observability.
- [ ] Implement scheduled PostgreSQL and Temporal backups to an approved backup target separate from the application object-storage bucket; restore-test both.
- [ ] Test restart, unclean shutdown, persistence, cache loss/rebuild, retries and disaster recovery.
- [ ] Record hosting provider evidence and regions per ADR-0014; document operator runbooks.
