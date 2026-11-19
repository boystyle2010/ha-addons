# Changelog

## 2.0.0
_Released: 2026-11-19_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v1.0.69` ➡️ **`v2.0.0`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` ➡️ **`Alpine 3.24`** *(Home Assistant official base)*
- **Nginx Engine:** `1.30.6-r0` ➡️ **`1.30.7-r0`**
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.0` (`sha256:a9f7fe0c92fd61dad3b534749cc9b35eacb2b934e726fde68640a32a2865930a`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.0` (`sha256:488533ff0beee1429177a6383594fa9ee2c3087e9b1c39dabbe982e1133fa01a`)

### 🚀 What's Changed
- Upgraded Nginx to `1.30.7-r0` on Home Assistant Alpine Base `3.24`.
- Refreshed multi-protocol engines (WebDAV, Samba, OpenSSH, vsftpd) with latest upstream security patches.
