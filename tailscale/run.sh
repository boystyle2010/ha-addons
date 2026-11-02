#!/usr/bin/with-contenv bashio

SOCK="/var/run/tailscale/tailscaled.sock"

# 1. Đọc cấu hình từ UI của Home Assistant
AUTH_KEY=$(bashio::config 'auth_key')
HOSTNAME=$(bashio::config 'hostname')
LOGIN_SERVER=$(bashio::config 'login_server')
ACCEPT_DNS=$(bashio::config 'accept_dns')
ACCEPT_ROUTES=$(bashio::config 'accept_routes')
EXIT_NODE_ADV=$(bashio::config 'advertise_exit_node')
CONNECTOR=$(bashio::config 'advertise_connector')
ALWAYS_DERP=$(bashio::config 'always_use_derp')
ENABLE_SSH=$(bashio::config 'enable_ssh')
SNAT_ROUTES=$(bashio::config 'snat_subnet_routes')
STATEFUL=$(bashio::config 'stateful_filtering')
USERSPACE=$(bashio::config 'userspace_networking')
LOG_UPLOAD=$(bashio::config 'log_upload')
SHARE_MODE=$(bashio::config 'share_homeassistant')
SHARE_PORT=$(bashio::config 'share_on_port')
EXTRA_ARGS=$(bashio::config 'extra_args')

USE_EXIT_NODE=""
if bashio::config.has_value 'exit_node'; then
    USE_EXIT_NODE=$(bashio::config 'exit_node')
fi

ROUTES_LIST=""
if bashio::config.has_value 'advertise_routes'; then
    ROUTES_LIST=$(bashio::config 'advertise_routes | join(",")')
fi

TAGS_LIST=""
if bashio::config.has_value 'advertise_tags'; then
    for TAG in $(bashio::config 'advertise_tags'); do
        if [[ "${TAG}" =~ ^tag:[A-Za-z][A-Za-z0-9-]*$ ]]; then
            TAGS_LIST="${TAGS_LIST:+${TAGS_LIST},}${TAG}"
        else
            bashio::log.warning "Bỏ qua tag không hợp lệ '${TAG}' (phải có dạng tag:ten-tag)."
        fi
    done
fi

if [ -n "${USE_EXIT_NODE}" ] && bashio::var.true "${EXIT_NODE_ADV}"; then
    bashio::log.warning "Không thể vừa quảng bá exit node vừa dùng exit node khác. Bỏ qua tùy chọn 'exit_node'."
    USE_EXIT_NODE=""
fi

if bashio::var.true "${ALWAYS_DERP}"; then
    export TS_DEBUG_ALWAYS_USE_DERP=true
fi
if ! bashio::var.true "${LOG_UPLOAD}"; then
    export TS_NO_LOGS_NO_SUPPORT=true
fi

# 2. Tối ưu hóa cổng mạng (UDP GRO Forwarding)
if ! bashio::var.true "${USERSPACE}"; then
    NETDEV=$(ip -o route get 8.8.8.8 2>/dev/null | cut -f 5 -d " ")
    if [ -n "${NETDEV}" ]; then
        bashio::log.info "Đang tối ưu hóa thông lượng UDP GRO trên cổng mạng ${NETDEV}..."
        ethtool -K "${NETDEV}" rx-udp-gro-forwarding on rx-gro-list off 2>/dev/null || true
    fi
fi

# 3. Khởi tạo thư mục lưu trữ trạng thái bền vững
mkdir -p /data/state /var/run/tailscale /run/nginx

TAILSCALED_PID=""
WEB_PID=""
NGINX_PID=""

