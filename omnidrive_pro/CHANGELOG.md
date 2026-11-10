## [1.0.10] - 2026-11-10
- **Maintenance & Improvements:** Update header.html

## [1.0.9] - 2026-11-10
- **Maintenance & Improvements:** Update login.html

## [1.0.8] - 2026-11-10
- **Maintenance & Improvements:** Update header.html

## [1.0.7] - 2026-11-10
- **Maintenance & Improvements:** Update footer.html

## [1.0.6] - 2026-11-10
- **Maintenance & Improvements:** Update header.html

## [1.0.5] - 2026-11-10
- **Maintenance & Improvements:** Update footer.html

## [1.0.4] - 2026-11-10
- **Maintenance & Improvements:** Update footer.html

## [1.0.3] - 2026-11-10
- **Maintenance & Improvements:** Update footer.html

## [1.0.2] - 2026-11-09
- **Maintenance & Improvements:** Update run.sh

## [1.0.1] - 2026-11-09
- **Maintenance & Improvements:** Create omnidrive_pro.yml

## [1.0.1] - 2026-11-09
- **Maintenance & Improvements:** Update CHANGELOG.md

## [1.0.0] - 2026-11-08
- **Initial Release:** Launched **WebDAV Server Pro** for Home Assistant (`aarch64` & `amd64`).
- **Full System Directory Mapping:** Unlocked read/write access to `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, and `ssl` with Unified Root support.
- **Native OS WebDAV Compliance:** Integrated `nginx-mod-http-dav-ext` with a shared `davlock` memory zone for full `PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `COPY`, `MOVE`, `LOCK`, and `UNLOCK` support on iOS, macOS, and Windows.
- **Built-in Cloud Code IDE (Ace Editor):** Added One Dark syntax highlighting for YAML, Python, JSON, Shell, JS/TS, HTML/CSS, PHP, SQL, and Markdown with Undo/Redo, Find & Replace, 2-space indentation, comment toggling, `A+`/`A-` font sizing, and Zen Fullscreen Mode.
- **Real-Time YAML Linter:** Integrated `js-yaml` syntax validation to catch Home Assistant configuration errors before saving.
- **Live Markdown Renderer:** Added instant GitHub Dark preview and edit toggling for `.md` files.
- **Backup & Archive Inspector:** Added in-browser content inspection for `.tar` backups and `.zip` archives.
- **iOS 27 Files Dark UI & Ingress:** Built responsive List/Grid views, sorting, live search, pill breadcrumbs with one-tap path copy, multi-file upload progress bars, Drag & Drop, Clipboard paste (`Cmd/Ctrl + V`), Action Sheet (`•••`), and Multi-Select batch operations.
- **Security Hardening:** Configured S6-Overlay v3 `apparmor.txt` profile, Bcrypt password hashing (`htpasswd -B`), and brute-force rate limiting (`limit_req_zone`).
