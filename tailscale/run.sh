#!/usr/bin/with-contenv bashio

# 1. Đọc cấu hình từ UI của Home Assistant
AUTH_KEY=$(bashio::config 'auth_key')
HOSTNAME=$(bashio::config 'hostname')
EXIT_NODE=$(bashio::config 'advertise_exit_node')
ACCEPT_ROUTES=$(bashio::config 'accept_routes')
ACCEPT_DNS=$(bashio::config 'accept_dns')
ENABLE_SSH=$(bashio::config 'enable_ssh')
SNAT_ROUTES=$(bashio::config 'snat_subnet_routes')
EXTRA_ARGS=$(bashio::config 'extra_args')

ROUTES_LIST=""
if bashio::config.has_value 'advertise_routes'; then
    ROUTES_LIST=$(bashio::config 'advertise_routes | join(",")')
fi

# 2. Tối ưu hóa phần cứng cổng mạng Pi 5 (UDP GRO Forwarding)
NETDEV=$(ip -o route get 8.8.8.8 2>/dev/null | cut -f 5 -d " ")
if [ -n "${NETDEV}" ]; then
    bashio::log.info "Đang tối ưu hóa thông lượng UDP GRO trên cổng mạng ${NETDEV}..."
    ethtool -K "${NETDEV}" rx-udp-gro-forwarding on rx-gro-list off 2>/dev/null || true
fi

# 3. Khởi tạo thư mục lưu trữ trạng thái bền vững trên NVMe
mkdir -p /data/state /var/run/tailscale

# Bắt tín hiệu tắt từ Home Assistant để đóng kết nối an toàn
cleanup() {
    bashio::log.info "Đang dừng tiến trình Tailscale Pro an toàn..."
    kill -TERM "${TAILSCALED_PID}" 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

bashio::log.info "Đang khởi chạy tiến trình nền tailscaled..."
tailscaled \
    --state=/data/state/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --port=41641 \
    --tun=tailscale0 &
TAILSCALED_PID=$!

# Đợi socket sẵn sàng (Tối đa 15 giây)
WAIT_COUNT=0
while [ ! -S /var/run/tailscale/tailscaled.sock ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ "${WAIT_COUNT}" -ge 15 ]; then
        bashio::log.error "Không thể khởi tạo socket tailscaled! Đang thoát để Watchdog khởi động lại..."
        exit 1
    fi
done

# 4. Xây dựng tham số cấu hình
UP_ARGS=(
    "--hostname=${HOSTNAME}"
    "--reset"
)

if ! bashio::var.is_empty "${AUTH_KEY}"; then
    UP_ARGS+=("--authkey=${AUTH_KEY}")
fi

if bashio::var.true "${EXIT_NODE}"; then
    UP_ARGS+=("--advertise-exit-node")
fi

if [ -n "${ROUTES_LIST}" ]; then
    UP_ARGS+=("--advertise-routes=${ROUTES_LIST}")
fi

if bashio::var.true "${ACCEPT_ROUTES}"; then
    UP_ARGS+=("--accept-routes")
else
    UP_ARGS+=("--accept-routes=false")
fi

if bashio::var.true "${ACCEPT_DNS}"; then
    UP_ARGS+=("--accept-dns")
else
    UP_ARGS+=("--accept-dns=false")
fi

if bashio::var.true "${ENABLE_SSH}"; then
    UP_ARGS+=("--ssh")
fi

if bashio::var.false "${SNAT_ROUTES}"; then
    UP_ARGS+=("--snat-subnet-routes=false")
fi

if ! bashio::var.is_empty "${EXTRA_ARGS}"; then
    # shellcheck disable=SC2206
    UP_ARGS+=(${EXTRA_ARGS})
fi

# 5. Bật Web UI trên cổng 5252 cho Home Assistant Ingress
bashio::log.info "Đang kích hoạt giao diện Web UI nội bộ trên cổng 5252..."
tailscale --socket=/var/run/tailscale/tailscaled.sock set --webclient=true || true

# 6. Kết nối Tailscale
bashio::log.info "Đang áp dụng cấu hình Tailscale Pro: ${UP_ARGS[*]}"
tailscale --socket=/var/run/tailscale/tailscaled.sock up "${UP_ARGS[@]}" &

bashio::log.info "✅ Tailscale Pro đã hoạt động và bắt đầu chế độ giám sát sức khỏe đường truyền (Health Monitor)!"

# 7. Vòng lặp kiểm tra sức khỏe đường truyền & Tự phục hồi (Mỗi 60 giây)
FAIL_COUNT=0
while kill -0 "${TAILSCALED_PID}" 2>/dev/null; do
    sleep 60
    
    # Kiểm tra trạng thái BackendState
    STATE=$(tailscale --socket=/var/run/tailscale/tailscaled.sock status --json 2>/dev/null | jq -r '.BackendState // "Unknown"')
    
    if [ "${STATE}" == "Running" ]; then
        FAIL_COUNT=0
    elif [ "${STATE}" == "NeedsLogin" ] || [ "${STATE}" == "Starting" ]; then
        bashio::log.warning "Tailscale đang ở trạng thái '${STATE}'. Vui lòng kiểm tra Auth Key hoặc đăng nhập qua Web UI."
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        bashio::log.warning "⚠️ Phát hiện đường truyền Tailscale không ổn định (Trạng thái: ${STATE} - Lần ${FAIL_COUNT}/3). Đang thử kích hoạt lại..."
        tailscale --socket=/var/run/tailscale/tailscaled.sock up "${UP_ARGS[@]}" || true
        
        if [ "${FAIL_COUNT}" -ge 3 ]; then
            bashio::log.error "❌ Đường truyền bị treo quá 3 lần liên tiếp. Đang thoát container để Home Assistant Watchdog khởi động lại mới hoàn toàn!"
            kill -TERM "${TAILSCALED_PID}" 2>/dev/null || true
            exit 1
        fi
    fi
done

bashio::log.error "Tiến trình tailscaled đã dừng đột ngột!"
exit 1
