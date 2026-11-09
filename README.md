# 🚀 HASS Pro Add-ons — Raspberry Pi 5 (`aarch64` & `amd64`)

![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20AMD64-blue?style=for-the-badge&logo=raspberrypi)
![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%26%20AppArmor-success?style=for-the-badge&logo=cloudflare)
![Auto Update](https://img.shields.io/badge/Upstream%20Sync-Automated%20CI%2FCD-orange?style=for-the-badge&logo=githubactions)

A high-performance Home Assistant add-on repository, designed and tuned specifically for the **Raspberry Pi 5 (NVMe SSD)**. It syncs automatically with the official upstream sources through GitHub Actions, with a build-safety gate (**Zero-Broken-Build**), a visual report (**CI/CD Execution Dashboard**) and automatic connection recovery (**Self-Healing Watchdog**).

---

## 📦 Add-ons in this Repository

| Add-on | Slug | Port / Interface | Core Features |
| :--- | :--- | :--- | :--- |
| **⚡ Cloudflared Pro** | `cloudflared` | Zero Trust Tunnel | Dual-Stack IPv4/IPv6, Remote Token & Local Ingress |
| **🛡️ Tailscale Pro** | `tailscale` | Ingress (`5252`) | Mesh VPN, Subnet Router (`192.168.68.0/24`), Exit Node |
| **📂 WebDAV Server Pro** | `webdav_pro` | `8090` & Ingress (`8099`) | WebDAV Gateway, iOS 27 Dark UI, Cloud IDE, YAML Linter & Archive Inspector |

---

### 1. ⚡ Cloudflared Pro (`cloudflared`)
A Zero Trust Edge Tunnel solution that needs no open ports and supports IPv4/IPv6 Dual-Stack side by side.
- **Automatic updates:** Syncs directly with `cloudflare/cloudflared` (verifies the binary returns `HTTP 200 OK` before upgrading).
- **Connection resilience:** Built-in Watchdog that checks link health and restarts the tunnel when the connection drops.
- **Multiple modes:** Manage it through a Remote Token (Zero Trust Dashboard) or a Local Ingress directly in the Home Assistant UI.
- **Multilingual:** Automatically switches between Vietnamese and English based on the system language.

---

### 2. 🛡️ Tailscale Pro (`tailscale`)
A fast Mesh VPN (WireGuard) that acts as a **Subnet Router** (`192.168.68.0/24`) and **Exit Node** for your entire home network.
- **Instant sync:** Pulls directly from `tailscale/tailscale` as soon as a release is published (verifies the `linux/arm64` architecture and the source before updating).
- **Full Web UI (Ingress):** Embeds the Tailscale Web Client control panel in the Home Assistant sidebar (port `5252`).
- **Raspberry Pi 5 tuning:** Automatically enables `rx-udp-gro-forwarding` on the physical network interface for maximum throughput.
- **Health check:** Monitors the `BackendState` and the connection to the coordination server (DERP/Control Plane), and reconnects automatically if it hangs.
- **Multilingual:** Full support for Vietnamese (`vi.yaml`) and English (`en.yaml`), selected automatically from the system language.

---

### 3. 📂 WebDAV Server Pro (`webdav_pro`)
A high-speed WebDAV file server combined with a **Cloud Code IDE** and an **iOS 27 Files Dark UI**. It unlocks the entire Home Assistant file system for iOS/iPadOS Files, macOS Finder, Windows Explorer, Rclone and Cloudflare Tunnel.
- **Full access (Unified Root):** Complete Read/Write access to `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share` and `ssl` from a single mount point.
- **Native OS compatibility (WebDAV Class 1 & 2):** Includes `nginx-mod-http-dav-ext` and a `davlock` file-lock memory zone, with full support for `PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `COPY`, `MOVE`, `LOCK` and `UNLOCK`.
- **Cloud Code IDE (Ace Editor):**
  - Syntax highlighting (One Dark theme) for `YAML`, `Python`, `JSON`, `Shell/Bash`, `JavaScript`, `TypeScript`, `HTML/CSS`, `PHP`, `SQL`, `Markdown`, `Dockerfile` and more.
  - **Real-time YAML validation (`js-yaml` linter):** Detects syntax and indentation errors in YAML and reports the exact line number before saving, protecting Home Assistant from broken configuration.
  - **Mobile coding toolbar:** Built-in `Undo`, `Redo`, `Find & Replace`, `Tab (2 spaces)`, `Toggle Comment (#)`, font size **`A+` / `A-`**, `Word Wrap` and full-screen **`⛶ Zen Mode`**.
- **Live Markdown Renderer (`👁️ Preview`):** Automatically shows a GitHub Dark style preview for `.md` files (`README.md`, `CHANGELOG.md`, `DOCS.md`), with a quick switch back to code editing.
- **Archive & Backup Inspector (`.tar` / `.zip`):** Quickly browse the file structure inside Home Assistant backups (`.tar`) or `.zip` files right in the browser, without downloading them.
- **iOS 27 Files-style file manager (Ingress port `8099`):**
  - Switch between **List** and **Grid** views, sort (`Name A–Z`, `Newest`, `Largest`), search instantly, and tap the breadcrumbs to copy the path (Breadcrumbs Copy Path).
  - Supports **New File**, **New Folder**, **Duplicate**, **Rename**, **Copy**, **Cut & Paste** across folders, and **Multi-Select Batch Operations**.
  - **Flexible uploads:** Upload multiple files with a percentage (`%`) progress bar, **Drag & Drop** directly into the browser, and quick paste of images/files from the clipboard (`Cmd/Ctrl + V`).
  - **Quick Look Media & PDF Preview:** Preview images, play video/audio (`.mp3`, `.wav`, `.m4a`) and read `PDF` documents right in the interface.
- **Maximum security rating:** Meets the Supervisor security standard with an isolated `apparmor.txt` profile (S6-Overlay v3), Bcrypt-hashed passwords (`htpasswd -B`), brute-force protection (`limit_req_zone`) and per-folder `read_only` / `allowed_users` permissions.

---

## 🔄 Automatic Update & Versioning Rules (CI/CD Versioning)

The GitHub Actions pipeline in this repository runs fully automatically under the following rules:
- **Major version bump (`1.0.x` ➔ `2.0.0`):** When an upstream vendor (Cloudflare, Tailscale, Alpine/Nginx) publishes a new release.
- **Patch version bump (`1.0.0` ➔ `1.0.1`):** When the configuration, scripts or the internal UI of the repository are changed.
- **Zero-Broken-Build & Visual Dashboard:** Every update is verified with a Docker build (`docker build`) and a visual report is published to the GitHub Actions Summary before the release commit is pushed to the `main` branch.

---

## 🛠️ Installation Guide for Home Assistant

1. Open **Home Assistant** -> **Settings** -> **Add-ons** -> **Add-on Store**.
2. Click the **three-dot menu** in the top right corner -> choose **Repositories**.
3. Paste the following URL and click **Add**:
   ```text
   https://github.com/boystyle2010/ha-addons
   ```
