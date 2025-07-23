#!/command/with-contenv bash
set -e
set -o pipefail

WEBUI_PORT=${WEBUI_PORT:-8080}
FWMARK=51820

cp -L "/etc/wireguard/original.conf" "/etc/wireguard/wg0.conf"
sed -i "/\[Interface\]/a FwMark = ${FWMARK}" "/etc/wireguard/wg0.conf"

iptables -F
ip6tables -F
iptables -X
ip6tables -X

wg-quick up wg0

# Set default policy to DROP
iptables -P INPUT DROP
ip6tables -P INPUT DROP
iptables -P FORWARD DROP
ip6tables -P FORWARD DROP
iptables -P OUTPUT DROP
ip6tables -P OUTPUT DROP

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow outbound traffic for Wireguard's own marked packets
iptables -A OUTPUT -m mark --mark ${FWMARK} -j ACCEPT
ip6tables -A OUTPUT -m mark --mark ${FWMARK} -j ACCEPT

# Allow traffic for established connections
# This allows return traffic for connections initiated by the container and the WebUI
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Allow essential ICMPv6 traffic for network discovery
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type echo-reply -j ACCEPT
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type neighbor-solicitation -j ACCEPT
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type neighbor-advertisement -j ACCEPT
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type router-solicitation -j ACCEPT
ip6tables -A INPUT  -p ipv6-icmp --icmpv6-type router-advertisement -j ACCEPT
ip6tables -A OUTPUT -p ipv6-icmp -j ACCEPT # Allow all outbound ICMPv6 for simplicity

# Allow inbound access to the WebUI
iptables -A INPUT -i eth0 -p tcp --dport ${WEBUI_PORT} -j ACCEPT
ip6tables -A INPUT -i eth0 -p tcp --dport ${WEBUI_PORT} -j ACCEPT

# Allow inbound connections on Wireguard through the torrenting port
if [[ -n "${TORRENTING_PORT}" ]]; then
	iptables -A INPUT -i wg0 -p tcp --dport ${TORRENTING_PORT} -j ACCEPT
	ip6tables -A INPUT -i wg0 -p tcp --dport ${TORRENTING_PORT} -j ACCEPT
	iptables -A INPUT -i wg0 -p udp --dport ${TORRENTING_PORT} -j ACCEPT
	ip6tables -A INPUT -i wg0 -p udp --dport ${TORRENTING_PORT} -j ACCEPT
fi

# Allow outbound connections ONLY through Wireguard
iptables -A OUTPUT -o wg0 -j ACCEPT
ip6tables -A OUTPUT -o wg0 -j ACCEPT
