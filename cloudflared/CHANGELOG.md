# Changelog

## 1.0.1
_Released: 2026-11-12_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v1.0.0` ➡️ **`v1.0.1`**
- **Cloudflared Engine:** Updated from `2026.10.7` ➡️ **`2026.11.0`** *(arm64 binary verified)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Official Links:** [GitHub Release 2026.11.0](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.0) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Binary:** `cloudflared-linux-arm64`
- **SHA256:** `abe54a006acf9faf2d19ee9d953cb0d0804e92f59c5382a162e57b84d086f56f`

### 🚀 What's Changed in Cloudflared 2026.11.0
- Release 2026.11.0
- chore: Bump golang to 1.27.4
- TUN-11065: Run Windows CI on production runners
- chore: Use correct logger
- VULN-170057: Don't bypass access with matrix parameters

---

## 2026.10.7
_Released: 2026-10-30_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.10.7` *(arm64 binary verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.10.7](https://github.com/cloudflare/cloudflared/releases/tag/2026.10.7) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Binary:** `cloudflared-linux-arm64`
- **SHA256:** `3df43aedc9ff291d1735b5cb576cb97e0b157488796db2e32b28aecabb445775`

### 🚀 What's Changed in Cloudflared 2026.10.7
- Release 2026.10.7
- TUN-11058: Fix regression on max concurrent streams over http2 introduced by go1.27
- TUN-10904: Stop advertising legacy default features to the edge

---

## 2026.10.6
_Released: 2026-10-29_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.10.6` *(arm64 binary verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.10.6](https://github.com/cloudflare/cloudflared/releases/tag/2026.10.6) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Binary:** `cloudflared-linux-arm64`
- **SHA256:** `0ae0e179475b2c77651a718d2b376e0151f4fca5954702a84f02843a4d5fcac0`

### 🚀 What's Changed in Cloudflared 2026.10.6
- Release 2026.10.6
- TUN-11051: Disable autoupdate in container images via NO_AUTOUPDATE
- TUN-11048: Randomize and enable the cloudflared update timer
- VULN-184686: Bump github.com/go-jose/go-jose/v4 to v4.1.6
- TUN-11048: Keep package-manager marker across RPM upgrades
- Remove unnecessary comment
- ci: enable in-build container scanning
- TUN-11018: Align prechecks with regular cloudflare connection

---

## 2026.10.5
_Released: 2026-10-27_

### 📦 Component & Version Matrix
- **Cloudflared Engine:** `2026.10.5` *(arm64 binary verified)*
- **Alpine Base Image:** `Alpine 3.24`
- **Official Links:** [GitHub Release 2026.10.5](https://github.com/cloudflare/cloudflared/releases/tag/2026.10.5) • [Cloudflared Changelog](https://github.com/cloudflare/cloudflared/blob/master/CHANGES.md)

### 🔐 Binary Integrity (Raspberry Pi 5 - aarch64)
- **Binary:** `cloudflared-linux-arm64`
- **SHA256:** `72e0d05a67e09da87cf495e409a28c3cc5994dd23fc66a982eebea6a55923b7d`

### 🚀 What's Changed in Cloudflared 2026.10.5
- Release 2026.10.5
- TUN-10996: Allow for validating config from stdin
- TUN-11015: Ignore unchanged fields in QUIC MetricsUpdated events
- VULN-183456: Bump github.com/go-chi/chi/v5 to v5.5.0

---

