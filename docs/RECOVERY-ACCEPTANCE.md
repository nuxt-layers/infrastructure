# Local recovery fixtures

Run separately with an approved exact pgBackRest apt package version and digest-qualified restic image.

```powershell
.\scripts\test-recovery.ps1 -PgBackRestVersion '<approved exact package version>'
.\scripts\test-restic.ps1 -ResticImage 'restic/restic:<approved-tag>@sha256:<digest>'
```

The PostgreSQL fixture uses an encrypted repository volume and a separate restore volume. It restores a named WAL recovery point after a subsequent destructive transaction. The restic fixture verifies repository data and restores a deleted synthetic file with an exact SHA-256 comparison. Neither touches existing project data or requires external services.

Same-host volumes prove logical restoration only, not physical disaster resilience. Application extension-image and Temporal-specific backup integration, independent protected production target, scheduled retention, measured RPO/RTO, erasure/revocation replay and credential recovery remain pending. No acceptance claimed until owner execution.
