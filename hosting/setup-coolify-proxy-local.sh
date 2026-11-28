#!/bin/bash
# Existing reviewed Coolify proxy layout only. No daemon startup or recreation.
set -euo pipefail
umask 077
mode=${1:---check}
[[ $EUID = 0 && ( $mode = --check || $mode = --apply ) ]] || exit 2
cd /data/coolify/proxy
target=docker-compose.yml
[[ -f $target && ! -L $target ]] || exit 3
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
python3 - "$target" >"$tmp" <<'PY'
import pathlib,sys
p=pathlib.Path(sys.argv[1])
s=p.read_text()
old="""    ports:
      - '80:80'
      - '443:443'
      - '443:443/udp'
      - '8080:8080'
"""
new="""    ports:
      - '127.0.0.1:80:80'
      - '127.0.0.1:443:443'
      - '127.0.0.1:443:443/udp'
"""
if s.count(old)==1:
    s=s.replace(old,new)
elif s.count(new)!=1:
    raise SystemExit("Unknown proxy port layout; review required")
s="".join(line for line in s.splitlines(keepends=True) if not line.strip().lower().startswith("- '--certificatesresolvers.letsencrypt.acme."))
if "certificatesresolvers." in s.lower():
    raise SystemExit("Unreviewed certificate resolver remains")
sys.stdout.write(s)
PY
docker compose --project-directory "$PWD" -f "$tmp" config --format json | python3 -c '
import json,sys
d=json.load(sys.stdin)
s=d["services"]["traefik"]
actual={(p.get("host_ip"),str(p.get("published")),p.get("target"),p.get("protocol","tcp")) for p in s.get("ports",[])}
expected={("127.0.0.1","80",80,"tcp"),("127.0.0.1","443",443,"tcp"),("127.0.0.1","443",443,"udp")}
if actual!=expected: raise SystemExit("Unexpected proxy port configuration")
if s.get("network_mode")=="host" or s.get("privileged"): raise SystemExit("Unsafe proxy service")
if any("certificatesresolvers." in x.lower() for x in s.get("command",[])): raise SystemExit("Certificate resolver remains")
'
if [[ $mode = --check ]]; then echo 'PASS: local proxy candidate; no runtime changes.'; exit 0; fi
systemctl is-active --quiet nuxt-ingress.service && nft list table inet nuxt_ingress >/dev/null || { echo 'Ingress guard required'; exit 3; }
if systemctl is-active --quiet docker.service || systemctl is-active --quiet docker.socket; then echo 'Stop Docker and socket first'; exit 3; fi
install -d -m 0700 /etc/nuxt-infrastructure
backup=/etc/nuxt-infrastructure/coolify-proxy-compose.original.yml
if ! cmp -s "$tmp" "$target"; then
 if [[ ! -e $backup ]]; then install -m 0600 "$target" "$backup"; fi
 cp --preserve=mode,ownership "$target" "$target.nuxt-new"
 cat "$tmp" > "$target.nuxt-new"
 mv -f "$target.nuxt-new" "$target"
fi
echo 'PASS: local proxy staged. Coolify may regenerate this file; revalidate after any management operation or upgrade.'
