#!/usr/bin/env bash
docker build --platform=linux/arm64 -t themacguffinman/qbittorrent-wg:latest .
docker run \
	-it \
	--rm \
	--platform linux/arm64 \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_NICE \
	--sysctl net.ipv4.conf.all.src_valid_mark=1 \
	-p 8080:8080 \
	-e TZ=UTC \
	-e PUID="$(id -u $USER)" \
	-e PGID="$(id -g $USER)" \
	-e WG_INTERFACE="..." \
	-e TORRENTING_PORT=7877 \
	-v ~/Documents/qbt:/config \
	-v ~/Documents/wg_confs:/wg_confs \
	themacguffinman/qbittorrent-wg:latest \
	/bin/bash
