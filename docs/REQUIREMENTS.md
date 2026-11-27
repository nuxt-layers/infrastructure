# Infrastructure requirements register

Owner-approved programme direction, 27 November 2026. IDs preserve the 210-item review baseline; related refinements are not separate products. All are planned, not proven. Conditional facilities require a selected consumer/use case, documented absence behaviour and acceptance; provision the complete selected local profile before MVP. Governing adoption of ADR-0020 is tracked in [architecture PR #6](https://github.com/nuxt-layers/architecture/pull/6). Phase numbers are primary delivery ownership; cross-phase gates are in ACCEPTANCE.md.

| ID | Requirement | Phase | Source / area |
|---|---|---|---|
| INF-R01 | Hetzner VPS target; no activation before MVP | 4 | Hosting |
| INF-R02 | Coolify deployment management | 4 | Hosting |
| INF-R03 | Docker images and Compose | 4 | Hosting |
| INF-R04 | Separate development acceptance production | 4 | Hosting |
| INF-R05 | Reproducible version-pinned deployments | 4 | Hosting |
| INF-R06 | Private networks and service discovery | 4 | Hosting |
| INF-R07 | Persistent volumes and resource allocation | 4 | Hosting |
| INF-R08 | Install verify upgrade recover scripts | 4 | Hosting |
| INF-R09 | Independent bootstrap/recovery | 4 | Hosting |
| INF-R10 | PostgreSQL 18 application baseline | 2 | Persistence |
| INF-R11 | Owner schemas and scoped credentials | 2 | Persistence |
| INF-R12 | Separate runtime migration maintenance diagnostic roles | 2 | Persistence |
| INF-R13 | Durable transactions and source-owned outboxes | 2 | Persistence |
| INF-R14 | Connection pooling facility | 2 | Persistence |
| INF-R15 | PgBouncer conditional | 2 | Persistence |
| INF-R16 | Native full-text search | 2 | Persistence |
| INF-R17 | pg_trgm | 2 | Persistence |
| INF-R18 | Apache AGE property graph | 2 | Persistence |
| INF-R19 | pgvector conditional | 2 | Persistence |
| INF-R20 | pg_textsearch BM25 candidate | 2 | Persistence |
| INF-R21 | PGMQ preferred transport evaluation | 2 | Persistence |
| INF-R22 | pg_cron maintenance | 2 | Persistence |
| INF-R23 | LISTEN/NOTIFY non-durable signalling | 2 | Persistence |
| INF-R24 | UNLOGGED regenerable cache only | 2 | Persistence |
| INF-R25 | Database backup/PITR facility | 2 | Persistence |
| INF-R26 | pgBackRest selected; Phase 5 | 2 | Persistence |
| INF-R27 | Durable background workers | 3 | Execution |
| INF-R28 | Scheduled worker execution | 3 | Execution |
| INF-R29 | Asynchronous event transport | 3 | Execution |
| INF-R30 | Temporal optional at runtime; provision local profile | 3 | Execution |
| INF-R31 | Isolated Temporal DB | 3 | Execution |
| INF-R32 | Temporal worker deployment and connectivity | 3 | Execution |
| INF-R33 | Optional Temporal UI | 3 | Execution |
| INF-R34 | NATS JetStream alternative | 3 | Execution |
| INF-R35 | Redis-compatible cache alternative only if justified | 3 | Execution |
| INF-R36 | Worker readiness recovery graceful shutdown | 3 | Execution |
| INF-R37 | Hetzner S3 application files/images | 6 | Storage |
| INF-R38 | Public private uploads and application-file backup buckets | 6 | Storage |
| INF-R39 | Scoped credentials | 6 | Storage |
| INF-R40 | Lifecycle and multipart cleanup | 6 | Storage |
| INF-R41 | Region controls | 6 | Storage |
| INF-R42 | Local filesystem development support, not S3 acceptance substitute | 6 | Storage |
| INF-R43 | Object integrity recovery deletion verification | 6 | Storage |
| INF-R44 | Separate infrastructure backup target | 6 | Storage |
| INF-R45 | HTTP ingress/reverse proxy | 4 | Networking |
| INF-R46 | DNS resolution and verification | 4 | Networking |
| INF-R47 | TLS issuance/renewal | 4 | Networking |
| INF-R48 | Verified custom-domain routes | 4 | Networking |
| INF-R49 | Trusted forwarded headers | 4 | Networking |
| INF-R50 | Firewall and network policies | 4 | Networking |
| INF-R51 | Controlled external API connectivity | 4 | Networking |
| INF-R52 | Secure inbound webhooks | 4 | Networking |
| INF-R53 | SMTP/API mail connectivity | 4 | Networking |
| INF-R54 | Timeout connection and egress controls | 4 | Networking |
| INF-R55 | Approved verified UTC sources | 4 | Time |
| INF-R56 | OS NTP/NTS | 4 | Time |
| INF-R57 | Source allowlist and applied policy | 4 | Time |
| INF-R58 | Compatible leap/smear policy | 4 | Time |
| INF-R59 | Offset and freshness measurement | 4 | Time |
| INF-R60 | Holdover degradation recovery | 4 | Time |
| INF-R61 | Qualified source readiness | 4 | Time |
| INF-R62 | Bounded structured log sinks | 7 | Observability |
| INF-R63 | Log rotation and storage limits | 7 | Observability |
| INF-R64 | Host/container metrics | 7 | Observability |
| INF-R65 | Provider readiness probes | 7 | Observability |
| INF-R66 | Alert delivery | 7 | Observability |
| INF-R67 | Conditional OpenTelemetry collector | 7 | Observability |
| INF-R68 | Conditional Prometheus | 7 | Observability |
| INF-R69 | Conditional Jaeger | 7 | Observability |
| INF-R70 | Conditional Alertmanager | 7 | Observability |
| INF-R71 | Telemetry retention and access | 7 | Observability |
| INF-R72 | Secrets provisioning and rotation | 4 | Security |
| INF-R73 | Risk-appropriate encryption at rest/in transit | 4 | Security |
| INF-R74 | Host hardening and updates | 4 | Security |
| INF-R75 | Image integrity and vulnerabilities | 4 | Security |
| INF-R76 | Isolated scanning execution | 4 | Security |
| INF-R77 | Malware detection | 4 | Security |
| INF-R78 | Quarantine | 4 | Security |
| INF-R79 | Isolated media/document processing | 4 | Security |
| INF-R80 | Resource upload execution limits | 4 | Security |
| INF-R81 | Privileged action accountability | 4 | Security |
| INF-R82 | Credential revocation and secure retirement | 4 | Security |
| INF-R83 | Scheduled DB backups | 5 | Recovery |
| INF-R84 | Separate Temporal backups | 5 | Recovery |
| INF-R85 | Encrypted independent backup target | 5 | Recovery |
| INF-R86 | Restore tests and backup verification | 5 | Recovery |
| INF-R87 | RPO/RTO | 5 | Recovery |
| INF-R88 | Disaster recovery/reconstruction | 5 | Recovery |
| INF-R89 | Unexpected shutdown recovery | 5 | Recovery |
| INF-R90 | Cache loss/rebuild | 5 | Recovery |
| INF-R91 | Upgrade and rollback | 5 | Recovery |
| INF-R92 | Recovery evidence and safe reactivation | 5 | Recovery |
| INF-R93 | Script administration | 7 | Administration |
| INF-R94 | Deployment status | 7 | Administration |
| INF-R95 | DB/extension compatibility status | 7 | Administration |
| INF-R96 | Backup/restore status | 7 | Administration |
| INF-R97 | Time source status | 7 | Administration |
| INF-R98 | Resource utilisation | 7 | Administration |
| INF-R99 | Optional operator GUI | 7 | Administration |
| INF-R100 | Explicit host super-admin authorisation for interactive management | 7 | Administration |
| INF-R101 | Key wrapping custody rotation | 6 | Supplementary |
| INF-R102 | Conditional collaborative editing transport | 6 | Supplementary |
| INF-R103 | Isolated solver execution | 6 | Supplementary |
| INF-R104 | Secure OS entropy | 6 | Supplementary |
| INF-R105 | Controlled fonts assets conversion | 6 | Supplementary |
| INF-R106 | Provider assurance and annual review ADR-0014 | 6 | Supplementary |
| INF-R107 | Region across primary derived backups ADR-0006/0014 | 6 | Supplementary |
| INF-R108 | SBOM and deployment provenance | 6 | Supplementary |
| INF-R109 | Independent Audit evidence/checkpoints | 6 | Supplementary |
| INF-R110 | Independent maintenance and backup scheduling | 6 | Supplementary |
| INF-R111 | Local S3 service SeaweedFS | 6 | Local parity |
| INF-R112 | Repeatable buckets and credentials | 6 | Local parity |
| INF-R113 | S3 compatibility suite | 6 | Local parity |
| INF-R114 | Local Coolify | 6 | Local parity |
| INF-R115 | Local Traefik | 6 | Local parity |
| INF-R116 | Local DNS/custom domains | 6 | Local parity |
| INF-R117 | Local CA/trust | 6 | Local parity |
| INF-R118 | Site Hosting applied-route reconciliation | 6 | Local parity |
| INF-R119 | Production-representative Linux | 6 | Local parity |
| INF-R120 | Environment-independent manifests | 6 | Local parity |
| INF-R121 | Integrated local MVP acceptance | 6 | Local parity |
| INF-R122 | Explicit approval before paid activation | 6 | Local parity |
| INF-R123 | Repeatable per-owner provisioning | 2 | Database assurance |
| INF-R124 | Non-owner roles without RLS bypass | 2 | Database assurance |
| INF-R125 | Negative cross-schema/tenant tests | 2 | Database assurance |
| INF-R126 | Pool exhaustion/recovery | 2 | Database assurance |
| INF-R127 | Extension upgrade/compatibility matrix | 2 | Database assurance |
| INF-R128 | WAL archiving/PITR | 2 | Database assurance |
| INF-R129 | Isolated destructive fixtures | 2 | Database assurance |
| INF-R130 | Rebuildable caches/indexes | 2 | Database assurance |
| INF-R131 | Unicode/multilingual indexing | 2 | Database assurance |
| INF-R132 | Repeatable local DNS records | 4 | Network assurance |
| INF-R133 | DNS TXT proof fixtures | 4 | Network assurance |
| INF-R134 | Local ACME certificate testing | 4 | Network assurance |
| INF-R135 | WebSocket ingress/lifecycle | 4 | Network assurance |
| INF-R136 | Multiple independently addressed federation peers | 4 | Network assurance |
| INF-R137 | Trusted proxy header validation | 4 | Network assurance |
| INF-R138 | Webhook replay testing | 4 | Network assurance |
| INF-R139 | SSRF/DNS rebinding fixtures | 4 | Network assurance |
| INF-R140 | Network partition/timeout simulation | 4 | Network assurance |
| INF-R141 | Local SMTP capture | 6 | Provider fixtures |
| INF-R142 | SMTP authentication TLS failures | 6 | Provider fixtures |
| INF-R143 | OAuth/OIDC fixtures | 6 | Provider fixtures |
| INF-R144 | WebAuthn virtual authenticator | 6 | Provider fixtures |
| INF-R145 | Payment simulator and signed callbacks | 6 | Provider fixtures |
| INF-R146 | Generic external HTTP/API simulation | 6 | Provider fixtures |
| INF-R147 | Rate limits/retry fixtures | 6 | Provider fixtures |
| INF-R148 | Accounting payroll marketplace fixtures | 6 | Provider fixtures |
| INF-R149 | Mapping/routing fixtures | 6 | Provider fixtures |
| INF-R150 | Notification/push fixtures | 6 | Provider fixtures |
| INF-R151 | Isolated malware scanner | 6 | Processing |
| INF-R152 | Controlled signature updates | 6 | Processing |
| INF-R153 | Quarantine/temp storage | 6 | Processing |
| INF-R154 | Bounded image decoding | 6 | Processing |
| INF-R155 | Conditional audio/video codecs | 6 | Processing |
| INF-R156 | Conditional OCR/languages | 6 | Processing |
| INF-R157 | Safe PDF inspection/rendering | 6 | Processing |
| INF-R158 | Document conversion | 6 | Processing |
| INF-R159 | Reproducible fonts | 6 | Processing |
| INF-R160 | Isolated browser rendering | 6 | Processing |
| INF-R161 | Archive bomb/exhaustion fixtures | 6 | Processing |
| INF-R162 | Temp volume cleanup | 6 | Processing |
| INF-R163 | Collaborative editing restart | 6 | Processing |
| INF-R164 | Apache Jena bounded OWL/SHACL | 6 | Processing |
| INF-R165 | Optional constraint solver | 6 | Processing |
| INF-R166 | Local certificate/trust management | 4 | Security assurance |
| INF-R167 | Signing keys | 4 | Security assurance |
| INF-R168 | Key wrapping rotation retirement recovery | 4 | Security assurance |
| INF-R169 | Independent Audit checkpoint fixtures | 4 | Security assurance |
| INF-R170 | Restore with erasure/revocation replay | 4 | Security assurance |
| INF-R171 | Secret rotation without log disclosure | 4 | Security assurance |
| INF-R172 | CPU memory storage process limits | 4 | Security assurance |
| INF-R173 | Disk exhaustion/resource pressure | 4 | Security assurance |
| INF-R174 | Unexpected restart/shutdown | 4 | Security assurance |
| INF-R175 | Independent maintenance recovery | 4 | Security assurance |
| INF-R176 | Local capacity assessment | 4 | Security assurance |
| INF-R177 | Dev/prod credential separation | 4 | Security assurance |
| INF-R178 | Local-only test provider restrictions | 4 | Security assurance |
| INF-R179 | Synthetic reproducible data | 4 | Security assurance |
| INF-R180 | Zero additional local expenditure | 4 | Security assurance |
| INF-R181 | Crypto algorithm/dependency inventory | 4 | Cryptographic resilience |
| INF-R182 | Versioned algorithm IDs and agility | 4 | Cryptographic resilience |
| INF-R183 | Hybrid/PQC TLS assessment | 4 | Cryptographic resilience |
| INF-R184 | ML-KEM support where interoperable | 4 | Cryptographic resilience |
| INF-R185 | ML-DSA/SLH-DSA assessment | 4 | Cryptographic resilience |
| INF-R186 | Quantum-resistant symmetric profiles | 4 | Cryptographic resilience |
| INF-R187 | Harvest-now-decrypt-later risk | 4 | Cryptographic resilience |
| INF-R188 | Key migration/re-encryption | 4 | Cryptographic resilience |
| INF-R189 | Threshold recovery custody | 4 | Cryptographic resilience |
| INF-R190 | Secure entropy | 4 | Cryptographic resilience |
| INF-R191 | Timing/memory/side-channel assessment | 4 | Cryptographic resilience |
| INF-R192 | Downgrade/negotiation tests | 4 | Cryptographic resilience |
| INF-R193 | Compromise/key replacement exercise | 4 | Cryptographic resilience |
| INF-R194 | Crypto resource benchmarking | 4 | Cryptographic resilience |
| INF-R195 | Known-answer/interoperability tests | 4 | Cryptographic resilience |
| INF-R196 | Zero-cost software key custody | 4 | Cryptographic resilience |
| INF-R197 | Conditional future hardware-backed custody | 4 | Cryptographic resilience |
| INF-R198 | Crypto supply-chain monitoring | 4 | Cryptographic resilience |
| INF-R199 | AI-assisted abuse/exhaustion threat assessment | 4 | Cryptographic resilience |
| INF-R200 | Mandatory local/production security parity | 8 | Release and payment |
| INF-R201 | Shared negative isolation suite | 8 | Release and payment |
| INF-R202 | Local mandatory control failure blocks release | 8 | Release and payment |
| INF-R203 | Operational Integrations plugin | 8 | Release and payment |
| INF-R204 | Stripe Sandbox | 8 | Release and payment |
| INF-R205 | Stripe CLI local webhook forwarding | 8 | Release and payment |
| INF-R206 | Test/live credential separation | 8 | Release and payment |
| INF-R207 | Payment lifecycle acceptance | 8 | Release and payment |
| INF-R208 | Plugin lifecycle/replacement/revocation | 8 | Release and payment |
| INF-R209 | Deterministic offline payment simulator | 8 | Release and payment |
| INF-R210 | Zero-cost external payment acceptance | 8 | Release and payment |
