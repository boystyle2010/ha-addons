# Home Assistant Add-on: OmniDrive Pro — Documentation

**OmniDrive Pro** combines a **Multi-Protocol Storage Server (WebDAV, SMB/Samba, SFTP, FTP)** with an **iOS Glassmorphism File Manager, Cloud Code IDE & System Operations Suite** accessible directly from the Home Assistant sidebar (Ingress port `8099`) or via your custom domain (`8090`).

---

## 💻 1. Built-in Cloud IDE & File Manager (Web UI & Ingress)

Open **OmniDrive Pro** from your Home Assistant sidebar (or via your external WebDAV/Cloudflare URL) to access the workspace:

### A. Ace Code Editor, Mini Map & Home Assistant YAML Linter
- **Syntax Highlighting:** Tap any `.yaml`, `.yml`, `.py`, `.json`, `.sh`, `.js`, `.ts`, `.html`, `.css`, `.php`, `.sql`, `.conf`, `.ini`, `.toml`, `.log`, or `.txt` file to open the built-in IDE.
- **Home Assistant YAML Validation:** Live validation powered by `js-yaml` with full support for Home Assistant tags (`!include`, `!secret`, `!include_dir_merge_named`, `!env_var`). Syntax errors are highlighted directly in the line gutter.
- **Unsaved Changes & Anti-Blank Protection:**
  - An orange indicator dot (`●`) and `UNSAVED` badge appear as soon as you modify a file.
  - Tapping **Done** with unsaved edits opens an iOS Glass dialog asking whether to **Save & Close**, **Discard Changes**, or **Keep Editing**.
  - If a network error occurs while loading a file, saving is automatically locked to prevent accidental blank overwrites.
- **Coding Toolbar:**
  - `↶` / `↷`: Undo and Redo changes.
  - `Find`: Open the search and replace box inside the code editor.
  - `✚ Cursor`: Add a multi-cursor to the next occurrence (or hold `Alt/Option + Click` to place multiple cursors).
  - `⇥ Tab`: Insert a 2-space soft tab (standard Home Assistant YAML indentation).
  - `#`: Toggle line comments on or off.
  - `A+` / `A-`: Increase or decrease editor font size (persisted locally).
  - `↵ Wrap`: Toggle word wrapping.
  - `Map`: Toggle the right-hand **Code Mini Map** to scroll rapidly through thousands of lines of code.
  - `Zen`: Toggle Zen Fullscreen Mode (hides sub-toolbars to maximize coding space).
- **Keyboard Shortcuts:** Press `Cmd + S` (macOS) or `Ctrl + S` (Windows/Linux) to trigger the save confirmation dialog.

### B. Git Status Integration
- When browsing a folder inside a Git repository, the header displays the active branch pill (`⎇ main`).
- Modified files/folders are automatically badged with a yellow dot (`🟡`), and newly added/untracked items are badged with a green dot (`🟢`).

### C. Advanced Document, Media & Binary Viewers
- **Direct `PDF.js` Viewer:** Tapping any `.pdf` file renders pages directly onto a hardware-accelerated canvas with `◀ Prev`, `Next ▶`, and zoom (`−` / `＋`) controls.
- **Pro Media Player & Background Audio:**
  - Tapping video/audio files opens the iOS Media Player card with `0.5x` ➔ `2.0x` playback speed pills and `↺ -10s` / `↻ +10s` skip buttons.
  - Tap **Play in Background** to minimize audio into the floating **Apple Music-style Mini Player** at the bottom of the screen, allowing you to continue browsing folders or editing YAML while listening.
- **Hex / Binary Inspector:** Tapping `.db`, `.sqlite`, `.bin` files (or selecting **Hex / Binary Inspector** from the `⋯` menu on any file) displays a side-by-side `HEX + ASCII` stream viewer.
- **Backup & Archive Inspector (`.tar` / `.zip`):** Tapping any `.tar` Home Assistant backup or `.zip` archive lists internal files and sizes without downloading or extracting.
- **Live Markdown Preview (`Preview`):** Automatically renders `.md` files in GitHub Dark style with a 1-tap toggle to switch back to raw code editing.

---

## 🛠️ 2. System Operations, Sharing & Security Suite

The second action bar in the Web UI provides four dedicated system administration tools:

1. **Terminal (`Web Terminal`):**
   - Opens an interactive `xterm.js` shell rooted in your current working directory.
   - Includes 1-tap quick chips for `df -h`, `ls -la`, `git status`, and `git pull`.
2. **Storage (`Storage Analytics`):**
   - Displays total NVMe capacity, used percentage, available free space, and an interactive **Donut Chart** breaking down storage consumption across `/config`, `/backup`, `/media`, `/share`, `/addons`, and `/ssl`.
3. **Quick Zip (`Quick Snapshot to Zip`):**
   - **Backup Entire `/config` Folder:** Compresses all YAML configurations, `custom_components`, and `.storage` (excluding heavy database/log files) into `/backup/quick_config_YYYYMMDD_HHMMSS.zip`.
   - **Backup Automations & Scripts Only:** Creates a fast, lightweight `.zip` snapshot of your automations, scripts, scenes, and packages before editing code.
