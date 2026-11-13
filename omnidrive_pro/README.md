# Home Assistant Add-on: OmniDrive Pro

![Version](https://img.shields.io/badge/version-1.0.48-blue.svg)
![Nginx](https://img.shields.io/badge/nginx-1.30.6--r0-009639.svg)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg)
![Protocols](https://img.shields.io/badge/protocols-WebDAV%20%7C%20SMB%20%7C%20SFTP%20%7C%20FTP-8b5cf6.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![AppArmor](https://img.shields.io/badge/apparmor-enabled-success.svg)
![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)

All-in-one Multi-Protocol Storage Hub (**WebDAV, SMB/Samba, SFTP, FTP**), iOS Glassmorphism File Manager, Cloud Code IDE & System Operations Suite for Home Assistant, tuned for Raspberry Pi 5.

## About

**OmniDrive Pro** transforms your Home Assistant into a high-speed, security-hardened multi-protocol storage server and full-featured Cloud IDE. Mount all your Home Assistant directories as a native network drive inside **iOS/iPadOS Files**, **macOS Finder**, **Windows Explorer**, **Infuse / VLC**, or **SFTP/FTP clients** (over LAN, Tailscale, or Cloudflare Zero Trust Tunnels), or manage files, run terminal commands, and edit configuration code directly from the Home Assistant sidebar via Ingress.

This add-on tracks official Alpine Linux and Nginx upstream releases and updates itself automatically via GitHub Actions after passing strict `docker build` verification checks.

## ⚠️ Read before you start

> 1. **Change the default password.** The default password is public (`changeme_strong_password`). Anyone who guesses it gets access to your HA configuration files and terminal. Change it in the **Add-on Configuration** tab.
> 2. **Root Access and Web Terminal are powerful.** By default, `root_access` is `false` and `enable_terminal` is `true`. If you enable `root_access`, file operations run as root. If you use the Web Terminal, you can execute root commands inside the container. Ensure your Home Assistant instance is not exposed directly to the internet without strong authentication (e.g., use Cloudflare Zero Trust or a VPN).
> 3. **Check ports.** This add-on requires ports `8090`, `445`, `2222`, `2121`, and `21000-21002`. If Samba (`445`) is already used by another add-on or the host, change the port mapping.
> 4. **Password Management Quirk:** You can change your password either in the HA Add-on Configuration or via the Web UI (Security -> Change Password). If you change it via the Web UI, it is immediately hashed. However, if you later open the HA Configuration tab and click "Save" without changing the password field, HA will overwrite your Web UI password with the plaintext one in the config. *Always update your password in the HA Configuration tab if you want to make it permanent.*

## Features

- **4-in-1 Multi-Protocol Storage Gateway:**
  - **WebDAV (Port `8090` & Ingress `8099`):** Full WebDAV Class 1 & 2 (`dav-ext` + `davlock`) for Cloudflare Tunnel, macOS Finder, Windows Explorer, and Rclone.
  - **SMB / Samba v3 (Port `445`):** Native network drive mounting for **iOS/iPadOS Files**, **macOS Finder (`smb://`)**, **Windows Explorer (`\\ip\`)**, and 4K streaming to **Infuse / VLC**.
  - **SFTP Server (Port `2222`):** Encrypted SSH File Transfer Protocol for **Termius, Cyberduck, Transmit, FileZilla, WinSCP, and FE File Explorer**.
  - **FTP Server (Port `2121`, Passive `21000–21002`):** High-speed LAN file transfers for legacy apps, network scanners, and cameras.
- **Hybrid Dual-Auth & iOS Glass Login UI:** Replaces ugly browser Basic Auth popups with a sleek **iOS Glassmorphism Login Page (`login.html`)** featuring `HMAC-SHA256` 30-day session cookies, while seamlessly supporting standard HTTP Basic Auth in the background for native WebDAV apps.
- **Unified System Storage Access:** Full Read/Write access to `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, and `ssl` under a single mount point.
- **Professional Ace Code IDE:**
  - Syntax highlighting (One Dark theme) for YAML, Python, JSON, Shell, JS/TS, HTML/CSS, PHP, SQL, Markdown, and Dockerfile.
  - **Code Mini Map & Multi-Cursor (`✚ Cursor`):** Live right-hand code minimap for fast scrolling through long YAML files, plus multi-cursor editing (`Alt/Option + Click`).
  - **Home Assistant YAML Linter (`js-yaml`):** Real-time validation supporting Home Assistant tags (`!include`, `!secret`, `!include_dir_merge_named`, `!env_var`) with gutter annotations.
  - **Anti-Blank Guard & Unsaved Changes Protection:** Tracks unsaved edits (`● UNSAVED`) and prompts with custom iOS Glass confirmation dialogs before saving, closing with unsaved changes, or deleting files.
  - **Git Status Integration:** Displays the active branch badge (`⎇ main`) and marks modified (`🟡`) or newly added/untracked (`🟢`) files directly in the file list.
- **Advanced Document, Media & Binary Viewers:**
  - **Direct `PDF.js` Canvas Viewer:** Multi-page PDF rendering with page navigation and zoom controls (`−` / `＋`) without downloading.
  - **Pro Media Player & Background Audio:** Video/audio playback with `↺ -10s` / `↻ +10s` seek, speed control (`0.5x` ➔ `2.0x`), and an **Apple Music-style Mini Player** for background audio playback while browsing or coding.
  - **Hex / Binary & Archive Inspector:** Inspects binary/database files (`.db`, `.sqlite`, `.bin`) in side-by-side `HEX + ASCII` view, and previews `.zip` and Home Assistant `.tar` backups without extraction.
- **System Operations, Sharing & Security Suite:**
  - **Integrated Web Terminal (`xterm.js`):** Execute shell and Git commands (`df -h`, `ls -la`, `git status`, `git pull`) directly from the Web UI (can be disabled in config).
  - **Storage Analytics (Donut Chart):** Visualizes total disk capacity, used/free space, and per-folder storage breakdown.
  - **1-Tap Quick Zip Snapshot:** Instant `.zip` backup of `/config` or `Automations & Scripts` straight into `/backup` before editing code.
  - **Temporary Expiry Share Links (`/s/<token>`):** Generate public download links for any file or folder (folders are automatically zipped). Set custom expiry (1 hour to 365 days), limit **max downloads**, and protect with a **password**.
  - **Security Audit Log & Devices:** View real-time file modifications and logins. See all signed-in devices, revoke access instantly, and change passwords securely (hashed with PBKDF2).

## 🔒 Security Notes

OmniDrive Pro is powerful by design, so please harden it:

- **Change the default password** immediately in the add-on configuration.
- **The Web Terminal runs shell commands as root** inside the container. Disable it (`enable_terminal: false`) if you don't need it, or restrict access to your HA instance.
- **Do not publish HA ports directly to the internet.** Prefer a VPN (Tailscale/WireGuard) or Cloudflare Zero Trust Tunnel.
- **Share links (`/s/<token>`) are public** to anyone with the URL until they expire or are revoked. Always set a short expiry, download limit, and password for sensitive files.
- **Passwords are hashed on disk.** The add-on strips plaintext passwords from `/data/options.json` on startup and replaces them with strong PBKDF2 hashes.
