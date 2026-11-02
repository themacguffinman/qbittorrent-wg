#!/usr/bin/env bash
# Updates versions.env to the newest versions that were already published 7 days ago, without ever downgrading.
# QBITTORRENT_VERSION is only changed by humans.
set -euo pipefail
shopt -s inherit_errexit
. ./versions.env

CUTOFF=$(date -u -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ)
SNAPSHOT=$(date -u -d "7 days ago" +%Y%m%dT%H%M%SZ)
GITHUB_API=https://api.github.com/repos
blocked=false

fetch() { curl -fsSL --retry 5 --retry-all-errors --max-time 180 "$@"; }
github_api() { fetch ${GH_TOKEN:+-H "Authorization: Bearer $GH_TOKEN"} "$@"; }
set_version() {
	echo "$1: $2 -> $3"
	sed -i "s|^$1=.*|$1=$3|" versions.env
}

### s6-overlay
held_s6=$(github_api "$GITHUB_API/just-containers/s6-overlay/releases?per_page=100" \
	| jq -r --arg cutoff "$CUTOFF" '.[] | select((.draft or .prerelease | not) and .published_at <= $cutoff) | .tag_name | ltrimstr("v")' \
	| sort -V | tail -1)
if [[ -z "$held_s6" ]]; then
	echo "No s6-overlay release found as of $CUTOFF" >&2
	exit 1
fi
if dpkg --compare-versions "$held_s6" gt "$S6_OVERLAY_VERSION"; then
	set_version S6_OVERLAY_VERSION "$S6_OVERLAY_VERSION" "$held_s6"
fi

### Debian base image
image=${DEBIAN_IMAGE%%@*}
image_name=${image%%:*}
image_tag=${image#*:}
current_digest=${DEBIAN_IMAGE#*@}

# The registry only knows a tag's current digest, docker-library/repo-info keeps the history of it in git
repo_info_sha=$(github_api "$GITHUB_API/docker-library/repo-info/commits?path=repos/$image_name/remote/$image_tag.md&until=$CUTOFF&per_page=1" | jq -r '.[0].sha')
repo_info=$(fetch "https://raw.githubusercontent.com/docker-library/repo-info/$repo_info_sha/repos/$image_name/remote/$image_tag.md")
held_digest=$(sed -n "s/.*$image_name@\(sha256:[0-9a-f]\{64\}\).*/\1/p" <<<"$repo_info")
held_digest=${held_digest%%$'\n'*}
if [[ -z "$held_digest" ]]; then
	echo "No digest found for $image as of $CUTOFF" >&2
	exit 1
fi

registry_token=$(fetch "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/$image_name:pull" | jq -r .token)
registry() {
	fetch -H "Authorization: Bearer $registry_token" \
		-H "Accept: application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json" \
		"https://registry-1.docker.io/v2/library/$image_name/$1"
}
image_created() {
	local manifest config created
	manifest=$(registry "manifests/$1" | jq -r '[.manifests[] | select(.platform.architecture == "amd64")][0].digest')
	config=$(registry "manifests/$manifest" | jq -r .config.digest)
	created=$(registry "blobs/$config" | jq -r .created)
	date -u -d "$created" +%s
}
if [[ "$held_digest" != "$current_digest" ]]; then
	held_created=$(image_created "$held_digest")
	current_created=$(image_created "$current_digest")
	if (( held_created > current_created )); then
		set_version DEBIAN_IMAGE "$DEBIAN_IMAGE" "$image@$held_digest"
	fi
fi

### qBittorrent Debian revision
suite=$(sed -n 's/^Suites: //p' Dockerfile)
revisions() {
	fetch "$1/dists/$suite/main/binary-$2/Packages.xz" | xz -dc | awk -v prefix="$QBITTORRENT_VERSION-" '
		$1 == "Package:" { package = $2 }
		$1 == "Version:" && package == "qbittorrent-nox" && index($2, prefix) == 1 { print substr($2, length(prefix) + 1) }
	'
}

# The archive drops old revisions, so a held revision is only usable if it can still be installed today on all platforms
available=$(for arch in amd64 arm64 armhf armel; do
	revisions https://deb.debian.org/debian "$arch" | sort -u
done | sort | uniq -c | awk '$1 == 4 { print $2 }')

held_revisions=$(revisions "https://snapshot.debian.org/archive/debian/$SNAPSHOT" amd64)
revision=$QBITTORRENT_DEB_REVISION
for held_revision in $held_revisions; do
	if grep -Fxq -- "$held_revision" <<<"$available" && dpkg --compare-versions "$held_revision" gt "$revision"; then
		revision=$held_revision
	fi
done
if [[ "$revision" != "$QBITTORRENT_DEB_REVISION" ]]; then
	set_version QBITTORRENT_DEB_REVISION "$QBITTORRENT_DEB_REVISION" "$revision"
fi

if ! grep -Fxq -- "$revision" <<<"$available"; then
	echo "::warning::qbittorrent-nox $QBITTORRENT_VERSION-$revision is not available in $suite on all platforms, so the image can't be built"
	blocked=true
fi
echo "blocked=$blocked" >> "${GITHUB_OUTPUT:-/dev/null}"