4. **Connect (`Multi-Protocol Connect Hub`):**
   - Displays live connection URLs for **SMB/Samba (`445`)**, **SFTP (`2222`)**, **FTP (`2121`)**, and **WebDAV (`8090`)** with 1-tap copy to clipboard.
5. **Security (`Audit Log & Expiry Share Links`):**
   - **Expiry Share Links:** Tap `⋯` -> **Create Expiry Share Link** on any **file or folder** to generate a temporary public download link (`/s/<token>`) valid for `1 Hour`, `6 Hours`, `24 Hours`, or `7 Days` without exposing your password. Shared folders are automatically packaged as `.zip` archives on download.
   - **Security Audit Log:** View real-time logs of web logins, file modifications (`PUT`), deletions (`DELETE`), snapshots, and share-link downloads.

---

## 🌐 3. Connecting External Devices (Multi-Protocol)

All enabled protocols share the exact same `users` credentials and directory structure configured in the add-on options.

### A. SMB / Samba (Port `445` — Recommended for LAN / Tailscale)
- **iOS / iPadOS (Native Files App):** Tap `⋯` -> **Connect to Server** -> Enter `smb://<HOME_ASSISTANT_IP>/OmniDrive` -> Sign in with your `users` credentials.
- **macOS (Finder):** Press `Cmd + K` -> Enter `smb://<HOME_ASSISTANT_IP>/OmniDrive` -> Click **Connect**.
- **Windows (File Explorer):** Open Run (`Win + R`) or File Explorer address bar -> Enter `\\<HOME_ASSISTANT_IP>\OmniDrive`.
- **Apple TV / Infuse / VLC:** Add a new SMB share pointing to `<HOME_ASSISTANT_IP>` (Port `445`) to stream recordings and media directly.

### B. SFTP — SSH File Transfer (Port `2222`)
- **Clients:** FileZilla, Cyberduck, Transmit, WinSCP, Termius, FE File Explorer.
- **Connection URL:** `sftp://<USERNAME>@<HOME_ASSISTANT_IP>:2222/`

### C. FTP Server (Port `2121`, Passive Ports `21000–21002`)
- **Connection URL:** `ftp://<USERNAME>@<HOME_ASSISTANT_IP>:2121/`

### D. WebDAV & Cloudflare Zero Trust Tunnel (Port `8090`)
1. Open your **Cloudflare Zero Trust Dashboard** -> **Networks** -> **Tunnels**.
2. Create a Public Hostname (e.g., `drive.yourdomain.com`) pointing to `http://<HOME_ASSISTANT_IP>:8090`.
3. **Web Browser Access:** Open `https://drive.yourdomain.com` in Safari or Chrome to sign in via the **iOS Glassmorphism Login UI**.
4. **Native WebDAV Mount:** Enter `https://drive.yourdomain.com/` in macOS Finder (`Cmd + K`), Windows Explorer, or iOS Files — OmniDrive Pro automatically authenticates native WebDAV clients via HTTP Basic Auth.

---

## ⚙️ 4. Configuration Reference

| Option | Default | Description |
| :--- | :--- | :--- |
| `unified_root` | `true` | Mounts all shares under a single root path `/` so you can browse and move files across all directories from a single connection. Set to `false` for per-folder `read_only` or `allowed_users` rules. |
| `smb_enabled` | `true` | Enables the SMB / Samba v3 server on port `445`. |
| `sftp_enabled` | `true` | Enables the OpenSSH SFTP server on port `2222`. |
| `ftp_enabled` | `true` | Enables the FTP server on port `2121` (with passive ports `21000–21002`). |
| `ssl` | `false` | Enables native HTTPS on port `8090` using certificates in `/ssl`. Keep `false` if routing through Cloudflare Tunnel or a reverse proxy. |
| `certfile` | `fullchain.pem` | SSL certificate filename in `/ssl`. |
| `keyfile` | `privkey.pem` | SSL private key filename in `/ssl`. |
| `max_upload_size` | `"0"` | Maximum allowed upload size (`"0"` = unlimited, ideal for multi-GB backups). |
| `fancy_ui` | `true` | Enables the iOS Glassmorphism Dark Web UI, Cloud Code IDE, and System Suite. |
| `show_dotfiles` | `true` | Displays hidden system files and folders starting with a dot (e.g., `.storage`, `.git`). |
| `log_level` | `info` | Server log verbosity (`debug`, `info`, `notice`, `warn`, `error`). |
| `users` | `[...]` | List of `{ username, password }` accounts authorized across Web UI, WebDAV, SMB, SFTP, and FTP. |
| `shares` | `[...]` | List of mapped Home Assistant directories (`config`, `addon_configs`, `addons`, `backup`, `media`, `share`, `ssl`). |
