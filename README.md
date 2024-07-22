Build the Dockerfile
```bash
cd /path/to/repo
docker build --platform=linux/amd64 -t themacguffinman/qbittorrent-wg:latest .
```

Example run command
```bash
docker run \
	--platform linux/amd64 \
	--cap-add=NET_ADMIN \
	--sysctl net.ipv4.conf.all.src_valid_mark=1 \
	-p 4722:8080 \
	-e WEBUI_PORT=8080 \
	-e TZ=America/New_York \
	-e PUID="$(id -u $USER)" \
	-e PGID="$(id -g $USER)" \
	-e WG_INTERFACE="my_wg" \
	-e TORRENTING_PORT=9999 \
	-v ~/qbt:/config \
	-v ~/wg_confs:/wg_confs \
	-v ~/downloads:/downloads \
	-v ~/temp_downloads:/temp_downloads \
	-v ~/torrent_export:/torrent_export \
	themacguffinman/qbittorrent-wg:latest
```
