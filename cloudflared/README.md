# Home Assistant App: Cloudflared Pro

![Version](https://img.shields.io/badge/version-1.0.2-blue.svg)
![Cloudflared](https://img.shields.io/badge/cloudflared-2026.11.0-F38020.svg)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![Arch](https://img.shields.io/badge/arch-aarch64-blue.svg)

High-stability, upstream-synced Cloudflare Tunnel add-on for Home Assistant, tuned for Raspberry Pi 5 (aarch64).

## About

Cloudflared Pro connects your Home Assistant instance securely to Cloudflare Zero Trust Tunnels without opening any router ports. It tracks official Cloudflare releases and Home Assistant Alpine Base images automatically after passing strict multi-layer verification checks.

## Features

- Direct official arm64 binary from Cloudflare
- Automatic, verified updates for both Cloudflared Engine and Alpine Base
- Token-based Zero Trust Tunnel configuration
- Built-in Watchdog & Healthcheck support
- Optimized for Raspberry Pi 5 (aarch64)
