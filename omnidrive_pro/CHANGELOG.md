# Changelog

## 3.0.2
_Released: 2026-11-27_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v3.0.1` ➡️ **`v3.0.2`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.8-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r2`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:3.0.2` (`sha256:86384d05befed21185d7c141da9a8ce2037826cbe365cf06ccd8d9914d793a24`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:3.0.2` (`sha256:084d89df06597ec8e1557c216abde0996e95df7e91f1f5cb1eb2577e1aea5441`)

### 🚀 What's Changed
- **Security & Core Engine:** Hardened RBAC (`admin`/`user`), enforced `allowed_users`/`read_only` isolation, blocked `X-WPro-Ingress` spoofing, and added graceful service shutdown.

---

## 3.0.1
_Released: 2026-11-27_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v3.0.0` ➡️ **`v3.0.1`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.8-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r2`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:3.0.1` (`sha256:979a9536fb179643deb731831ddf9bd471c164cdf5e85619672f571a0fb63144`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:3.0.1` (`sha256:3de170c7a4258243449ab7c15470cba0673cce71ef8b65dcc4f4d68e24d56614`)

### 🚀 What's Changed
- **Security & Core Engine:** Hardened RBAC (`admin`/`user`), enforced `allowed_users`/`read_only` isolation, blocked `X-WPro-Ingress` spoofing, and added graceful service shutdown.

---

## 3.0.0
_Released: 2026-11-25_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.5` ➡️ **`v3.0.0`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` ➡️ **`Alpine 3.24`** *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0` ➡️ **`1.30.8-r0`**
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r2`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:3.0.0` (`sha256:eacc0b4993a5b9fc42695d273e7e4aa4fe4f519f5034faab9157537a0e5abbbf`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:3.0.0` (`sha256:7e0ea59b20f25552fce4b6f8becc60ff6031a743c52d100a70de1d72ac2a5d18`)

### 🚀 What's Changed
- Upgraded Nginx to `1.30.8-r0` on Home Assistant Alpine Base `3.24`.
- Refreshed multi-protocol engines (WebDAV, Samba, OpenSSH, vsftpd) with latest upstream security patches.

---

## 2.0.5
_Released: 2026-11-24_

### 📦 Component & Version Matrix
- **Add-on Release:** Bumped from `v2.0.4` ➡️ **`v2.0.5`**
- **Supported Architectures:** `aarch64` (ARM64) & `amd64` (x86_64) *(Pre-built GHCR Package)*
- **Alpine Base Image:** `Alpine 3.24` *(Home Assistant official base)*
- **Nginx Engine:** `1.30.7-r0`
- **Protocol Stack:** `Samba 4.23.8-r0` • `OpenSSH 10.3_p1-r2` • `vsftpd 3.0.5-r3` • `Python 3.14.10-r2`

### 🔐 Package Integrity (GHCR Multi-Arch)
- **ARM64 (`aarch64`):** `ghcr.io/boystyle2010/omnidrive_pro-aarch64:2.0.5` (`sha256:afc78424f67b97b6c2b2cda556568201be95734c438698986e827fde56094bf5`)
- **AMD64 (`x86_64`):** `ghcr.io/boystyle2010/omnidrive_pro-amd64:2.0.5` (`sha256:a9ea8d66bb00a8ba624993d48f5840c9aafa15c2a4a00c98e0e3b635f49f663c`)

### 🚀 What's Changed
- **Security:** Rebuilt on the latest Alpine `3.24` security updates (Samba `4.23.8-r0`, OpenSSH, vsftpd, OpenSSL, Python `3.14.10-r2`).
- **Web UI library:** `marked` `18.2.1` ➡️ **`18.3.0`**

---

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
