# Home Assistant Add-on: WebDAV Server Pro

A high-performance, security-hardened **WebDAV Server** for Home Assistant built on Alpine Linux and Nginx (`ngx_http_dav_ext_module` & `ngx_http_fancyindex_module`). Designed for seamless file management across iOS/iPadOS Files, macOS Finder, Windows Explorer, Rclone, and Cloudflare Zero Trust Tunnels.

---

## ✨ Key Features

- **Full WebDAV Class 1 & 2 Compliance:** Supports `PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `COPY`, `MOVE`, `LOCK`, and `UNLOCK` with shared memory lock zones for native macOS Finder and iOS Files compatibility.
- **Unified System Access:** Unlocks read/write access to all Home Assistant directories:
  - `/config` (`/homeassistant`)
  - `/addon_configs`
  - `/addons`
  - `/backup`
  - `/media`
  - `/share`
  - `/ssl`
- **Built-in Dark Mode Web UI & Ingress:** Features a custom **FancyIndex Dark Theme** with real-time file filtering, accessible directly from the Home Assistant sidebar via Ingress (zero login prompts) or any web browser.
- **Multi-User & Granular Permissions:** Bcrypt-encrypted authentication (`htpasswd -B`), built-in brute-force rate limiting, per-folder Read-Only toggles, and user-level access restrictions.
- **Maximum Security Rating:** Runs with a dedicated **AppArmor** profile without requiring privileged container permissions.

---

## 🚀 Connection Guide

### 1. Local Network (LAN)
Connect using your favorite WebDAV client or browser:
- **Unified Root URL:** `http://<HOME_ASSISTANT_IP>:8080/`
- **Direct Folder URL:** `http://<HOME_ASSISTANT_IP>:8080/config/`

### 2. Remote Access via Cloudflare Tunnel (Zero Trust)
Because WebDAV operates purely over HTTP/HTTPS, it works seamlessly over Cloudflare Tunnels without opening router ports or running a VPN:
1. Open your **Cloudflare Zero Trust Dashboard** -> **Networks** -> **Tunnels**.
2. Add a **Public Hostname** (e.g., `dav.yourdomain.com`).
3. Set the Service Type to **HTTP** and URL to `localhost:8080` (or `<HOME_ASSISTANT_IP>:8080`).
4. Connect from anywhere using `https://dav.yourdomain.com/`.

### 3. Connecting from Apple Devices & PC
- **iPhone / iPad (Files App, FE File Explorer, Documents):** Tap the `...` menu -> **Connect to Server** -> Enter `http://<HOME_ASSISTANT_IP>:8080/` (or your `https://` domain) -> Enter your configured username and password.
- **macOS (Finder):** Press `Cmd + K` -> Enter `http://<HOME_ASSISTANT_IP>:8080/` -> Click **Connect**.
- **Windows (File Explorer):** Right-click **This PC** -> **Map network drive** -> Enter the URL and check *Connect using different credentials*.

---

## ⚙️ Configuration Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `unified_root` | `true` | Combines all configured shares under `/` so you can mount a single drive and move files across directories. Set to `false` to enforce individual `read_only` or `allowed_users` rules per share. |
| `ssl` | `false` | Enables native HTTPS on port `8080` using certificates in `/ssl`. Leave `false` if using Cloudflare Tunnel or an external reverse proxy. |
| `certfile` | `fullchain.pem` | SSL certificate filename in `/ssl`. |
| `keyfile` | `privkey.pem` | SSL private key filename in `/ssl`. |
| `max_upload_size` | `"0"` | Maximum allowed upload size (`"0"` = unlimited). |
| `fancy_ui` | `true` | Enables the modern Dark Mode Web UI with instant search. |
| `show_dotfiles` | `true` | Displays hidden files and folders (e.g., `.storage`). |
| `log_level` | `info` | Nginx error log verbosity (`debug`, `info`, `notice`, `warn`, `error`). |
| `users` | `[...]` | List of `{ username, password }` objects. |
| `shares` | `[...]` | List of mapped directories `{ name, path, read_only, allowed_users }`. |
