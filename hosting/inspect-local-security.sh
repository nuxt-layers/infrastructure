#!/bin/bash
# Read-only; no service activation or configuration changes.
set -euo pipefail
export LC_ALL=C
[[ $EUID = 0 ]] || { echo 'Root required' >&2; exit 2; }
echo '=== Host and interfaces ==='
uname -sr
ip -br link
ip -br address
ip -4 route show default
ip -6 route show default
echo '=== Service state ==='
for service in ssh.service ssh.socket docker.service docker.socket nuxt-ingress.service; do
 printf '%s: ' "$service"
 systemctl is-active "$service" || true
done
echo '=== Listening sockets ==='
ss -lntup
echo '=== SSH effective defaults (not Match contexts) ==='
sshd -T | grep -E '^(port|listenaddress|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|allowtcpforwarding|gatewayports|x11forwarding|permituserenvironment|allowagentforwarding) '
echo '=== Firewall policies ==='
nft list ruleset
echo '=== Docker (only if service already active) ==='
if systemctl is-active --quiet docker.service; then
 docker version --format '{{.Server.Version}}'
 docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}'
 docker network ls --format '{{.Name}}|{{.Driver}}'
 # Print only selected metadata, never environment, labels, SSH keys or full inspect.
 while IFS= read -r id; do
  [[ -n "$id" ]] || continue
  docker inspect --format '{{.Name}} {{json .HostConfig.PortBindings}} restart={{.HostConfig.RestartPolicy.Name}} privileged={{.HostConfig.Privileged}}' "$id"
 done < <(docker ps -aq)
else
 echo 'Docker inactive; not started by inventory.'
fi
echo 'UNKNOWN: router, off-host reachability, Windows policy, SSH Match contexts, upgrade persistence.'
