# Temporal Phase 3 — isolated baseline

Authority: architecture master e9dac240c16891fcbed9669228dac6cd5cde9c3c; infrastructure baseline e0fd02330cad86fed4cff7dab7e488ab67c81995. Apply INF-R27–R36 and A03, with A06 isolation and Phase 5 recovery requirements. Temporal Gateway canonical record and ADR-0015 define a separate independent integration library. Its implementation master b17dd57c2f74dcde58b468575f70139b39cbb04f has no published CONTRACT.md; direct SDK fixtures are not gateway acceptance.

## Baseline and qualification

Retain auto-setup 1.27.2 and SDK 1.24.0 for an initial controlled baseline, not an assertion that they are current or production-approved. PostgreSQL 18 uses the previously observed official base digest from Phase 2; no application extensions or application volumes. Upstream persistence compatibility lists actively tested PostgreSQL versions through 16; PG18 requires local qualification and separate production approval. SQL advanced visibility uses a separate database on the Temporal-only cluster. See https://docs.temporal.io/temporal-service/persistence and https://docs.temporal.io/self-hosted-guide/visibility. Auto-setup remains local only; use explicit schema setup/update jobs and production server configuration for release (https://github.com/temporalio/docker-builds/blob/main/docker-readme/auto-setup.md).

## Run

PowerShell 7, Docker Desktop, existing Node/pnpm toolchain:
```powershell
.\scripts\test-temporal-phase3.ps1 -Stage Startup
.\scripts\test-temporal-phase3.ps1 -Stage Execution
.\scripts\test-temporal-phase3.ps1 -Stage Recovery
```
Default All executes startup, real worker workflow and completed-history retrieval after clean server and database restart. Each invocation uses an independent project and disposable volume, no existing .env or application database, dynamically allocated loopback frontend port, private persistence network and synthetic credentials. No UI is required for acceptance. Capture schema versions and observed image digests. Server image pinned from owner evidence; UI is not part of this fixture. No assistant execution.

## Remaining packages

- Verify selected supported server/SDK versions and immutable digests; retain tested baseline until deliberate upgrade approval.
- Separate schema migration identity and runtime identity, explicit execution/visibility schema jobs, controlled compatibility checks and upgrade/restore plan; no auto-setup in production.
- Exercise scheduled dispatch, activity retry/heartbeat, worker drain, in-flight server/database interruption and durable history, SQL visibility and namespace separation.
- Scope namespace/queue operations with real authorisation and TLS; namespace and task queue identifiers alone confer no permissions. Direct SDK fixture is trusted local only.
- Verify published gateway contract independently; no business ownership or direct Temporal SQL access by capabilities. Backup/PITR belongs to Phase 5. No paid activation.

## Owner startup evidence — 27 November 2026

Startup passed at 282a40a: PostgreSQL 18, Temporal auto-setup 1.27.2, execution schema 1.16 (minimum 1.0), visibility schema 1.9 (minimum 0.1), both healthy, complete cleanup. Observed repository digest b44cbfeb43dbeae42db113b44fb8414c3452f05643b3d6b1592f955277d73526 now pins the fixture. This is local platform evidence, not general architecture support or upstream certification.

Execution now exercises a real activity with one intentional transient failure and exactly two attempts, then drains the worker. Recovery additionally suspends a distinct workflow after the completed activity, restarts both services, resumes via signal with a fresh worker and asserts no repeated completed activity. This is clean restart/replay evidence only; heartbeat timeout, abrupt crash, scheduling, visibility query, authorisation and migrations remain separate. Existing legacy SDK fixture unchanged; no new dependencies. Local execution pending.
