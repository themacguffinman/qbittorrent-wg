# check=skip=InvalidDefaultArgInFrom
ARG DEBIAN_IMAGE

# s6-overlay is downloaded and unpacked on the build machine's own platform, so it needs no emulation,
# and is cached by S6_OVERLAY_VERSION without being downloaded again
FROM --platform=$BUILDPLATFORM ${DEBIAN_IMAGE} AS s6
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends ca-certificates curl xz-utils
COPY install_s6.sh /tmp/
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION
RUN /tmp/install_s6.sh /s6

FROM ${DEBIAN_IMAGE}
LABEL authors="josh"

USER root
ENV HOME=/config
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/config

ARG DEBIAN_FRONTEND=noninteractive

# Changes less often than the packages below, so it goes first to stay cached
COPY --from=s6 /s6/ /

# stable-backports provides newer qbittorrent-nox than stable
COPY <<"EOT" /etc/apt/sources.list.d/backports.sources
Types: deb
URIs: http://deb.debian.org/debian
Suites: stable-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOT

ARG QBITTORRENT_VERSION
ARG QBITTORRENT_DEB_REVISION
# Every RUN below sees this ARG, so a change to package_versions.txt reruns the upgrade instead of reusing a cached layer
ARG PACKAGE_VERSIONS_HASH
# upgrade picks up security fixes released after the base image was built
RUN apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	qbittorrent-nox=${QBITTORRENT_VERSION}-${QBITTORRENT_DEB_REVISION} \
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

# wg-quick runs sysctl but you can't change sysctl settings inside a container, so just fake it to let wg-quick succeed
COPY fake_sysctl.sh /usr/sbin/sysctl

COPY ./default_qbittorrent.conf /default/qBittorrent.conf

COPY ./s6-rc.d /etc/s6-overlay/s6-rc.d/

ENTRYPOINT ["/init"]
