#!/bin/sh

#set -x

# Natter/NATMap
private_port=$4 # Natter: $3; NATMap: $4
public_port=$2 # Natter: $5; NATMap: $2
protocol=$5 # Natter: $1; NATMap: $5

# qBittorrent.
qb_addr_url="http://localhost:8080"
#qb_ip_addr="192.168.1.2" # Only needed when qbit runs on a different host
qb_username="admin"
qb_password="adminadmin"

echo "Update qBittorrent listen port to $public_port..."

# Update qBittorrent listen port.
curl -s -o /dev/null -c - --header "Referer: http://$qb_web_host:$qb_web_port" --data "username=$qb_username&password=$qb_password" "http://$qb_web_host:$qb_web_port/api/v2/auth/login" \
| curl -s -X POST -b - -d "json={\"listen_port\":\"$public_port\"}" "http://$qb_web_host:$qb_web_port/api/v2/app/setPreferences"

echo "Update nftables..."

# Use nftables to forward traffic.
if nft list tables | grep -q "qbit_redirect"; then
    nft delete table inet qbit_redirect
fi
nft add table inet qbit_redirect
nft 'add chain inet qbit_redirect prerouting { type nat hook prerouting priority -100; }'

if [ "$protocol" = "tcp" ];then
	if [ "$qb_ip_addr" = "" ];then
		nft add rule inet qbit_redirect prerouting tcp dport $private_port redirect to :$public_port
	else
		nft add rule inet qbit_redirect prerouting tcp dport $private_port dnat ip to $qb_ip_addr:$public_port
	fi
fi

if [ "$protocol" = "udp" ];then
	if [ "$qb_ip_addr" = "" ];then
		nft add rule inet qbit_redirect prerouting udp dport $private_port redirect to :$public_port
	else
		nft add rule inet qbit_redirect prerouting udp dport $private_port dnat ip to $qb_ip_addr:$public_port
	fi
fi

echo "Done."