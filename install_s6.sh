#!/usr/bin/env bash
# Downloads s6-overlay S6_OVERLAY_VERSION for TARGETPLATFORM, verifies it and unpacks it into $1
set -euo pipefail

dest=${1:?usage: install_s6.sh <dest>}
declare -A arch=(
	["amd64"]="x86_64"
	["arm64"]="aarch64"
	["arm/v7"]="arm"
	["arm/v6"]="armhf"
)

mkdir -p "$dest"
cd "$(mktemp -d)"
for name in noarch "${arch[${TARGETPLATFORM#linux/}]}"; do
	file=s6-overlay-$name.tar.xz
	url=https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/$file
	curl -fsSL --retry 5 --retry-all-errors -o "$file" "$url" -o "$file.sha256" "$url.sha256"
	sha256sum -c "$file.sha256"
	tar -C "$dest" -Jxpf "$file"
done
