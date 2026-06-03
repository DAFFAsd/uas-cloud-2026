#!/usr/bin/env bash
set -euo pipefail

UPLINK="wlo1"
BRIDGE="cloudbr0"
SUBNET="172.16.20.0/24"
GATEWAY="172.16.20.1/24"
MGMT_IP="192.168.1.3"
MGMT_TO_GUEST="192.168.1.3"

ip addr show dev "$BRIDGE" | grep -q "172.16.20.1/24" || ip addr add "$GATEWAY" dev "$BRIDGE"
sysctl -w net.ipv4.ip_forward=1 >/dev/null

iptables -t nat -C POSTROUTING -s "$SUBNET" -d "$MGMT_IP" -j RETURN 2>/dev/null || \
  iptables -t nat -I POSTROUTING 1 -s "$SUBNET" -d "$MGMT_IP" -j RETURN
iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE

while iptables -D FORWARD -i "$BRIDGE" -o "$UPLINK" -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i "$UPLINK" -o "$BRIDGE" -s "$MGMT_TO_GUEST" -d "$SUBNET" -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; do :; done

iptables -I FORWARD 1 -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 1 -i "$UPLINK" -o "$BRIDGE" -s "$MGMT_TO_GUEST" -d "$SUBNET" -j ACCEPT
iptables -I FORWARD 1 -i "$BRIDGE" -o "$UPLINK" -j ACCEPT
