## [2.2.2] - 2026-11-09
- **Maintenance & Improvements:** Update footer.html

## [2.2.1] - 2026-11-09
- **Maintenance & Improvements:** Update footer.html

## [2.1.5] - 2026-11-09
- **Maintenance & Improvements:** Update footer.html

## [2.1.4] - 2026-11-09
- **Maintenance & Improvements:** Update footer.html

## [2.1.3] - 2026-11-09
- **Maintenance & Improvements:** Update header.html

## [2.1.2] - 2026-11-09
- **Maintenance & Improvements:** Update run.sh

## [2.1.1] - 2026-11-09
- **Maintenance & Improvements:** Update Dockerfile

## [2.0.31] - 2026-11-09
- **Maintenance & Improvements:** Update README.md

## [2.0.30] - 2026-11-09
- **Maintenance & Improvements:** Update DOCS.md

## [2.0.29] - 2026-11-09
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


## [2.0.28] - 2026-11-09
- **Maintenance & Improvements:** Update DOCS.md

## [2.0.27] - 2026-11-09
- **Maintenance & Improvements:** Update README.md

## [2.0.26] - 2026-11-09
- **Maintenance & Improvements:** Update apparmor.txt

## [2.0.25] - 2026-11-09
- **Maintenance & Improvements:** Update header.html

## [2.0.24] - 2026-11-09
- **Maintenance & Improvements:** Update footer.html

## [2.0.23] - 2026-11-09
- **Maintenance & Improvements:** Update apparmor.txt

## [2.0.22] - 2026-11-09
- **Maintenance & Improvements:** Update README.md

## [2.0.21] - 2026-11-09
- **Maintenance & Improvements:** Update DOCS.md

## [2.0.20] - 2026-11-09
- **Maintenance & Improvements:** Rename webdav_pro.yaml to webdav_pro.yml

## [2.0.19] - 2026-11-09
- **Maintenance & Improvements:** Add files via upload

## [2.0.18] - 2026-11-08
- **Maintenance & Improvements:** Create README.md

## [2.0.17] - 2026-11-08
- **Maintenance & Improvements:** Update DOCS.md

## [2.0.16] - 2026-11-08
- **Maintenance & Improvements:** Update apparmor.txt

## [2.0.15] - 2026-11-08
- **Maintenance & Improvements:** Rename AppArmor.txt to apparmor.txt

## [2.0.14] - 2026-11-08
- **Maintenance & Improvements:** Update footer.html

## [2.0.13] - 2026-11-08
- **Maintenance & Improvements:** Update header.html

## [2.0.12] - 2026-11-08
- **Maintenance & Improvements:** Update footer.html

## [2.0.11] - 2026-11-08
- **Maintenance & Improvements:** Update header.html

## [2.0.10] - 2026-11-08
- **Maintenance & Improvements:** Update run.sh

## [2.0.9] - 2026-11-08
- **Maintenance & Improvements:** Update footer.html

## [2.0.8] - 2026-11-08
- **Maintenance & Improvements:** Update header.html

## [2.0.7] - 2026-11-08
- **Maintenance & Improvements:** Update run.sh

## [2.0.6] - 2026-11-08
- **Maintenance & Improvements:** Update Dockerfile

## [2.0.5] - 2026-11-08
- **Maintenance & Improvements:** Create footer.html

## [2.0.4] - 2026-11-08
- **Maintenance & Improvements:** Create header.html

## [2.0.3] - 2026-11-08
- **Maintenance & Improvements:** Delete webdav_pro/fancyindex/footer.html

## [2.0.2] - 2026-11-08
- **Maintenance & Improvements:** Add files via upload

## [2.0.1] - 2026-11-08
- **Maintenance & Improvements:** Update config.yaml

## [2.0.0] - 2026-11-08
- **Upstream Update:** Upgraded Nginx to `1.30.6-r0` on Home Assistant Alpine Base `3.24`.
- Updated `dav-ext` and `fancyindex` modules with the latest upstream security patches.

## [1.0.0] - 2026-11-08
- **Initial Release:** Launched **WebDAV Server Pro** for Home Assistant.
- **Full System Directory Mapping:** Added read/write support for `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, and `ssl`.
- **Native OS Compatibility:** Integrated `nginx-mod-http-dav-ext` with shared `davlock` memory zone for full `PROPFIND`, `LOCK`, and `UNLOCK` support on iOS, macOS, and Windows.
- **FancyIndex Dark UI & Ingress:** Built-in responsive dark theme with instant search bar and Home Assistant sidebar Ingress integration.
- **Security Hardening:** Added custom AppArmor profile, Bcrypt password hashing, and brute-force rate limiting (`limit_req_zone`).
