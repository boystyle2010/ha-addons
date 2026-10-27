# Hướng dẫn cấu hình Cloudflare Pro

## Chế độ 1: Sử dụng Cloudflare Zero Trust Token (Khuyên dùng)
1. Truy cập trang quản trị [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) -> **Networks** -> **Tunnels**.
2. Tạo một Tunnel mới (chọn loại **Cloudflared**) hoặc chọn Tunnel hiện có -> bấm **Configure**.
3. Copy chuỗi **Token** (bắt đầu bằng `eyJ...`).
4. Mở tab **Configuration** của Add-on này -> dán vào ô **Cloudflare Tunnel Token** -> bấm **Save** và khởi động Add-on.
5. Trong mục **Public Hostname** trên web Cloudflare, trỏ tên miền của bạn về `http://localhost:8123`.

## Chế độ 2: Sử dụng Local Mode (Khai báo trực tiếp trên UI)
- Để trống ô **Tunnel Token**.
- Đặt file chứng thực `credentials.json` vào thư mục `/share/cloudflared/credentials.json`.
- Nhập tên miền chính vào ô **External Hostname** và thêm các dịch vụ khác vào mục **Additional Hosts**.

## Lưu ý cho Home Assistant (`configuration.yaml`)
Đừng quên thêm cấu hình `trusted_proxies` vào file `/config/configuration.yaml` của Home Assistant để cho phép kết nối qua Reverse Proxy:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.30.33.0/24
    - 127.0.0.1
    - ::1
```
