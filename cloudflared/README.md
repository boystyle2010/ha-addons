# Home Assistant App: Cloudflared Pro

![Release][release-shield] ![Project Stage][stage-shield]
![Supports aarch64][arch-shield] ![Cloudflare Zero Trust][cf-shield]

Connect remotely to your Home Assistant instance without opening any ports using Cloudflared (Native ARM64 for Raspberry Pi 5).

## About

Cloudflared Pro connects your Home Assistant Instance via a secure tunnel to a domain or subdomain at Cloudflare. Doing that, you can expose your Home Assistant to the Internet without opening ports in your router. Additionally, you can utilize Cloudflare Zero Trust platform to further secure your Home Assistant connection.

**To use this app, you have to own a domain name (e.g. example.com) that is using Cloudflare for its DNS entries.**

## Key Features
- **Auto-Verified Updates:** Automatically tracks official `cloudflare/cloudflared` releases and Home Assistant Alpine Base images.
- **Full UI Configuration:** Supports Zero Trust Tunnel Token, Local Ingress routing, Post-Quantum encryption, and Prometheus Metrics.

## Disclaimer

Please make sure to be compliant with the [Cloudflare Self-Serve Subscription Agreement](https://www.cloudflare.com/terms/) when using this app.

[release-shield]: https://img.shields.io/github/v/release/cloudflare/cloudflared?label=cloudflared&color=007ec6
[stage-shield]: https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg
[arch-shield]: https://img.shields.io/badge/aarch64-yes-brightgreen.svg
[cf-shield]: https://img.shields.io/badge/maintained-yes-brightgreen.svg
