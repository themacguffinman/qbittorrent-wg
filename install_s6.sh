#!/usr/bin/env bash
set -e
set -o pipefail

tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

declare -A arch=(
	["amd64"]="x86_64"
	["arm64"]="aarch64"
	["arm/v7"]="arm"
	["arm/v6"]="armhf"
)
tar -C / -Jxpf "/tmp/s6-overlay-${arch[${TARGETPLATFORM#linux/}]}.tar.xz"
