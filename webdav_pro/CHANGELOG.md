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
