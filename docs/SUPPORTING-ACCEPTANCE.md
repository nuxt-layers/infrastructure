# Supporting services: initial local fixture

Separate disposable project, loopback ports, synthetic credentials, bounded resources and logs. No paid services. Supply exact reviewed image digests for SeaweedFS and Mailpit (do not guess digests). Use Docker's registry inspection to resolve an approved release tag before running.

```powershell
.\scripts\test-supporting.ps1 -SeaweedImage 'chrislusf/seaweedfs:<approved-tag>@sha256:<digest>' -MailpitImage 'axllent/mailpit:<approved-tag>@sha256:<digest>'
```

The initial acceptance covers signed object CRUD, invalid/anonymous rejection and SMTP capture. It does not claim Storage adapter parity, scoped tenant isolation, multipart/presigning, TLS/authentication failures, backup/restore or production readiness. Those remain mandatory follow-on gates. Owner execution pending.
