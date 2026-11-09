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
API_PORT=8098
TTYD_PORT=8097
WPRO_DATA=/data/wpro

mkdir -p "$WPRO_DATA"
touch "$WPRO_DATA/audit.jsonl"
[ ! -f "$WPRO_DATA/shares.json" ] && echo "{}" > "$WPRO_DATA/shares.json"

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

# Configure Git safe.directory so Git Status works across all mounted folders
git config --system --add safe.directory '*' || true

# 6. Create the Python Backend API service (Disk Stats, Quick Zip, Git Status, Share Links, Audit Log, Shell Fallback)
cat << 'PYEOF' > /usr/local/bin/wpro_api.py
#!/usr/bin/env python3
import os, sys, json, time, shutil, secrets, subprocess, urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from datetime import datetime

ROOT_DIR = "/var/webdav_root"
DATA_DIR = "/data/wpro"
SHARES_FILE = os.path.join(DATA_DIR, "shares.json")
AUDIT_FILE = os.path.join(DATA_DIR, "audit.jsonl")

def load_shares():
    try:
        with open(SHARES_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        now = time.time()
        cleaned = {k: v for k, v in data.items() if v.get("exp", 0) > now}
        if len(cleaned) != len(data):
            save_shares(cleaned)
        return cleaned
    except Exception:
        return {}

def save_shares(data):
    with open(SHARES_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

def append_audit(user, method, path, status=200, ip="local"):
    entry = {
        "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "user": user or "ingress",
        "method": method,
        "path": urllib.parse.unquote(path),
        "status": status,
        "ip": ip
    }
    try:
        with open(AUDIT_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        pass

def safe_resolve(rel_path):
    clean = urllib.parse.unquote(rel_path or "/").lstrip("/")
    full = os.path.normpath(os.path.join(ROOT_DIR, clean))
    if not full.startswith(ROOT_DIR):
        raise ValueError("Invalid path")
    return full

def dir_size_du(path):
    try:
        out = subprocess.check_output(["du", "-sk", path], stderr=subprocess.DEVNULL, timeout=8).decode()
        return int(out.split()[0]) * 1024
    except Exception:
        return 0

class WProHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def send_json(self, payload, code=200):
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def read_json_body(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        # Public Temporary Share Download: /s/<token> or /__wpro_api/share_dl?token=...
        if route.startswith("/s/") or route == "/__wpro_api/share_dl":
            token = route.split("/s/")[1].split("/")[0] if route.startswith("/s/") else (qs.get("token", [""])[0])
            shares = load_shares()
            info = shares.get(token)
            if not info or info.get("exp", 0) < time.time():
                self.send_response(404)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(b"Share link expired or invalid.")
                return
            try:
                target = safe_resolve(info["path"])
                if not os.path.isfile(target):
                    raise FileNotFoundError()
                fname = os.path.basename(target)
                fsize = os.path.getsize(target)
                append_audit("share-link", "SHARE_DL", info["path"], 200, self.headers.get("X-Real-IP", self.client_address[0]))
                self.send_response(200)
                self.send_header("Content-Type", "application/octet-stream")
                self.send_header("Content-Disposition", f'attachment; filename="{fname}"')
                self.send_header("Content-Length", str(fsize))
                self.end_headers()
                with open(target, "rb") as f:
                    shutil.copyfileobj(f, self.wfile)
            except Exception:
                self.send_response(404)
                self.end_headers()
            return

        if route == "/__wpro_api/disk":
            try:
                total, used, free = shutil.disk_usage(ROOT_DIR)
                folders = []
                for name in sorted(os.listdir(ROOT_DIR)):
                    fpath = os.path.join(ROOT_DIR, name)
                    if os.path.isdir(fpath):
                        real_p = os.path.realpath(fpath)
                        folders.append({"name": name, "bytes": dir_size_du(real_p)})
                self.send_json({"total": total, "used": used, "free": free, "folders": folders})
            except Exception as e:
                self.send_json({"error": str(e)}, 500)
            return

        if route == "/__wpro_api/git_status":
            rel = qs.get("path", ["/"])[0]
            try:
                target = os.path.realpath(safe_resolve(rel))
                if not os.path.isdir(target):
                    target = os.path.dirname(target)
                top = subprocess.check_output(
                    ["git", "-C", target, "rev-parse", "--show-toplevel"],
                    stderr=subprocess.DEVNULL, timeout=4
                ).decode().strip()
                branch = subprocess.check_output(
                    ["git", "-C", target, "rev-parse", "--abbrev-ref", "HEAD"],
                    stderr=subprocess.DEVNULL, timeout=4
                ).decode().strip()
                porcelain = subprocess.check_output(
                    ["git", "-C", target, "status", "--porcelain", "-uall"],
                    stderr=subprocess.DEVNULL, timeout=5
                ).decode()
                rel_from_top = os.path.relpath(target, top)
                prefix = "" if rel_from_top == "." else rel_from_top.rstrip("/") + "/"
                statuses = {}
                for line in porcelain.splitlines():
                    if len(line) < 4:
                        continue
                    st = line[:2]
                    fp = line[3:].strip().strip('"')
                    if " -> " in fp:
                        fp = fp.split(" -> ")[-1].strip('"')
                    if prefix and not fp.startswith(prefix):
                        continue
                    sub = fp[len(prefix):] if prefix else fp
                    first_seg = sub.split("/")[0]
                    if not first_seg:
                        continue
                    kind = "added" if ("?" in st or "A" in st) else "modified"
                    if first_seg not in statuses or kind == "modified":
                        statuses[first_seg] = kind
                self.send_json({"is_git": True, "branch": branch, "statuses": statuses})
            except Exception:
                self.send_json({"is_git": False, "statuses": {}})
            return

        if route == "/__wpro_api/shares":
            shares = load_shares()
            items = [{"token": k, **v} for k, v in shares.items()]
            items.sort(key=lambda x: x.get("created", 0), reverse=True)
            self.send_json({"shares": items})
            return

        if route == "/__wpro_api/audit":
            limit = int(qs.get("limit", ["150"])[0])
            logs = []
            try:
                if os.path.exists(AUDIT_FILE):
                    with open(AUDIT_FILE, "r", encoding="utf-8", errors="ignore") as f:
                        lines = f.readlines()[-limit:]
                    for ln in reversed(lines):
                        ln = ln.strip()
                        if not ln:
                            continue
                        try:
                            obj = json.loads(ln)
                            # Ignore internal asset/API polling noise
                            p_str = obj.get("path", "")
                            if p_str.startswith("/.fancyindex") or p_str.startswith("/__wpro_api") or p_str.startswith("/__wpro_ttyd"):
                                continue
                            logs.append(obj)
                        except Exception:
                            pass
            except Exception:
                pass
            self.send_json({"logs": logs[:100]})
            return

        self.send_json({"error": "Not found"}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        body = self.read_json_body()

        if route == "/__wpro_api/snapshot":
            target_mode = body.get("target", "config")
            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = os.path.realpath(os.path.join(ROOT_DIR, "backup"))
            os.makedirs(backup_dir, exist_ok=True)
            cfg_dir = os.path.realpath(os.path.join(ROOT_DIR, "config"))
            try:
                if target_mode == "automations":
                    zip_name = f"quick_automations_{stamp}.zip"
                    zip_path = os.path.join(backup_dir, zip_name)
                    cmd = ["zip", "-r", "-q", zip_path, "automations.yaml", "scripts.yaml", "scenes.yaml", "configuration.yaml", "automations", "packages"]
                    subprocess.run(cmd, cwd=cfg_dir, check=False, timeout=60)
                else:
                    zip_name = f"quick_config_{stamp}.zip"
                    zip_path = os.path.join(backup_dir, zip_name)
                    cmd = ["zip", "-r", "-q", zip_path, ".", "-x", "home-assistant_v2.db*", "*.log*", "deps/*", "tts/*", ".storage/core.entity_registry"]
                    subprocess.run(cmd, cwd=cfg_dir, check=False, timeout=120)

                size_kb = round(os.path.getsize(zip_path) / 1024, 1) if os.path.exists(zip_path) else 0
                append_audit("admin", "SNAPSHOT", f"/backup/{zip_name}", 200)
                self.send_json({"ok": True, "filename": zip_name, "path": f"/backup/{zip_name}", "size_kb": size_kb})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/share":
            action = body.get("action", "create")
            shares = load_shares()
            if action == "revoke":
                tok = body.get("token", "")
                shares.pop(tok, None)
                save_shares(shares)
                append_audit("admin", "SHARE_REVOKE", tok, 200)
                self.send_json({"ok": True})
                return

            rel_path = body.get("path", "")
            ttl = int(body.get("ttl", 3600))
            try:
                full = safe_resolve(rel_path)
                if not os.path.isfile(full):
                    self.send_json({"ok": False, "error": "Only files can be shared via direct link"}, 400)
                    return
                token = secrets.token_urlsafe(12)
                now = int(time.time())
                shares[token] = {
                    "path": rel_path,
                    "name": os.path.basename(full),
                    "created": now,
                    "exp": now + ttl
                }
                save_shares(shares)
                append_audit("admin", "SHARE_CREATE", rel_path, 200)
                self.send_json({"ok": True, "token": token, "exp": now + ttl, "name": os.path.basename(full)})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/audit_clear":
            try:
                open(AUDIT_FILE, "w").close()
                append_audit("admin", "AUDIT_CLEAR", "/", 200)
                self.send_json({"ok": True})
            except Exception as e:
                self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/exec":
            cmd_str = body.get("cmd", "").strip()
            cwd_rel = body.get("cwd", "/")
            if not cmd_str:
                self.send_json({"output": ""})
                return
            try:
                cwd_full = os.path.realpath(safe_resolve(cwd_rel))
                if not os.path.isdir(cwd_full):
                    cwd_full = ROOT_DIR
                proc = subprocess.run(
                    cmd_str, shell=True, cwd=cwd_full,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    timeout=20, text=True
                )
                append_audit("admin", "TERMINAL_CMD", cmd_str[:80], proc.returncode)
                self.send_json({"output": proc.stdout, "code": proc.returncode})
            except subprocess.TimeoutExpired:
                self.send_json({"output": "Command timed out after 20s.\n", "code": 124})
            except Exception as e:
                self.send_json({"output": f"Error: {e}\n", "code": 1})
            return

        self.send_json({"error": "Unknown endpoint"}, 404)

if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), WProHandler)
    server.serve_forever()
PYEOF
chmod +x /usr/local/bin/wpro_api.py

# 7. Start the Python API server & ttyd WebSocket Terminal in the background
python3 /usr/local/bin/wpro_api.py "${API_PORT}" &
bashio::log.info "Started WebDAV Pro API service on 127.0.0.1:${API_PORT}"

if command -v ttyd >/dev/null 2>&1; then
    ttyd -i 127.0.0.1 -p "${TTYD_PORT}" -W -b /__wpro_ttyd bash -l >/dev/null 2>&1 &
    bashio::log.info "Started Web Terminal (ttyd WebSocket) on 127.0.0.1:${TTYD_PORT}"
fi

# 8. Generate the main Nginx configuration (with JSON Audit Log & Proxy routes)
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

    log_format wpro_audit escape=json '{"time":"\$time_iso8601","user":"\$remote_user","ip":"\$remote_addr","method":"\$request_method","path":"\$uri","status":\$status}';
    map \$request_method \$is_mutating_or_dl {
        default 0;
        PUT     1;
        DELETE  1;
        MKCOL   1;
        COPY    1;
        MOVE    1;
        GET     1;
    }

    access_log /dev/stdout;
    access_log ${WPRO_DATA}/audit.jsonl wpro_audit if=\$is_mutating_or_dl;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    server_tokens off;

    client_max_body_size ${MAX_UPLOAD};
    client_body_temp_path /var/lib/nginx/tmp/client_body;

    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }

    # File lock memory zone (macOS Finder, iOS Files & Windows Explorer)
    dav_ext_lock_zone zone=davlock:10m;

    # Brute-force protection
    limit_req_zone \$binary_remote_addr zone=dav_auth_limit:10m rate=15r/s;

    # =========================================================
    # SERVER 1: HOME ASSISTANT INGRESS (Full WebDAV + Pro Suite)
    # =========================================================
    server {
        listen 8099;
        allow 172.30.32.2;
        deny all;

        location /.fancyindex/ {
            alias /usr/share/nginx/fancyindex/;
            access_log off;
        }

        location ^~ /__wpro_api/ {
            proxy_pass http://127.0.0.1:${API_PORT};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            access_log off;
        }

        location ^~ /__wpro_ttyd {
            proxy_pass http://127.0.0.1:${TTYD_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;
            proxy_set_header Host \$host;
            proxy_read_timeout 86400;
            access_log off;
        }

        location ^~ /s/ {
            proxy_pass http://127.0.0.1:${API_PORT};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
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
            access_log off;
        }

        # Public Temporary Share Links (no WebDAV password required)
        location ^~ /s/ {
            auth_basic off;
            proxy_pass http://127.0.0.1:${API_PORT};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }

        # Authenticated Pro API & Web Terminal on External Port
        location ^~ /__wpro_api/ {
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};
            proxy_pass http://127.0.0.1:${API_PORT};
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            access_log off;
        }

        location ^~ /__wpro_ttyd {
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};
            proxy_pass http://127.0.0.1:${TTYD_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;
            proxy_set_header Host \$host;
            proxy_read_timeout 86400;
            access_log off;
        }

        ${DOTFILES_RULE}
EOF

# 9. Unified Root mode vs. separate per-share permissions
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
    cat <<EOF >> "$NGINX_CONF"
        location = / {
            auth_basic "Home Assistant WebDAV Pro";
            auth_basic_user_file ${HTPASSWD_FILE};
            root ${ROOT_DIR};
            ${INDEX_CONFIG}
        }
EOF
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

# 10. Validate the Nginx configuration before starting
bashio::log.info "Checking Nginx configuration syntax..."
if ! nginx -t 2>&1; then
    bashio::log.error "Invalid Nginx configuration, see the details in the log lines above."
    cat -n "$NGINX_CONF" >&2
    bashio::exit.nok "Stopping add-on due to an Nginx configuration error."
fi
bashio::log.info "Nginx configuration is valid."

bashio::log.info "WebDAV Server Pro is ready on port ${WEBDAV_PORT} (and Ingress on port ${INGRESS_PORT})!"
exec nginx -g "daemon off;"
