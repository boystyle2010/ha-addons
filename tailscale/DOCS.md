# Home Assistant App: Tailscale Pro

Tailscale Pro connects Home Assistant to your private Tailscale network. Use it
to reach your home from anywhere, share your local network as a subnet router,
or route traffic through your home connection as an exit node.

This is an unofficial add-on. Tailscale is a trademark of Tailscale Inc.

## Prerequisites

You need a Tailscale account. Personal use is free, and you can sign up at
https://tailscale.com/start.

## Installation

1. Add this repository to the Home Assistant Add-on Store.
2. Install **Tailscale Pro**.
3. Review the **Configuration** tab. The defaults work for most setups.
4. Start the add-on.
5. Sign in using one of these methods:
   - Paste an auth key into **Auth key** before starting, or
   - Open the **Web UI** and follow the sign-in link.
6. Open the Tailscale admin console and approve any subnet routes or exit node
   you enabled (Machines, then your device, then Edit route settings).
7. Consider disabling key expiry for this device so it never loses connection.

If you previously used another Tailscale add-on, stop it first. Two add-ons
cannot use the same network interface, and the second one fails with
"device or resource busy".

## Configuration

| Option | Default | Description |
|---|---|---|
| Auth key | empty | Key for automatic sign-in. Leave empty to sign in through the Web UI |
| Hostname | hass-pi5-pro | Device name in your tailnet |
| Login server | Tailscale default | Control server. Change only for self-hosted setups such as Headscale |
| Accept DNS | off | Use your tailnet DNS settings on this device |
| Accept routes | off | Accept subnet routes from other devices |
| Advertise as an exit node | on | Offer this device as an exit node |
| Advertise as an app connector | off | Act as an app connector |
| Advertise subnet routes | 192.168.68.0/24 | Local subnets to share with your tailnet |
| Advertise tags | none | ACL tags, each starting with `tag:` |
| Use an exit node | empty | Tailscale IP of an exit node to use |
| Always use DERP connection | off | Force relayed traffic, for troubleshooting only |
| Tailscale SSH | off | Allow Tailscale SSH to this device |
| Source NAT subnet routes | on | Keeps subnet routing simple |
| Stateful packet filtering | off | Only allow return traffic for connections started from inside |
| Userspace networking mode | off | No tailscale0 interface, one-way access into Home Assistant |
| Log upload | off | Send client logs to Tailscale |
| Share Home Assistant | disabled | disabled, serve or funnel |
| Share on port | 443 | HTTPS port for Serve or Funnel |
| Extra arguments | empty | Extra arguments for `tailscale up` |

Restart the add-on after changing any option.

Note: an exit node cannot also use another exit node. If both are set, the
add-on logs a warning and ignores **Use an exit node**.

## Subnet router

Set **Advertise subnet routes** to the networks you want to reach remotely,
for example your home LAN. After the add-on starts, approve the routes in the
admin console. Devices on your tailnet can then reach those addresses.

On devices that should use these routes, enable "Use Tailscale subnets" in
the Tailscale app. On Linux, run `tailscale up --accept-routes`.

## Exit node

With **Advertise as an exit node** enabled, other devices can choose this
device as their exit node after you approve it in the admin console. All of
their internet traffic then leaves through your home connection.

## Share Home Assistant with Serve or Funnel

Serve publishes Home Assistant over HTTPS to devices in your tailnet. Funnel
publishes it to the public internet.

Requirements:

1. Enable **HTTPS Certificates** in the DNS page of the admin console.
2. For Funnel, allow it in your tailnet policy.
3. Add this to your Home Assistant `configuration.yaml`, then restart Home
   Assistant:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
```

Then set **Share Home Assistant with Serve or Funnel** and restart the
add-on. The address is `https://<hostname>.<tailnet-name>.ts.net`. Funnel
only works on ports 443, 8443 and 10000.

Be careful with Funnel: it exposes your Home Assistant login page to the
whole internet. Use strong passwords and two-factor authentication.

## Health monitor

Every 60 seconds the add-on checks the connection:

- **Running**: everything is fine.
- **NeedsLogin or Starting**: a warning is logged. Check your auth key or
  sign in through the Web UI.
- Anything else: the add-on tries to reconnect. After 3 failed attempts in a
  row it exits so the Home Assistant Watchdog restarts it cleanly.

## Automatic updates

A GitHub Actions bot checks for new official Tailscale releases every 6 hours.
It only publishes an update when the release is stable, the official files and
container images are fully available, and the edited files pass validation.
Each update is listed in the Changelog tab.

## Troubleshooting

- **device or resource busy**: another Tailscale add-on is using the network
  interface. Stop it and start this add-on again.
- **Cannot sign in**: the auth key may be expired or revoked. Create a new one.
- **Subnet or exit node not working**: approve it in the admin console.
- **Serve or Funnel not starting**: enable HTTPS Certificates in the admin
  console and restart the add-on.
- **Add-on restarts repeatedly**: open the Log tab, the health monitor logs
  the reason.

## Support

Open an issue in the GitHub repository:
https://github.com/boystyle2010/ha-addons/issues
