#!/bin/bash
# Existing installation only; no installer download, pull, restart or deployment.
set -euo pipefail
umask 077
mode=${1:---check}
[[ $EUID = 0 && ( $mode = --check || $mode = --apply ) ]] || exit 2
cd /data/coolify/source
[[ -f docker-compose.yml && -f docker-compose.prod.yml && -f .env ]] || { echo 'Unsupported Coolify layout'; exit 3; }
target=docker-compose.custom.yml
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
base=(--env-file .env -f docker-compose.yml -f docker-compose.prod.yml)
# Compose rendering can contain secrets: stream it privately, never print it.
docker compose "${base[@]}" config --format json 2>"$tmp/render.err" | python3 -c '
import json,sys
d=json.load(sys.stdin)
out={}
for name,s in d["services"].items():
    ports=s.get("ports",[])
    if not ports: continue
    values=[]
    for p in ports:
        if not isinstance(p,dict): raise SystemExit("Unsupported port format")
        published=str(p.get("published",""))
        target=p.get("target")
        protocol=p.get("protocol","tcp")
        if not published.isdecimal() or not isinstance(target,int) or protocol not in ("tcp","udp"):
            raise SystemExit("Unsupported port mapping")
        values.append("      - "+json.dumps("127.0.0.1:"+published+":"+str(target)+"/"+protocol))
    out[name]=values
if not out: raise SystemExit("No known published ports found; review installation")
print("# Managed by Nuxt Layers local setup")
print("services:")
for name,values in out.items():
    print("  "+json.dumps(name)+":")
    print("    ports: !override")
    print("\n".join(values))
' >"$tmp/override.yml"
if [[ -e $target ]] && ! cmp -s "$target" "$tmp/override.yml"; then
 echo 'Existing custom override differs; reconcile without overwriting.' >&2; exit 3
fi
docker compose "${base[@]}" -f "$tmp/override.yml" config --format json 2>"$tmp/render.err" | python3 -c '
import json,sys
for s in json.load(sys.stdin)["services"].values():
    if s.get("network_mode")=="host" or s.get("privileged"): raise SystemExit("Unsafe service configuration")
    for p in s.get("ports",[]):
        if p.get("host_ip")!="127.0.0.1": raise SystemExit("Non-loopback port")
'
if [[ $mode = --check ]]; then echo 'PASS: candidate local Compose override; runtime unchanged.'; exit 0; fi
systemctl is-active --quiet nuxt-ingress.service && nft list table inet nuxt_ingress >/dev/null || { echo 'Ingress guard required'; exit 3; }
if [[ ! -e $target ]]; then install -m 0600 "$tmp/override.yml" "$target"; fi
echo 'PASS: persistent override staged. Existing containers unchanged; controlled recreation and proxy policy remain separate gates.'
