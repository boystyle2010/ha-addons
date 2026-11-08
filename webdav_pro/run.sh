#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "---------------------------------------------------"
bashio::log.info " Initializing Home Assistant WebDAV Server Pro..."
bashio::log.info "---------------------------------------------------"

CONFIG_PATH=/data/options.json
HTPASSWD_FILE=/etc/nginx/webdav.htpasswd
NGINX_CONF=/etc/nginx/nginx.conf
ROOT_DIR=/var/webdav_root
WEBDAV_PORT=8090
INGRESS_PORT=8099

# 1. Read configuration from the Home Assistant UI
UNIFIED_ROOT=$(bashio::config 'unified_root')
SSL=$(bashio::config 'ssl')
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
MAX_UPLOAD=$(bashio::config 'max_upload_size')
FANCY_UI=$(bashio::config 'fancy_ui')
SHOW_DOTFILES=$(bashio::config 'show_dotfiles')
LOG_LEVEL=$(bashio::config 'log_level')

# 2. Create the account list with Bcrypt hashing
rm -f "$HTPASSWD_FILE"
touch "$HTPASSWD_FILE"

USERS_COUNT=$(jq '.users | length' "$CONFIG_PATH")
if [ "$USERS_COUNT" -eq 0 ]; then
    bashio::exit.nok "Error: you must define at least one account under 'users'!"
fi

for (( i=0; i<USERS_COUNT; i++ )); do
    USERNAME=$(jq -r ".users[$i].username" "$CONFIG_PATH")
    PASSWORD=$(jq -r ".users[$i].password" "$CONFIG_PATH")
    if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        htpasswd -Bb "$HTPASSWD_FILE" "$USERNAME" "$PASSWORD" >/dev/null 2>&1
        bashio::log.info "Enabled WebDAV account: ${USERNAME}"
    fi
done

# 3. SSL/TLS configuration
LISTEN_DIRECTIVE="listen ${WEBDAV_PORT};"
SSL_DIRECTIVES=""
if bashio::var.true "$SSL"; then
    if [ ! -f "/ssl/${CERTFILE}" ] || [ ! -f "/ssl/${KEYFILE}" ]; then
        bashio::exit.nok "SSL certificate not found at /ssl/${CERTFILE} or /ssl/${KEYFILE}"
    fi
    LISTEN_DIRECTIVE="listen ${WEBDAV_PORT} ssl;"
    SSL_DIRECTIVES="
        ssl_certificate /ssl/${CERTFILE};
        ssl_certificate_key /ssl/${KEYFILE};
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
    "
    bashio::log.info "Security mode: HTTPS (SSL/TLS) enabled."
else
    bashio::log.info "Connection mode: standard HTTP (compatible with Cloudflare Tunnel / reverse proxy)."
fi

# 4. File browser UI (FancyIndex vs AutoIndex)
DOTFILES_RULE=""
if ! bashio::var.true "$SHOW_DOTFILES"; then
    DOTFILES_RULE="location ~ /\. { deny all; }"
fi

if bashio::var.true "$FANCY_UI"; then
    INDEX_CONFIG="
        fancyindex on;
        fancyindex_exact_size off;
        fancyindex_localtime on;
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

# 5. Prepare the unified root directory (/var/webdav_root)
mkdir -p "$ROOT_DIR"
rm -rf "${ROOT_DIR:?}"/*

SHARES_COUNT=$(jq '.shares | length' "$CONFIG_PATH")
for (( i=0; i<SHARES_COUNT; i++ )); do
    SHARE_NAME=$(jq -r ".shares[$i].name" "$CONFIG_PATH")
    SHARE_PATH=$(jq -r ".shares[$i].path" "$CONFIG_PATH")

    if [ ! -d "$SHARE_PATH" ]; then
        bashio::log.warning "Folder ${SHARE_PATH} does not exist, creating it..."
        mkdir -p "$SHARE_PATH"
    fi

    ln -sfn "$SHARE_PATH" "${ROOT_DIR}/${SHARE_NAME}"
done

# 6. Generate the main Nginx configuration
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

    # File lock memory zone (macOS Finder, iOS Files & Windows Explorer)
    dav_ext_lock_zone zone=davlock:10m;

    # Brute-force protection
    limit_req_zone \$binary_remote_addr zone=dav_auth_limit:10m rate=15r/s;

    # =========================================================
    # SERVER 1: HOME ASSISTANT INGRESS (Full WebDAV + Code Editor)
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

            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
            dav_ext_lock zone=davlock;
            create_full_put_path on;
            dav_access user:rw group:rw all:r;

            if (-d \$request_filename) {
                rewrite ^(.*[^/])$ \$1/ break;
            }
        }
    }

    # =========================================================
    # SERVER 2: MAIN WEBDAV SERVER (port ${WEBDAV_PORT})
    # =========================================================
    server {
        ${LISTEN_DIRECTIVE}
        ${SSL_DIRECTIVES}
        server_name _;

        # Serve the FancyIndex UI assets without asking for a password
        location ^~ /.fancyindex/ {
            alias /usr/share/nginx/fancyindex/;
            auth_basic off;
        }

        ${DOTFILES_RULE}
EOF

# 7. Unified Root mode vs. separate per-share permissions
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
    bashio::log.info "Unified Root mode: all folders merged under the root path '/'."
else
    # Allow listing the root /
    cat <<EOF >> "$NGINX_CONF"
        location = / {
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};
            root ${ROOT_DIR};
            ${INDEX_CONFIG}
        }
EOF
    # Create each share with its own Read-Only / allowed-users rules
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
            MODE_TEXT="Read-Only"
        else
            DAV_CONFIG="
                dav_methods PUT DELETE MKCOL COPY MOVE;
                dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
                dav_ext_lock zone=davlock;
                create_full_put_path on;
                dav_access user:rw group:rw all:r;
            "
            MODE_TEXT="Read/Write"
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
        bashio::log.info "Mapped share: /${SHARE_NAME} -> ${SHARE_PATH} [${MODE_TEXT}]"
    done
fi

cat <<EOF >> "$NGINX_CONF"
    }
}
EOF

# 8. Validate the Nginx configuration before starting
bashio::log.info "Checking Nginx configuration syntax..."
if ! nginx -t 2>&1; then
    bashio::log.error "Invalid Nginx configuration, see the details in the log lines above."
    bashio::log.error "Generated config (with line numbers) for reference:"
    cat -n "$NGINX_CONF" >&2
    bashio::exit.nok "Stopping add-on due to an Nginx configuration error."
fi
bashio::log.info "Nginx configuration is valid."

bashio::log.info "WebDAV Server Pro is ready on port ${WEBDAV_PORT} (and Ingress on port ${INGRESS_PORT})!"
exec nginx -g "daemon off;"
