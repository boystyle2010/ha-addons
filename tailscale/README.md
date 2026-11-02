# Home Assistant App: Tailscale Pro

![Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/boystyle2010/ha-addons/main/tailscale/config.yaml&query=$.version&label=version&color=blue)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)
![Architectures](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-informational)

Zero-config mesh VPN for building secure networks, tuned for Raspberry Pi 5.

## About

Tailscale Pro connects your Home Assistant to your private Tailscale network
in minutes. Reach your home from anywhere, share your local network as a
subnet router, or route all your traffic through your home as an exit node.

This add-on tracks the official Tailscale releases and updates itself
automatically after passing a series of safety checks.

## Features

- Subnet router and exit node
- Web UI in the Home Assistant sidebar (Ingress)
- Built-in health monitor with automatic recovery
- UDP GRO forwarding optimization for higher throughput
- Persistent login state, no need to sign in again after a restart
- AppArmor protection
- Automatic, verified updates from the official Tailscale releases
- Supports aarch64 and amd64

## Installation

1. Add this repository to the Home Assistant Add-on Store
2. Install **Tailscale Pro**
3. Open the **Configuration** tab and set your options
4. Start the add-on and open the **Web UI**

Full setup instructions are in the **Documentation** tab.

## Support

Found a problem? Please open an issue in the
[GitHub repository](https://github.com/boystyle2010/ha-addons/issues).

## Disclaimer

This is an unofficial add-on. Tailscale is a trademark of Tailscale Inc.
This project is not affiliated with or endorsed by Tailscale Inc. or the
Home Assistant project.
