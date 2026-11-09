# Home Assistant App: WebDAV Server Pro

![Version](https://img.shields.io/badge/version-2.0.21-blue.svg)
![Nginx](https://img.shields.io/badge/nginx-1.30.6--r0-009639.svg)
![Alpine Base](https://img.shields.io/badge/alpine%20base-3.24-0D597F.svg)
![Project Stage](https://img.shields.io/badge/project%20stage-stable-brightgreen.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![AppArmor](https://img.shields.io/badge/apparmor-enabled-success.svg)
![Arch](https://img.shields.io/badge/arch-aarch64%20%7C%20amd64-blue.svg)

High-performance WebDAV file gateway & cloud IDE with an iOS-inspired Dark UI, built and tuned for Raspberry Pi 5.

## About

**WebDAV Server Pro** turns your Home Assistant into a fast, security-hardened file server and mobile-friendly code workspace. Mount all your Home Assistant directories directly inside **iOS/iPadOS Files**, **macOS Finder**, or **Windows Explorer**, or manage and edit your configuration files right from the Home Assistant sidebar via Ingress.

This add-on tracks official Alpine Linux and Nginx upstream releases and updates itself automatically via GitHub Actions after passing strict `docker build` verification checks.

## Features

- **Unified System Storage Access:** Full Read/Write access to `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, and `ssl` from a single mount point.
- **Built-in Ace Code Editor (IDE):** Syntax highlighting (One Dark theme) for YAML, Python, JSON, Shell, HTML/CSS/JS, and Markdown with line numbers, Undo/Redo, Find & Replace, auto-indentation, and YAML syntax validation.
- **Live Markdown Renderer:** Instant side-by-side preview for `.md` files (`README.md`, `CHANGELOG.md`, `DOCS.md`) with GitHub Dark styling.
- **iOS 27 Files Dark UI (Ingress):** Native-feeling mobile interface with Grid/List view toggle, instant search, pill breadcrumbs, one-tap path copying, and real-time upload progress bars.
- **Full File & Batch Operations:** Create files/folders, upload multiple files, Duplicate, Rename, Copy, Move (Cut & Paste across folders), and Multi-Select batch actions directly in the browser.
- **Quick Look Media & PDF Preview:** Built-in preview player for images, video streams, audio files (`.mp3`, `.wav`, `.m4a`), and PDF documents.
- **Native OS & Cloudflare Tunnel Ready:** Powered by `nginx-mod-http-dav-ext` with shared `davlock` memory zones for zero-error mounting over LAN or Cloudflare Zero Trust Tunnels.
- **Maximum Security Rating:** Hardened with a dedicated `apparmor.txt` profile, Bcrypt password hashing (`htpasswd -B`), per-share Read-Only rules, and brute-force rate limiting.
