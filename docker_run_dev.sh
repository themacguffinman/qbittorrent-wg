#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_ARGS=()
if [[ -f "$SCRIPT_DIR/dev.env" ]]; then
	ENV_FILE_ARGS=(--env-file "$SCRIPT_DIR/dev.env")
fi

docker build --platform=linux/arm64 -t themacguffinman/qbittorrent-wg:latest .
docker run \
	-it \
	--rm \
	--platform linux/arm64 \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_NICE \
	--sysctl net.ipv4.conf.all.src_valid_mark=1 \
	-p 8080:8080 \
	"${ENV_FILE_ARGS[@]}" \
	-e PUID="$(id -u $USER)" \
	-e PGID="$(id -g $USER)" \
	-e TORRENTING_PORT=7877 \
	-v ~/Documents/qbt:/config \
	-v ~/Documents/wg_confs:/wg_confs \
	themacguffinman/qbittorrent-wg:latest \
	/bin/bash
