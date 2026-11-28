#!/bin/bash
# Dedicated infrastructure host only. Does not install Docker or open provider firewall.
set -euo pipefail
umask 077
profile=${1:-}
mode=${2:---check}
iface=${3:-}
[[ $EUID = 0 ]] || { echo 'Root required' >&2; exit 2; }
[[ $profile = local || $profile = production ]] || { echo 'Specify local or production' >&2; exit 2; }
[[ $mode = --check || $mode = --apply ]] || exit 2
[[ $iface =~ ^[a-zA-Z0-9_.-]+$ && $iface != lo ]] && ip link show dev "$iface" >/dev/null || { echo 'Explicit external interface required' >&2; exit 2; }
command -v nft >/dev/null
command -v systemctl >/dev/null
# Require console access for application; production SSH ingress intentionally denied here.
# Existing established connections are permitted; management must use a separately reviewed private interface.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
{
 if nft list table inet nuxt_ingress >/dev/null 2>&1; then echo 'delete table inet nuxt_ingress'; fi
 cat <<EOF
table inet nuxt_ingress {
 chain input {
  type filter hook input priority -10; policy accept;
  iifname "$iface" ct state established,related accept
  iifname "$iface" meta l4proto ipv6-icmp accept
  iifname "$iface" ip protocol icmp accept
EOF
 if [[ $profile = production ]]; then echo "  iifname \"$iface\" tcp dport { 80, 443 } accept"; fi
 cat <<EOF
  iifname "$iface" drop
 }
 chain forward {
  type filter hook forward priority -10; policy accept;
  iifname "$iface" ct state established,related accept
EOF
 if [[ $profile = production ]]; then echo "  iifname \"$iface\" ct status dnat meta l4proto tcp ct original proto-dst { 80, 443 } accept"; fi
 cat <<EOF
  iifname "$iface" drop
 }
}
EOF
} > "$tmp"
nft -c -f "$tmp"
if [[ $mode = --check ]]; then
 echo 'PASS: candidate syntax only; no live isolation asserted.'
 exit 0
fi
# Do not silently replace an existing independently administered nftables configuration.
[[ -d /etc/systemd/system ]] || exit 2
install -d -m 0700 /etc/nuxt-infrastructure
# Persistent rules use a dedicated table and atomically replace only that table.
sed '/^delete table inet nuxt_ingress$/d' "$tmp" > /etc/nuxt-infrastructure/ingress.nft
cat > /etc/nuxt-infrastructure/load-ingress.sh <<'EOF'
#!/bin/bash
set -euo pipefail
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if nft list table inet nuxt_ingress >/dev/null 2>&1; then echo 'delete table inet nuxt_ingress' > "$tmp"; fi
cat /etc/nuxt-infrastructure/ingress.nft >> "$tmp"
nft -f "$tmp"
EOF
chmod 0700 /etc/nuxt-infrastructure/load-ingress.sh
cat > /etc/systemd/system/nuxt-ingress.service <<'EOF'
[Unit]
Description=Nuxt infrastructure external ingress guard
After=nftables.service
Before=docker.service ssh.service
[Service]
Type=oneshot
ExecStart=/etc/nuxt-infrastructure/load-ingress.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
for svc in docker ssh; do
 install -d "/etc/systemd/system/$svc.service.d"
 printf '[Unit]\nRequires=nuxt-ingress.service\nAfter=nuxt-ingress.service\n' > "/etc/systemd/system/$svc.service.d/nuxt-ingress.conf"
done
systemctl daemon-reload
systemctl enable nuxt-ingress.service
systemctl restart nuxt-ingress.service
nft list table inet nuxt_ingress
echo 'Guard applied to specified interface only. Verify all other interfaces, DHCP, loopback, container SSH, published ports, restart and external reachability independently.'
