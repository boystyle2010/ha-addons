# Changelog

## 1.0.2
_Released: 2026-11-11_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v1.0.1` ➡️ **`v1.0.2`**
- **Tailscale Engine:** Updated from `v1.104.5` ➡️ **`v1.104.6`** *(arm64 & amd64 verified)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Official Links:** [GitHub Release v1.104.6](https://github.com/tailscale/tailscale/releases/tag/v1.104.6) • [Official Tailscale Changelog](https://tailscale.com/changelog#client)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Package:** `tailscale_1.104.6_arm64.tgz`
- **SHA256:** `d0e4f297da3c428d02162c6235b9948e4ddc245c64502b7b05647da9b96a0971`

### 🚀 What's Changed in Tailscale v1.104.6
- A rare connectivity issue that affected dormant connections has been resolved.
- A connectivity issue that occurred when resuming from Modern Standby on devices without Always On or Unattended mode enabled is resolved.
- Error handling has been improved when multiple network extensions are present.
- An issue where MagicDNS could select a suffix-scoped DNS resolver during network transitions has been resolved.
- A DNS configuration race condition that could occur during network transitions has been resolved.
- ip:publicAddress device posture attribute is GA ( generally available ). The attribute is available for use in postures and viewable on the Machines page of the admin console.
- The India DERP servers have moved from Bengaluru ( blr ) to Mumbai ( bom ). The region ID remains 6.
- The IPv4 and IPv6 addresses for these servers have changed. If you use custom firewall settings that rely on these addresses specifically, refer to the information in our DERP map and make the necessary updates. Otherwise, no action is required.

---

## 1.104.5
_Released: 2026-11-03_

### 📦 Component & Version Matrix
- **Tailscale Engine:** `v1.104.5` *(arm64 & amd64 verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release v1.104.5](https://github.com/tailscale/tailscale/releases/tag/v1.104.5) • [Official Tailscale Changelog](https://tailscale.com/changelog#client)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Package:** `tailscale_1.104.5_arm64.tgz`
- **SHA256:** `e900b0e6e25023a1e504b2c237ce2a32ea0535e006f8c1a1097a490886493b6c`

### 🚀 What's Changed in Tailscale v1.104.5
- Connectivity stalls affecting Tailscale SSH , Tailscale Serve , and tsnet on lossy networks are resolved.
- Tailscale SSH sessions no longer disconnect when a check mode approval expires.
- An issue that could cause Tailscale SSH restarts to hang or background tasks to terminate is resolved.
- Connection reliability is improved when the network reports an unreachable destination.

---

## 1.104.4
_Released: 2026-10-28_

### 📦 Component & Version Matrix
- **Tailscale Engine:** `v1.104.4` *(arm64 & amd64 verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release v1.104.4](https://github.com/tailscale/tailscale/releases/tag/v1.104.4) • [Official Tailscale Changelog](https://tailscale.com/changelog#client)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Package:** `tailscale_1.104.4_arm64.tgz`
- **SHA256:** `a1c249ce6bdebef62e1ae3b997595555bce2ae4709bf95a718e9ca7a129dad7e`

### 🚀 What's Changed in Tailscale v1.104.4
- Tailscale SSH performs Unix socket forwarding on behalf of the authenticated user rather than as root , preventing authorized peers from using local and remote forwarding to reach root-only Unix sockets such as the Docker socket or the tailscaled local API. This fix addresses a security vulnerability described in TS-2026-014 .
- Tailscale SSH bounds the memory used for session handling and releases it when the peer disconnects, preventing denial of service through unbounded memory growth in tailscaled from continuous window-change messages and environment variable appends. This fix addresses a security vulnerability described in TS-2026-015 .
- Tailscale Serve restricts TCP forwards to Unix socket backends and revalidates backend paths on each connection, preventing access to privileged Unix sockets such as the tailscaled local API socket. This fix addresses a security vulnerability described in TS-2026-016 .
- Tailscale Serve derives per-request capabilities from the request context rather than from a context shared across all HTTP/2 streams, preventing Tailscale-App-Capabilities values from one mount from being sent with requests for another. This fix addresses a security vulnerability described in TS-2026-017 .
- tailscale_dns_configuration resource reconciles updates in keeping with the user-specified order of nameservers.
- tailscale_dns_configuration resource defines split_dns as a set, not a list.
- tailscale_tailnet_key resource no longer panics on updates when the key is not found.
- tailscale_dns_configuration no longer displays a stale alpha warning.
- tailscale_acl resource validates the policy file at plan time.
- Create and manage OAuth Apps for Device Provisioning with the Tailscale API (GA) .

---

## 1.104.2
_Released: 2026-10-21_

### 📦 Component & Version Matrix
- **Tailscale Engine:** `v1.104.2` *(arm64 & amd64 verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release v1.104.2](https://github.com/tailscale/tailscale/releases/tag/v1.104.2) • [Official Tailscale Changelog](https://tailscale.com/changelog#client)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Package:** `tailscale_1.104.2_arm64.tgz`
- **SHA256:** `5776aaa901b5ef1916e66be5bb54b9f481cd399c9c28db123a8cab620efa237b`

### 🚀 What's Changed in Tailscale v1.104.2
- Go is updated to version 1.27.3, to explicitly distrust compromised TLS intermediate certificates as described in security bulletin TS-2026-013 .
- An issue where the Windows client could repeatedly disconnect on large tailnets while processing peer updates is resolved.
- A regression where Windows clients made 100.100.100.100 the system's primary DNS resolver when MagicDNS was disabled (or a device from another tailnet was shared in) and no global nameservers were configured, causing all DNS queries to be proxied through Tailscale instead of only the configured split DNS domains is resolved.
- Menu construction timing could result in the macOS app not fully activating and, on macOS Ventura 13, rendering a malformed menu.
- Searches entered on the services tab do not inadvertently filter pinned services on the pinned tab.
- Use MagicRoute ( beta ) to choose between redundant subnet routers, app connectors, exit nodes, and Tailscale Service hosts.
- Configure how the tailnet performs Route selection , replacing the toggle that enabled Regional Routing in the admin console.
- Users with the Owner role can switch their tailnet's identity provider from the admin console for supported providers ( generally available ).
- Ingress ProxyGroups can share a single persistent Let's Encrypt account key per tailnet to ensure certificate renewals keep their exemption from Let's Encrypt rate limits .
- PeerRelay resources support a custom UDP port and additional static endpoints for peers that cannot reach the relay at its load balancer address.

---

