#!/usr/bin/env bash
set -euo pipefail
UPLINK="wlp128s20f3"
BRIDGE="cloudbr0"
SUBNET="172.16.10.0/24"
iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE
while iptables -D FORWARD -i "$BRIDGE" -o "$UPLINK" -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; do :; done
iptables -I FORWARD 1 -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 1 -i "$BRIDGE" -o "$UPLINK" -j ACCEPT
