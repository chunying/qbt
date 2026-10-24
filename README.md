# qbt

A small Docker setup that runs [qBittorrent-nox](https://www.qbittorrent.org/) (the headless qBittorrent with a Web UI) on Alpine Linux, optionally routing its traffic through a WireGuard VPN.

## Features

- Alpine-based image with `qbittorrent-nox` and `wireguard-tools`
- Brings up a WireGuard tunnel automatically if a profile is present in `vpn/`
- Runs qBittorrent as an unprivileged `qbt` user whose UID/GID match the host user, so files in `qbt/` are owned by you
- Web UI exposed on `127.0.0.1:9080` only (not reachable from other hosts)
- Uses `tini` as PID 1 for proper signal handling

## Layout

| Path                 | Purpose                                                              |
|----------------------|----------------------------------------------------------------------|
| `Dockerfile`         | Builds the `chuang/qbt` image                                        |
| `docker-compose.yml` | Service definition (capabilities, sysctls, ports, volumes)           |
| `entrypoint.sh`      | Creates the `qbt` user, starts WireGuard, then launches qBittorrent |
| `launch.sh`          | Builds and starts the container with your current UID/GID            |
| `vpn/`               | WireGuard profiles (`*.conf`), mounted read-only at `/etc/wireguard` |
| `qbt/`               | qBittorrent profile (config, data), created on first run             |

`qbt/` and `vpn/*.conf` are git-ignored.

## Requirements

- Docker with the Compose plugin (`docker compose`)
- A Linux host kernel with WireGuard support, if you want to use the VPN

## Usage

1. (Optional) Copy a WireGuard profile into `vpn/`:

   ```sh
   cp ~/my-vpn.conf vpn/
   ```

   If there are several `.conf` files, the first one in sorted order is used. With no profile, qBittorrent runs without a VPN.

2. Build and start the container:

   ```sh
   ./launch.sh
   ```

   This runs `docker compose up -d --build` with `_UID`/`_GID` set to your user's IDs (both default to `1000` if you run `docker compose` directly).

3. Open the Web UI at <http://127.0.0.1:9080>.

   The username is `admin`. Recent qBittorrent versions generate a temporary password on first start and print it to the log:

   ```sh
   docker compose logs main
   ```

   Change the password under *Tools → Options → Web UI* after logging in.

### Accessing from another machine

The port is bound to localhost only. To reach the Web UI remotely, use an SSH tunnel:

```sh
ssh -L 9080:127.0.0.1:9080 user@server
```

### Common commands

```sh
docker compose logs -f main     # follow logs
docker compose exec main wg     # check the WireGuard tunnel status
docker compose exec main curl -s https://ifconfig.me   # check the public IP
docker compose down             # stop and remove the container
```

## Notes

- **Download location:** only `qbt/` (mounted at `/home/qbt/qBittorrent`) is persisted. Set the default save path in the Web UI to a directory under `/home/qbt/qBittorrent` (e.g. `/home/qbt/qBittorrent/downloads`), or add another volume in `docker-compose.yml`, otherwise downloads are lost when the container is removed.
- **No kill switch:** if a WireGuard profile is present but the tunnel fails to come up, qBittorrent still starts and uses the regular network. Check `docker compose exec main wg` after starting.
- **sysctl:** `wg-quick` tries to call `sysctl`, which is not allowed inside the container. The image replaces `/sbin/sysctl` with a no-op, and the required settings (`net.ipv4.ip_forward`, `net.ipv4.conf.all.src_valid_mark`) are set through `sysctls` in `docker-compose.yml` instead.
- **Capabilities:** the container needs `NET_ADMIN` and `SYS_MODULE` to create the WireGuard interface and adjust routing.
- `entrypoint.sh` is bind-mounted, so changes to it take effect on the next container restart without rebuilding the image.
