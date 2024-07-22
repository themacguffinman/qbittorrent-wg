#!/command/with-contenv bash
set -e
set -o pipefail
wg-quick up wg0

WEBUI_PORT=${WEBUI_PORT:-8080}

iptables -A OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT ! -o wg0 -j REJECT
iptables -A INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP

ip6tables -A OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT ! -o wg0 -j REJECT
ip6tables -A INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP
