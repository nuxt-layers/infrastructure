#!/bin/bash
set -euo pipefail
export LC_ALL=C
[[ $(id -u) = 0 ]] || { echo 'Requires authorised host operator via sudo' >&2; exit 1; }
[[ $(uname -s) = Linux ]] || { echo 'Linux required' >&2; exit 1; }
for cmd in docker chronyc timeout ss; do command -v "$cmd" >/dev/null || { echo "Missing prerequisite: $cmd" >&2; exit 1; }; done
docker compose version
docker info --format 'Docker {{.ServerVersion}} / {{.OSType}} / {{.Architecture}}'
[[ $(docker info --format '{{.OSType}}') = linux ]]
echo 'Listening TCP ports (operator review; not firewall evidence):'
ss -ltn
bash "$(dirname "$0")/host-status.sh"
echo 'Coolify/Traefik deployment, NTS trust, firewall and capacity remain independent gates.'
