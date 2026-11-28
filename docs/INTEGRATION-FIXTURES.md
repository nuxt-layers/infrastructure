# Local protocol fixtures

Run ` .\scripts\test-integrations.ps1 ` from the repository root. Requires the existing Node runtime, no added package or external account.

Synthetic loopback OIDC authorization-code/PKCE flow, discovery, JWKS and signed ID tokens; fixed synthetic principal, fixed client, bounded in-memory state. HTTP faults and idempotent replay/conflict tests are generic connector fixtures, not an implementation of Stripe or any production provider. No production identity or payment use; no external network access required.

DNS/CA/ACME, Stripe-specific parity, real connector acceptance and production identity-provider configuration remain separate requirements. Owner acceptance passed at f510801 on 28 November 2026: both OIDC and HTTP fault/idempotency suites.
