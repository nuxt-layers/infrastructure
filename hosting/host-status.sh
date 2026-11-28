#!/bin/bash
# Read-only local host CLI; no network listener, container environment or tenant data.
set -euo pipefail
if [[ $(id -u) != 0 ]]; then echo 'Requires authorised host operator via sudo' >&2; exit 1; fi
export LC_ALL=C
printf 'observed_at=%s\n' "$(date -u +%FT%TZ)"
echo 'scope=host_resources_only'
printf 'os=%s\n' "$(uname -srm)"
printf 'cpu_count=%s\n' "$(nproc)"
awk '/^MemTotal:|^MemAvailable:/ {print $1,$2,$3}' /proc/meminfo
df -Pk / | awk 'NR==2 {print "root_capacity_kib=" $2 "\nroot_available_kib=" $4 "\nroot_used_percent=" $5}'
if command -v docker >/dev/null && timeout 10 docker info --format 'docker_server={{.ServerVersion}}' 2>/dev/null; then
    echo 'docker_status=ready'
    timeout 10 docker stats --no-stream --format '{{.Name}} {{.CPUPerc}} {{.MemUsage}} {{.PIDs}}' || echo 'container_metrics=unknown'
else
    echo 'docker_status=unavailable'
fi
if command -v chronyc >/dev/null && tracking=$(timeout 5 chronyc -n tracking 2>/dev/null); then
    printf '%s\n' "$tracking" | awk -F: '/^(Stratum|Reference time|System time|Last offset|Root dispersion|Leap status)/ {print}'
fi
# Never infer authenticated NTS or business readiness from a sync flag.
echo 'time_authentication=unknown'
echo 'time_status=unknown'
echo 'backup_status=unknown'
echo 'application_status=unknown'
