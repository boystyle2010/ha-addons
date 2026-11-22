#!/usr/bin/with-contenv bashio

HOST_ARCH=$(uname -m)
bashio::log.info "==================================================="
bashio::log.info " Starting Cloudflared Pro Add-on (Arch: ${HOST_ARCH})"
bashio::log.info " Binary version: $(cloudflared --version)"
bashio::log.info "==================================================="

TOKEN=$(bashio::config 'tunnel_token')
PROTOCOL=$(bashio::config 'protocol')
LOG_LEVEL=$(bashio::config 'log_level')
METRICS_PORT=$(bashio::config 'metrics_port')
EDGE_IP_RAW=$(bashio::config 'edge_ip_version')
RETRIES=$(bashio::config 'retries')
GRACE_PERIOD=$(bashio::config 'grace_period')

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

if [ -n "${METRICS_PORT}" ] && [ "${METRICS_PORT}" != "0" ] && [ "${METRICS_PORT}" != "null" ]; then
    ARGS+=("--metrics" "0.0.0.0:${METRICS_PORT}")
    bashio::log.info "Prometheus Metrics & Healthcheck enabled on port: ${METRICS_PORT}"
else
    ARGS+=("--metrics" "127.0.0.1:49999")
    bashio::log.info "Internal Healthcheck endpoint enabled on 127.0.0.1:49999/ready"
fi

if bashio::config.true 'post_quantum'; then
    ARGS+=("--post-quantum")
    bashio::log.info "Post-Quantum Cryptography enabled."
fi

# custom_flags: one list item per flag (a value may follow after a space or "="). Read item by item so that
# characters such as * or ? are never expanded by the shell.
if bashio::config.has_value 'custom_flags'; then
    while IFS= read -r item; do
        [ -z "${item}" ] && continue
        read -r -a parts <<< "${item}"
        for part in "${parts[@]}"; do
            case "${part}" in
                --token|--token=*)
                    bashio::log.warning "Ignoring '--token' in custom_flags: use the tunnel_token option instead."
                    ;;
                *)
                    ARGS+=("${part}")
                    ;;
            esac
        done
    done < <(bashio::config 'custom_flags|.[]')
fi

if bashio::config.has_value 'tunnel_token'; then
    bashio::log.info "Operating Mode: Remote Managed Tunnel (Zero Trust Token)"
    # Token qua biến môi trường thay vì dòng lệnh (không lộ trong danh sách tiến trình 'ps')
    export TUNNEL_TOKEN="${TOKEN}"
    ARGS+=("run")
