# Changelog

## 2.0.4
_Released: 2026-11-22_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.3` ➡️ **`v2.0.4`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.4` (`sha256:6c6fdb64927a107efc2df996d9b832a131eabe3d5f5a077a0301c32622e1d9a4`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.4` (`sha256:2ab704693454daaa149212dde5f32d187f626127f325de9fcd0b1764d84da3af`)

### 🚀 What's Changed
- **Update:** feat(omnidrive_pro): js-yaml 5 with full Home Assistant YAML 1.1 compatibility

---

## 2.0.3
_Released: 2026-11-22_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.2` ➡️ **`v2.0.3`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.3` (`sha256:e42ada4bd3a923e2c63cdec9d14a0d32b2cc56f0c62d1698dd782e01e4d163cf`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.3` (`sha256:60adb319c8e2962031e3cbcd8c39dc743e502c50a0ab07f2c1979feaed7bd52c`)

### 🚀 What's Changed
- **Update:** ci: Node 24 actions, automatic security & library updates without pull requests
- **Security:** Rebuilt on the latest Alpine `3.24` security updates (Samba `4.23.8-r0`, OpenSSH, vsftpd, OpenSSL, Python `3.14.10-r1`).

---

## 2.0.2
_Released: 2026-11-22_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.1` ➡️ **`v2.0.2`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r1`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.2` (`sha256:43cc110dcc67403377da8fb6629f081af9028d0d722f11cc062e79e04ff5f31b`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.2` (`sha256:d58aa9d95eb3a6f56b8322ef2efaa31a8eb9e006a36a3fcf3e3f2923dd67efff`)

### 🚀 What's Changed
- **Update:** fix: self-hosted Web UI libraries, auto-restart services, private Cloudflared credentials, safer Tailscale defaults

---

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
