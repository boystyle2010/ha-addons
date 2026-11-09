# 🚀 HASS Pro Add-ons — Raspberry Pi 5 (`aarch64` & `amd64`)

![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%2F%20AMD64-blue?style=for-the-badge&logo=raspberrypi)
![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%26%20AppArmor-success?style=for-the-badge&logo=cloudflare)
![Auto Update](https://img.shields.io/badge/Upstream%20Sync-Automated%20CI%2FCD-orange?style=for-the-badge&logo=githubactions)

Kho lưu trữ Add-on Home Assistant hiệu năng cao, được thiết kế và tinh chỉnh chuyên biệt cho **Raspberry Pi 5 (NVMe SSD)**[span_1](start_span)[span_1](end_span). Tự động đồng bộ hóa trực tiếp với mã nguồn chính thức từ nhà phát hành thông qua GitHub Actions kèm cơ chế kiểm duyệt chống lỗi (**Zero-Broken-Build**), báo cáo trực quan (**CI/CD Execution Dashboard**) và tự phục hồi kết nối (**Self-Healing Watchdog**)[span_2](start_span)[span_2](end_span).

---

## 📦 Danh sách Add-on trong Repository

| Add-on | Slug | Cổng / Giao diện | Tính năng cốt lõi |
| :--- | :--- | :--- | :--- |
| **⚡ Cloudflared Pro** | `cloudflared` | Zero Trust Tunnel | Dual-Stack IPv4/IPv6, Remote Token & Local Ingress[span_3](start_span)[span_3](end_span) |
| **🛡️ Tailscale Pro** | `tailscale` | Ingress (`5252`) | Mesh VPN, Subnet Router (`192.168.68.0/24`), Exit Node[span_4](start_span)[span_4](end_span) |
| **📂 WebDAV Server Pro** | `webdav_pro` | `8080` & Ingress (`8099`) | WebDAV Gateway, iOS 18 Dark UI, Cloud IDE, YAML Linter & Archive Inspector |

---

### 1. ⚡ Cloudflared Pro (`cloudflared`)
Giải pháp kết nối Zero Trust Edge Tunnel không cần mở port, hỗ trợ song song IPv4/IPv6 Dual-Stack[span_5](start_span)[span_5](end_span).
- **Tự động cập nhật:** Đồng bộ trực tiếp với `cloudflare/cloudflared` (Kiểm tra `HTTP 200 OK` binary trước khi nâng cấp)[span_6](start_span)[span_6](end_span).
- **Chống đứt kết nối:** Tích hợp Watchdog tự động kiểm tra sức khỏe đường truyền và khởi động lại khi mất kết nối[span_7](start_span)[span_7](end_span).
- **Hỗ trợ đa chế độ:** Quản lý qua Remote Token (Zero Trust Dashboard) hoặc Local Ingress trực tiếp trên giao diện Home Assistant[span_8](start_span)[span_8](end_span).
- **Đa ngôn ngữ:** Tự động chuyển đổi Tiếng Việt / English theo ngôn ngữ hệ thống[span_9](start_span)[span_9](end_span).

---

### 2. 🛡️ Tailscale Pro (`tailscale`)
Mạng riêng ảo Mesh VPN (WireGuard) tốc độ cao, đóng vai trò **Subnet Router** (`192.168.68.0/24`) và **Exit Node** cho toàn bộ hệ thống mạng gia đình[span_10](start_span)[span_10](end_span).
- **Đồng bộ tức thì:** Trích xuất trực tiếp từ `tailscale/tailscale` ngay khi hãng phát hành (Xác thực kiến trúc `linux/arm64` và mã nguồn trước khi cập nhật)[span_11](start_span)[span_11](end_span).
- **Full Web UI (Ingress):** Tích hợp bảng điều khiển Tailscale Web Client ngay trên thanh công cụ của Home Assistant (Cổng `5252`)[span_12](start_span)[span_12](end_span).
- **Tối ưu phần cứng Pi 5:** Tự động kích hoạt `rx-udp-gro-forwarding` trên cổng mạng vật lý để đạt băng thông tối đa[span_13](start_span)[span_13](end_span).
- **Kiểm tra sức khỏe đường truyền (Healthcheck):** Giám sát trạng thái `BackendState` và kết nối tới máy chủ điều phối (DERP/Control Plane), tự động kết nối lại nếu bị treo[span_14](start_span)[span_14](end_span).
- **Đa ngôn ngữ:** Hỗ trợ đầy đủ Tiếng Việt (`vi.yaml`) và English (`en.yaml`) tự động theo hệ thống[span_15](start_span)[span_15](end_span).

---

### 3. 📂 WebDAV Server Pro (`webdav_pro`)
Máy chủ quản lý tập tin WebDAV tốc độ cao kết hợp **Cloud Code IDE** và giao diện **iOS 18 Files Dark UI**, mở khóa toàn bộ phân vùng hệ thống của Home Assistant cho iOS/iPadOS Files, macOS Finder, Windows Explorer, Rclone và Cloudflare Tunnel.
- **Truy cập toàn diện (Unified Root):** Mở khóa đầy đủ quyền Đọc/Ghi cho `config` (`/homeassistant`), `addon_configs`, `addons`, `backup`, `media`, `share`, và `ssl` trong một điểm gắn kết duy nhất.
- **Tương thích Native OS (WebDAV Class 1 & 2):** Tích hợp `nginx-mod-http-dav-ext` cùng vùng nhớ khóa file `davlock` hỗ trợ đầy đủ `PROPFIND`, `OPTIONS`, `PUT`, `DELETE`, `MKCOL`, `COPY`, `MOVE`, `LOCK`, `UNLOCK`.
- **Tích hợp Cloud Code IDE (Ace Editor):**
  - Tô màu cú pháp (Syntax Highlighting - One Dark Theme) cho `YAML`, `Python`, `JSON`, `Shell/Bash`, `JavaScript`, `TypeScript`, `HTML/CSS`, `PHP`, `SQL`, `Markdown`, `Dockerfile`...
  - **Kiểm tra lỗi YAML thời gian thực (`js-yaml` Linter):** Tự động phát hiện và báo chính xác số dòng bị lỗi cú pháp/thụt lề YAML trước khi lưu, bảo vệ Home Assistant khỏi lỗi cấu hình.
  - **Thanh công cụ lập trình di động:** Tích hợp sẵn các nút `Undo`, `Redo`, `Find & Replace`, `Tab (2 spaces)`, `Toggle Comment (#)`, chỉnh cỡ chữ **`A+` / `A-`**, `Word Wrap` và chế độ toàn màn hình **`⛶ Zen Mode`**.
- **Live Markdown Renderer (`👁️ Preview`):** Tự động hiển thị bản xem trước chuẩn GitHub Dark cho các file `.md` (`README.md`, `CHANGELOG.md`, `DOCS.md`) với nút chuyển đổi nhanh sang chế độ sửa code.
- **Trình đọc file nén & Backup (`.tar` / `.zip` Inspector):** Duyệt nhanh danh sách cấu trúc file bên trong các bản sao lưu Home Assistant (`.tar`) hoặc file `.zip` trực tiếp trên trình duyệt mà không cần tải về máy.
- **Quản lý File chuẩn iOS 18 Files (Ingress cổng `8099`):**
  - Chuyển đổi linh hoạt giữa chế độ **Danh sách (List)** và **Lưới (Grid)**, sắp xếp (`Name A–Z`, `Newest`, `Largest`), tìm kiếm tức thì và chạm để sao chép nhanh đường dẫn (Breadcrumbs Copy Path).
  - Hỗ trợ **Tạo File mới**, **Tạo Thư mục mới**, **Nhân bản (Duplicate)**, **Đổi tên (Rename)**, **Sao chép (Copy)**, **Di chuyển (Cut & Paste)** xuyên thư mục và **Chọn hàng loạt (Multi-Select Batch Operations)**.
  - **Upload đa phương thức:** Tải nhiều file kèm thanh tiến trình phần trăm (`%`), hỗ trợ **Kéo-Thả (Drag & Drop)** trực tiếp vào trình duyệt và **Dán nhanh ảnh/file từ Clipboard (`Cmd/Ctrl + V`)**.
  - **Quick Look Media & PDF Preview:** Xem trước ảnh, phát video/âm thanh (`.mp3`, `.wav`, `.m4a`) và đọc tài liệu `PDF` ngay trong giao diện.
- **Bảo mật tối đa (Maximum Security Rating):** Đạt chuẩn bảo mật Supervisor với hồ sơ cô lập `apparmor.txt` (S6-Overlay v3), mật khẩu mã hóa Bcrypt (`htpasswd -B`), chống dò mật khẩu (`limit_req_zone`) và phân quyền `read_only` / `allowed_users` cho từng thư mục.

---

## 🔄 Quy chuẩn Tự động Cập nhật & Phiên bản (CI/CD Versioning)

Hệ thống GitHub Actions trong kho lưu trữ này vận hành hoàn toàn tự động theo quy tắc:
- **Nâng cấp Major Version (`1.0.x` ➔ `2.0.0`):** Khi nhà phát hành (Cloudflare, Tailscale, Alpine/Nginx) tung ra bản cập nhật mới từ Upstream.
- **Nâng cấp Patch Version (`1.0.0` ➔ `1.0.1`):** Khi có chỉnh sửa cấu hình, tối ưu hóa script hoặc nâng cấp giao diện nội bộ trong Repository.
- **Zero-Broken-Build & Visual Dashboard:** Mọi bản cập nhật đều được kiểm thử đóng gói Docker (`docker build`) và xuất bảng báo cáo trực quan trên GitHub Actions Summary trước khi đẩy commit phát hành lên nhánh `main`.

---

## 🛠️ Hướng dẫn cài đặt vào Home Assistant

1. Truy cập **Home Assistant** -> **Settings (Cài đặt)** -> **Add-ons (Tiện ích bổ sung)** -> **Add-on Store (Cửa hàng)**[span_16](start_span)[span_16](end_span).
2. Bấm vào biểu tượng **3 chấm** ở góc trên bên phải -> Chọn **Repositories (Kho lưu trữ)**[span_17](start_span)[span_17](end_span).
3. Dán đường dẫn sau vào và bấm **Add (Thêm)**[span_18](start_span)[span_18](end_span):
   ```text
   [https://github.com/boystyle2010/ha-addons](https://github.com/boystyle2010/ha-addons)
