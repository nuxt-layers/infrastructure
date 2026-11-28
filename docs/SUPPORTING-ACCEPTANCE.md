# Supporting services: initial local fixture

Separate disposable project, loopback ports, synthetic credentials, bounded resources and logs. No paid services. Supply exact reviewed image digests for SeaweedFS and Mailpit (do not guess digests). Use Docker's registry inspection to resolve an approved release tag before running.

```powershell
.\scripts\test-supporting.ps1 -SeaweedImage 'chrislusf/seaweedfs:<approved-tag>@sha256:<digest>' -MailpitImage 'axllent/mailpit:<approved-tag>@sha256:<digest>'
```

Owner acceptance at 9f422b7 covers signed CRUD, scoped bucket isolation, invalid/anonymous denial, SMTP capture and object persistence on restart. Storage adapter parity, presigning/multipart, TLS/authentication failures, backup/restore and production readiness remain separate gates.

## Additional local fixtures

- `scripts/test-payments.ps1`: offline protocol model, no Stripe connection.
- `scripts/test-local-tls.ps1 -TraefikImage <digest-qualified-image>`: existing protocol checks plus actual Traefik route application, withdrawal, reapplication and spoofed forwarded-header refusal. Not Coolify/ACME acceptance.
- `scripts/test-ontology.ps1 -JavaImage <digest-qualified-JDK-image> -JenaArchive <reviewed-apache-jena-tar.gz> -JenaSha512 <published-SHA512>`: isolated synthetic OWL Micro and SHACL acceptance, no unrestricted SPARQL or network.

New fixtures await owner execution. Exact versions, licences and security assurance remain separate.
