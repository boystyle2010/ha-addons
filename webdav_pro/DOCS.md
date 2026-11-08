# Home Assistant Add-on: WebDAV Server Pro — Documentation

**WebDAV Server Pro** combines a compliant **Class 1 & 2 WebDAV Server** with an **iOS-styled File Manager & Cloud Code IDE** built directly into your Home Assistant sidebar.

---

## 🛠️ Built-in Web UI & Code IDE (Ingress)

Click **WebDAV Pro** in your Home Assistant sidebar to open the full workspace without entering a password:

1. **Ace Code Editor (Syntax Highlighting):**
   - Tap any `.yaml`, `.py`, `.sh`, `.json`, `.js`, `.html`, `.css`, `.conf`, `.log`, or `.txt` file to open the built-in IDE.
   - Includes **Undo / Redo**, **Find & Replace (`🔍 Find`)**, **2-Space Tab Indentation**, **Line Comment Toggle (`# Toggle`)**, **Word Wrap**, and **YAML Syntax Validation** before saving.
   - Press `Cmd + S` (macOS) / `Ctrl + S` (Windows) or tap **Save** to write changes directly via WebDAV `PUT`.
2. **Live Markdown Preview (`👁️ Preview`):**
   - Opening any `.md` file automatically renders formatted GitHub-flavored Markdown. Tap **✏️ Edit Code** in the top bar to switch between raw code and live preview.
3. **File & Batch Management:**
   - **Action Bar:** Create a **New File**, **New Folder**, or **Upload** multiple files with a real-time percentage progress bar.
   - **Context Menu (`•••`):** Open in Code Editor, Copy, Move (Cut), Duplicate, Rename, Copy Full Path, Download, or Delete.
   - **Multi-Select Mode (`Select`):** Select multiple files and folders at once to perform batch Copy, Move, or Delete operations.

---

## 🌐 Connecting External Devices (WebDAV Port `8080`)

### 1. Local Network (LAN)
- **Unified Root URL:** `http://<HOME_ASSISTANT_IP>:8080/`
- **Individual Share URL:** `http://<HOME_ASSISTANT_IP>:8080/config/`

### 2. Remote Access via Cloudflare Zero Trust Tunnel
1. Open **Cloudflare Zero Trust** -> **Networks** -> **Tunnels**.
2. Add a Public Hostname (e.g., `dav.yourdomain.com`) pointing to `http://localhost:8080`.
3. Mount `https://dav.yourdomain.com/` from anywhere in the world over HTTPS.

### 3. Mounting on Apple & Windows Devices
- **iOS / iPadOS (Files App):** Tap `•••` -> **Connect to Server** -> Enter URL -> Authenticate with your configured `users` credentials.
- **macOS (Finder):** Press `Cmd + K` -> Enter URL -> Connect.
- **Windows (File Explorer):** Right-click **This PC** -> **Map network drive** -> Enter URL.

---

## ⚙️ Configuration Reference

| Option | Default | Description |
| :--- | :--- | :--- |
| `unified_root` | `true` | Mounts all shares under `/` so you can move files across directories. Set to `false` to enforce per-share `read_only` or `allowed_users` rules. |
| `ssl` | `false` | Enables native HTTPS on port `8080`. Keep `false` when using Cloudflare Tunnel. |
| `certfile` | `fullchain.pem` | SSL certificate in `/ssl`. |
| `keyfile` | `privkey.pem` | SSL private key in `/ssl`. |
| `max_upload_size` | `"0"` | Maximum file upload size (`"0"` = unlimited). |
| `fancy_ui` | `true` | Enables the iOS Dark Mode Web UI and built-in Code IDE. |
| `show_dotfiles` | `true` | Shows hidden system files and folders (e.g., `.storage`). |
| `log_level` | `info` | Nginx log verbosity (`debug`, `info`, `notice`, `warn`, `error`). |
| `users` | `[...]` | List of `{ username, password }` accounts (hashed with Bcrypt). |
| `shares` | `[...]` | Mapped directories (`config`, `addon_configs`, `addons`, `backup`, `media`, `share`, `ssl`). |
