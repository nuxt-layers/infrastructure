# Infrastructure acceptance specification

No acceptance results asserted. CI or owner executes tests; record command, revision, fixture, environment, versions/digests, timestamp, expected/actual result, redacted evidence, pass/fail/unknown, defects and rerun. Never treat readiness probes as proof of domain outcomes. All mandatory local gates must pass before MVP release/paid activation; production-specific verification remains separate. Use isolated disposable fixtures and synthetic credentials. Requirements map by phase in REQUIREMENTS.md; this specification groups cross-cutting gates.

| Gate | Required evidence | Phase |
|---|---|---|
| A01 | Clean bootstrap/start/stop/restart, safe reruns, version manifest, SBOM, private services, no production dev override | 2–4, 8 |
| A02 | PostgreSQL native search, AGE, BM25, PGMQ, cron, pg_trgm, conditional vector; scoped roles, RLS negative tests, pool exhaustion, migrations/upgrades, restart; owner schema boundary | 2 |
| A03 | Worker claims, retries, idempotency, outbox delivery, Temporal namespace/task queue, controlled migrations, worker/server restart/history; no direct Temporal DB access | 3 |
| A04 | Local Coolify/Traefik, multiple sites, DNS TXT ownership, route revision applied/withdrawn, local ACME issuance/renewal, trusted headers, failure/recovery | 4, 6 |
| A05 | S3 suite below | 6 |
| A06 | Negative isolation suite below; crypto inventory, known-answer tests, downgrade, negotiated protocol, key rotation/compromise/restore, resource limits and no secret logging | 2–8 |
| A07 | SMTP/OIDC/WebAuthn/API/fault fixtures and Stripe sandbox suite below | 6 |
| A08 | Selected isolated scanning, quarantine, decoding, conversion, Jena profile/SHACL and conditional collaboration/solver; bounded execution and unsupported modes | 6 |
| A09 | Independent restic and pgBackRest backup/PITR/restore, lost volumes, unexpected shutdown, erasure/revocation replay, independent reconstruction without app jobs | 5 |
| A10 | Qualified ready/degraded/unavailable/stale/unknown status, time drift/holdover, resource pressure, log/metric limits and redaction | 7 |
| A11 | Production manifests, regional controls/provider assurance, TLS/secret policies, documented differences and unverified external gates | 8 |
| A12 | Zero additional local cost, no mandatory paid trials, no live payment, explicit approval before Hetzner account or deployment | all |

## S3 (SeaweedFS)
Test same Storage client/adapter as intended for Hetzner: SigV4 success/rejection; public/private/uploads/application-file backup bucket scope; PUT/GET/HEAD/DELETE/list; presigned expiry/method restrictions; multipart complete/abort/cleanup; CORS; checksum/metadata; lifecycle; cross-tenant and cross-bucket negatives; restart and restore; quotas/usage as supported; resource budgets. Missing mandatory behaviour blocks selection acceptance; evaluate RustFS only if required. Infrastructure backups never use application bucket.

## Negative isolation
For each supported store prove denied cross-owner access and denied cross-tenant read/inference/write with synthetic tenants A/B and restricted runtime credentials; no bypass by table owner, client-supplied tenant or host super-admin label. Include DB schemas/RLS, object prefixes/buckets, cache keys, search/graph traversal, MQ producers/consumers, Temporal worker namespace/queue scope (not business authority), keys, logs/metrics, backups/restore and integration accounts. Reuse production policy templates and test suite locally. No release on failure; separately verify actual production provider controls.

## Stripe and plugin
Register/discover/enable/disable/revoke/replace trusted versioned connector; verify scoped test credentials and reject live keys, independent merchant/tenant connections; hosted Checkout, authorisation/capture/cancel/refund, 3DS, decline, timeout, signed webhooks via Stripe CLI, duplicate/out-of-order/replay, idempotency, reconciliation and provider withdrawal. Deterministic offline simulator for fault injection; actual Stripe sandbox for interoperability. No money moved, no paid activation; confirm account access and zero-cost terms before use. Integrations owns connection/plugin lifecycle; Payment Gateway owns payment operations. No provider SDK in shared contracts.

## Cryptographic and recovery evidence
Follow ADR-0020 upon adoption: inventory algorithms and key owners, actual protocol negotiation, hybrid/PQC support where interoperable, known-answer tests, migration/re-encryption, downgrade refusal, threshold custody/recovery, supply-chain and side-channel assessment, benchmark, automated abuse controls. No custom algorithms or FIPS/P=NP-proof assertion. No HSM purchase. Test source-owner restore consistency separately from resource recovery.

## MVP and production
MVP composition and user journeys require separate owner agreement; infrastructure acceptance does not prove platform MVP. Hetzner account activation only after local MVP and explicit owner approval. Recheck ADR-0014 assurance, region, public DNS/TLS, actual S3 and provider behavior after activation.
