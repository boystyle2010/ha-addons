# Changelog

## 1.1.5
_Released: 2026-11-23_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v1.1.4` ➡️ **`v1.1.5`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64)
- **Cloudflared Engine:** Updated from `2026.11.1` ➡️ **`2026.11.2`** *(arm64 & amd64 binaries verified)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Official Links:** [GitHub Release 2026.11.2](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.2) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Multi-Arch: aarch64 & amd64)
- **ARM64 (`aarch64`):** `cloudflared-linux-arm64`
  - **SHA256:** `04a7b7f08bce85d56b26ffe1fdbfbb21a074495a363d16f0783c40e25b5c5281`
- **AMD64 (`x86_64`):** `cloudflared-linux-amd64`
  - **SHA256:** `56f13335143ec0e22772963290683a84a04114a35ec64cbc794a4d39ff9bb8cf`

### 🚀 What's Changed in Cloudflared 2026.11.2
- Release 2026.11.2
- chore: Update Google Distroless image digests
- TUN-11396: Bump golang.org/x/net and golang.org/x/crypto
- TUN-11362: Read the whole protocol version of a tunnel stream

---

## Cloudflared 2026.11.1
_Released: 2026-11-17_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.11.1` *(arm64 & amd64 binaries verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.11.1](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.1) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Multi-Arch: aarch64 & amd64)
- **ARM64 (`aarch64`):** `cloudflared-linux-arm64`
  - **SHA256:** `b155cec3e48e489cfb8e5c602769fb8c771083018d8881d68b4d18a791567c5a`
- **AMD64 (`x86_64`):** `cloudflared-linux-amd64`
  - **SHA256:** `97bb3b02d23a5980fc9c15a1a270e692da1923f103f920d5b16d4931d5ab55e7`

### 🚀 What's Changed in Cloudflared 2026.11.1
- Release 2026.11.1
- chore: Update base images to latest versions
- TUN-11062: Reconnect on account region changes
- fix: Allow quick tunnels to fall back to HTTP/2
- VULN-187395: Bump OpenTelemetry to 1.47.0

---

## Cloudflared 2026.11.0
_Released: 2026-11-12_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.11.0` *(arm64 & amd64 binaries verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.11.0](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.0) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Multi-Arch: aarch64 & amd64)
- **ARM64 (`aarch64`):** `cloudflared-linux-arm64`
  - **SHA256:** `abe54a006acf9faf2d19ee9d953cb0d0804e92f59c5382a162e57b84d086f56f`
- **AMD64 (`x86_64`):** `cloudflared-linux-amd64`
  - **SHA256:** `51f7c68b57ed7269164075d7e789efce5b59355982f06392deeb037d982a51fd`

### 🚀 What's Changed in Cloudflared 2026.11.0
- Release 2026.11.0
- chore: Bump golang to 1.27.4
- TUN-11065: Run Windows CI on production runners
- chore: Use correct logger
- VULN-170057: Don't bypass access with matrix parameters

---

## Cloudflared 2026.10.7
_Released: 2026-10-30_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.10.7` *(arm64 & amd64 binaries verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.10.7](https://github.com/cloudflare/cloudflared/releases/tag/2026.10.7) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Multi-Arch: aarch64 & amd64)
- **ARM64 (`aarch64`):** `cloudflared-linux-arm64`
  - **SHA256:** `3df43aedc9ff291d1735b5cb576cb97e0b157488796db2e32b28aecabb445775`
- **AMD64 (`x86_64`):** `cloudflared-linux-amd64`
  - **SHA256:** `1f99fb518b83dec2ba8d870a7cc991d82a77e6196295a3d2754ba17ab9f91872`

### 🚀 What's Changed in Cloudflared 2026.10.7
- Release 2026.10.7
- TUN-11058: Fix regression on max concurrent streams over http2 introduced by go1.27
- TUN-10904: Stop advertising legacy default features to the edge

---

