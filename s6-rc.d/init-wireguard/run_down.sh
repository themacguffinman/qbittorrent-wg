#!/command/with-contenv bash
set -e
set -o pipefail

WEBUI_PORT=${WEBUI_PORT:-8080}

iptables -D OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -D OUTPUT ! -o wg0 -j REJECT
iptables -D INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP
iptables -D INPUT -i wg0 -p udp -m multiport --dports "${WEBUI_PORT}" -j DROP

ip6tables -D OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -D OUTPUT ! -o wg0 -j REJECT
ip6tables -D INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP
ip6tables -D INPUT -i wg0 -p udp -m multiport --dports "${WEBUI_PORT}" -j DROP

wg-quick down wg0
