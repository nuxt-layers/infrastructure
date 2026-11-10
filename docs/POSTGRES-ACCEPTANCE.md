# PostgreSQL local functional acceptance

Run only against the **disposable, local development stack**. The suite creates and drops the fixed `infra_acceptance` schema, AGE graph `infra_accept_graph`, pgmq queue `infra_accept_q`, and cron fixtures. **Never point this suite at a shared or production database.** It will replace any existing objects with those exact test names.

```powershell
.\scripts\start.ps1
.\scripts\install-extensions.ps1
.\scripts\verify-extensions.ps1
.\scripts\test-postgres.ps1
```

The script requires a functioning Docker Desktop, a local `.env`, and the already-built PostgreSQL extension image. After modifying Compose settings, `start.ps1` must recreate the PostgreSQL container to apply them; no database volume reset is necessary. The first pg_cron test on the previously preloaded AGE configuration failed because AGE hooks accessed `ag_catalog` in the `postgres` database. The fixed configuration loads AGE only for graph sessions.

Checks:

1. Apache AGE graph create, two vertices, directed edge and traversal.
2. `pg_textsearch` BM25 index, ranking and a basic explicit tenant predicate. This does **not** establish production tenant isolation or row-level security.
3. `pgmq` message delivery, temporary invisibility, redelivery after visibility timeout, archiving.
4. `pg_cron` scheduled insertion and successful job-run record using PostgreSQL background workers.
5. Logged table survives a **clean** container restart; UNLOGGED table is verified as UNLOGGED and may retain its rows after a clean restart.

`-SkipRestart` leaves persistence fixtures behind and avoids restarting PostgreSQL while other local clients are connected.

**Not included:** a simulated power failure or crash, cache truncation after an unclean shutdown, replication, tenant-policy attacks, concurrency/load benchmarking, backups or restore testing. The destructive crash test must use a separate ephemeral Compose project and isolated volume; never force-crash the shared development database.

On test failures, do not merge the PR. Capture error output and correct the suite or extension implementation. Tests were authored but not executed in this session.
