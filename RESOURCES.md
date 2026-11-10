# Resources

- [Nuxt Layers architecture rules](https://github.com/nuxt-layers/architecture-rules) — governing architecture; reviewed master SHA `3436b1cc2a33401a7c3f08d5bc9ee9fe11ea93d2`.
- [ADR-0006 — data store security](https://github.com/nuxt-layers/architecture-rules/blob/master/docs/decisions/ADR-0006-polyglot-persistence-and-data-store-security.md).
- [ADR-0014 — hosting and storage providers](https://github.com/nuxt-layers/architecture-rules/blob/master/docs/decisions/ADR-0014-hosting-and-storage-providers.md).
- [Security baseline](https://github.com/nuxt-layers/architecture-rules/blob/master/docs/security.md).
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
