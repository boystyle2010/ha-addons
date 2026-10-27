# Cloudflare Pro (Raspberry Pi 5 Edition)

![Supports aarch64 Architecture][aarch64-shield]
![Cloudflare Zero Trust][cf-shield]

Add-on **Cloudflare Tunnel (cloudflared)** chuyên biệt tối ưu hóa cho phần cứng **64-bit (`aarch64`) của Raspberry Pi 5** chạy Home Assistant OS.

## ✨ Tính năng nổi bật

- 🚀 **Native ARM64 Binary:** Tải và chạy trực tiếp mã nguồn `cloudflared-linux-arm64` chính gốc từ Cloudflare.
- 🔄 **Auto-Update Verified:** Tự động kiểm tra bản phát hành mới từ Cloudflare & Alpine Base mỗi 6 giờ (xác thực HTTP 200 trước khi báo Update lên Home Assistant).
- 🛡️ **Zero Trust Dashboard & Local Mode:** Hỗ trợ song song chế độ chạy bằng **Tunnel Token** (quản lý tên miền trên web Cloudflare) hoặc **Local Ingress** (khai báo Subdomain ngay trên UI của Home Assistant).
- 🔐 **Post-Quantum Cryptography:** Hỗ trợ bật mã hóa lượng tử bảo vệ đường truyền.
- 📊 **Prometheus Metrics:** Tích hợp cổng xuất dữ liệu giám sát trạng thái Tunnel.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[cf-shield]: https://img.shields.io/badge/Cloudflare-Zero_Trust-F38020?logo=cloudflare&logoColor=white
