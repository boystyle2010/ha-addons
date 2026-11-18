![Version](https://img.shields.io/badge/version-1.1.2-blue.svg) ![Cloudflared](https://img.shields.io/badge/cloudflared-2026.11.1-F38020.svg) ![Alpine](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg) ![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg) ![AppArmor](https://img.shields.io/badge/apparmor-enforced-success.svg)





# Home Assistant Add-on: Cloudflared Pro

Cloudflared Pro runs the official `cloudflared` binary from Cloudflare inside Home Assistant and connects your network to Cloudflare through an outbound tunnel. You can reach Home Assistant, and other services in your home, from the internet **without opening any port on your router**.

The add-on supports `aarch64` (Raspberry Pi 4/5 and similar) and `amd64` (mini PCs, VMs), and runs under an enforced AppArmor profile.

## How it works

1. `cloudflared` opens outbound connections from your Home Assistant to Cloudflare.
2. A public hostname in your Cloudflare account points to the tunnel.
3. Requests to that hostname travel through the tunnel to the service you choose, for example `http://homeassistant:8123`.

The add-on starts in one of two modes, chosen automatically:

| Mode | When it is used | Where the routes are managed |
| :--- | :--- | :--- |
| **Remote managed tunnel** | `tunnel_token` is filled in | In the Cloudflare Zero Trust dashboard |
| **Local configuration** | `tunnel_token` is empty | In this add-on's options (`external_hostname`, `additional_hosts`, `catch_all_service`) |

The mode is printed in the add-on log at every start (`Operating Mode: ...`).

---

## Quick start: remote managed tunnel (recommended)

This is the simplest way. Routes are edited in the Cloudflare dashboard, so you never need to restart the add-on to add a hostname.

1. In the Cloudflare Zero Trust dashboard, go to **Networks → Tunnels** and create a tunnel.
2. Copy the tunnel token Cloudflare shows you.
3. Add a **Public Hostname** for the tunnel, for example `ha.example.com`, with the service `http://homeassistant:8123`.
4. Paste the token into the `tunnel_token` option of this add-on and start it.
5. Allow the proxy in Home Assistant (see [Home Assistant settings](#home-assistant-settings)).

When `tunnel_token` is set, the add-on ignores `external_hostname`, `additional_hosts` and `catch_all_service`. Only the connection options (protocol, IP version, retries, grace period, metrics, post-quantum, custom flags, log level) still apply.

## Quick start: local configuration

Use this mode when you prefer to keep the routes in the add-on options. The add-on does the Cloudflare setup for you.

1. Leave `tunnel_token` empty.
2. Set `external_hostname` (for example `ha.example.com`) and, if you like, `additional_hosts` for other services.
3. Start the add-on and open its **Log**.
4. **First start only:** the log shows a Cloudflare login URL. Open it in a browser, log in and choose your domain. You have 10 minutes.
5. The add-on creates the tunnel (named by `tunnel_name`), writes the routing file and creates a DNS record for every hostname.

On later starts nothing needs to be repeated: the add-on reuses the tunnel and regenerates `/share/cloudflared/config.yml` from your options.

```yaml
# generated file (example)
tunnel: <tunnel id>
credentials-file: /share/cloudflared/credentials.json
ingress:
  - hostname: "ha.example.com"
    service: http://homeassistant:8123
  # one entry per item of additional_hosts
  - service: http_status:404      # catch_all_service
```

Good to know:

- DNS records are created with Cloudflare's "overwrite" option. **An existing DNS record with the same name is replaced.**
- If you only want to expose other services, leave `external_hostname` empty and fill `additional_hosts`.
- If the login is not completed, the add-on stops with a message; restart it to get a new login URL.
- The login certificate is kept in `/share/cloudflared/home/.cloudflared/cert.pem`. It lets the add-on manage DNS for your domain, and `/share` is visible to other add-ons. If you do not need automatic DNS updates after the first setup, delete that file; the tunnel keeps working and you manage DNS yourself.
- Already have a tunnel? Copy its credentials file to `/share/cloudflared/credentials.json` and the add-on will use it without asking you to log in.

---

## Configuration reference

> Restart the add-on after changing any option.

| Option | Default | Description |
| :--- | :--- | :--- |
| `tunnel_token` | empty | Token of a remote managed tunnel. When set, the add-on runs in remote mode. |
| `protocol` | `auto` | Transport to Cloudflare: `auto`, `quic` or `http2`. Use `http2` if your network blocks UDP. |
| `edge_ip_version` | `Auto` | IP version used to reach Cloudflare: `Auto`, `IPv4` or `IPv6`. |
| `post_quantum` | `false` | Enables post-quantum encryption for the tunnel (`--post-quantum`). See Cloudflare's documentation for its requirements. |
| `log_level` | `info` | `debug`, `info`, `warn`, `error` or `fatal`. |
| `retries` | `5` | Maximum connection retries, 1 to 20. |
| `grace_period` | `30s` | Time `cloudflared` waits for active requests to finish when it stops, for example `30s`. |
| `metrics_port` | `0` | `0` keeps metrics internal. Any other port exposes metrics (see below). |
| `tunnel_name` | `homeassistant` | Local mode only. Name of the tunnel created on the first start. Must be unique in your Cloudflare account. |
| `external_hostname` | empty | Local mode only. Public hostname routed to Home Assistant. |
| `additional_hosts` | `[]` | Local mode only. Extra hostnames routed to other services. |
| `catch_all_service` | `http_status:404` | Local mode only. What happens to hostnames that are not listed above. The default answers `404`, so only the hostnames you configured work. Set a URL such as `http://192.168.1.10` to forward them instead. |
| `nginx_proxy_manager` | `false` | Local mode only. Sends unlisted hostnames to the official Nginx Proxy Manager add-on (overrides `catch_all_service`). |
| `custom_flags` | `[]` | Extra command-line flags passed to `cloudflared`. |

### `additional_hosts`

Each item can contain:

| Field | Required | Description |
| :--- | :--- | :--- |
| `hostname` | yes | Public hostname, for example `nas.example.com`. |
| `service` | yes | Target service, for example `http://192.168.1.20:5000` or `https://192.168.1.2:5001`. |
| `no_tls_verify` | no | Set `true` to accept a self-signed certificate on an HTTPS target. |
| `http_host_header` | no | Sends this value as the `Host` header to the target. |

```yaml
external_hostname: ha.example.com
additional_hosts:
  - hostname: nas.example.com
    service: https://192.168.1.2:5001
    no_tls_verify: true
  - hostname: cam.example.com
    service: http://192.168.1.30:8080
    http_host_header: cam.local
catch_all_service: http://homeassistant:8123
```

### Metrics and health check

- With `metrics_port: 0` the add-on keeps a private endpoint on `127.0.0.1:49999` (`/ready`) for its own health check. It is not reachable from outside.
- With a port such as `metrics_port: 2000`, metrics are served on `0.0.0.0:2000` inside the add-on, so other add-ons on the Home Assistant network can read them. To read them from outside Home Assistant (for example a Prometheus server), also choose a host port for `2000/tcp` in the add-on **Network** section. This port has no authentication, so use it only on a trusted network.

### `custom_flags`

Every item is added to the `cloudflared` command line before `run`. Put **one flag per item** and write values with `=`, because items are split on spaces:

```yaml
custom_flags:
  - "--region=us"
  - "--ha-connections=4"
```

Do not repeat options that already have their own setting here (`--protocol`, `--loglevel`, `--edge-ip-version`, `--retries`, `--grace-period`, `--metrics`). A `--token` entry is ignored with a warning; use `tunnel_token`.

### Command line used by the add-on

```text
cloudflared tunnel --no-autoupdate --protocol <protocol> --loglevel <log_level>
  --edge-ip-version <auto|4|6> --retries <retries> --grace-period <grace_period>
  --metrics <address> [--post-quantum] [custom_flags...]
  run --token <token>          # remote mode
  --config /share/cloudflared/config.yml run   # local mode
```

---

## Home Assistant settings

Home Assistant rejects requests that arrive through a proxy unless you allow it. Add this to `configuration.yaml`, then restart Home Assistant:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.30.33.0/24
```

`172.30.33.0/24` is the usual network of Home Assistant add-ons. If you see `400 Bad Request` or a "request from a reverse proxy" error in the Home Assistant log, use the address shown in that log message instead.

---

## Files and permissions

| Path | Access | Purpose |
| :--- | :--- | :--- |
| `/share/cloudflared/` | read/write | Local mode: `config.yml`, `credentials.json` and the login certificate (see above) |
| `/ssl` | read-only | Available for certificates if you need them in `custom_flags` |
| `2000/tcp` | optional | Metrics port you can publish in the Network section (see `metrics_port`) |

The add-on starts at boot (`boot: auto`) in the `services` stage.

---

## Troubleshooting

| Symptom | What to check |
| :--- | :--- |
| `No Tunnel Token provided, and nothing to expose` | Fill in `tunnel_token`, or set `external_hostname` and/or `additional_hosts`. |
| `400 Bad Request` when opening Home Assistant | Add the proxy settings in [Home Assistant settings](#home-assistant-settings). |
| `Cloudflare login was not completed` | Restart the add-on, open the new login URL within 10 minutes and pick your domain. |
| `Could not create the tunnel` | A tunnel with that `tunnel_name` already exists. Choose another name, or delete the old tunnel in the Cloudflare dashboard. |
| Tunnel never connects | Set `protocol` to `http2`; some networks block QUIC. Set `edge_ip_version` to `IPv4` if IPv6 is unreliable. |
| Hostname does not resolve | In local mode, create the CNAME record to your tunnel in Cloudflare. In remote mode, add the Public Hostname in the dashboard. |
| An extra service shows a certificate error | Set `no_tls_verify: true` on that item of `additional_hosts`. |
| Need more detail | Set `log_level: debug`, restart, and read the add-on log. |

---

## Notes

- Binary version, architecture and operating mode are printed at the top of every add-on log.
- Cloudflare Tunnel is a Cloudflare service. Use it in line with Cloudflare's own terms: <https://www.cloudflare.com/terms/>.
- Tunnel documentation from Cloudflare: <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/>.
