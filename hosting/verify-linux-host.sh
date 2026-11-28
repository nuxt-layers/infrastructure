#!/bin/bash
# Read-only evidence collection. Does not install, start or reconfigure services.
set -uo pipefail
export LC_ALL=C
if [[ $(id -u) != 0 || $(uname -s) != Linux ]]; then
    echo 'Run as an authorised operator on the dedicated Linux VM.' >&2
    exit 3
fi
failed=0
unknown=0
report() {
    printf '%s %s\n' "$1" "$2"
    case "$1" in FAIL) failed=1;; UNKNOWN) unknown=1;; esac
}
printf 'observed_at=%s\n' "$(date -u +%FT%TZ)"
printf 'revision=%s\n' "$(git -C "$(dirname "$0")" rev-parse HEAD 2>/dev/null || echo unknown)"
if systemd-detect-virt --vm >/dev/null 2>&1; then report PASS vm_detected; else report UNKNOWN vm_identity; fi
if [[ $(timedatectl show -p Timezone --value 2>/dev/null) = UTC || $(timedatectl show -p Timezone --value 2>/dev/null) = Etc/UTC ]]; then report PASS utc_timezone; else report FAIL utc_timezone; fi
if timeout 10 docker info --format '{{.ServerVersion}}' 2>/dev/null; then report PASS docker_api; else report FAIL docker_api; fi
if docker compose version; then report PASS compose_cli; else report FAIL compose_cli; fi
if command -v sshd >/dev/null && cfg=$(sshd -T 2>/dev/null); then
    if grep -qx 'passwordauthentication no' <<< "$cfg" && grep -qx 'kbdinteractiveauthentication no' <<< "$cfg"; then report PASS ssh_default_password_disabled; else report FAIL ssh_default_password_disabled; fi
    if grep -qx 'permitrootlogin no' <<< "$cfg"; then report PASS ssh_default_root_login_disabled; else report FAIL ssh_default_root_login_disabled; fi
else report UNKNOWN ssh_effective_defaults; fi
# SSH Match contexts and actual remote denial need a separate external probe.
if [[ $(sysctl -n net.ipv4.ip_forward 2>/dev/null) = 1 ]]; then report PASS ipv4_forwarding_enabled; else report UNKNOWN ipv4_forwarding; fi
if command -v chronyc >/dev/null && tracking=$(timeout 5 chronyc -n tracking 2>/dev/null); then
    printf '%s\n' "$tracking" | awk -F: '/^(Stratum|Reference time|System time|Last offset|Root dispersion|Leap status)/ {print}'
    if grep -Eq '^Leap status[[:space:]]*:[[:space:]]*Normal$' <<< "$tracking"; then report PASS clock_sync_indicator; else report FAIL clock_sync_indicator; fi
    # chrony authdata output: require selected network source with NTS, keys and cookies.
    sources=$(timeout 5 chronyc -n sources 2>/dev/null || true)
    selected=$(awk '$1=="^*" {print $2}' <<< "$sources")
    auth=$(timeout 5 chronyc -n authdata 2>/dev/null || true)
    if [[ -n "$selected" ]] && awk -v src="$selected" '$1==src && $2=="NTS" && $4+0>0 && $9+0>0 {found=1} END{exit !found}' <<< "$auth"; then report PASS selected_source_nts_indicator; else report UNKNOWN selected_source_nts_indicator; fi
else report UNKNOWN chrony_tracking; fi
# No inspection of container environment or command lines (may contain secrets).
if rows=$(timeout 10 docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}' 2>/dev/null); then
    if grep -Eq '^coolify\|[^|]+\|Up ' <<< "$rows"; then report PASS coolify_container_running; else report UNKNOWN coolify_container_running; fi
    if grep -Eq '^coolify-proxy\|[^|]+\|Up ' <<< "$rows"; then report PASS coolify_proxy_running; else report UNKNOWN coolify_proxy_running; fi
else report UNKNOWN coolify_runtime; fi
bash "$(dirname "$0")/host-alerts.sh"
case $? in 0) report PASS resource_observation;; 2) report FAIL resource_observation;; *) report UNKNOWN resource_observation;; esac
report UNKNOWN external_firewall_and_ssh_match_probe
report UNKNOWN coolify_deployment_and_operator_iam
report UNKNOWN independent_backup_custody
if (( failed )); then exit 2; fi
if (( unknown )); then exit 3; fi