cleanup() {
    bashio::log.info "Đang dừng tiến trình Tailscale Pro an toàn..."
    [ -n "${NGINX_PID}" ] && kill -TERM "${NGINX_PID}" 2>/dev/null || true
    [ -n "${WEB_PID}" ] && kill -TERM "${WEB_PID}" 2>/dev/null || true
    if [ -n "${TAILSCALED_PID}" ]; then
        kill -TERM "${TAILSCALED_PID}" 2>/dev/null || true
        wait "${TAILSCALED_PID}" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup SIGTERM SIGINT

TAILSCALED_ARGS=(
    "--state=/data/state/tailscaled.state"
    "--statedir=/data/state"
    "--socket=${SOCK}"
    "--port=41641"
)
if bashio::var.true "${USERSPACE}"; then
    bashio::log.info "Chế độ userspace networking: sẽ không tạo card mạng tailscale0."
    TAILSCALED_ARGS+=("--tun=userspace-networking")
else
    TAILSCALED_ARGS+=("--tun=tailscale0")
fi

bashio::log.info "Đang khởi chạy tiến trình nền tailscaled..."
tailscaled "${TAILSCALED_ARGS[@]}" &
TAILSCALED_PID=$!

# Đợi socket sẵn sàng (tối đa 15 giây)
WAIT_COUNT=0
while [ ! -S "${SOCK}" ]; do
    if ! kill -0 "${TAILSCALED_PID}" 2>/dev/null; then
        bashio::log.error "tailscaled đã thoát ngay khi khởi động."
        exit 1
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ "${WAIT_COUNT}" -ge 15 ]; then
        bashio::log.error "Không thể khởi tạo socket tailscaled! Đang thoát..."
        kill -TERM "${TAILSCALED_PID}" 2>/dev/null || true
        exit 1
    fi
done

# 4. Khởi chạy giao diện Web UI cho Home Assistant Ingress (Cổng 5252 -> 5253)
bashio::log.info "Đang khởi chạy máy chủ Web UI nội bộ cho Home Assistant Ingress (Cổng 5252)..."

# Tắt chế độ webclient cũ để tránh xung đột port
tailscale --socket="${SOCK}" set --webclient=false 2>/dev/null || true

# Chạy tiến trình tailscale web lắng nghe cục bộ ở cổng 5253
tailscale --socket="${SOCK}" web --listen=127.0.0.1:5253 &
WEB_PID=$!

# Cấu hình Nginx proxy ở cổng 5252: chỉ cho phép kết nối từ Home Assistant Ingress (172.30.32.2) và localhost
cat > /etc/nginx/http.d/ingress.conf <<'EOF'
server {
    listen 5252;
    allow 127.0.0.1;
    allow 172.30.32.2;
    deny all;

    access_log off;

    location / {
        proxy_pass http://127.0.0.1:5253;
        proxy_http_version 1.1;
        proxy_set_header Host "127.0.0.1:5253";
        proxy_set_header Origin "http://127.0.0.1:5253";
        proxy_set_header Referer "http://127.0.0.1:5253/";
        proxy_set_header X-Forwarded-For "";
        proxy_set_header X-Forwarded-Host "";
        proxy_set_header X-Forwarded-Proto "";
        proxy_buffering off;
    }
}
EOF
rm -f /etc/nginx/http.d/default.conf
nginx -g "daemon off;" &
NGINX_PID=$!

# 5. Xây dựng tham số cấu hình Tailscale
UP_ARGS=(
    "--hostname=${HOSTNAME}"
    "--reset"
)

if bashio::config.has_value 'login_server'; then
    UP_ARGS+=("--login-server=${LOGIN_SERVER}")
fi

if ! bashio::var.is_empty "${AUTH_KEY}"; then
    UP_ARGS+=("--authkey=${AUTH_KEY}")
fi

if bashio::var.true "${EXIT_NODE_ADV}"; then
    UP_ARGS+=("--advertise-exit-node")
fi

if bashio::var.true "${CONNECTOR}"; then
    UP_ARGS+=("--advertise-connector")
fi

if [ -n "${ROUTES_LIST}" ]; then
    UP_ARGS+=("--advertise-routes=${ROUTES_LIST}")
fi

if [ -n "${TAGS_LIST}" ]; then
    UP_ARGS+=("--advertise-tags=${TAGS_LIST}")
fi

if [ -n "${USE_EXIT_NODE}" ]; then
    UP_ARGS+=("--exit-node=${USE_EXIT_NODE}")
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

if bashio::var.true "${STATEFUL}"; then
    UP_ARGS+=("--stateful-filtering")
