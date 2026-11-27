# Resources

- [Nuxt Layers architecture rules](https://github.com/nuxt-layers/architecture) — governing architecture; reviewed master SHA `0cbc06560db54a7460b707012730887b01180a7d`.
- [ADR-0006 — data store security](https://github.com/nuxt-layers/architecture/blob/master/docs/decisions/ADR-0006-polyglot-persistence-and-data-store-security.md).
- [ADR-0014 — hosting and storage providers](https://github.com/nuxt-layers/architecture/blob/master/docs/decisions/ADR-0014-hosting-and-storage-providers.md).
- [Security baseline](https://github.com/nuxt-layers/architecture/blob/master/docs/standards/security-standard.md).
- [PostgreSQL official Docker image](https://hub.docker.com/_/postgres) — persistent directory differs at PostgreSQL 18.
- [Temporal Docker images and auto-setup](https://github.com/temporalio/docker-builds/blob/main/docker-readme/auto-setup.md) — development reference only.
- [Archived Temporal Compose reference](https://github.com/temporalio/docker-compose/blob/main/docker-compose-postgres.yml) — archived 2026-01-05; not production guidance.

**Verification status:** Image tags in the local example are provisional development references, not a claim that they are the latest or production-certified.

## Extension build references (checked 2026-11-10)

- [Apache AGE PG18 1.8.0 release](https://github.com/apache/age/releases/tag/PG18%2Fv1.8.0-rc0).
- [pg_textsearch 1.5.1](https://github.com/timescale/pg_textsearch/releases/tag/v1.5.1).
- [pgmq 1.13.0](https://github.com/pgmq/pgmq/releases/tag/v1.13.0).
- [pg_cron PostgreSQL 18 Debian installation](https://github.com/citusdata/pg_cron#installing-pg_cron).
- [PostgreSQL 18 Debian packages](https://www.postgresql.org/download/linux/debian/).

## Functional API documentation (consulted for PR #3)

- [Apache AGE Cypher creation/traversal](https://age.apache.org/getstarted/quickstart/).
- [pg_textsearch BM25 querying](https://github.com/timescale/pg_textsearch/blob/main/README.md).
- [pgmq SQL API](https://pgmq.github.io/pgmq/api/sql/functions/).
- [pg_cron jobs, execution history and background workers](https://github.com/citusdata/pg_cron).

## Apache AGE preload compatibility

- [Apache AGE issue #2180](https://github.com/apache/age/issues/2180) — errors when AGE globally preloaded in a database without `ag_catalog`.
- [Apache AGE utility-command fix discussion #2578](https://github.com/apache/age/pull/2578) — TRUNCATE and other utility commands can access missing AGE catalogues.

## Temporal PostgreSQL 18 evaluation (2026-11-10)

- [Temporal persistence compatibility matrix](https://docs.temporal.io/temporal-service/persistence) — PostgreSQL 16.6 is in the published tested matrix; PostgreSQL 18 is **not** listed, and therefore requires local acceptance before production approval.
- [Temporal TypeScript SDK worker example](https://github.com/temporalio/samples-typescript/blob/main/hello-world/src/worker.ts).
- [Temporal TypeScript SDK worker reference](https://typescript.temporal.io/api/namespaces/worker).
- [PostgreSQL 18 Docker layout](https://hub.docker.com/_/postgres) — `/var/lib/postgresql`, not `/var/lib/postgresql/data`.

## Approved programme references (selection, not release verification)

- [Infrastructure specification](https://github.com/nuxt-layers/architecture/blob/master/docs/infrastructure/infrastructure/infrastructure-record.md)
- [Governing Phase 1 PR](https://github.com/nuxt-layers/architecture/pull/6)
- [SeaweedFS](https://github.com/seaweedfs/seaweedfs)
- [Apache Jena](https://jena.apache.org/)
- [restic](https://restic.net/)
- [pgBackRest](https://pgbackrest.org/)
- [Coolify](https://coolify.io/docs/)
- [Stripe testing](https://docs.stripe.com/testing), [sandboxes](https://docs.stripe.com/sandboxes), [CLI](https://docs.stripe.com/stripe-cli), [Node SDK](https://github.com/stripe/stripe-node)
- [NIST PQC](https://csrc.nist.gov/projects/post-quantum-cryptography), [Node crypto](https://nodejs.org/api/crypto.html), [noble post-quantum](https://github.com/paulmillr/noble-post-quantum), [shamir-secret-sharing](https://www.npmjs.com/package/shamir-secret-sharing)

Exact selected versions, licences, transitive dependencies and provider access remain implementation acceptance matters.
