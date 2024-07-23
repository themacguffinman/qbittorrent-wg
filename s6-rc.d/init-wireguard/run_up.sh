#!/command/with-contenv bash
set -e
set -o pipefail
wg-quick up wg0

WEBUI_PORT=${WEBUI_PORT:-8080}

# Block all outbound traffic outside Wireguard, except if it was initiated by an inbound connection (exception is for qBittorrent WebUI)
iptables -A OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT ! -o wg0 -j REJECT
ip6tables -A OUTPUT ! -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT ! -o wg0 -j REJECT

# Block all inbound traffic from Wireguard targeting the WebUI port, don't want Wireguard peers accessing the WebUI
iptables -A INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP
iptables -A INPUT -i wg0 -p udp -m multiport --dports "${WEBUI_PORT}" -j DROP
ip6tables -A INPUT -i wg0 -p tcp -m multiport --dports "${WEBUI_PORT}" -j DROP
ip6tables -A INPUT -i wg0 -p udp -m multiport --dports "${WEBUI_PORT}" -j DROP

# TODO: Block all inbound traffic from Wireguard, except if it was initiated by an outbound connection or targets the $TORRENTING_PORT
#iptables -A INPUT -i wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
#ip6tables -A INPUT -i wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
#if [[ -n "${TORRENTING_PORT}" ]]; then
#    iptables -A INPUT -i wg0 -p tcp -m multiport --dports "${TORRENTING_PORT}" -j ACCEPT
#    iptables -A INPUT -i wg0 -p udp -m multiport --dports "${TORRENTING_PORT}" -j ACCEPT
#    ip6tables -A INPUT -i wg0 -p tcp -m multiport --dports "${TORRENTING_PORT}" -j ACCEPT
#    ip6tables -A INPUT -i wg0 -p udp -m multiport --dports "${TORRENTING_PORT}" -j ACCEPT
#fi
#iptables -A INPUT -i wg0 -j REJECT
#ip6tables -A INPUT -i wg0 -j REJECT
