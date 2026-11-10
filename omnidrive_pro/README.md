# Home Assistant App: WebDAV Server Pro

![Version](https://img.shields.io/badge/version-1.0.19-blue.svg)
![Nginx](https://img.shields.io/badge/nginx-1.30.6--r0-009639.svg)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![AppArmor](https://img.shields.io/badge/apparmor-enabled-success.svg)
![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)

High-performance WebDAV file gateway, iOS-inspired File Manager & Cloud Code IDE for Home Assistant, tuned for Raspberry Pi 5.

## About

**WebDAV Server Pro** transforms your Home Assistant into a fast, security-hardened WebDAV file server and full-featured Cloud IDE. Mount all your Home Assistant directories directly as a network drive inside **iOS/iPadOS Files**, **macOS Finder**, or **Windows Explorer** (over LAN or Cloudflare Zero Trust Tunnels), or manage files and edit configuration code directly from the Home Assistant sidebar via Ingress.

This add-on tracks official Alpine Linux and Nginx upstream releases and updates itself automatically via GitHub Actions after passing strict `docker build` verification checks.

## Features

- **Unified System Storage Access:** Full Read/Write access to `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, and `ssl` under a single mount point.
- **Built-in Ace Code IDE:** Syntax highlighting (One Dark theme) for YAML, Python, JSON, Shell, JS/TS, HTML/CSS, PHP, SQL, and Markdown with mobile coding toolbar (`Undo`, `Redo`, `Find & Replace`, `2-Space Tab`, `Toggle Comment`, `Word Wrap`), font scaling (`A+` / `A-`), and **Zen Fullscreen Mode (`⛶ Zen`)**.
- **Real-Time YAML Syntax Linter:** Powered by `js-yaml`, automatically validates Home Assistant YAML files as you type and warns of exact line errors before saving.
- **Live Markdown Renderer (`👁️ Preview`):** Instant GitHub-styled preview for `.md` files (`README.md`, `CHANGELOG.md`, `DOCS.md`) with one-tap toggle between preview and code editor.
- **Backup & Archive Inspector (`.tar` / `.zip`):** Peek inside Home Assistant `.tar` backups and `.zip` archives directly in the browser without downloading gigabytes of data.
- **iOS 27 Files Dark UI (Ingress):** Native-feeling mobile & desktop interface with List/Grid view toggle, sorting (`Name A–Z`, `Newest`, `Largest`), instant search filter, pill breadcrumbs with one-tap path copy, and header app icon integration.
- **Complete File & Batch Operations:** Create files/folders, Duplicate, Rename, Copy, Cut/Move across directories, and **Multi-Select (`Select`)** for batch Copy, Move, and Delete.
- **Smart Upload Engine:** Multi-file upload with real-time progress bar (`%`), **Drag & Drop** anywhere on screen, and direct **Clipboard Paste (`Cmd/Ctrl + V`)**.
- **Quick Look Media & PDF Player:** Built-in viewer for images, video streams, audio files (`.mp3`, `.wav`, `.m4a`, `.flac`), and PDF documents.
- **Native OS & Security Hardened:** Full WebDAV Class 1 & 2 (`dav-ext` + `davlock`), S6-Overlay v3 `apparmor.txt` profile, Bcrypt password encryption, per-share Read-Only rules, and brute-force rate limiting.