fi

if ! bashio::var.is_empty "${EXTRA_ARGS}"; then
    # shellcheck disable=SC2206
    UP_ARGS+=(${EXTRA_ARGS})
fi

# 6. Kết nối Tailscale
SAFE_ARGS="${UP_ARGS[*]}"
if ! bashio::var.is_empty "${AUTH_KEY}"; then
    SAFE_ARGS="${SAFE_ARGS//"${AUTH_KEY}"/***}"
fi
bashio::log.info "Đang áp dụng cấu hình Tailscale Pro: ${SAFE_ARGS}"
tailscale --socket="${SOCK}" up "${UP_ARGS[@]}" &

apply_share() {
    case "${SHARE_MODE}" in
        serve|funnel)
            if [ "${SHARE_MODE}" = "funnel" ] && ! [[ "${SHARE_PORT}" =~ ^(443|8443|10000)$ ]]; then
                bashio::log.warning "Funnel chỉ hỗ trợ cổng 443, 8443 hoặc 10000 (đang đặt ${SHARE_PORT}). Bỏ qua chia sẻ."
                return 1
            fi
            tailscale --socket="${SOCK}" serve reset >/dev/null 2>&1 || true
            if tailscale --socket="${SOCK}" "${SHARE_MODE}" --bg --https="${SHARE_PORT}" "http://127.0.0.1:8123"; then
                bashio::log.info "✅ Đã bật ${SHARE_MODE} cho Home Assistant trên cổng ${SHARE_PORT}."
            else
                bashio::log.warning "Không bật được ${SHARE_MODE}. Hãy bật HTTPS Certificates trong Tailscale admin console rồi khởi động lại add-on."
                return 1
            fi
            ;;
        *)
            tailscale --socket="${SOCK}" serve reset >/dev/null 2>&1 || true
            ;;
    esac
    return 0
}

bashio::log.info "✅ Tailscale Pro đã hoạt động và bắt đầu chế độ giám sát sức khỏe đường truyền (Health Monitor)!"

# 7. Vòng lặp kiểm tra sức khỏe đường truyền & tự phục hồi (mỗi 60 giây)
FAIL_COUNT=0
SHARE_DONE=0
while kill -0 "${TAILSCALED_PID}" 2>/dev/null; do
    sleep 60 &
    wait $!

    # Tự động khởi động lại tiến trình Web UI nếu chẳng may bị tắt
    if ! kill -0 "${WEB_PID}" 2>/dev/null; then
        bashio::log.warning "Tiến trình Web UI bị dừng, đang khởi chạy lại..."
        tailscale --socket="${SOCK}" web --listen=127.0.0.1:5253 &
        WEB_PID=$!
    fi

    STATE=$(tailscale --socket="${SOCK}" status --json 2>/dev/null | jq -r '.BackendState // "Unknown"')

    if [ "${STATE}" == "Running" ]; then
        FAIL_COUNT=0
        if [ "${SHARE_DONE}" -eq 0 ]; then
            apply_share || true
            SHARE_DONE=1
        fi
    elif [ "${STATE}" == "NeedsLogin" ] || [ "${STATE}" == "Starting" ]; then
        bashio::log.warning "Tailscale đang ở trạng thái '${STATE}'. Vui lòng kiểm tra Auth Key hoặc đăng nhập qua Web UI."
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        bashio::log.warning "⚠️ Đường truyền Tailscale không ổn định (Trạng thái: ${STATE} - Lần ${FAIL_COUNT}/3). Đang thử kích hoạt lại..."
        tailscale --socket="${SOCK}" up "${UP_ARGS[@]}" || true

        if [ "${FAIL_COUNT}" -ge 3 ]; then
            bashio::log.error "❌ Đường truyền bị treo quá 3 lần liên tiếp. Đang thoát để Home Assistant Watchdog khởi động lại mới hoàn toàn!"
            kill -TERM "${TAILSCALED_PID}" 2>/dev/null || true
            exit 1
        fi
    fi
done

bashio::log.error "Tiến trình tailscaled đã dừng đột ngột!"
exit 1
