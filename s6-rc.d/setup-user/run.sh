#!/command/with-contenv bash
set -e
set -o pipefail
if [[ -n "${TZ}" ]]; then
	ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
	dpkg-reconfigure --frontend=noninteractive tzdata
fi

if [[ -n "${PUID}" || -n "${PGID}" ]]; then
	if [[ -n "${PUID}" ]]; then
		echo "Changing qbt UID to ${PUID}"
		usermod -o -u $PUID qbt
	fi
	if [[ -n "${PGID}" ]]; then
		echo "Changing qbt GID to ${PGID}"
		groupmod -o -g $PGID qbt
	fi

	chown -R qbt:qbt /default
	chown qbt:qbt "${HOME}"
	chown qbt:qbt "/downloads"
	chown qbt:qbt "/temp_downloads"
	chown qbt:qbt "/torrent_export"
fi

QBT_CONFIG="${HOME}/qBittorrent/qBittorrent.conf"
if [ ! -f "${QBT_CONFIG}" ]; then
	echo "No qBittorrent.conf detected, copying default qBittorrent.conf to ${QBT_CONFIG}"
	mkdir -p "${HOME}/qBittorrent"
	chown qbt:qbt "${HOME}/qBittorrent"
	cp /default/qBittorrent.conf "${QBT_CONFIG}"
fi

ln -s "/wg_confs/${WG_INTERFACE}.conf" "/etc/wireguard/wg0.conf"
