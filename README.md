# 🚀 HASS Pro Add-ons — Raspberry Pi 5 (`aarch64`)

![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20Pi%205-blue?style=for-the-badge&logo=raspberrypi)
![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%26%20AppArmor-success?style=for-the-badge&logo=cloudflare)
![Auto Update](https://img.shields.io/badge/Upstream%20Sync-Automated%20CI%2FCD-orange?style=for-the-badge&logo=githubactions)

Kho lưu trữ Add-on Home Assistant hiệu năng cao, được thiết kế chuyên biệt cho **Raspberry Pi 5 (NVMe SSD)**. Tự động đồng bộ hóa trực tiếp với mã nguồn chính thức từ nhà phát hành thông qua GitHub Actions kèm cơ chế kiểm duyệt chống lỗi (**Zero-Broken-Build**) và tự phục hồi kết nối (**Self-Healing Watchdog**).

---

## 📦 Danh sách Add-on trong Repository

| Add-on | Slug | Cổng / Giao diện | Tính năng cốt lõi |
| :--- | :--- | :--- | :--- |
| **⚡ Cloudflared Pro** | `cloudflared` | Zero Trust Tunnel | Dual-Stack IPv4/IPv6, Remote Token & Local Ingress |
| **🛡️ Tailscale Pro** | `tailscale` | Ingress (`5252`) | Mesh VPN, Subnet Router (`192.168.68.0/24`), Exit Node |
| **📂 WebDAV Server Pro** | `webdav_pro` | `8080` & Ingress (`8099`) | Quản lý toàn bộ file hệ thống HA, FancyIndex Dark UI |

---

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

### 3. 📂 WebDAV Server Pro (`webdav_pro`)
Máy chủ quản lý tập tin WebDAV tốc độ cao (Nginx + `dav-ext` + `fancyindex`), mở khóa toàn bộ phân vùng hệ thống của Home Assistant cho iOS/iPadOS Files, macOS Finder, Windows Explorer và Cloudflare Tunnel.
- **Truy cập toàn diện (Unified Root):** Mở khóa đầy đủ quyền Đọc/Ghi cho `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, và `ssl` trong một điểm gắn kết duy nhất.
- **Tương thích Native OS:** Tích hợp vùng nhớ khóa file `davlock` hỗ trợ đầy đủ giao thức WebDAV Class 1 & 2 (`PROPFIND`, `LOCK`, `UNLOCK`, `MOVE`, `COPY`).
- **FancyIndex Dark Web UI & Ingress:** Tích hợp sẵn giao diện duyệt file nền tối kèm thanh tìm kiếm tức thì ngay trên thanh bên của Home Assistant (Cổng Ingress `8099`).
- **Bảo mật chuẩn Supervisor:** Đạt mức Security Rating cao nhất với hồ sơ cô lập `AppArmor.txt`, mã hóa mật khẩu Bcrypt, giới hạn chống dò mật khẩu (`limit_req_zone`) và phân quyền Read-Only theo từng thư mục.
- **Tự động cập nhật thông minh:** GitHub Actions tự động kiểm tra bản phát hành Alpine Base & Nginx mới nhất mỗi ngày, kiểm thử `docker build` thành công trước khi nâng cấp phiên bản.

---

## 🔄 Quy chuẩn Tự động Cập nhật & Phiên bản (CI/CD Versioning)

Hệ thống GitHub Actions trong kho lưu trữ này vận hành hoàn toàn tự động theo quy tắc:
- **Nâng cấp Major Version (`1.0.x` ➔ `2.0.0`):** Khi nhà phát hành (Cloudflare, Tailscale, Alpine/Nginx) tung ra bản cập nhật mới từ Upstream.
- **Nâng cấp Patch Version (`1.0.0` ➔ `1.0.1`):** Khi có chỉnh sửa cấu hình, tối ưu hóa script hoặc giao diện nội bộ trong Repository.
- **Zero-Broken-Build:** Mọi bản cập nhật đều được xác thực mã nguồn và chạy thử nghiệm trước khi đẩy commit phát hành lên nhánh `main`.

---

## 🛠️ Hướng dẫn cài đặt vào Home Assistant

1. Truy cập **Home Assistant** -> **Settings (Cài đặt)** -> **Add-ons (Tiện ích bổ sung)** -> **Add-on Store (Cửa hàng)**.
2. Bấm vào biểu tượng **3 chấm** ở góc trên bên phải -> Chọn **Repositories (Kho lưu trữ)**.
3. Dán đường dẫn sau vào và bấm **Add (Thêm)**:
   ```text
   [https://github.com/boystyle2010/ha-addons](https://github.com/boystyle2010/ha-addons)
