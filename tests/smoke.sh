#!/usr/bin/env bash
set -euo pipefail
. ./versions.env
IMG=${1:?usage: smoke.sh <image>}
WEBUI_PORT=${WEBUI_PORT:-8080}
WG_CONFS=$(mktemp -d)
trap 'docker logs qbt-test 2>&1 | tail -30 || true; docker rm -f qbt-test >/dev/null 2>&1 || true' EXIT

# wg-quick never contacts the peer, so a fake conf with throwaway keys lets the container start up normally
priv=$(docker run --rm --entrypoint wg "$IMG" genkey)
peer=$(docker run --rm --entrypoint wg "$IMG" genkey | docker run --rm -i --entrypoint wg "$IMG" pubkey)
printf '[Interface]\nPrivateKey = %s\nAddress = 10.200.200.2/32\n\n[Peer]\nPublicKey = %s\nAllowedIPs = 0.0.0.0/0, ::/0\nEndpoint = 192.0.2.1:51820\n' "$priv" "$peer" > "$WG_CONFS/test.conf"

docker run -d --name qbt-test \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_NICE \
	--sysctl net.ipv4.conf.all.src_valid_mark=1 \
	-p "$WEBUI_PORT:$WEBUI_PORT" \
	-e WEBUI_PORT="$WEBUI_PORT" \
	-e WG_INTERFACE=test \
	-v "$WG_CONFS:/wg_confs:ro" \
	"$IMG"
for _ in {1..30}; do
	docker exec qbt-test curl -fs -o /dev/null http://127.0.0.1:$WEBUI_PORT/ && break
	sleep 1
done

# Installed version and non-root user
docker exec qbt-test qbittorrent-nox --version | grep -qF "v$QBITTORRENT_VERSION"
docker exec qbt-test sh -c 'grep -q "^Uid:.100" /proc/$(pidof qbittorrent-nox)/status'

# From outside the container, log in, check the running version, add a torrent and confirm it's listed
pass=$(docker logs qbt-test 2>&1 | sed -n 's/.*temporary password is provided for this session: //p' | tail -1)
COOKIES=$(mktemp)
api() { curl -fs --max-time 5 -b "$COOKIES" -c "$COOKIES" "$@"; }
api --data-urlencode username=admin --data-urlencode "password=$pass" http://127.0.0.1:$WEBUI_PORT/api/v2/auth/login | grep -qx 'Ok.'
version=$(api http://127.0.0.1:$WEBUI_PORT/api/v2/app/version)
echo "API reports qBittorrent $version"
[ "$version" = "v$QBITTORRENT_VERSION" ]
hash=0123456789abcdef0123456789abcdef01234567
api --data-urlencode "urls=magnet:?xt=urn:btih:$hash&dn=test" http://127.0.0.1:$WEBUI_PORT/api/v2/torrents/add | grep -qx 'Ok.'
sleep 2
api http://127.0.0.1:$WEBUI_PORT/api/v2/torrents/info | grep -q "$hash"

echo "Smoke test passed"
