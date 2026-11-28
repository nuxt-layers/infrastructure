#!/bin/bash
# Operator-only local polling. Exit 0 normal, 2 degraded, 3 unknown/unavailable.
set -euo pipefail
export LC_ALL=C
[[ $(id -u) = 0 ]] || { echo 'Operator authorisation required' >&2; exit 3; }
disk_limit=DISK_LIMIT_PERCENT:-85
memory_limit=MEMORY_LIMIT_PERCENT:-90
for value in "$disk_limit" "$memory_limit"; do [[ "$value" =~ ^[0-9]{1,2}$ && "$value" -gt 0 ]] || exit 3; done
status=0
emit(){ printf '%s %s %s\n' "$(date -u +%FT%TZ)" "$1" "$2"; }
disk=$(df -Pk / | awk 'NR==2 {gsub(/%/,"",$5);print $5}')
memory=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if(t>0&&a>=0)printf "%d",100*(t-a)/t;else exit 1}' /proc/meminfo)
if [[ ! "$disk" =~ ^[0-9]+$ || ! "$memory" =~ ^[0-9]+$ ]]; then emit unknown resource_metrics; exit 3; fi
if (( disk >= disk_limit )); then emit degraded disk_pressure; status=2; else emit ready disk_pressure; fi
if (( memory >= memory_limit )); then emit degraded memory_pressure; status=2; else emit ready memory_pressure; fi
if ! timeout 10 docker info --format '{{.ServerVersion}}' >/dev/null 2>&1; then emit unavailable docker; status=3; else emit ready docker; fi
if tracking=$(timeout 5 chronyc -n tracking 2>/dev/null); then
    if grep -Eq '^Leap status[[:space:]]*:[[:space:]]*Normal$' <<< "$tracking"; then emit ready clock_sync_indicator; else emit degraded clock_sync_indicator; [[ $status = 3 ]] || status=2; fi
else emit unknown clock_sync_indicator; status=3; fi
emit unknown time_authentication
emit unknown backup_recoverability
emit unknown application_readiness
exit "$status"
