FROM debian:trixie-slim@sha256:109e2c65005bf160609e4ba6acf7783752f8502ad218e298253428690b9eaa4b
LABEL authors="josh"

USER root
ENV HOME=/config
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/config

ARG TARGETPLATFORM
ARG DEBIAN_FRONTEND=noninteractive

# trixie-backports provides newer qbittorrent-nox than stable
COPY <<"EOT" /etc/apt/sources.list.d/backports.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOT

RUN apt-get update -y \
	&& apt-get install -y \
	qbittorrent-nox=5.1.4-1~bpo13+1 \
	wireguard \
	iproute2 \
	openresolv \
	iptables \
	xz-utils \
	# Debugging tools
	traceroute \
	iputils-ping \
	iputils-tracepath \
	curl \
	dnsutils \
	&& apt-get clean -y \
	&& groupadd -o -g 100 qbt \
	&& useradd -M -o -s /bin/bash -u 100 -g 100 qbt \
	&& mkdir -p \
	/config/qBittorrent \
	/wg_confs \
	/downloads \
	/temp_downloads \
	/torrent_export \
	&& chown qbt:qbt \
	/config \
	/config/qBittorrent \
	/downloads \
	/temp_downloads \
	/torrent_export \
	&& chmod 0755 \
	/config \
	/config/qBittorrent \
	/wg_confs \
	/downloads \
	/temp_downloads \
	/torrent_export

ARG S6_OVERLAY_VERSION=3.2.3.0
ADD "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-arm.tar.xz" \
	"https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-armhf.tar.xz" \
	install_s6.sh \
	/tmp/
RUN /tmp/install_s6.sh && rm /tmp/*

# wg-quick runs sysctl but you can't change sysctl settings inside a container, so just fake it to let wg-quick succeed
COPY fake_sysctl.sh /usr/sbin/sysctl

COPY ./default_qbittorrent.conf /default/qBittorrent.conf

COPY ./s6-rc.d /etc/s6-overlay/s6-rc.d/

ENTRYPOINT ["/init"]
