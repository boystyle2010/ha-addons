# Hướng dẫn sử dụng WebDAV Server Pro

### 1. Đường dẫn kết nối
- **Qua mạng nội bộ (LAN):** `http://<IP_HOME_ASSISTANT>:8080/`
- **Qua Cloudflare Tunnel:** Trỏ Subdomain (ví dụ `dav.tenmiencuaban.com`) về `http://localhost:8080`. Khi đó đường dẫn kết nối từ mọi nơi là `https://dav.tenmiencuaban.com/`.

### 2. Các thư mục được mở khóa sẵn
- `/config`: Thư mục cấu hình chính của Home Assistant (`/homeassistant`).
- `/addon_configs`: Thư mục chứa file cấu hình riêng của toàn bộ các Add-on đã cài.
- `/addons`: Thư mục chứa các Local Add-ons.
- `/backup`: Thư mục chứa các file sao lưu `.tar`.
- `/media` & `/share`: Thư mục đa phương tiện và dữ liệu dùng chung.
- `/ssl`: Thư mục chứa chứng chỉ bảo mật.
