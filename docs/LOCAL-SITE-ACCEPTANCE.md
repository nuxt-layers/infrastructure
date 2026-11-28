# Local DNS and TLS acceptance

Run ` .\scripts\test-local-tls.ps1 ` with PowerShell and Node. Generates disposable CA and site certificates, starts loopback-only authoritative DNS and HTTPS fixtures, validates exact names, unknown-name rejection, CA trust, SNI site separation and HTTP redirection. Does not modify the host DNS or trusted certificate store.

This is a protocol fixture, not Traefik, Coolify or an ACME server. ACME issuance/renewal and real proxy routing remain open. No external services or dependencies.
