# Home Assistant Add-on: WebDAV Server Pro — Documentation

**WebDAV Server Pro** combines a compliant **Class 1 & 2 WebDAV Server** (port `8090`) with an **iOS 27 Dark File Manager & Cloud Code IDE** accessible directly from the Home Assistant sidebar (Ingress port `8099`).

---

## 💻 1. Built-in Cloud IDE & File Manager (Ingress UI)

Open **WebDAV Pro** from your Home Assistant sidebar to access the workspace without any login prompt:

### A. Ace Code Editor & YAML Linter
- **Syntax Highlighting:** Tap any `.yaml`, `.yml`, `.py`, `.json`, `.sh`, `.js`, `.ts`, `.html`, `.css`, `.php`, `.sql`, `.conf`, `.ini`, `.toml`, `.log`, or `.txt` file to open the built-in IDE.
- **Real-Time YAML Validation:** When editing `.yaml` / `.yml` files (including Home Assistant tags like `!include` and `!secret`), a live status bar verifies syntax and highlights exact line numbers if an indentation or syntax error is detected.
- **Coding Toolbar:**
  - `↶` / `↷`: Undo and Redo changes.
  - `🔍 Find`: Open the search and replace box inside the code editor.
  - `⇥ Tab`: Insert a 2-space soft tab (standard Home Assistant YAML indentation).
  - `#`: Toggle line comments on or off.
  - `A+` / `A-`: Increase or decrease editor font size (automatically saved to your device).
  - `↵ Wrap`: Toggle word wrapping.
  - `⛶ Zen`: Toggle Zen Fullscreen Mode (hides sub-toolbars to maximize coding space on mobile).
- **Keyboard Shortcuts:** Press `Cmd + S` (macOS) or `Ctrl + S` (Windows/Linux) to save changes instantly.

### B. Live Markdown Preview (`👁️ Preview`)
- Tapping any `.md` or `.markdown` file automatically renders a formatted GitHub Dark preview (including tables, code blocks, and badges).
- Tap **✏️ Edit Code** in the top bar to switch to the raw Markdown editor, and tap **👁️ Preview** to switch back.

### C. Backup & Archive Inspector (`.tar` / `.zip`)
- Tapping any `.tar` file (such as Home Assistant backups in `/backup`) or `.zip` archive opens the **Archive Inspector**, listing internal files, folders, and sizes without downloading the entire archive.

### D. File, Folder & Batch Operations
- **Top Action Bar:** Create a **New File** (opens directly in the IDE), create a **New Folder** (`MKCOL`), or **Upload** multiple files with a real-time percentage progress bar.
- **Drag & Drop + Clipboard Paste:** Drag files from your computer straight into the browser window, or press `Cmd/Ctrl + V` to upload copied files or screenshots from your clipboard.
- **Row Menu (`•••`):** Open in Code Editor, Copy, Move (Cut), Duplicate, Rename, Copy Full Path, Download, or Delete.
- **Multi-Select Batch Mode:** Tap **Select** in the top-right corner to check multiple files/folders and perform batch **Copy**, **Move**, or **Delete** operations via the floating bottom bar.
- **One-Tap Path Copy:** Tap the active folder badge in the breadcrumb bar (`🏠 Home › config`) to copy its full system path to your clipboard.

---

## 🌐 2. Connecting External Devices (WebDAV Port `8090`)

### A. Local Network (LAN)
- **Unified Root URL:** `http://<HOME_ASSISTANT_IP>:8090/`
- **Direct Share URL:** `http://<HOME_ASSISTANT_IP>:8090/config/`

### B. Remote Access via Cloudflare Zero Trust Tunnel
Because WebDAV operates over standard HTTP/HTTPS, it works seamlessly over Cloudflare Tunnels without opening router ports:
1. Open your **Cloudflare Zero Trust Dashboard** -> **Networks** -> **Tunnels**.
2. Create a Public Hostname (e.g., `dav.yourdomain.com`) pointing to `http://localhost:8090` (or `http://<HOME_ASSISTANT_IP>:8090`).
3. Connect from anywhere using `https://dav.yourdomain.com/`.

### C. Mounting as a Native Drive
- **iOS / iPadOS (Files App, FE File Explorer, Documents):** Tap the `•••` menu -> **Connect to Server** -> Enter `http://<HOME_ASSISTANT_IP>:8090/` (or your `https://` tunnel domain) -> Sign in with your configured `users` credentials.
- **macOS (Finder):** Press `Cmd + K` -> Enter the WebDAV URL -> Click **Connect**.
- **Windows (File Explorer):** Right-click **This PC** -> **Map network drive** -> Enter the WebDAV URL and check *Connect using different credentials*.

---

## ⚙️ 3. Configuration Reference

| Option | Default | Description |
| :--- | :--- | :--- |
| `unified_root` | `true` | Combines all configured shares under `/` so you can mount a single drive and move files across directories. Set to `false` to enforce individual `read_only` or `allowed_users` rules per share. |
| `ssl` | `false` | Enables native HTTPS on port `8080` using certificates in `/ssl`. Leave `false` if routing through Cloudflare Tunnel or a reverse proxy. |
| `certfile` | `fullchain.pem` | SSL certificate filename in `/ssl`. |
| `keyfile` | `privkey.pem` | SSL private key filename in `/ssl`. |
| `max_upload_size` | `"0"` | Maximum allowed upload size (`"0"` = unlimited, ideal for multi-GB backups). |
| `fancy_ui` | `true` | Enables the iOS 18 Dark Web UI, Cloud Code IDE, and Ingress workspace. |
| `show_dotfiles` | `true` | Displays hidden system files and folders starting with a dot (e.g., `.storage`). |
| `log_level` | `info` | Nginx error log verbosity (`debug`, `info`, `notice`, `warn`, `error`). |
| `users` | `[...]` | List of `{ username, password }` accounts (encrypted with Bcrypt). |
| `shares` | `[...]` | List of mapped directories (`config`, `addon_configs`, `addons`, `backup`, `media`, `share`, `ssl`). |
