# qbittorrent-wg ![Docker Image Size (tag)](https://img.shields.io/docker/image-size/themacguffinman/qbittorrent-wg/latest?label=Docker%20Hub&link=https%3A%2F%2Fhub.docker.com%2Fr%2Fthemacguffinman%2Fqbittorrent-wg)

Run headless qBittorrent wrapped by WireGuard all inside a Docker container.

Build the Dockerfile
```bash
cd /path/to/repo
docker build --platform=linux/amd64 -t themacguffinman/qbittorrent-wg:latest .
```

## Usage

Example run command
```bash
docker run \
	--platform linux/amd64 \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_NICE \
	--sysctl net.ipv4.conf.all.src_valid_mark=1 \
	-p 8080:8080 \
	-e WEBUI_PORT=8080 \
	-e TZ=America/New_York \
	-e PUID="$(id -u $USER)" \
	-e PGID="$(id -g $USER)" \
	-e WG_INTERFACE="my_wg" \
	-e TORRENTING_PORT=9999 \
	-e NICE=9 \
	-e IONICE_CLASS=idle \
	-v ~/qbt:/config \
	-v ~/wg_confs:/wg_confs \
	-v ~/downloads:/downloads \
	-v ~/temp_downloads:/temp_downloads \
	-v ~/torrent_export:/torrent_export \
	themacguffinman/qbittorrent-wg:latest
```

The only required parameters are the `--cap-add=...`, `--sysctl ...`, and `-e WG_INTERFACE=...`. The rest are optional.

### Parameters

| Parameter          | Description                                                                                                                                                                                                                                                                   |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `$WEBUI_PORT`      | Change the port that the qBittorrent WebUI listens on inside the container. Make sure this is the same as the Docker host port (ie. `docker run -p <host-port>:<webui-port>`) since the WebUI will reject requests with a different port in the HTTP host name. Default: 8080 |
| `$TZ`              | Change the container timezone. Must be a canonical timezone, pick a TZ identifier from this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)                                                                                                              |
| `$PUID`            | Run qBittorrent with this user ID to support the right file permissions on mounted volumes                                                                                                                                                                                    |
| `$PGID`            | Run qBittorrent with this group ID to support the right file permissions on mounted volumes                                                                                                                                                                                   |
| `$WG_INTERFACE`    | Name of the Wireguard conf file mounted to `/wg_confs/${WG_INTERFACE}.conf` (omit the `.conf` file extension from the parameter)                                                                                                                                              |
| `$TORRENTING_PORT` | Select a open port for seeding as an active node. This requires port forwarding from your Wireguard server.                                                                                                                                                                   |
| `$NICE`            | Set the CPU scheduling priority of qBittorrent with `nice -n $NICE`. Default is `10`, set to `skip` if you don't want to set a niceness. Unless you use `skip`, you must run the container with `--cap-add=SYS_NICE`.                                                         |
| `$IONICE_CLASS`    | Set the I/O scheduling priority of qBittorrent with `ionice -c $IONICE_CLASS`. Default is `idle`, set to `skip` if you don't want to set a niceness. Unless you use `skip`, you must run the container with `--cap-add=SYS_NICE`.                                             |

### Volumes

| Container path  | Description                                                     |
|-----------------|-----------------------------------------------------------------|
| `/config`         | Contains qBittorrent configuration files                        |
| `/wg_confs`       | Contains Wireguard conf files that can be used in $WG_INTERFACE |
| `/downloads`      | Default qBittorrent download location.                          |
| `/temp_downloads` | Default qBittorrent incomplete download location.               |
| `/torrent_export` | Default qBittorrent location to copy .torrent files to.         |

## How the networking works
This container is designed to be run in the default bridge network mode.

Internally, it uses `wg-quick up` to apply your Wireguard conf.

### Firewall 
To ensure qBittorrent doesn't leak traffic outside the Wireguard connection, `iptables` is used to block all outbound non-Wireguard traffic, with the exception of traffic initiated from inbound connections so WebUI can work.

There's also a block on all inbound Wireguard traffic to your `$WEBUI_PORT` to prevent others in the Wireguard network from accessing your qBittorrent WebUI.

The `iptables` rules are defined in [s6-rc.d/init-wireguard/run_up.sh](s6-rc.d/init-wireguard/run_up.sh)
