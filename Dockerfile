FROM debian:testing-slim@sha256:7aa6005592145de753828ada9a9da8b28d1037b389e5773ffc25fab73a9c8389
LABEL authors="josh"

USER root
ENV HOME /config
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /config

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        tzdata=2024a-4 \
        bash=5.2.21-2.1 \
        coreutils=9.4-3.1 \
        qbittorrent-nox=4.6.5-1+b1 \
        wireguard=1.0.20210914-1.1 \
        passwd=1:4.15.3-2 \
        iproute2=6.9.0-1 \
        openresolv=3.13.2-1 \
        util-linux=2.40.2-1 \
        sed=4.9-2 \
        iptables=1.8.10-4 \
        xz-utils=5.6.2-2 \
        # Debugging tools
        findutils=4.10.0-2 \
        iputils-ping=3:20240117-1 \
        iputils-tracepath=3:20240117-1 \
        curl=8.8.0-4 \
        dnsutils=1:9.19.24-185-g392e7199df2-1 \
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

ARG S6_OVERLAY_VERSION=3.2.0.0
ADD "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
    /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

COPY fake_sysctl.sh /usr/sbin/sysctl

COPY ./default_qbittorrent.conf /default/qBittorrent.conf

COPY ./s6-rc.d /etc/s6-overlay/s6-rc.d/

ENTRYPOINT ["/init"]