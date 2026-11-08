#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "---------------------------------------------------"
bashio::log.info " Đang khởi tạo Home Assistant WebDAV Server Pro..."
bashio::log.info "---------------------------------------------------"

CONFIG_PATH=/data/options.json
HTPASSWD_FILE=/etc/nginx/webdav.htpasswd
NGINX_CONF=/etc/nginx/nginx.conf
ROOT_DIR=/var/webdav_root

# 1. Đọc cấu hình từ Home Assistant UI
UNIFIED_ROOT=$(bashio::config 'unified_root')
SSL=$(bashio::config 'ssl')
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
MAX_UPLOAD=$(bashio::config 'max_upload_size')
FANCY_UI=$(bashio::config 'fancy_ui')
SHOW_DOTFILES=$(bashio::config 'show_dotfiles')
LOG_LEVEL=$(bashio::config 'log_level')

# 2. Khởi tạo danh sách tài khoản với mã hóa Bcrypt
rm -f "$HTPASSWD_FILE"
touch "$HTPASSWD_FILE"

USERS_COUNT=$(jq '.users | length' "$CONFIG_PATH")
if [ "$USERS_COUNT" -eq 0 ]; then
    bashio::exit.nok "Lỗi: Bạn phải khai báo ít nhất 1 tài khoản trong phần 'users'!"
fi

for (( i=0; i<USERS_COUNT; i++ )); do
    USERNAME=$(jq -r ".users[$i].username" "$CONFIG_PATH")
    PASSWORD=$(jq -r ".users[$i].password" "$CONFIG_PATH")
    if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        htpasswd -Bb "$HTPASSWD_FILE" "$USERNAME" "$PASSWORD" >/dev/null 2>&1
        bashio::log.info "Đã kích hoạt tài khoản WebDAV: ${USERNAME}"
    fi
done

# 3. Cấu hình SSL/TLS
LISTEN_DIRECTIVE="listen 8080;"
SSL_DIRECTIVES=""
if bashio::var.true "$SSL"; then
    if [ ! -f "/ssl/${CERTFILE}" ] || [ ! -f "/ssl/${KEYFILE}" ]; then
        bashio::exit.nok "Không tìm thấy chứng chỉ SSL tại /ssl/${CERTFILE} hoặc /ssl/${KEYFILE}"
    fi
    LISTEN_DIRECTIVE="listen 8080 ssl;"
    SSL_DIRECTIVES="
        ssl_certificate /ssl/${CERTFILE};
        ssl_certificate_key /ssl/${KEYFILE};
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
    "
    bashio::log.info "Chế độ bảo mật: HTTPS (SSL/TLS) đã bật."
else
    bashio::log.info "Chế độ kết nối: HTTP tiêu chuẩn (tương thích Cloudflare Tunnel / Reverse Proxy)."
fi

# 4. Cấu hình giao diện duyệt file (FancyIndex vs AutoIndex)
DOTFILES_RULE=""
if ! bashio::var.true "$SHOW_DOTFILES"; then
    DOTFILES_RULE="location ~ /\. { deny all; }"
fi

if bashio::var.true "$FANCY_UI"; then
    INDEX_CONFIG="
        fancyindex on;
        fancyindex_exact_size off;
        fancyindex_localtime on;
        fancyindex_name_length 255;
        fancyindex_header \"/.fancyindex/header.html\";
        fancyindex_footer \"/.fancyindex/footer.html\";
        fancyindex_ignore \"fancyindex\";
    "
else
    INDEX_CONFIG="
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    "
fi

