# Changelog

## 2.0.1
_Released: 2026-11-22_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.0` ➡️ **`v2.0.1`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.1` (`sha256:f8232fbaf2f148427f2a80c8be6ed0bed0d7d92ee291c9ba9596ac3aca8fe72f`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.1` (`sha256:6fe3767a4732e088a130cb9b330d617d8177f1d460f5f9559087c7516aa9e461`)

### 🚀 What's Changed
- **Update:** fix(omnidrive_pro): security hardening (share ACL bypass, git RCE, XSS, DoS)

---

## 2.0.0
_Released: 2026-11-19_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v1.0.69` ➡️ **`v2.0.0`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` ➡️ **`Alpine 3.24`** *(Home Assistant official base)*
- **Nginx Engine:** `1.30.6-r0` ➡️ **`1.30.7-r0`**
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.0` (`sha256:6701845d21ecba939b0120e7ee1d1109d0db158f236b2092fba1238e33b1091d`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.0` (`sha256:71a6525b3ce5a05fb656ae32627cc3d265c3f9b6a0007ba87152bbad3402448f`)

### 🚀 What's Changed
- Upgraded Nginx to `1.30.7-r0` on Home Assistant Alpine Base `3.24`.
- Refreshed multi-protocol engines (WebDAV, Samba, OpenSSH, vsftpd) with latest upstream security patches.
