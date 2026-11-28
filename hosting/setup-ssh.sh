#!/bin/bash
# Console-only setup on a dedicated infrastructure host. Does not generate or expose keys.
set -euo pipefail
umask 077
mode=${1:---check}
[[ $EUID = 0 ]] || { echo 'Root required' >&2; exit 2; }
[[ $mode = --check || $mode = --apply ]] || exit 2
command -v sshd >/dev/null
target=/etc/ssh/sshd_config.d/00-nuxt-infrastructure.conf
[[ -f /etc/ssh/sshd_config && -d /etc/ssh/sshd_config.d ]] || exit 2
# Coolify's local management may require root public-key access.
# Network isolation and key ownership must be verified independently.
candidate=$(mktemp)
trap 'rm -f "$candidate"' EXIT
cat > "$candidate" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
PermitUserEnvironment no
PermitEmptyPasswords no
EOF
validate() {
 local config=$1 output expected
 sshd -t -f "$config"
 output=$(sshd -T -f "$config")
 for expected in 'passwordauthentication no' 'kbdinteractiveauthentication no' 'pubkeyauthentication yes' 'x11forwarding no' 'allowagentforwarding no' 'allowtcpforwarding no' 'gatewayports no' 'permittunnel no' 'permituserenvironment no' 'permitemptypasswords no'; do
  grep -Fxq "$expected" <<< "$output" || { echo "Effective SSH mismatch: $expected" >&2; return 1; }
 done
 grep -Eq '^permitrootlogin (without-password|prohibit-password)$' <<< "$output"
}
# Check candidate in isolation first, not a claim about the live daemon.
validate "$candidate"
if [[ $mode = --check ]]; then
 echo 'PASS: candidate SSH policy; live precedence, Match contexts and key connectivity remain unverified.'
 exit 0
fi
[[ -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] || { echo 'Use local console, not SSH.' >&2; exit 3; }
systemctl is-active --quiet nuxt-ingress.service && nft list table inet nuxt_ingress >/dev/null || { echo 'Live ingress guard required.' >&2; exit 3; }
[[ -s /root/.ssh/authorized_keys ]] || { echo 'Reviewed Coolify management key required before applying.' >&2; exit 3; }
# Never change an existing administrator-owned file.
if [[ -e $target ]] && ! cmp -s "$candidate" "$target"; then echo 'Existing SSH policy differs; manual reconciliation required.' >&2; exit 3; fi
created=0
if [[ ! -e $target ]]; then install -m 0600 "$candidate" "$target"; created=1; fi
if ! validate /etc/ssh/sshd_config; then
 if (( created )); then rm -f "$target"; fi
 echo 'Live configuration validation failed; daemon not reloaded.' >&2
 exit 3
fi
# Match blocks can override effective defaults. Refuse until separately reviewed.
if grep -Ei '^[[:space:]]*Match[[:space:]]' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf >/dev/null; then
 if (( created )); then rm -f "$target"; fi
 echo 'SSH Match contexts require explicit review.' >&2
 exit 3
fi
if systemctl is-active --quiet ssh.service; then
 if ! systemctl reload ssh.service; then
  if (( created )); then rm -f "$target"; fi
  echo 'SSH reload failed; inspect from console.' >&2; exit 3
 fi
fi
echo 'PASS: effective default SSH policy; actual key login and Coolify compatibility require acceptance.'