# 5. Chuẩn bị thư mục gốc hợp nhất (/var/webdav_root)
rm -rf "${ROOT_DIR:?}"/*
mkdir -p "$ROOT_DIR"

SHARES_COUNT=$(jq '.shares | length' "$CONFIG_PATH")
for (( i=0; i<SHARES_COUNT; i++ )); do
    SHARE_NAME=$(jq -r ".shares[$i].name" "$CONFIG_PATH")
    SHARE_PATH=$(jq -r ".shares[$i].path" "$CONFIG_PATH")

    if [ ! -d "$SHARE_PATH" ]; then
        bashio::log.warning "Thư mục ${SHARE_PATH} chưa có sẵn, đang tự động tạo..."
        mkdir -p "$SHARE_PATH"
    fi

    ln -sfn "$SHARE_PATH" "${ROOT_DIR}/${SHARE_NAME}"
done

# 6. Tạo file cấu hình Nginx chính
cat <<EOF > "$NGINX_CONF"
load_module /usr/lib/nginx/modules/ngx_http_dav_ext_module.so;
load_module /usr/lib/nginx/modules/ngx_http_fancyindex_module.so;

user root;
worker_processes auto;
pid /run/nginx/nginx.pid;
error_log /dev/stderr ${LOG_LEVEL};

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /dev/stdout;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    server_tokens off;

    client_max_body_size ${MAX_UPLOAD};
    client_body_temp_path /var/lib/nginx/tmp/client_body;

    # Bộ nhớ quản lý khóa file (Lock) cho macOS Finder, iOS Files & Windows Explorer
    dav_ext_lock_zone zone=davlock:10m;

    # Giới hạn chống dò mật khẩu (Brute-force protection)
    limit_req_zone \$binary_remote_addr zone=dav_auth_limit:10m rate=15r/s;

    # =========================================================
    # SERVER 1: HOME ASSISTANT INGRESS (Truy cập nội bộ trên HA UI)
    # =========================================================
    server {
        listen 8099;
        allow 172.30.32.2;
        deny all;

        location /.fancyindex/ {
            alias /usr/share/nginx/fancyindex/;
        }

        location / {
            root ${ROOT_DIR};
            ${INDEX_CONFIG}
        }
    }

    # =========================================================
    # SERVER 2: WEBDAV SERVER CHÍNH (Cổng 8080)
    # =========================================================
    server {
        ${LISTEN_DIRECTIVE}
        ${SSL_DIRECTIVES}
        server_name _;

        # Cho phép tải giao diện FancyIndex không cần hỏi lại mật khẩu
        location /.fancyindex/ {
            alias /usr/share/nginx/fancyindex/;
            auth_basic off;
        }

        ${DOTFILES_RULE}
EOF

# 7. Kiểm tra chế độ Gộp 1 đường dẫn gốc (Unified Root) hay Tách riêng phân quyền
if bashio::var.true "$UNIFIED_ROOT"; then
    cat <<EOF >> "$NGINX_CONF"
        location / {
            limit_req zone=dav_auth_limit burst=40 nodelay;
            root ${ROOT_DIR};
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};

            ${INDEX_CONFIG}

            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
            dav_ext_lock zone=davlock;
            create_full_put_path on;
            dav_access user:rw group:rw all:r;

            if (-d \$request_filename) {
                rewrite ^(.*[^/])$ \$1/ break;
            }
        }
EOF
    bashio::log.info "Chế độ Unified Root: Đã gộp toàn bộ thư mục vào đường dẫn gốc '/'."
else
    # Cho phép duyệt danh sách ở gốc /
    cat <<EOF >> "$NGINX_CONF"
        location = / {
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};
            root ${ROOT_DIR};
            ${INDEX_CONFIG}
        }
EOF
    # Khởi tạo từng nhánh thư mục với quyền Read-Only / Allowed Users riêng
    for (( i=0; i<SHARES_COUNT; i++ )); do
        SHARE_NAME=$(jq -r ".shares[$i].name" "$CONFIG_PATH")
        SHARE_PATH=$(jq -r ".shares[$i].path" "$CONFIG_PATH")
        READ_ONLY=$(jq -r ".shares[$i].read_only" "$CONFIG_PATH")
        ALLOWED_COUNT=$(jq ".shares[$i].allowed_users | length" "$CONFIG_PATH")

        AUTH_FILE="$HTPASSWD_FILE"
        if [ "$ALLOWED_COUNT" -gt 0 ]; then
            AUTH_FILE="/etc/nginx/webdav_${SHARE_NAME}.htpasswd"
            rm -f "$AUTH_FILE"
            touch "$AUTH_FILE"
            for (( j=0; j<ALLOWED_COUNT; j++ )); do
                ALLOWED_USER=$(jq -r ".shares[$i].allowed_users[$j]" "$CONFIG_PATH")
                grep "^${ALLOWED_USER}:" "$HTPASSWD_FILE" >> "$AUTH_FILE" || true
            done
        fi

        if [ "$READ_ONLY" = "true" ]; then
            DAV_CONFIG="
                dav_ext_methods PROPFIND OPTIONS;
                limit_except GET HEAD OPTIONS PROPFIND {
                    deny all;
                }
            "
            MODE_TEXT="Chỉ đọc (Read-Only)"
        else
            DAV_CONFIG="
                dav_methods PUT DELETE MKCOL COPY MOVE;
                dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
                dav_ext_lock zone=davlock;
                create_full_put_path on;
                dav_access user:rw group:rw all:r;
            "
            MODE_TEXT="Đọc & Ghi (Read/Write)"
        fi

        cat <<EOF >> "$NGINX_CONF"
        location ^~ /${SHARE_NAME} {
            limit_req zone=dav_auth_limit burst=40 nodelay;
            alias ${SHARE_PATH};
            auth_basic "WebDAV - ${SHARE_NAME}";
            auth_basic_user_file ${AUTH_FILE};

            ${INDEX_CONFIG}
            ${DAV_CONFIG}

            if (-d \$request_filename) {
                rewrite ^(.*[^/])$ \$1/ break;
            }
        }
EOF
        bashio::log.info "Đã ánh xạ nhánh: /${SHARE_NAME} -> ${SHARE_PATH} [${MODE_TEXT}]"
    done
fi

cat <<EOF >> "$NGINX_CONF"
    }
}
EOF

bashio::log.info "WebDAV Server Pro đã sẵn sàng phục vụ trên cổng 8080 (và Ingress cổng 8099)!"
exec nginx -g "daemon off;"
