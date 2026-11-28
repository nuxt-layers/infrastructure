# Hosting and operator acceptance

Inactive until owner authorises local VM provisioning. No paid services. Use a dedicated Linux VM on existing equipment, not the Windows developer Docker daemon as production assurance. Install reviewed Docker Engine, Compose, Coolify and chrony versions using their official release instructions; record version, digest, provenance and licence. Restrict SSH to authorised operators, disable password login after testing key access, restrict admin interface to private management network, keep database and backup services private. Verify firewall externally from a second machine, not merely via listening socket inspection. Coolify controls deployment; no public Docker socket. Use explicit approved operator identity and audit records; root access alone does not prove IAM authorisation.

Render the inactive database manifest on Linux using a protected environment file and pipe directly into the static policy check (do not save or print rendered secrets):

    set -o pipefail
    docker compose --env-file /protected/infra.env -f hosting/compose.production.yaml config --format json | node hosting/check-production-config.mjs

Policy check does not deploy. Digest, resource, network, port, inline-secret and bounded-log rules are enforced on rendered manifest. Inspect host firewall, disk encryption, secret file modes (0600), independently held encrypted backup target and actual runtime negotiated TLS separately. Do not share a production environment file or use dev overrides.

Run sudo bash hosting/check-local-host.sh and sudo bash hosting/host-alerts.sh. The latter emits local resource conditions and a nonzero status for pressure or missing telemetry; it is not a notification connector. Unknown backup/application/authenticated-time status remains unknown, never inferred from daemon or clock reachability. Review thresholds with owner before enabling optional systemd timer. To enable only on approved local VM, install files from hosting/systemd into /etc/systemd/system, place reviewed checkout at /opt/nuxt-layers/infrastructure, run systemctl daemon-reload and enable --now nuxt-infrastructure-alerts.timer. Inspect journalctl -u nuxt-infrastructure-alerts.service; disable timer to roll back. Bound journal storage using host-specific retention policy. IAM and remote alert delivery remain separate gates.

## Local ACME

Use disposable Pebble and Traefik fixture only, with private network and .test hostnames. Never substitute a public ACME endpoint. Verify trusted issued certificate, hostname isolation, persistence on restart; renewal is a separate acceptance criterion. See test-acme.ps1.

## Release gates requiring external evidence

Coolify local VM and external firewall probe; actual Stripe Sandbox account/connector with explicit zero-cost approval; Storage adapter parity, tenant prefix policy, CORS/lifecycle/quotas; independent protected backup custody and capability-owner erasure/revocation replay; controlled upgrades with approved target versions; signed software provenance and cryptographic inventory; authorised host operator IAM and actual alert routing; provider region/controls after approval. No production activation or blanket acceptance from local fixture passes.

## Owner execution on the dedicated VM

First run `scripts/test-host-policy.ps1` on the Windows development machine. It is a synthetic negative/positive policy fixture and does not provision a VM. On an existing, separately provisioned Linux VM with Docker, Compose, chrony, OpenSSH and Coolify installed, run `sudo bash hosting/verify-linux-host.sh` from the checked-out repository. Exit 2 indicates a failed local check; exit 3 indicates unresolved evidence (expected until external checks are complete). Do not treat a running Coolify container as proof of a deployed application. Use the external management client to verify permitted SSH/key access and denied unauthorised access, private DB ports and admin UI, deploy two disposable synthetic sites through Coolify, verify TLS, route isolation, revision change and rollback, remove both sites, and record the result. No actual VM or Coolify installation is asserted by this repository change. The example chrony configuration is not active and requires an approved source.
