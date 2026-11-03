# Changelog

## 1.0.1
_Released: 2026-11-03_

### 📦 Component Updates
- **Add-on Version:** `v1.0.1`
- **Tailscale Engine (arm64 & amd64 verified):** Updated to **`v1.104.5`**
- **Home Assistant Alpine Base Image:** `Alpine 3.24`
- **Official Release Source:** [GitHub Release v1.104.5](https://github.com/tailscale/tailscale/releases/tag/v1.104.5) | [Tailscale Full Changelog](https://tailscale.com/changelog#client)

### 📝 Upstream Release Notes (v1.104.5)
- Connectivity stalls affecting Tailscale SSH , Tailscale Serve , and tsnet on lossy networks are resolved.
- Tailscale SSH sessions no longer disconnect when a check mode approval expires.
- An issue that could cause Tailscale SSH restarts to hang or background tasks to terminate is resolved.
- An issue in the Windows .exe installer that could lead to privilege escalation at install time has been resolved. Existing installations do not need to be reinstalled.
- Connection reliability is improved when the network reports an unreachable destination.
- Connection reliability is improved when the network reports an unreachable destination.
- Connection reliability is improved when the network reports an unreachable destination.
- **SHA256 (`tailscale_1.104.5_arm64.tgz`):** `e900b0e6e25023a1e504b2c237ce2a32ea0535e006f8c1a1097a490886493b6c`

---

## 1.104.4
_Released: 2026-10-28_

### 📦 System Components
- **Tailscale Engine (arm64 & amd64 verified):** `v1.104.4`
- **Home Assistant Alpine Base Image:** `Alpine 3.24`
- **Official Release Source:** [GitHub Release v1.104.4](https://github.com/tailscale/tailscale/releases/tag/v1.104.4) | [Tailscale Full Changelog](https://tailscale.com/changelog#client)

### 📝 Upstream Release Notes (v1.104.4)
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
- **SHA256 (`tailscale_1.104.4_arm64.tgz`):** `a1c249ce6bdebef62e1ae3b997595555bce2ae4709bf95a718e9ca7a129dad7e`

---

## 1.104.2
_Released: 2026-10-21_

### 📦 System Components
- **Tailscale Engine (arm64 & amd64 verified):** `v1.104.2`
- **Home Assistant Alpine Base Image:** `Alpine 3.24`
- **Official Release Source:** [GitHub Release v1.104.2](https://github.com/tailscale/tailscale/releases/tag/v1.104.2) | [Tailscale Full Changelog](https://tailscale.com/changelog#client)

### 📝 Upstream Release Notes (v1.104.2)
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
- The DNSConfig custom resource supports image pull secrets for nameserver pods.
- The operator Helm chart supports the nameOverride and fullnameOverride values to customize the names of the resources it installs.
- **SHA256 (`tailscale_1.104.2_arm64.tgz`):** `5776aaa901b5ef1916e66be5bb54b9f481cd399c9c28db123a8cab620efa237b`

---

## 1.104.1
_Released: 2026-10-07_

### 📦 System Components
- **Tailscale Engine (arm64 & amd64 verified):** `v1.104.1`
- **Home Assistant Alpine Base Image:** `Alpine 3.24`
- **Official Release Source:** [GitHub Release v1.104.1](https://github.com/tailscale/tailscale/releases/tag/v1.104.1) | [Tailscale Full Changelog](https://tailscale.com/changelog#client)

### 📝 Upstream Release Notes (v1.104.1)
- Go is updated to version 1.27.
- WireGuard packet buffering uses less memory while waiting for peer handshakes.
- WireGuard packet queue depth scales with CPU core count, reducing peak memory usage under heavy traffic.
- Client-side netmap caching improves start up speed and connectivity when the Tailscale control plane is unreachable.
- WireGuard allocates a single packet buffer for batched I/O, improving throughput and reducing memory usage.
- An issue that could prevent traffic over IPv6 link-local addresses from flowing through direct and Tailscale Peer Relay connections is resolved.
- An issue preventing Linux desktop detection from working on Wayland environments is resolved.
- Client-side netmap caching improves start up speed and connectivity when the Tailscale control plane is unreachable.
- Client-side netmap caching improves start up speed and connectivity when the Tailscale control plane is unreachable.
- Tailscale Services and Tailscale PAM Services are available in the app window.
- Devices , Exit Nodes , and Services can be pinned to the top of their respective lists in the app window. Pins also appear in the Pinned page of the app window.
- Tailscale's iOS widgets are available on macOS Tahoe 26 and later.
- **SHA256 (`tailscale_1.104.1_arm64.tgz`):** `f60294374967f3dfd8cf57bbbd474d6cfce32d123e3a8ddeab82a87940daa806`

---

