#!/bin/bash
set -euo pipefail
umask 077
mode=${1:---check}
[[ $EUID = 0 && ( $mode = --check || $mode = --apply ) ]] || exit 2
command -v python3 >/dev/null
command -v dockerd >/dev/null
target=/etc/docker/daemon.json
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
python3 - "$target" >"$tmp" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1])
d=json.loads(p.read_text()) if p.exists() else {}
if not isinstance(d,dict): raise SystemExit("Invalid daemon configuration")
if any(not x.startswith("unix://") for x in d.get("hosts", [])):
    raise SystemExit("Non-Unix Docker API configuration; reconcile first")
for key in ("iptables","ip6tables"):
    if d.get(key) is False: raise SystemExit("Docker firewall disabled: "+key)
d["ip"]="127.0.0.1"
d.setdefault("default-network-opts",{}).setdefault("bridge",{})["com.docker.network.bridge.host_binding_ipv4"]="127.0.0.1"
print(json.dumps(d,indent=2))
PY
dockerd --validate --config-file "$tmp" >/dev/null
if [[ $mode = --check ]]; then echo 'PASS: candidate Docker configuration; existing networks and containers unchanged.'; exit 0; fi
systemctl is-active --quiet nuxt-ingress.service && nft list table inet nuxt_ingress >/dev/null || { echo 'Ingress guard required'; exit 3; }
if systemctl is-active --quiet docker.service || systemctl is-active --quiet docker.socket; then
 echo 'Stop Docker and socket gracefully before applying; no automatic restart.' >&2; exit 3
fi
install -d -m 0755 /etc/docker
install -d -m 0700 /etc/nuxt-infrastructure
if [[ -e $target && ! -e /etc/nuxt-infrastructure/daemon.json.original ]]; then
 install -m 0600 "$target" /etc/nuxt-infrastructure/daemon.json.original
fi
if [[ ! -e $target ]] || ! cmp -s "$tmp" "$target"; then
 install -m 0600 "$tmp" /etc/docker/daemon.json.nuxt-new
 mv -f /etc/docker/daemon.json.nuxt-new "$target"
fi
echo 'PASS: loopback defaults staged. Existing networks, explicit bindings and Docker service flags still require independent verification.'
