# 🚀 HASS Pro Add-ons — Raspberry Pi 5 (`aarch64` & `amd64`)

![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20AMD64-blue?style=for-the-badge&logo=raspberrypi)
![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%26%20AppArmor-success?style=for-the-badge&logo=cloudflare)
![Auto Update](https://img.shields.io/badge/Upstream%20Sync-Automated%20CI%2FCD-orange?style=for-the-badge&logo=githubactions)

A high-performance Home Assistant add-on repository, designed and tuned specifically for the **Raspberry Pi 5 (NVMe SSD)**. It syncs automatically with official upstream sources through GitHub Actions, featuring a build-safety gate (**Zero-Broken-Build**), a visual report (**CI/CD Execution Dashboard**), and automatic connection recovery (**Self-Healing Watchdog**).

---

## 📦 Add-ons in this Repository

| Add-on | Slug | Port / Interface | Core Features |
| :--- | :--- | :--- | :--- |
| **⚡ Cloudflared Pro** | `cloudflared` | Zero Trust Tunnel | Dual-Stack IPv4/IPv6, Remote Token & Local Ingress |
| **🛡️ Tailscale Pro** | `tailscale` | Ingress (`5252`) | Mesh VPN, Subnet Router (`192.168.68.0/24`), Exit Node |
| **🌐 OmniDrive Pro** | `omnidrive_pro` | `8090`, `445`, `2222`, `2121` & Ingress (`8099`) | Multi-Protocol Storage Hub (WebDAV, SMB, SFTP, FTP), iOS Glass UI, Cloud IDE, Web Terminal, Disk Analytics & Share Links |

---

### 1. ⚡ Cloudflared Pro (`cloudflared`)
A Zero Trust Edge Tunnel solution that requires no open ports and supports IPv4/IPv6 Dual-Stack side by side.
- **Automatic updates:** Syncs directly with `cloudflare/cloudflared` (verifies the binary returns `HTTP 200 OK` before upgrading).
- **Connection resilience:** Built-in Watchdog that checks link health and restarts the tunnel automatically when the connection drops.
- **Multiple modes:** Manage through a Remote Token (Zero Trust Dashboard) or Local Ingress directly in the Home Assistant UI.
- **Multilingual:** Automatically switches between Vietnamese and English based on the system language.

---

### 2. 🛡️ Tailscale Pro (`tailscale`)
A fast Mesh VPN (WireGuard) that acts as a **Subnet Router** (`192.168.68.0/24`) and **Exit Node** for your entire home network.
- **Instant sync:** Pulls directly from `tailscale/tailscale` as soon as a release is published (verifies the `linux/arm64` architecture and source before updating).
- **Full Web UI (Ingress):** Embeds the Tailscale Web Client control panel in the Home Assistant sidebar (port `5252`).
- **Raspberry Pi 5 tuning:** Automatically enables `rx-udp-gro-forwarding` on the physical network interface for maximum throughput.
- **Health check:** Monitors `BackendState` and the connection to the coordination server (DERP/Control Plane), reconnecting automatically if it hangs.
- **Multilingual:** Full support for Vietnamese (`vi.yaml`) and English (`en.yaml`), selected automatically from the system language.

---

### 3. 🌐 OmniDrive Pro (`omnidrive_pro`)
An all-in-one **Multi-Protocol Storage Hub**, **Cloud Code IDE**, and **System Operations Suite** wrapped in an **iOS Glassmorphism Dark UI**. It unlocks the entire Home Assistant file system across every major file transfer protocol and operating system.

- **Multi-Protocol Storage Gateway (Unified Credentials & Shares):**
  - **WebDAV (Port `8090` & Ingress `8099`):** Full WebDAV Class 1 & 2 (`PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `COPY`, `MOVE`, `LOCK`, `UNLOCK`) with a `davlock` memory zone, compatible with Cloudflare Tunnel, macOS Finder, Windows Explorer, and Rclone.
  - **SMB / Samba v3 (Port `445`):** Native network drive mounting for **iOS/iPadOS Files ("Connect to Server")**, **macOS Finder (`smb://`)**, **Windows Explorer (`\\ip\`)**, and direct 4K media streaming to **Infuse / VLC** on Apple TV.
  - **SFTP Server (Port `2222`):** Encrypted SSH File Transfer Protocol for pro clients including **Termius, Cyberduck, Transmit, FileZilla, WinSCP, and FE File Explorer**.
  - **FTP Server (Port `2121`, Passive `21000–21002`):** High-speed LAN transfers for legacy apps, network scanners, and cameras.
  - **Built-in Connect Hub:** 1-tap copy cards in the Web UI displaying live connection URLs for all active protocols.

- **Hybrid Dual-Authentication & iOS Glass Login UI:**
  - **Web Browser Sessions:** Replaces ugly browser Basic Auth popups with a sleek **iOS Glassmorphism Login Page (`login.html`)** featuring `HMAC-SHA256` 30-day session cookies, password visibility toggle, and 1-tap Sign Out.
  - **Native App Compatibility:** Seamlessly falls back to standard HTTP Basic Auth in the background when accessed by native WebDAV clients (Finder, Explorer, iOS Files).

- **Professional Cloud Code IDE (Ace Editor):**
  - **Syntax Highlighting & Mini Map:** One Dark theme for `YAML`, `Python`, `JSON`, `Shell/Bash`, `JS/TS`, `HTML/CSS`, `PHP`, `SQL`, `Markdown`, and `Dockerfile`, paired with a live right-hand **Code Mini Map** for fast scrolling through long configurations.
  - **Multi-Cursor Editing & Mobile Toolbar:** Supports `Alt/Option + Click` and a dedicated **`✚ Cursor`** chip for simultaneous multi-line edits, alongside `Undo`, `Redo`, `Find & Replace`, `Tab`, `Comment (#)`, font zoom **`A+` / `A-`**, `Word Wrap`, and **`⛶ Zen Mode`**.
  - **Home Assistant YAML Linter (`js-yaml`):** Real-time syntax validation with native support for Home Assistant tags (`!include`, `!secret`, `!include_dir_merge_named`, `!env_var`) and gutter error annotations.
  - **Anti-Blank Guard & iOS Glass Dialogs:** Tracks unsaved edits (`● UNSAVED`) and prompts with custom iOS Glass confirmation dialogs before saving, closing with unsaved changes, or deleting files.
  - **Git Status Integration:** Automatically detects Git repositories, displays the active branch pill (`⎇ main`), and marks modified (`🟡`) or newly added/untracked (`🟢`) files directly in the file list.

- **Advanced Document, Media & Binary Viewers:**
  - **Direct `PDF.js` Canvas Viewer:** Renders multi-page PDF documents directly in the modal with page navigation and zoom controls (`−` / `＋`) without downloading.
  - **Pro Media Player & Background Audio:** Plays video and audio (`.mp3`, `.wav`, `.m4a`, `.flac`, `.mp4`, `.mov`) with `↺ -10s` / `↻ +10s` seek, playback speed control (`0.5x` ➔ `2.0x`), and an **Apple Music-style Mini Player** that continues playing audio in the background while browsing folders or editing code.
  - **Hex / Binary & Archive Inspector:** Inspects binary/database files (`.db`, `.sqlite`, `.bin`) in side-by-side `HEX + ASCII` format, and previews `.zip` and Home Assistant `.tar` backups without extraction.

- **System Operations, Sharing & Security Suite:**
  - **Integrated Web Terminal (`xterm.js`):** Run shell commands (`df -h`, `ls -la`, `git status`, `git pull`) directly inside the browser.
  - **Storage Analytics (Donut Chart):** Visualizes total NVMe disk usage, free space, and per-folder size breakdown (`/config`, `/backup`, `/media`, `/share`, etc.).
  - **1-Tap Quick Zip Snapshot:** Compresses `/config` or `Automations & Scripts` into a timestamped `.zip` archive inside `/backup` before making risky edits.
  - **Temporary Expiry Share Links (`/s/<token>`):** Generate public download links for any **file or folder** (folders are automatically zipped on the fly) with custom expiration (`1 Hour`, `6 Hours`, `24 Hours`, `7 Days`) without exposing WebDAV passwords.
  - **Security Audit Log:** Real-time activity log tracking logins, file edits (`PUT`), deletions (`DELETE`), snapshots, and share-link downloads.

---

## 🔄 Automatic Update & Versioning Rules (CI/CD Versioning)

The GitHub Actions pipeline in this repository runs fully automatically under the following rules:
- **Major version bump (`2.x.x` ➔ `3.0.0`):** When an upstream vendor (Cloudflare, Tailscale, Alpine/Nginx/Samba) publishes a new release.
- **Patch version bump (`3.0.0` ➔ `3.0.1`):** When configuration, scripts, translations, or the internal UI of the repository are updated.
- **Zero-Broken-Build & Visual Dashboard:** Every update is verified with a full Docker build (`docker build`) and a visual report is published to the GitHub Actions Summary before the release commit is pushed to the `main` branch.

---

## 🛠️ Installation Guide for Home Assistant

1. Open **Home Assistant** -> **Settings** -> **Add-ons** -> **Add-on Store**.
2. Click the **three-dot menu (`⋮`)** in the top right corner -> choose **Repositories**.
3. Paste the following URL and click **Add**:
   ```text
   [https://github.com/boystyle2010/ha-addons](https://github.com/boystyle2010/ha-addons)
