# Artefact infrastructure traceability

Architecture master reviewed: `0cbc06560db54a7460b707012730887b01180a7d`. All 93 index entries represented. Links point to canonical design records. This is a targeted extraction and engineering mapping, not exhaustive line-by-line proof or actual installed dependencies. Relationships in index are information exchanges, not mandatory runtime dependencies. DB applies only where stateful; shared facilities are host-composed, not private cross-owner access.

| Artefact | Kind | Infrastructure implications / acceptance | Related facilities (index) |
|---|---|---|---|
| [accounting](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/accounting/capability-record.md) | capability | External accounting/bank fixtures | clock, integrations, logging, payment-gateway |
| [api-gateway](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/api-gateway/compositions-record.md) | composition | Trusted ingress | Host baseline as applicable |
| [assessment](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/assessment/capability-record.md) | capability | Submission files and bounded processing | clock, content-security, federation, integrations, logging, media, scheduler, storage |
| [asset](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/asset/capability-record.md) | capability | Evidence bytes | clock, integrations, logging, media, observability, storage |
| [attendance](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/attendance/capability-record.md) | capability | Time and replay | clock, integrations, logging, message-queue |
| [audit](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/audit/capability-record.md) | capability | Independent checkpoints, integrity and restore | caching, clock, content-security, federation, integrations, logging, mailer, media, message-queue, metadata, observability, scheduler, search, site-hosting, storage |
| [authentication](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/authentication/capability-record.md) | capability | Key custody, SMTP, OIDC, WebAuthn | clock, federation, logging |
| [authorisation](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/authorisation/capability-record.md) | capability | Negative isolation, revocation | clock |
| [billing](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/billing/capability-record.md) | capability | Recurring payment simulator | integrations, payment-gateway |
| [booking](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/booking/capability-record.md) | capability | Concurrent reservations and expiry | clock, integrations |
| [caching](https://github.com/nuxt-layers/architecture/blob/master/docs/services/caching/services-record.md) | service | Conditional PostgreSQL shared cache; coherence/loss | clock |
| [checkout](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/checkout/capability-record.md) | capability | Payment recovery and idempotency | payment-gateway |
| [clock](https://github.com/nuxt-layers/architecture/blob/master/docs/services/clock/services-record.md) | service | UTC NTP/NTS quality | Host baseline as applicable |
| [comments-engine](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/comments-engine/capability-record.md) | capability | Content checks | content-security |
| [configuration](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/configuration/capability-record.md) | capability | Versioned settings/reconciliation | clock, message-queue |
| [content-editor](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/content-editor/presentation-record.md) | presentation | Conditional WebSockets/Yjs | Host baseline as applicable |
| [content-security](https://github.com/nuxt-layers/architecture/blob/master/docs/services/content-security/services-record.md) | service | Scanner, quarantine, OCR, isolation | integrations, media, storage |
| [course](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/course/capability-record.md) | capability | Learning content | metadata |
| [credentials](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/credentials/capability-record.md) | capability | Signing, revocation | Host baseline as applicable |
| [employment](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/employment/capability-record.md) | capability | Effective dates | clock |
| [enrolment](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/enrolment/capability-record.md) | capability | Eligibility lifecycle | clock |
| [error-normalisation](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/error-normalisation/stateless-library-record.md) | library | No direct infrastructure | logging |
| [events](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/events/capability-record.md) | capability | Scheduled operations | clock, scheduler |
| [export](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/export/stateless-library-record.md) | library | Fonts and isolated conversion | Host baseline as applicable |
| [facility](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/facility/capability-record.md) | capability | Conditional geometry | Host baseline as applicable |
| [federation](https://github.com/nuxt-layers/architecture/blob/master/docs/services/federation/services-record.md) | service | Independent local peers | search, site-hosting |
| [file-library](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/file-library/stateless-library-record.md) | library | No direct infrastructure | content-security, storage |
| [gallery](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/gallery/presentation-record.md) | presentation | Media delivery | media |
| [gaming](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/gaming/compositions-record.md) | composition | Conditional leaderboard persistence | Host baseline as applicable |
| [help](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/help/presentation-record.md) | presentation | Versioned content | metadata, search |
| [iam-integration](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/iam-integration/compositions-record.md) | composition | Member stores, keys, mail | Host baseline as applicable |
| [identity](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/identity/capability-record.md) | capability | Scoped DB, outbox | Host baseline as applicable |
| [integrations](https://github.com/nuxt-layers/architecture/blob/master/docs/services/integrations/services-record.md) | service | Plugin lifecycle, OAuth/webhook/API fixtures | message-queue, scheduler |
| [inventory](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/inventory/capability-record.md) | capability | Concurrent stock transactions | Host baseline as applicable |
| [invoice](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/invoice/capability-record.md) | capability | Document rendering and e-invoice fixtures | payment-gateway |
| [job](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/job/capability-record.md) | capability | Position records | Host baseline as applicable |
| [legal-compliance](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/legal-compliance/capability-record.md) | capability | Versioned legal source fixtures | Host baseline as applicable |
| [localisation](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/localisation/capability-record.md) | capability | Unicode and translation fixtures | integrations |
| [location](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/location/capability-record.md) | capability | Map/geo fixtures; no default GIS server | search |
| [logging](https://github.com/nuxt-layers/architecture/blob/master/docs/services/logging/services-record.md) | service | Bounded sinks/rotation; no mandatory DB | observability |
| [logistics](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/logistics/capability-record.md) | capability | Routing matrices and optional solver | integrations |
| [mailer](https://github.com/nuxt-layers/architecture/blob/master/docs/services/mailer/services-record.md) | service | SMTP capture and failure fixtures | integrations |
| [manufacturing](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/manufacturing/capability-record.md) | capability | Conditional isolated solver | Host baseline as applicable |
| [marketplace](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/marketplace/capability-record.md) | capability | Provider fixtures | Host baseline as applicable |
| [media](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/media/capability-record.md) | capability | Isolated decoders, derivatives | content-security, metadata, search, storage |
| [membership](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/membership/capability-record.md) | capability | Expiry | Host baseline as applicable |
| [message-queue](https://github.com/nuxt-layers/architecture/blob/master/docs/services/message-queue/services-record.md) | service | PGMQ, replay and leases | observability, scheduler, temporal-gateway |
| [metadata](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/metadata/capability-record.md) | capability | AGE, Jena; no second authoritative store | media, search |
| [moderation](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/moderation/capability-record.md) | capability | Restricted evidence | content-security, media |
| [notifications](https://github.com/nuxt-layers/architecture/blob/master/docs/services/notifications/services-record.md) | service | Channel fixtures | mailer, message-queue, scheduler |
| [observability](https://github.com/nuxt-layers/architecture/blob/master/docs/services/observability/services-record.md) | service | Native first; optional collector | clock, logging |
| [office](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/office/compositions-record.md) | composition | File/export composition | Host baseline as applicable |
| [order](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/order/capability-record.md) | capability | Provider reconciliation | payment-gateway |
| [organisation-console](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/organisation-console/presentation-record.md) | presentation | Authorised operations UI | Host baseline as applicable |
| [page-builder](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/page-builder/presentation-record.md) | presentation | Bounded templates | metadata |
| [party](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/party/capability-record.md) | capability | Relationship records | Host baseline as applicable |
| [payment-gateway](https://github.com/nuxt-layers/architecture/blob/master/docs/services/payment-gateway/services-record.md) | service | Stripe Sandbox and offline simulator | integrations |
| [payroll](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/payroll/capability-record.md) | capability | Financial/statutory fixtures | integrations |
| [pricing](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/pricing/capability-record.md) | capability | External tariff/currency fixtures | clock |
| [privacy](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/privacy/capability-record.md) | capability | Erasure/restore replay | Host baseline as applicable |
| [process](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/process/capability-record.md) | capability | Durable checkpoints | scheduler |
| [product](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/product/capability-record.md) | capability | Search projections | media |
| [profile](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/profile/capability-record.md) | capability | Per-person wrapped keys | Host baseline as applicable |
| [project](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/project/capability-record.md) | capability | Dependency calculations | Host baseline as applicable |
| [publisher](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/publisher/capability-record.md) | capability | Publication/withdrawal and route consistency | media, metadata, search |
| [qualification](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/qualification/capability-record.md) | capability | Evidence and signing | Host baseline as applicable |
| [quality](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/quality/capability-record.md) | capability | Inspection evidence | Host baseline as applicable |
| [recruitment](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/recruitment/capability-record.md) | capability | Restricted applicant files | Host baseline as applicable |
| [reporting](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/reporting/capability-record.md) | capability | Large exports and jobs | logging, observability, scheduler, search, storage |
| [reviews](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/reviews/capability-record.md) | capability | Content safety | content-security |
| [rich-text](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/rich-text/stateless-library-record.md) | library | No direct infrastructure | Host baseline as applicable |
| [scheduler](https://github.com/nuxt-layers/architecture/blob/master/docs/services/scheduler/services-record.md) | service | Durable claims/fencing; Temporal optional | clock, observability, temporal-gateway |
| [search](https://github.com/nuxt-layers/architecture/blob/master/docs/services/search/services-record.md) | service | FTS/pg_trgm, conditional BM25/vector | federation, media, metadata |
| [seo](https://github.com/nuxt-layers/architecture/blob/master/docs/services/seo/services-record.md) | service | Crawler routes/public origins | media, metadata, search, site-hosting |
| [shop](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/shop/compositions-record.md) | composition | Integrated commercial/payment journey | Host baseline as applicable |
| [shopping-basket](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/shopping-basket/capability-record.md) | capability | Concurrent guest state | Host baseline as applicable |
| [site-hosting](https://github.com/nuxt-layers/architecture/blob/master/docs/services/site-hosting/services-record.md) | service | Coolify/Traefik/DNS/ACME and route evidence | Host baseline as applicable |
| [storage](https://github.com/nuxt-layers/architecture/blob/master/docs/services/storage/services-record.md) | service | SeaweedFS/S3 parity | content-security, media |
| [subscription](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/subscription/capability-record.md) | capability | Recurring payments | payment-gateway, scheduler |
| [task](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/task/capability-record.md) | capability | Scheduled work and attachments | scheduler, storage |
| [template-engine](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/template-engine/stateless-library-record.md) | library | Bounded pure execution; isolation if needed | Host baseline as applicable |
| [temporal-gateway](https://github.com/nuxt-layers/architecture/blob/master/docs/adapters/temporal-gateway/adapters-record.md) | adapter | Temporal endpoint, namespace, queue, worker, recovery | message-queue, scheduler |
| [theme-manager](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/theme-manager/presentation-record.md) | presentation | Standalone/IAM modes | Host baseline as applicable |
| [time-attendance](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/time-attendance/capability-record.md) | capability | Offline/time reconciliation | clock |
| [todo](https://github.com/nuxt-layers/architecture/blob/master/docs/compositions/todo/compositions-record.md) | composition | Durable records | clock |
| [training](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/training/capability-record.md) | capability | Learning evidence | Host baseline as applicable |
| [ui](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/ui/presentation-record.md) | presentation | Browser/accessibility runtime | Host baseline as applicable |
| [user](https://github.com/nuxt-layers/architecture/blob/master/docs/presentation/user/presentation-record.md) | presentation | IAM integration | Host baseline as applicable |
| [uuid-generator](https://github.com/nuxt-layers/architecture/blob/master/docs/libraries/uuid-generator/stateless-library-record.md) | library | OS secure entropy | Host baseline as applicable |
| [verification](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/verification/capability-record.md) | capability | External trust fixtures | federation, integrations |
| [warehouse](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/warehouse/capability-record.md) | capability | Barcode/concurrency fixtures | Host baseline as applicable |
| [workflow](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/workflow/capability-record.md) | capability | Durable approvals | scheduler |
| [workforce-scheduling](https://github.com/nuxt-layers/architecture/blob/master/docs/capabilities/workforce-scheduling/capability-record.md) | capability | Calendar constraints | clock, scheduler |
