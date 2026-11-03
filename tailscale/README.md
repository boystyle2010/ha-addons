# Home Assistant App: Tailscale Pro

![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)
![Tailscale](https://img.shields.io/badge/tailscale-v1.104.5-0052CC.svg)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)

Zero-config mesh VPN for building secure networks, tuned for Raspberry Pi 5.

## About

Tailscale Pro connects your Home Assistant to your private Tailscale network in minutes. Reach your home from anywhere, share your local network as a subnet router, or route all your traffic through your home as an exit node.

This add-on tracks the official Tailscale releases and updates itself automatically after passing a series of safety checks.

## Features

- Subnet router and exit node
- Web UI in the Home Assistant sidebar (Ingress)
- Built-in health monitor with automatic recovery
- UDP GRO forwarding optimization for higher throughput
- Persistent login state, no need to sign in again after a restart
- AppArmor protection
- Automatic, verified updates from the official Tailscale repository
- Taildrive & Taildrop built-in support
