# PostgreSQL build and extension upgrade acceptance

## Build identity

Development defaults remain mutable until verified. Compose accepts POSTGRES_BASE as a digest-qualified official PostgreSQL image and CRON_PACKAGE_VERSION as an exact apt version. Both stages use the same base reference; builder apt repositories and transitive dependencies must also be captured/pinned for a reproducible release. Existing AGE RC tag is provisional; resolve its commit and verify it in the Dockerfile before release. Do not claim output image identity from a source tag.

After local build/start, run:
```powershell
.\scripts\record-postgres-build.ps1
```
This emits redacted runtime evidence, including image ID, local base tag digests, installed apt package versions and application extension versions. The local base tag may have moved since build; capture actual build provenance separately. Record reviewed platform, base manifest digest, exact source commits, package versions/checksums, dependency provenance and vulnerability assessment. No publication or paid service is required for local testing.

## Upgrade gate (disposable copy only)

1. Record current image ID, source revision, server version and every installed extension version in both application and maintenance databases. Identify a supported upgrade path from upstream release notes. If none exists, mark blocked, not passed.
2. Take a verified backup and restore into a separate disposable project/volume; never attach the only original volume to an upgrade candidate. For development fixtures a synthetic populated database suffices; actual backup/PITR is Phase 5.
3. Populate representative relational data, graph, search index, queue and cron fixtures using the old image. Record expected rows, graph traversals, search results, queued messages and job state.
4. Build candidate with reviewed versions and immutable inputs. Start it against the disposable copy; verify PostgreSQL major compatibility, preload, available extension versions and startup logs.
5. Operator explicitly selects each supported target version; use ALTER EXTENSION name UPDATE TO 'verified-version' in its owning database, never automatic latest. Review dependent objects, privileges and migration paths. pg_cron is in postgres; graph extension is not globally preloaded.
6. Repeat functional and negative isolation suites, restart and compare recorded state. Record failed/unknown outcomes; do not activate candidate if any mandatory check fails.
7. Rollback means restoring the pre-upgrade copy with matching old image, not assuming ALTER EXTENSION downgrade is supported. Test recovery separately.

## Consuming host

Companion [infrastructure-test PR #2](https://github.com/nuxt-layers-test/infrastructure-test/pull/2) introduces restricted-role and bounded client-pool checks. Provision diagnostic role separately using owner template, activate login securely, set server-only URL and run on loopback. The existing application lockfile lacks dependency graph; regenerate and review locally before frozen-lockfile validation. No tests/builds executed here.

## Outstanding

Exact base digest, AGE commit, apt version and complete dependency provenance remain unresolved until verified. No specific extension upgrade is authorised merely because a new release exists. Runtime acceptance, graph/queue privilege compatibility, search inference resistance, real host diagnostics and recovery remain release gates.
