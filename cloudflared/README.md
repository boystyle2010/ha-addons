# Home Assistant App: Cloudflared Pro

![Version](https://img.shields.io/badge/version-1.0.5-blue.svg)
![Cloudflared](https://img.shields.io/badge/cloudflared-2026.11.0-F38020.svg?logo=cloudflare&logoColor=white)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg?logo=alpinelinux&logoColor=white)
![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)
![Security](https://img.shields.io/badge/apparmor-enforced-success.svg?logo=linux&logoColor=white)
![Post-Quantum](https://img.shields.io/badge/crypto-post--quantum-blueviolet.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-production-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)

High-stability, multi-arch (`aarch64` & `amd64`), upstream-synced Cloudflare Tunnel add-on for Home Assistant.

## About

**Cloudflared Pro** connects your Home Assistant instance securely to Cloudflare Zero Trust Tunnels without opening any router ports. It automatically detects your hardware architecture (`aarch64` / Raspberry Pi 5 or `amd64` / x86_64 Mini PC) and pulls the verified official binary directly from Cloudflare.

## Key Features

- **Auto Multi-Arch Support:** Native `aarch64` (ARM64) and `amd64` (x86_64) official binaries
- **Hardened Security:** Enforced custom AppArmor security profile for maximum Home Assistant Security Rating
- **Zero-Touch Verified Updates:** Tracks official Cloudflare releases & HA Alpine Base images with SHA256 verification
- **Post-Quantum Cryptography:** Built-in support for post-quantum tunnel encryption
- **Smart Watchdog & Healthcheck:** Internal readiness endpoint monitoring
