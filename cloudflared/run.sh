#!/usr/bin/with-contenv bashio

bashio::log.info "==================================================="
bashio::log.info " Starting Cloudflared Pro Add-on (Raspberry Pi 5)  "
bashio::log.info " Binary version: $(cloudflared --version)"
bashio::log.info "==================================================="

TOKEN=$(bashio::config 'tunnel_token')
PROTOCOL=$(bashio::config 'protocol')
LOG_LEVEL=$(bashio::config 'log_level')
METRICS_PORT=$(bashio::config 'metrics_port')
EDGE_IP_RAW=$(bashio::config 'ha_Edge_IP_Version')
RETRIES=$(bashio::config 'retries')
GRACE_PERIOD=$(bashio::config 'grace_period')

# Chuyển đổi hiển thị UI (Auto / IPv4 / IPv6) sang tham số chuẩn của cloudflared (auto / 4 / 6)
case "${EDGE_IP_RAW}" in
    "IPv4"|"4")
        EDGE_IP="4"
        ;;
    "IPv6"|"6")
        EDGE_IP="6"
        ;;
    *)
        EDGE_IP="auto"
        ;;
esac

ARGS=("tunnel" "--no-autoupdate")
ARGS+=("--protocol" "${PROTOCOL}")
ARGS+=("--loglevel" "${LOG_LEVEL}")
ARGS+=("--edge-ip-version" "${EDGE_IP}")
ARGS+=("--retries" "${RETRIES}")
ARGS+=("--grace-period" "${GRACE_PERIOD}")

bashio::log.info "Connection settings: Protocol=${PROTOCOL} | Edge IP=${EDGE_IP_RAW} (${EDGE_IP}) | Retries=${RETRIES}"

# Cổng Metrics
if [ -n "${METRICS_PORT}" ] && [ "${METRICS_PORT}" != "0" ] && [ "${METRICS_PORT}" != "null" ]; then
    ARGS+=("--metrics" "0.0.0.0:${METRICS_PORT}")
    bashio::log.info "Prometheus Metrics enabled on port: ${METRICS_PORT}"
fi

# Chế độ Post-Quantum
if bashio::config.true 'post_quantum'; then
    ARGS+=("--post-quantum")
    bashio::log.info "Post-Quantum Cryptography enabled."
fi

# Thêm các Custom Flags từ UI (nếu có)
if bashio::config.has_value 'custom_flags'; then
    for flag in $(bashio::config 'custom_flags'); do
        ARGS+=("${flag}")
    done
fi

# Kiểm tra chế độ chạy: Remote Token (Zero Trust) hay Local Config YAML
if bashio::config.has_value 'tunnel_token'; then
    bashio::log.info "Operating Mode: Remote Managed Tunnel (Zero Trust Token)"
    ARGS+=("run" "--token" "${TOKEN}")
else
    bashio::log.info "Operating Mode: Local Configuration (/share/cloudflared/config.yml)"
    mkdir -p /share/cloudflared
    CONFIG_FILE="/share/cloudflared/config.yml"

    if bashio::config.has_value 'external_hostname'; then
        EXT_HOST=$(bashio::config 'external_hostname')
        CATCH_ALL=$(bashio::config 'catch_all_service')
        
        bashio::log.info "Generating Ingress rules for: ${EXT_HOST}"
        cat <<EOF > "${CONFIG_FILE}"
tunnel: homeassistant-local
credentials-file: /share/cloudflared/credentials.json
ingress:
  - hostname: "${EXT_HOST}"
    service: http://homeassistant:8123
EOF
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
        bashio::log.fatal "No Tunnel Token provided and ${CONFIG_FILE} does not exist!"
        exit 1
    fi

    ARGS+=("--config" "${CONFIG_FILE}" "run")
fi

exec /usr/bin/cloudflared "${ARGS[@]}"