else
    bashio::log.info "Operating Mode: Local Configuration (managed by this add-on)"
    # Chứng chỉ đăng nhập Cloudflare (toàn quyền DNS/tunnel của tài khoản) và credentials được giữ trong /data,
    # thư mục riêng của add-on, KHÔNG để trong /share (mọi add-on khác và người dùng Samba/WebDAV đều đọc được).
    CF_DIR="/data/cloudflared"
    CF_HOME="${CF_DIR}/home"                       # cloudflared keeps its login certificate in $HOME/.cloudflared
    CERT_FILE="${CF_HOME}/.cloudflared/cert.pem"
    CRED_FILE="${CF_DIR}/credentials.json"
    CONFIG_FILE="${CF_DIR}/config.yml"
    mkdir -p "${CF_DIR}" "${CF_HOME}/.cloudflared"
    chmod 700 "${CF_DIR}" "${CF_HOME}" "${CF_HOME}/.cloudflared"

    # Chuyển dữ liệu cũ (hoặc credentials bạn tự đặt vào) từ /share/cloudflared sang /data/cloudflared
    OLD_DIR="/share/cloudflared"
    if [ -f "${OLD_DIR}/credentials.json" ]; then
        if [ ! -f "${CRED_FILE}" ]; then
            mv "${OLD_DIR}/credentials.json" "${CRED_FILE}"
            bashio::log.notice "Moved ${OLD_DIR}/credentials.json to the add-on's private storage."
        else
            bashio::log.warning "${OLD_DIR}/credentials.json is ignored: the add-on already has a tunnel. Delete that file (it is readable by other add-ons)."
        fi
    fi
    if [ -f "${OLD_DIR}/home/.cloudflared/cert.pem" ] && [ ! -f "${CERT_FILE}" ]; then
        mv "${OLD_DIR}/home/.cloudflared/cert.pem" "${CERT_FILE}"
        bashio::log.notice "Moved the Cloudflare login certificate out of ${OLD_DIR} to the add-on's private storage."
    fi
    if [ -d "${OLD_DIR}" ]; then
        # Xóa phần còn lại (file JSON của tunnel, config.yml cũ) có chứa bí mật; giữ thư mục nếu người dùng còn file khác
        rm -f "${OLD_DIR}/config.yml" "${OLD_DIR}"/home/.cloudflared/*.json 2>/dev/null || true
        rmdir "${OLD_DIR}/home/.cloudflared" "${OLD_DIR}/home" "${OLD_DIR}" 2>/dev/null || true
    fi
    [ -f "${CRED_FILE}" ] && chmod 600 "${CRED_FILE}"
    [ -f "${CERT_FILE}" ] && chmod 600 "${CERT_FILE}"

    EXT_HOST=$(bashio::config 'external_hostname')
    [ "${EXT_HOST}" = "null" ] && EXT_HOST=""
    HOST_COUNT=$(bashio::config 'additional_hosts|length' 2>/dev/null || echo 0)

    if [ -n "${EXT_HOST}" ] || [ "${HOST_COUNT}" -gt 0 ]; then
        TUNNEL_NAME=$(bashio::config 'tunnel_name')
        if [ -z "${TUNNEL_NAME}" ] || [ "${TUNNEL_NAME}" = "null" ]; then TUNNEL_NAME="homeassistant"; fi

        # Where do hostnames that are not listed go? (safe default: 404)
        CATCH_ALL=$(bashio::config 'catch_all_service')
        if bashio::config.true 'nginx_proxy_manager'; then
            CATCH_ALL="http://a0d7b954-nginxproxymanager:80"
            bashio::log.info "Nginx Proxy Manager enabled: unlisted hostnames go to ${CATCH_ALL}"
        elif [ -z "${CATCH_ALL}" ] || [ "${CATCH_ALL}" = "null" ]; then
            CATCH_ALL="http_status:404"
        fi

        # Step 1: log in to Cloudflare once (the URL appears in this log), then create the tunnel.
        if [ ! -f "${CRED_FILE}" ]; then
            if [ ! -f "${CERT_FILE}" ]; then
                bashio::log.notice "First start: open the URL shown below in a browser, log in to Cloudflare and choose your domain. You have 10 minutes."
                HOME="${CF_HOME}" timeout 600 cloudflared tunnel login || true
                if [ ! -f "${CERT_FILE}" ]; then
                    bashio::log.fatal "Cloudflare login was not completed. Restart the add-on to try again, or use the tunnel_token option."
                    exit 1
                fi
            fi
            bashio::log.info "Creating tunnel '${TUNNEL_NAME}'..."
            if ! CREATE_OUT=$(HOME="${CF_HOME}" cloudflared tunnel create "${TUNNEL_NAME}" 2>&1); then
                bashio::log.error "${CREATE_OUT}"
                bashio::log.fatal "Could not create the tunnel. If a tunnel named '${TUNNEL_NAME}' already exists, choose another tunnel_name or delete it in the Cloudflare dashboard."
                exit 1
            fi
            NEW_ID=$(printf '%s' "${CREATE_OUT}" | grep -oE '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}' | head -1)
            if [ -z "${NEW_ID}" ] || [ ! -f "${CF_HOME}/.cloudflared/${NEW_ID}.json" ]; then
                bashio::log.error "${CREATE_OUT}"
                bashio::log.fatal "Tunnel created, but its credentials file was not found."
                exit 1
            fi
            cp "${CF_HOME}/.cloudflared/${NEW_ID}.json" "${CRED_FILE}"
            chmod 600 "${CRED_FILE}"
        fi

        TUNNEL_ID=$(jq -r '.TunnelID // empty' "${CRED_FILE}" 2>/dev/null)
        if [ -z "${TUNNEL_ID}" ]; then
            bashio::log.fatal "${CRED_FILE} is not a valid tunnel credentials file."
            exit 1
        fi

        # Step 2: write the routing file from the options.
        bashio::log.info "Generating Ingress rules for tunnel ${TUNNEL_ID}"
        {
            echo "tunnel: ${TUNNEL_ID}"
            echo "credentials-file: ${CRED_FILE}"
            echo "ingress:"
            if [ -n "${EXT_HOST}" ]; then
                echo "  - hostname: \"${EXT_HOST}\""
                echo "    service: http://homeassistant:8123"
            fi
        } > "${CONFIG_FILE}"

        DNS_HOSTS=()
        [ -n "${EXT_HOST}" ] && DNS_HOSTS+=("${EXT_HOST}")
        for host in $(bashio::config 'additional_hosts|keys'); do
            H_NAME=$(bashio::config "additional_hosts[${host}].hostname")
            H_SVC=$(bashio::config "additional_hosts[${host}].service")
            H_TLS=$(bashio::config "additional_hosts[${host}].no_tls_verify")
            H_HEADER=$(bashio::config "additional_hosts[${host}].http_host_header")
            DNS_HOSTS+=("${H_NAME}")

            echo "  - hostname: \"${H_NAME}\"" >> "${CONFIG_FILE}"
            echo "    service: ${H_SVC}" >> "${CONFIG_FILE}"
            if [ "${H_TLS}" == "true" ] || { [ "${H_HEADER}" != "null" ] && [ -n "${H_HEADER}" ]; }; then
                echo "    originRequest:" >> "${CONFIG_FILE}"
                [ "${H_TLS}" == "true" ] && echo "      noTLSVerify: true" >> "${CONFIG_FILE}"
                [ "${H_HEADER}" != "null" ] && [ -n "${H_HEADER}" ] && echo "      httpHostHeader: \"${H_HEADER}\"" >> "${CONFIG_FILE}"
            fi
        done
        echo "  - service: ${CATCH_ALL}" >> "${CONFIG_FILE}"

        # Step 3: point each hostname at the tunnel (needs the login certificate from step 1).
        # An existing DNS record that points somewhere else is only replaced when overwrite_dns is enabled.
        DNS_FLAGS=()
        if bashio::config.true 'overwrite_dns'; then
            DNS_FLAGS+=("--overwrite-dns")
            bashio::log.warning "overwrite_dns is enabled: existing DNS records with the same names will be replaced."
        fi
        if [ -f "${CERT_FILE}" ]; then
            for H in "${DNS_HOSTS[@]}"; do
                if DNS_OUT=$(HOME="${CF_HOME}" cloudflared tunnel route dns "${DNS_FLAGS[@]}" "${TUNNEL_ID}" "${H}" 2>&1); then
                    bashio::log.info "DNS record ready: ${H}"
                else
                    bashio::log.warning "Could not set the DNS record for ${H}: $(printf '%s' "${DNS_OUT}" | tail -n 1)"
                    bashio::log.warning "If a record with this name already exists, delete it in Cloudflare, enable overwrite_dns, or point it yourself (CNAME to ${TUNNEL_ID}.cfargotunnel.com)."
                fi
            done
        else
            bashio::log.info "DNS records are not updated automatically (no login certificate). Make sure each hostname has a CNAME to ${TUNNEL_ID}.cfargotunnel.com."
        fi
    fi

    if [ ! -f "${CONFIG_FILE}" ]; then
        bashio::log.fatal "No Tunnel Token provided, and nothing to expose: set tunnel_token, or external_hostname / additional_hosts."
        exit 1
    fi

    ARGS+=("--config" "${CONFIG_FILE}" "run")
fi

exec /usr/bin/cloudflared "${ARGS[@]}"
