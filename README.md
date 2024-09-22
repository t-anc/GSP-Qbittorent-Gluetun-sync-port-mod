# (Q)GSP : Qbittorrent - Gluetun synchronised port mod
A mod to sync forwarded ports from gluetun to qbittorrent.  
This mod is to be used with [linuxserver/qbittorrent container](https://github.com/linuxserver/docker-qbittorrent) and [qdm12/gluetun container](https://github.com/qdm12/gluetun).

> :star: 
> If you like this mod, don't hesitate to give it a star ! It's always nice :)


> :warning: **Be aware !**
> I'm not a developper. I just needed something and found a way to do it. This is my first Linuxserver mod and my first attempt at creating anything with docker. Also my first use of github actions, so everything is probably far from perfect. If you have suggestions, feel free to open an issue.


## Install 

Follow the instructions [here](https://docs.linuxserver.io/general/container-customization/#docker-mods).
With the following link for the mod `ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main`.

### qBittorrent
- You will need to enable `Bypass authentication for clients on localhost` inside qbittorrent's `settings` > `Web UI`. Otherwise you can set the `GSP_QBT_USERNAME` and `GSP_QBT_PASSWORD` (or `GSP_QBT_PASSWORD_FILE`) variables.
- If you have enabled the `Enable Host header validation` option, you will need to add `localhost` to the `Server domains` list.

### Gluetun
You will need to add the following lines to your [config.toml](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md#authentication) :

```toml
[[roles]]
name = "t-anc/GSP-Qbittorent-Gluetun-sync-port-mod"
routes = ["GET /v1/openvpn/portforwarded"]
auth = "apikey"
# This is an example, generate your own. See bellow.
apikey = "yOdKVNFEA3/BSIWhPZohxppHd9I6bHiSJ+FasGlncleveW4LvuO7ONy5w1IsEA2Pu6s="
```
You can generate your own API key with one of the following command :
```bash
# Using GPG
gpg --gen-random --armor 1 50
# Using openssl
openssl rand -base64 50
# Using gluetun's internal program
docker run --rm qmcgaw/gluetun genkey
```

And pass this key to your container via the `GSP_GTN_API_KEY` env variable. You can take a look at the [compose example](#docker-compose-example).

## Variables

The following env variables can be used to configure the mod (Only `GSP_GTN_API_KEY` is compulsory) :
|      Variable          |      Default value      | Comment                                                                                                  |
|:----------------------:|:-----------------------:|----------------------------------------------------------------------------------------------------------|
|  `GSP_GTN_API_KEY`     |                         | Gluetun's API key. See the [install section](#gluetun).                                                  |
| `GSP_GTN_API_KEY_FILE` |                         | Gluetun's API key file (for [docker secret](https://docs.docker.com/compose/use-secrets/) use). This supplants `GSP_GTN_API_KEY`. |
|   `GSP_GTN_ADDR`       | `http://localhost:8000` | Gluetun API host address.                                                                                |
|   `GSP_QBT_ADDR`       | `http://localhost:8080` | Qbittorrent API host address. If the env variable `WEBUI_PORT` is set, it will be used as default.       |
|     `GSP_SLEEP`        |           `60`          | Time between checks in seconds.                                                                          |
|  `GSP_RETRY_DELAY`     |           `10`          | Time between retries in case of error (in s).                                                            |
|  `GSP_GTN_PORT_INDEX`      |           `1`           | Index of port to use from gluetun. Set to `2` to use the second one, etc. Only if you have multiple ports forwarded.          |
| `GSP_QBT_USERNAME`     |                         | Qbittorrent username.                                                                                    |
| `GSP_QBT_PASSWORD`     |                         | Qbittorrent password.                                                                                    |
| `GSP_QBT_PASSWORD_FILE`|                         | Qbittorrent password file (for [docker secret](https://docs.docker.com/compose/use-secrets/) use). This supplants `GSP_QBT_PASSWORD`. |
| `GSP_SKIP_INIT_CHECKS` |         `false`         | Set to `true` to disable qbt config checks ("Bypass authentication on localhost", etc). Set to `warning`to see check results but continue anyway.|
| `GSP_MINIMAL_LOGS`     |         `true`          | Set to `false` to enable "Ports did not change." logs.                                                   |
| `GSP_INIT_RETRY_WAIT`  |      `10` (=60s)        | Number of retries to connect to qbittorrent's webUI at startup. Each retry takes 6 seconds. Increase to allow a longer wait at startup.          |
|     `GSP_DEBUG`        |         `false`         | Set to `true` to enable mod's `set -x`.<br>:warning: **FOR DEBUG ONLY.**                                 |

I was planning on implementing the option to use Gluetun's port forwarding file but since it will be [deprecated in v4](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md#native-integrations), I won't.

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
          - VPN_SERVICE_PROVIDER=custom
          - VPN_TYPE=wireguard
          - VPN_PORT_FORWARDING=on
          - VPN_PORT_FORWARDING_PROVIDER=protonvpn
        volumes:
          - "./config.toml:/gluetun/auth/config.toml:ro"

    qbittorrent:
        image: ghcr.io/linuxserver/qbittorrent
        container_name: qbittorrent
        environment:
          - TZ=Europe/Paris
          - WEBUI_PORT=8080
          - DOCKER_MODS=ghcr.io/t-anc/gsp-qbittorent-gluetun-sync-port-mod:main
          - GSP_GTN_API_KEY=yOdKVNFEA3/BSIWhPZohxppHd9I6bHiSJ+FasGlncleveW4LvuO7ONy5w1IsEA2Pu6s= # Of course this is an exemple, don't use this
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

Here's some tips for troubleshooting :

<details>

  <summary>Check the logs</summary>

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
|  GTN port index : 1                                     |
+---------------------------------------------------------+

04/10/24 01:03:49 [GSP] - Waiting for Qbittorrent WebUI ...
WebUI will be started shortly after internal preparations. Please wait...

******** Information ********
To control qBittorrent, access the WebUI at: http://localhost:8080

Connection to localhost (::1) 8080 port [tcp/http-alt] succeeded!
[ls.io-init] done.
04/10/24 01:03:55 [GSP] - Init checks passed. Listening for a change.
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

</details>

<details>

  <summary>Check Gluetun's control server and forwarded port</summary>

If the log indicates `Error retrieving port from Gluetun API.` then try to get the port mannually (replace the container's name and `localhost:8000` if needed) :

```bash
 docker exec gluetun wget -q -O- /dev/tty http://localhost:8000/v1/openvpn/portforwarded
```

and you should get this (with your port number) :
```bash
{"port":34981}
```

> If you get `0` it means gluetun's port forwarding is misconfigured.

If you get anything else, then the issue is from your gluetun's configuration, you can get help [on the wiki](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md) or [open an issue](https://github.com/qdm12/gluetun/issues).

**Note :** even with `openvpn` in the URL, this is also valid for wireguard.

</details>

 
<details>

  <summary>[mod-init] (ERROR) digest could not be fetched from ghcr.io</summary>


  This is due to the fact that at startup, qBittorrent container does not have internet access. Since the container gets the connexion from Gluetun, you have to tell Docker to wait for an established VPN connexion before starting qBittorrent.

  To do that, the solution is quite simple, just add the following to your qBittorrent's `docker-compose.yml` file section (according to the [example](#docker-compose-example)) :

```yaml
  depends_on:
    gluetun:
      condition: service_healthy
```

This is thanks to [Gluetun's healthcheck](https://github.com/qdm12/gluetun-wiki/blob/main/faq/healthcheck.md) being healthy only when the connexion is set.

</details>