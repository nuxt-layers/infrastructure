#!/bin/bash
# Read-only. Never starts Docker or prints container environment or secrets.
set -euo pipefail
[[ $EUID = 0 ]] || { echo 'Root required' >&2; exit 2; }
systemctl is-active --quiet docker.service || { echo 'UNKNOWN: Docker inactive'; exit 3; }
command -v python3 >/dev/null
failed=0
container_ids=$(docker ps -aq)
listeners=$(ss -H -lntp)
while IFS= read -r id; do
 [[ -n "$id" ]] || continue
 # Include stopped containers because restart policies can activate them.
 name=$(docker inspect --format '{{.Name}}' "$id")
 if ! docker inspect --format '{"network":{{json .HostConfig.NetworkMode}},"ports":{{json .HostConfig.PortBindings}},"publishAll":{{json .HostConfig.PublishAllPorts}},"privileged":{{json .HostConfig.Privileged}}}' "$id" | python3 -c '
import json,sys
d=json.load(sys.stdin)
errors=[]
if d["network"]=="host": errors.append("host network")
if d["publishAll"]: errors.append("automatic port publishing")
if d["privileged"]: errors.append("privileged container")
for port, bindings in (d["ports"] or {}).items():
    for binding in bindings or []:
        if binding.get("HostIp") not in ("127.0.0.1","::1"):
            errors.append("non-loopback binding: "+port)
for error in errors: print("FAIL: "+error)
sys.exit(bool(errors))
'; then
  printf 'FAIL: container %s\n' "$name"
  failed=1
 fi
done <<< "$container_ids"
# The Docker socket must not be served by an IP listener.
if grep -E ':(2375|2376)([[:space:]]|$)|users:\(\("dockerd"' <<< "$listeners"; then
 echo 'FAIL: potential network Docker API listener'
 failed=1
fi
if (( failed )); then exit 2; fi
echo 'PASS: inspected Docker publishing and API listener policy.'
echo 'UNKNOWN: external connectivity, firewall persistence, reverse tunnels, deployment and upgrade drift.'
