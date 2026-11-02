#!/usr/bin/with-contenv bashio

# 1. Đọc cấu hình từ giao diện Home Assistant
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

# 2. Tối ưu hóa card mạng vật lý (UDP GRO) cho Exit Node & Subnet Router trên Pi 5
NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
if [ -n "${NETDEV}" ]; then
    bashio::log.info "Đang tối ưu hóa thông lượng UDP GRO trên cổng mạng ${NETDEV}..."
    ethtool -K "${NETDEV}" rx-udp-gro-forwarding on rx-gro-list off 2>/dev/null || true
fi

# 3. Khởi tạo thư mục lưu trữ trạng thái bền vững trên NVMe
mkdir -p /data/state /var/run/tailscale

bashio::log.info "Đang khởi chạy tiến trình nền tailscaled..."
tailscaled \
    --state=/data/state/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --port=41641 \
    --tun=tailscale0 &
TAILSCALED_PID=$!

# Chờ socket khởi tạo xong
while [ ! -S /var/run/tailscale/tailscaled.sock ]; do
    sleep 1
done

# 4. Ánh xạ cấu hình từ UI vào cờ lệnh
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

# 5. Bật Web UI trước (để nếu chưa có Auth Key thì bạn vẫn vào Web UI bấm Login được ngay)
bashio::log.info "Đang kích hoạt giao diện Web UI nội bộ trên cổng 5252..."
tailscale --socket=/var/run/tailscale/tailscaled.sock set --webclient=true || true

# 6. Đưa Tailscale lên mạng
bashio::log.info "Đang kết nối Tailscale Pro với cấu hình: ${UP_ARGS[*]}"
tailscale --socket=/var/run/tailscale/tailscaled.sock up "${UP_ARGS[@]}" &

bashio::log.info "Tailscale Pro đã sẵn sàng hoạt động!"
wait "${TAILSCALED_PID}"
