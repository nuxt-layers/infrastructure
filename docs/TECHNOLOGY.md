# Technology and environment inventory

Zero additional local spend. Exact versions, licensing for selected builds, transitive dependencies, digest, compatibility and resource evidence must be recorded before deployment. Selected does not mean installed or verified. Alternative services are not mandatory; do not provision competing products by default.

| Facility | Local / production direction | Status |
|---|---|---|
| Docker / Compose | Windows development and Linux acceptance; same deployment manifests where practical | Retain |
| Linux / Coolify / Traefik | Local Linux VM (existing hardware), Coolify and Traefik; production Hetzner VPS only after approval | Selected target; VM/resources unverified |
| DNS / TLS | CoreDNS and step-ca candidates locally; public DNS/ACME after activation | Evaluate |
| PostgreSQL | 18 application; separately persisted Temporal DB 18 compatibility candidate | Retain; verify support |
| Extensions | AGE, pg_textsearch, PGMQ, pg_cron existing; pg_trgm and conditional pgvector | Verify exact releases and ABI; no global schema |
| Pool / cache | Native pools; PgBouncer conditional; in-process or PostgreSQL regenerable cache | Evaluate |
| MQ alternatives | NATS JetStream; Redis-compatible cache only justified separately | Conditional |
| Temporal | Controlled server/schema migration, worker and optional UI | Selected supported profile |
| S3 | SeaweedFS local single-node; Hetzner S3 production; RustFS fallback only if acceptance fails | Approved; no parallel candidates by default |
| Ontology | Apache Jena bounded RDF/OWL profile and SHACL, isolated Java runtime; no unrestricted SPARQL or second authority | Approved |
| File backup | restic encrypted independent target | Approved |
| DB backup | pgBackRest separate app and Temporal recovery | Approved |
| Test mail / OIDC | Mailpit; Keycloak or lightweight fixture | Evaluate |
| API / faults | MockServer or WireMock; Toxiproxy | Evaluate |
| Payments | Stripe Sandbox, stripe SDK, hosted Checkout, Stripe CLI, offline simulator | Approved reference connector; no live credentials or money |
| Processing | ClamAV, libvips, FFmpeg, Tesseract, LibreOffice headless, Playwright Chromium, fonts | Conditional, exact builds and licence review |
| Collaboration / solver | Yjs/Hocuspocus; HiGHS or OR-Tools | Conditional |
| UTC | OS NTP/NTS, allowlist and qualified status | Required |
| Monitoring | Native logging/observability; OpenTelemetry, Prometheus, Jaeger, Alertmanager conditional | Evaluate |

## Cryptography

Canonical candidate applicability and upstream source snapshots are maintained in the [governing Infrastructure specification](https://github.com/nuxt-layers/architecture/blob/master/docs/infrastructure/infrastructure/infrastructure-record.md#cryptographic-technology-and-implementation-candidates) and [architecture resource register](https://github.com/nuxt-layers/architecture/blob/master/RESOURCES.md#node-crypto), pending adoption of [architecture PR #6](https://github.com/nuxt-layers/architecture/pull/6). Infrastructure records environment-level versions, supported TLS/protocol combinations, key custody facilities and operational evidence; actual application package dependencies and lockfiles belong to consuming artefacts. No universal crypto dependency is mandated.

Apply governing ADR-0020 upon adoption. Prefer Node crypto, Web Crypto and OpenSSL/maintained protocol stacks; use ML-KEM, ML-DSA, SLH-DSA and standard hybrid protocols when interoperable, reviewed AEAD (AES-256-GCM, ChaCha20-Poly1305 as appropriate), SHA-2/SHA-3 and OS-backed CSPRNG. No custom handshakes, OTP platform cipher or P=NP-proof claims. Assess @noble/post-quantum, @noble/ciphers, @noble/hashes, @noble/curves only for native gaps; shamir-secret-sharing for reviewed independent threshold custody; @quxtech/pqc-crypto, @digital-defiance/secrets-ts, liboqs as conditional alternatives; HSM/PKCS#11 future risk-based option only. Audit exact dependencies and side-channel assumptions; no hardware purchase. Node crypto support does not establish TLS negotiation support across proxies/providers.

## Local / production equivalence

| Area | Local | Production-specific evidence |
|---|---|---|
| Network and hosting | Linux/Coolify/Traefik, synthetic DNS and CA/ACME | Public DNS, certificates, firewall, region |
| Database and execution | Same scoped roles, extension versions and controlled migrations; isolated fixtures | Real provider sizing, backup and compatibility |
| Object storage | SeaweedFS with same Storage adapter and policy suite | Hetzner S3 actual behaviour/regions |
| External providers | Captured SMTP, simulated APIs and Stripe Sandbox | Approved real routes, provider assurance and live credential segregation |
| Recovery | Independent local backup target and restore drills | Independently protected remote backup and RPO/RTO |
| Cryptography | Same mandatory policy, synthetic keys, negative tests, actual negotiated protocols | External protocol/provider compatibility and custody assurance |
| Capacity | Existing workstation budget; measure CPU/RAM/disk | VPS sizing and costs after MVP |
| Credentials | Synthetic only | Production secrets and rotation; never reuse local values |

Provider assurance under ADR-0014, public trust, actual external behaviour and physical failure cannot be certified by local success. Local failures block production. Separate physical backup media if already available; same-drive backup proves restoration only.
