# Home Assistant App: Tailscale Pro

## Quick start

1. Create an auth key at https://login.tailscale.com/admin/settings/keys
   (reusable keys are recommended)
2. Paste it into the **auth_key** option and start the add-on
3. Open the **Tailscale Pro** panel in the sidebar to check the status
4. If you use subnet routes or an exit node, approve them in the Tailscale
   admin console (Machines → your device → Edit route settings)

You can also leave **auth_key** empty and log in through the Web UI instead.

## Configuration

- **auth_key**: Tailscale auth key used to log in automatically. Optional
- **hostname**: Name of this device in your tailnet
- **advertise_exit_node**: Offer this device as an exit node
- **advertise_routes**: List of subnets to share with your tailnet
  (for example `192.168.1.0/24`)
- **accept_routes**: Accept subnet routes advertised by other devices
- **accept_dns**: Use Tailscale DNS settings (MagicDNS) on this device
- **enable_ssh**: Enable Tailscale SSH
- **snat_subnet_routes**: Source NAT for subnet routes. Keep it enabled
  unless you know you need it off
- **extra_args**: Extra arguments passed to `tailscale up`. Optional

## Health monitor

The add-on checks the connection state every 60 seconds:

- **Running**: everything is fine
- **NeedsLogin / Starting**: a warning is logged, check your auth key or log in via the Web UI
- Any other state: the add-on tries to reconnect. After 3 failed attempts in a row
  it exits so the Home Assistant Watchdog can restart it cleanly

## Automatic updates

A GitHub Actions bot checks for new official Tailscale releases every 6 hours.
It only updates when the release is stable and the linux/arm64 image is available.
Every update is recorded in the Changelog tab.

## Troubleshooting

- **Cannot log in**: check the auth key has not expired or been revoked
- **Subnet not reachable**: make sure the routes are approved in the admin console
- **Add-on keeps restarting**: open the Log tab, the health monitor explains the reason
- **Exit node not shown**: approve it in the admin console first

## Support

Please open an issue in the GitHub repository.
