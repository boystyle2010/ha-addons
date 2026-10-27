#!/usr/bin/with-contenv bashio

bashio::log.info "==================================================="
bashio::log.info " Khởi động Cloudflared Pro Add-on (Raspberry Pi 5) "
bashio::log.info " Phiên bản binary: $(cloudflared --version)"
bashio::log.info "==================================================="

# Đọc cấu hình từ UI của Home Assistant
TOKEN=$(bashio::config 'tunnel_token')
PROTOCOL=$(bashio::config 'protocol')
LOG_LEVEL=$(bashio::config 'log_level')
METRICS_PORT=$(bashio::config 'metrics_port')
POST_QUANTUM=$(bashio::config 'post_quantum')
EDGE_IP=$(bashio::config 'ha_Edge_IP_Version')

# Khởi tạo mảng tham số dòng lệnh
ARGS=("tunnel" "--no-autoupdate")
ARGS+=("--protocol" "${PROTOCOL}")
ARGS+=("--loglevel" "${LOG_LEVEL}")
ARGS+=("--edge-ip-version" "${EDGE_IP}")

# Cổng Metrics
if [ "${METRICS_PORT}" -ne 0 ] && [ "${METRICS_PORT}" != "null" ]; then
    ARGS+=("--metrics" "0.0.0.0:${METRICS_PORT}")
    bashio::log.info "Đã bật Prometheus Metrics tại cổng: ${METRICS_PORT}"
fi

# Chế độ Post-Quantum
if bashio::config.true 'post_quantum'; then
    ARGS+=("--post-quantum")
    bashio::log.info "Đã kích hoạt mã hóa Post-Quantum."
fi

# Thêm các Custom Flags từ UI (nếu có)
if bashio::config.has_value 'custom_flags'; then
    for flag in $(bashio::config 'custom_flags'); do
        ARGS+=("${flag}")
    done
fi

# Kiểm tra chế độ chạy: Remote Token (Zero Trust) hay Local Config YAML
if bashio::config.has_value 'tunnel_token'; then
    bashio::log.info "Chế độ hoạt động: Remote Managed Tunnel (Zero Trust Token)"
    ARGS+=("run" "--token" "${TOKEN}")
else
    bashio::log.info "Chế độ hoạt động: Local Configuration (/share/cloudflared/config.yml)"
    mkdir -p /share/cloudflared
    CONFIG_FILE="/share/cloudflared/config.yml"

    # Nếu người dùng khai báo hostname trên UI, tự động sinh file config.yml
    if bashio::config.has_value 'external_hostname'; then
        EXT_HOST=$(bashio::config 'external_hostname')
        CATCH_ALL=$(bashio::config 'catch_all_service')
        
        bashio::log.info "Đang tạo file cấu hình Ingress tự động cho: ${EXT_HOST}"
        cat <<EOF > "${CONFIG_FILE}"
tunnel: homeassistant-local
credentials-file: /share/cloudflared/credentials.json
ingress:
  - hostname: "${EXT_HOST}"
    service: http://localhost:8123
EOF
        # Thêm các subdomain phụ từ UI
        for host in $(bashio::config 'additional_hosts|keys'); do
            H_NAME=$(bashio::config "additional_hosts[${host}].hostname")
            H_SVC=$(bashio::config "additional_hosts[${host}].service")
            H_TLS=$(bashio::config "additional_hosts[${host}].no_tls_verify")
            H_HEADER=$(bashio::config "additional_hosts[${host}].http_host_header")

            echo "  - hostname: \"${H_NAME}\"" >> "${CONFIG_FILE}"
            echo "    service: ${H_SVC}" >> "${CONFIG_FILE}"
            if [ "${H_TLS}" == "true" ] || [ "${H_HEADER}" != "null" ]; then
                echo "    originRequest:" >> "${CONFIG_FILE}"
                [ "${H_TLS}" == "true" ] && echo "      noTLSVerify: true" >> "${CONFIG_FILE}"
                [ "${H_HEADER}" != "null" ] && [ -n "${H_HEADER}" ] && echo "      httpHostHeader: \"${H_HEADER}\"" >> "${CONFIG_FILE}"
            fi
        done

        echo "  - service: ${CATCH_ALL}" >> "${CONFIG_FILE}"
    fi

    if [ ! -f "${CONFIG_FILE}" ]; then
        bashio::log.fatal "Không tìm thấy Tunnel Token và cũng chưa có file ${CONFIG_FILE}!"
        exit 1
    fi

    ARGS+=("--config" "${CONFIG_FILE}" "run")
fi

# Thực thi tiến trình cloudflared
exec /usr/bin/cloudflared "${ARGS[@]}"

