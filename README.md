# 🚀 HASS Pro Add-ons — Raspberry Pi 5 (`aarch64`)

![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20Pi%205-blue?style=for-the-badge&logo=raspberrypi)
![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%26%20Mesh%20VPN-success?style=for-the-badge&logo=cloudflare)
![Auto Update](https://img.shields.io/badge/Upstream%20Sync-Automated%20CI%2FCD-orange?style=for-the-badge&logo=githubactions)

Kho lưu trữ Add-on Home Assistant hiệu năng cao, được thiết kế chuyên biệt cho **Raspberry Pi 5 (NVMe SSD)**. Tự động đồng bộ hóa trực tiếp với mã nguồn chính thức từ nhà phát hành thông qua GitHub Actions kèm cơ chế kiểm duyệt chống lỗi (Zero-Broken-Build) và tự phục hồi kết nối (Self-Healing Watchdog).

---

## 📦 Danh sách Add-on trong Repository

### 1. ⚡ Cloudflared Pro (`cloudflared`)
Giải pháp kết nối Zero Trust Edge Tunnel không cần mở port, hỗ trợ song song IPv4/IPv6 Dual-Stack.
- **Tự động cập nhật:** Đồng bộ trực tiếp với `cloudflare/cloudflared` (Kiểm tra `HTTP 200 OK` binary trước khi nâng cấp).
- **Chống đứt kết nối:** Tích hợp Watchdog tự động kiểm tra sức khỏe đường truyền và khởi động lại khi mất kết nối.
- **Hỗ trợ đa chế độ:** Quản lý qua Remote Token (Zero Trust Dashboard) hoặc Local Ingress trực tiếp trên giao diện Home Assistant.
- **Đa ngôn ngữ:** Tự động chuyển đổi Tiếng Việt / English theo ngôn ngữ hệ thống.

### 2. 🛡️ Tailscale Pro (`tailscale`)
Mạng riêng ảo Mesh VPN (WireGuard) tốc độ cao, đóng vai trò **Subnet Router** (`192.168.68.0/24`) và **Exit Node** cho toàn bộ hệ thống mạng gia đình.
- **Đồng bộ tức thì:** Trích xuất trực tiếp từ `tailscale/tailscale` ngay khi hãng phát hành (Xác thực kiến trúc `linux/arm64` và mã nguồn trước khi cập nhật).
- **Full Web UI (Ingress):** Tích hợp bảng điều khiển Tailscale Web Client ngay trên thanh công cụ của Home Assistant (Cổng `5252`).
- **Tối ưu phần cứng Pi 5:** Tự động kích hoạt `rx-udp-gro-forwarding` trên cổng mạng vật lý để đạt băng thông tối đa.
- **Kiểm tra sức khỏe đường truyền (Healthcheck):** Giám sát trạng thái `BackendState` và kết nối tới máy chủ điều phối (DERP/Control Plane), tự động kết nối lại nếu bị treo.
- **Đa ngôn ngữ:** Hỗ trợ đầy đủ Tiếng Việt (`vi.yaml`) và English (`en.yaml`) tự động theo hệ thống.

---

## 🛠️ Hướng dẫn cài đặt vào Home Assistant

1. Truy cập **Home Assistant** -> **Settings (Cài đặt)** -> **Add-ons (Tiện ích bổ sung)** -> **Add-on Store (Cửa hàng)**.
2. Bấm vào biểu tượng **3 chấm** ở góc trên bên phải -> Chọn **Repositories (Kho lưu trữ)**.
3. Dán đường dẫn sau vào và bấm **Add**:
   ```text
   [https://github.com/boystyle2010/ha-addons](https://github.com/boystyle2010/ha-addons)
