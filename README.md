# (Q)GSP : Qbittorrent - Gluetun synchronised port mod
A mod to sync forwarded ports from gluetun to qbittorrent.  
This mod is to be used with [linuxserver/qbittorrent container](https://github.com/linuxserver/docker-qbittorrent) and [qdm12/gluetun container](https://github.com/qdm12/gluetun).

> :warning: **Be aware !**
> I'm not a developper, nor anything. I just needed something and found a way to do it. This is my first Linuxserver mod, and my first attempt to create anything with docker. Also my first use of github actions, so everything is probably far from perfect.

## Install 

Follow the instructions [here](https://docs.linuxserver.io/general/container-customization/#docker-mods).
With the following link for the mod `ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main`.

- You will need to enable `Bypass authentication for clients on localhost` inside qbittorrent's `settings` > `Web UI`. (Authentication method not implemented yet)
- If you have enabled the `Enable Host header validation` option, you will need to add `localhost` to the `Server domains` list.


## Variables

The following env variables can be used to configure the mod (none is compulsory) :
|      Variable          |      Default value      | Comment                                                                                                  |
|:----------------------:|:-----------------------:|----------------------------------------------------------------------------------------------------------|
|   `GSP_GTN_ADDR`       | `http://localhost:8000` | Gluetun API host address.                                                                                |
|   `GSP_QBT_ADDR`       | `http://localhost:8080` | Qbittorrent API host address. If the env variable `WEBUI_PORT` is set, it will be used as default.       |
|     `GSP_SLEEP`        |           `60`          | Time between checks in seconds.                                                                          |
|  `GSP_RETRY_DELAY`     |           `10`          | Time between retry in case of error (in s).                                                              |
| `GSP_QBT_USERNAME`     |                         | NOT IMPLEMENTED YET                                                                                      |
| `GSP_QBT_PASSWORD`     |                         | NOT IMPLEMENTED YET                                                                                      |
| `GSP_SKIP_INIT_CHECKS` |         `false`         | Set to true to disable qbt config checks ("Bypass authentication on localhost", etc).                    |
| `GSP_MINIMAL_LOGS`     |         `true`          | Set to false to enable "Ports did not change." logs.                                                     |
|     `GSP_DEBUG`        |         `false`         | Set to `true` to enable mod's `set -x`. /!\ FOR DEBUG ONLY.                                              |

I was planning to implement the option to use Gluetun's port forwarding file but since it will be [deprecated in v4](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md#native-integrations), I won't.

## Docker compose example
This is just an example for the mod, adapt it to your needs.


```yaml
services:
    gluetun:
        image: qmcgaw/gluetun
        container_name: gluetun
        restart: always
        cap_add:
          - NET_ADMIN
        environment:
          - TZ=Europe/Paris
          - VPN_PORT_FORWARDING=on

    qbittorrent:
        image: ghcr.io/linuxserver/qbittorrent
        container_name: qbittorrent
        environment:
          - TZ=Europe/Paris
          - WEBUI_PORT=8080
          - DOCKER_MODS=ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main
          - GSP_SLEEP=120
          - GSP_MINIMAL_LOGS=false
        volumes:
          - "./qbittorrent/config/:/config"
          - "./qbittorrent/webui/:/webui"
          - "./download:/download"
        network_mode: container:gluetun
        depends_on:
          gluetun:
            condition: service_healthy
        restart: unless-stopped
```

## Troubleshooting

The mod's logs are visible in the container's log : 
```bash
docker logs -f qbittorrent
```

<details>

  <summary>Qbittorrent docker logs</summary>

```log
[mod-init] Running Docker Modification Logic
[mod-init] Adding t-anc/gsp-qbittorent-gluetun-sync-port-mod:main to container
[mod-init] Downloading t-anc/gsp-qbittorent-gluetun-sync-port-mod:main from ghcr.io
[mod-init] Installing t-anc/gsp-qbittorent-gluetun-sync-port-mod:main
[mod-init] t-anc/gsp-qbittorent-gluetun-sync-port-mod:main applied to container
[migrations] started
[migrations] no migrations found
usermod: no changes
───────────────────────────────────────

      ██╗     ███████╗██╗ ██████╗
      ██║     ██╔════╝██║██╔═══██╗
      ██║     ███████╗██║██║   ██║
      ██║     ╚════██║██║██║   ██║
      ███████╗███████║██║╚██████╔╝
      ╚══════╝╚══════╝╚═╝ ╚═════╝

   Brought to you by linuxserver.io
───────────────────────────────────────

To support LSIO projects visit:
https://www.linuxserver.io/donate/

───────────────────────────────────────
GID/UID
───────────────────────────────────────

User UID:    1000
User GID:    1000
───────────────────────────────────────

[custom-init] No custom files found, skipping...
+---------------------------------------------------------+
|           Gluetun sync port (GSP) mod loaded            |
+---------------------------------------------------------+
|  Qbittorrent address : http://localhost:8080            |
|  Gluetun address : http://localhost:8000                |
+---------------------------------------------------------+

04/10/24 01:03:49 [GSP] - Waiting for Qbittorrent WebUI ...
WebUI will be started shortly after internal preparations. Please wait...

******** Information ********
To control qBittorrent, access the WebUI at: http://localhost:8080

Connection to localhost (::1) 8080 port [tcp/http-alt] succeeded!
[ls.io-init] done.
04/10/24 01:03:55 [GSP] - Ports did not change.
04/10/24 01:04:55 [GSP] - Ports changed :
04/10/24 01:04:55 [GSP] -  - Old : 22684
04/10/24 01:04:55 [GSP] -  - New : 38473
04/10/24 01:04:55 [GSP] - Updating qbittorrent port via API ...
04/10/24 01:04:55 [GSP] - Qbittorrent port successfully updated.
04/10/24 01:05:55 [GSP] - Ports did not change.
```

</details>

To (*drastically*) increase the log level, you can set the `GSP_DEBUG` var to `true`.

# TODO

- Add support for `GSP_QBT_USERNAME` and `GSP_QBT_PASSWORD`. [DOC](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#login)
- Add `latest` tag.
