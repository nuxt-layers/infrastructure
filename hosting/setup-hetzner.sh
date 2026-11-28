#!/bin/bash
# No provider API calls, package installation or firewall modification.
set -euo pipefail
[[ ${1:---check} = --check ]] || { echo 'Production activation not authorised'; exit 3; }
[[ $EUID = 0 ]] || { echo 'Root required'; exit 2; }
here=$(cd -- "$(dirname -- "$0")" && pwd)
iface=${2:-}
bash "$here/setup-network-guard.sh" production --check "$iface"
echo 'BLOCKED: owner approval, provider firewall, management path, reviewed versions, backups and production acceptance required.'
exit 3
