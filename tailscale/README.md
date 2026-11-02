# Home Assistant App: Tailscale Pro

High-stability, upstream-synced Tailscale mesh VPN and Subnet Router for Home Assistant, tuned for Raspberry Pi 5.

## Features

- Always up to date: a bot checks for new official Tailscale releases and updates this add-on automatically
- Subnet router and exit node support
- Web UI integrated in the Home Assistant sidebar (Ingress)
- Built-in health monitor: restarts the connection automatically if it becomes unstable
- UDP GRO forwarding optimization for better throughput
- Persistent state, so you do not need to log in again after a restart
- Supports aarch64 and amd64

## Installation

1. Add this repository to the Home Assistant Add-on Store
2. Install **Tailscale Pro**
3. Fill in the configuration (see the Documentation tab)
4. Start the add-on

See the **Documentation** tab for full setup instructions.
