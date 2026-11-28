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

## Partial Recovery acceptance — 28 November 2026

Owner run on b28c424 passed frozen installation, two-attempt activity execution, worker drain, and suspended workflow signal wait; both containers restarted and cleanup succeeded. Post-restart host SDK connection timed out before historical result or resumption could be verified. Root cause not confirmed: original harness reused pre-restart dynamic port and relied on container-internal readiness. Updated harness stops Temporal before restarting persistence, restores dependency ordering, rediscovers the loopback mapping and verifies namespace RPC via the host SDK before proceeding. Retry is bounded and does not retry the workflow operations. No change to tested activity/workflow semantics or dependencies. Recovery remains unverified until owner reruns Recovery.

## Successful Recovery acceptance — 28 November 2026

Owner run at 00:26–00:27 UTC on 504fe23 passed the complete Recovery stage: pinned images, PG18 and both schema versions, frozen dependency installation, external SDK namespace probe, bounded two-attempt activity retry, worker drain, suspended workflow signal wait, ordered persistence/server restart, historical result retrieval, resumed workflow with zero repeated completed activity invocations, final result retrieval and complete disposable resource cleanup. Docker reassigned the host port from 56363 to 56371; endpoint rediscovery and host readiness probe succeeded immediately. This establishes clean restart and replay acceptance, not abrupt crash, heartbeat, HA or backup/restore qualification. Earlier parser error at 922ec6e was caused by an erroneous text replacement; corrected at 504fe23. DEP0205 warning remains a non-blocking dependency maintenance item. No further clean Recovery repetition required unless its implementation or dependencies change.

## Expanded functional package

Run `./scripts/test-temporal-phase3.ps1 -Stage Functional` to execute Schedule, Heartbeat, Visibility, Separation and Crash on one disposable stack. Each named stage is separately selectable; All includes the original clean Recovery as well. The existing Recovery path remains unchanged. Schedule uses an automatic interval limited to one action (no manual trigger). Heartbeat records a checkpoint, deliberately stops heartbeating and requires the retry to recover that checkpoint. Visibility waits for the exact completed workflow ID. Separation tests namespace-scoped workflow identity and task routing to workers in distinct namespaces and queues; it does not claim access control. Crash SIGKILLs only the disposable Temporal server and database after a workflow reached a durable signal wait and worker drained; recovery verifies no repeated completed activity and final result. This is not abrupt worker-process termination during an active activity, nor backup/restore. No new dependencies; heartbeat resolves the existing activity SDK from the worker's locked dependency graph. SDK v1.24.0 schedule and activity source reviewed; no tests or builds executed by assistant. Local acceptance pending. TLS, real authorisation, controlled schema jobs and gateway contract remain separate gates.

## Functional package startup failure — 28 November 2026

Owner run at 76b0476 failed internal namespace readiness before functional stages; both containers reported healthy and cleanup passed. Root cause unknown because tctl stderr and service logs were discarded. Harness now reports periodic namespace probe failures and collects bounded, secret-redacted service logs and container state before cleanup on failure. Readiness criteria, pinned images, timeout attempts and functional assertions remain unchanged. Prior clean Recovery acceptance stands. No functional acceptance claimed.

## Successful Functional acceptance — 28 November 2026

Owner run at 00:52–00:53 UTC on 0cadd87 passed all five stages on the pinned baseline: automatic scheduled dispatch once; heartbeat timeout with second-attempt checkpoint recovery; exact completed workflow returned through SQL Advanced Visibility; namespace-scoped identity and independent namespace/task-queue routing; SIGKILL of disposable Temporal and PostgreSQL containers after durable signal wait, followed by recovery without repeating completed activity and historical result retrieval. Initial namespace NotFound resolved during polling; the earlier failed startup remains unexplained. Both container sets healthy after restart; host endpoint changed from 64960 to 64975 and SDK readiness passed. All disposable resources removed. No new dependency changes. No repeat required unless relevant code or dependencies change. Routing separation is not authorisation; abrupt infrastructure crash is not active worker-process crash. Controlled migrations, TLS/authentication, active worker crash, consumer integration, gateway contract and production qualification remain outstanding.
