#!/usr/bin/with-contenv bashio
set -e

ADDON_VERSION=$(bashio::app.version)
bashio::log.info "--------------------------------------------------------"
bashio::log.info " Initializing OmniDrive Pro v${ADDON_VERSION} (Multi-Protocol)"
bashio::log.info "--------------------------------------------------------"

CONFIG_PATH=/data/options.json
HTPASSWD_FILE=/etc/nginx/webdav.htpasswd
NGINX_CONF=/etc/nginx/nginx.conf
ROOT_DIR=/var/webdav_root
WEBDAV_PORT=8090
INGRESS_PORT=8099
API_PORT=8098
WPRO_DATA=/data/wpro

mkdir -p "$WPRO_DATA"
touch "$WPRO_DATA/audit.jsonl"
[ ! -f "$WPRO_DATA/shares.json" ] && echo "{}" > "$WPRO_DATA/shares.json"

# 1. Read configuration from Home Assistant UI
UNIFIED_ROOT=$(bashio::config 'unified_root')
SMB_ENABLED=$(bashio::config 'smb_enabled')
SFTP_ENABLED=$(bashio::config 'sftp_enabled')
FTP_ENABLED=$(bashio::config 'ftp_enabled')
SSL=$(bashio::config 'ssl')
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
MAX_UPLOAD=$(bashio::config 'max_upload_size')
FANCY_UI=$(bashio::config 'fancy_ui')
SHOW_DOTFILES=$(bashio::config 'show_dotfiles')
LOG_LEVEL=$(bashio::config 'log_level')
ROOT_ACCESS=$(bashio::config 'root_access')
ENABLE_TERMINAL=$(bashio::config 'enable_terminal')
LOCK_ROOT=$(bashio::config 'lock_root')
TRUSTED_PROXIES=$(bashio::config 'trusted_proxies' 2>/dev/null || true)
if [ -z "$TRUSTED_PROXIES" ] || [ "$TRUSTED_PROXIES" = "null" ]; then TRUSTED_PROXIES="172.16.0.0/12,127.0.0.0/8"; fi

export ROOT_ACCESS ENABLE_TERMINAL

# Thông tin hiển thị trong "Connect Hub" (footer.html đọc qua /__wpro_api/protocols)
# - LAN_IP: ưu tiên option 'lan_ip', nếu trống thì tự lấy IP của interface chính từ Supervisor
# - PUBLIC_URL: tên miền Cloudflare cho WebDAV (tuỳ chọn)
LAN_IP=$(bashio::config 'lan_ip' 2>/dev/null || true)
[ "$LAN_IP" = "null" ] && LAN_IP=""
if [ -z "$LAN_IP" ]; then
    # Hỏi Supervisor trực tiếp: lấy interface chính (primary) đang kết nối, nếu không có thì interface đầu tiên có IPv4
    LAN_IP=$(curl -fsS --max-time 5 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/network/info 2>/dev/null \
        | jq -r '[.data.interfaces[]? | select((.connected // true) and ((.ipv4.address // []) | length > 0))] | ((map(select(.primary))[0]) // .[0]) | .ipv4.address[0] // empty' 2>/dev/null \
        | cut -d/ -f1 || true)
fi
[ "$LAN_IP" = "null" ] && LAN_IP=""
if [ -z "$LAN_IP" ]; then
    bashio::log.warning "Could not detect the LAN IP automatically (needs 'hassio_api: true' in config.yaml). Set 'lan_ip' in the add-on configuration, otherwise the Connect Hub shows the address you browse with."
fi
PUBLIC_URL=$(bashio::config 'public_url' 2>/dev/null || true)
[ "$PUBLIC_URL" = "null" ] && PUBLIC_URL=""

# Port thực tế trên host (người dùng có thể đổi ở tab Network của add-on)
host_port() {
    local p
    p=$(bashio::app.port "$1" 2>/dev/null || bashio::addon.port "$1" 2>/dev/null || true)
    if [[ "$p" =~ ^[0-9]+$ ]]; then echo "$p"; else echo "${1%/*}"; fi
}
SMB_PORT=$(host_port 445/tcp)
SFTP_PORT=$(host_port 2222/tcp)
FTP_PORT=$(host_port 2121/tcp)
EXT_PORT=$(host_port 8090/tcp)
SHARE_ZIP_MAX_MB=$(bashio::config 'share_zip_max_mb' 2>/dev/null || true)
if ! [[ "$SHARE_ZIP_MAX_MB" =~ ^[0-9]+$ ]]; then SHARE_ZIP_MAX_MB=2048; fi
export WPRO_PLATFORM=ha
INGRESS_TOKEN=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d " \n")
export INGRESS_TOKEN
export LAN_IP PUBLIC_URL SMB_PORT SFTP_PORT FTP_PORT EXT_PORT SHARE_ZIP_MAX_MB
bashio::log.info "Connect Hub: LAN_IP='${LAN_IP}' PUBLIC_URL='${PUBLIC_URL}'"

# 2. Prepare the unified root directory (/var/webdav_root)
mkdir -p "$ROOT_DIR"
find "${ROOT_DIR:?}" -mindepth 1 -maxdepth 1 -type l -delete

SHARES_COUNT=$(jq '.shares | length' "$CONFIG_PATH")
for (( i=0; i<SHARES_COUNT; i++ )); do
    SHARE_NAME=$(jq -r ".shares[$i].name" "$CONFIG_PATH")
    SHARE_PATH=$(jq -r ".shares[$i].path" "$CONFIG_PATH")

    if [ ! -d "$SHARE_PATH" ]; then
        mkdir -p "$SHARE_PATH"
    fi
    ln -sfn "$SHARE_PATH" "${ROOT_DIR}/${SHARE_NAME}"
done

# 3. Accounts provisioning & Hashing (Có SHA-512 từ openssl)
if bashio::var.true "$SMB_ENABLED"; then
    mkdir -p /var/lib/samba /data/wpro/samba
    chmod 700 /data/wpro/samba
    if [ ! -L /var/lib/samba/private ]; then
        cp -a /var/lib/samba/private/. /data/wpro/samba/ 2>/dev/null || true
        rm -rf /var/lib/samba/private
        ln -s /data/wpro/samba /var/lib/samba/private
    fi
fi

cat << 'USEREOF' > /usr/local/bin/wpro_users.py
#!/usr/bin/env python3
import os, sys, json, hmac, hashlib, secrets, subprocess

CFG = "/data/options.json"
ROOT_DIR = "/var/webdav_root"
ITER = 200000
SMB = os.environ.get("SMB_ENABLED_RESOLVED", "true") == "true"
RUN_AS_ROOT = os.environ.get("ROOT_ACCESS", "false") == "true"
PUID = os.environ.get("PUID", "1000")
PGID = os.environ.get("PGID", "1000")

def log(msg): print("[INFO] " + msg, flush=True)
def warn(msg): print("[WARN] " + msg, flush=True)

def make_hash(pw):
    salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac("sha256", str(pw).encode("utf-8"), bytes.fromhex(salt), ITER).hex()
    return "pbkdf2_sha256$%d$%s$%s" % (ITER, salt, h)

def check_hash(stored, pw):
    try:
        algo, it, salt, h = stored.split("$")
        if algo != "pbkdf2_sha256":
            return False
        calc = hashlib.pbkdf2_hmac("sha256", str(pw).encode("utf-8"), bytes.fromhex(salt), int(it)).hex()
        return hmac.compare_digest(calc, h)
    except Exception:
        return False

def run(args, inp=None):
    return subprocess.run(args, input=inp, capture_output=True, text=True)

def crypt_hash(pw):
    try:
        r = run(["openssl", "passwd", "-6", "-stdin"], str(pw) + "\n")
        return r.stdout.strip() if r.returncode == 0 and r.stdout.startswith("$6$") else ""
    except FileNotFoundError:
        warn("openssl not found. SFTP/FTP will use plaintext chpasswd.")
        return ""

USERS_FILE = "/data/wpro/users.json"
KEEP_MARKERS = ("", "__keep__")   # empty or __KEEP__ in the config = keep the existing password

def make_fp(pw):
    salt = secrets.token_hex(16)
    return {"salt": salt, "hash": hashlib.pbkdf2_hmac("sha256", str(pw).encode("utf-8"), bytes.fromhex(salt), 100000).hex()}

def match_fp(fp, pw):
    try:
        calc = hashlib.pbkdf2_hmac("sha256", str(pw).encode("utf-8"), bytes.fromhex(fp["salt"]), 100000).hex()
        return hmac.compare_digest(calc, fp["hash"])
    except Exception:
        return False

try:
    with open(CFG, encoding="utf-8") as f:
        cfg = json.load(f)
except Exception as e:
    print("[ERROR] cannot read options.json: %s" % e); sys.exit(1)

# /data/options.json is rewritten by the Supervisor on every start, so the real account state
# (hashes, password changed on the Web UI) lives in our own file: /data/wpro/users.json
try:
    with open(USERS_FILE, encoding="utf-8") as f:
        stored_list = json.load(f)
    if not isinstance(stored_list, list): stored_list = []
except Exception:
    stored_list = []
stored = {str(x.get("username")): x for x in stored_list if isinstance(x, dict)}

users = cfg.get("users") or []
plain = {}     # name -> plaintext, only for accounts whose password is (re)applied from the config now
status = {}
to_clear = []   # users whose password field in the config gets emptied after applying
out = []
for u in users:
    name = str(u.get("username", "")).strip()
    if not name or ":" in name or "\n" in name or len(name) > 32:
        warn("Skipping invalid username %r" % name); continue
    raw = u.get("password")
    pw = "" if raw is None else str(raw)
    keep = pw.strip().lower() in KEEP_MARKERS
    st = stored.get(name)
    has_st = bool(st and st.get("password_hash"))
    entry = {"username": name}
    for k, v in u.items():
        if k not in ("username", "password", "password_hash", "crypt_hash", "cfg_fp"):
            entry[k] = v
    if keep:
        if not has_st:
            warn("User %s: password is empty / __KEEP__ but this account does not exist yet -> SKIPPED. Enter a password in the add-on configuration to create it." % name)
            continue
        entry["password_hash"] = st["password_hash"]
        entry["crypt_hash"] = st.get("crypt_hash", "")
        status[name] = "kept"
        log("User %s: KEEP -> existing password kept (config marker)." % name)
    elif has_st and st.get("cfg_fp") and match_fp(st["cfg_fp"], pw):
        entry["password_hash"] = st["password_hash"]
        entry["crypt_hash"] = st.get("crypt_hash", "")
        entry["cfg_fp"] = st["cfg_fp"]
        status[name] = "unchanged"
        log("User %s: config password unchanged since the last start -> current password kept (the one you set on the Web UI, if you changed it)." % name)
    else:
        entry["password_hash"] = make_hash(pw)
        entry["crypt_hash"] = crypt_hash(pw)
        entry["cfg_fp"] = make_fp(pw)
        plain[name] = pw
        if has_st:
            status[name] = "reset"
            log("User %s: new password in the config -> password RESET on all protocols." % name)
        else:
            status[name] = "created"
            log("User %s: account CREATED from the config password." % name)
    # Xoá trắng ô cấu hình, trừ khi đó vẫn là mật khẩu mặc định ĐANG CÓ HIỆU LỰC (để người dùng còn thấy và đổi nó)
    if pw.strip() and (pw != "changeme_strong_password" or not check_hash(entry["password_hash"], pw)):
        to_clear.append(name)
    out.append(entry)

if not out:
    print("[ERROR] you must define at least one account under 'users' in the add-on configuration"); sys.exit(1)

os.makedirs(os.path.dirname(USERS_FILE), exist_ok=True)
tmp = USERS_FILE + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
os.chmod(tmp, 0o600)
os.replace(tmp, USERS_FILE)

CLEAR_FILE = "/data/wpro/clear_pw.json"
try:
    if to_clear:
        with open(CLEAR_FILE, "w", encoding="utf-8") as f: json.dump(to_clear, f)
        os.chmod(CLEAR_FILE, 0o600)
    elif os.path.exists(CLEAR_FILE):
        os.remove(CLEAR_FILE)
except Exception:
    pass

if any(check_hash(e["password_hash"], "changeme_strong_password") for e in out):
    warn("A user still has the DEFAULT password 'changeme_strong_password'. Change it (Web UI > Change Password, or enter a new one in the add-on configuration) now!")

for e in out:
    name = e["username"]
    if run(["id", name]).returncode != 0:
        run(["adduser", "-D", "-H", "-h", ROOT_DIR, "-s", "/bin/bash", "-G", "root", name])

    # SFTP / FTP: system account, recreated at every start from the stored SHA-512 hash
    if e.get("crypt_hash"):
        run(["chpasswd", "-e"], "%s:%s\n" % (name, e["crypt_hash"]))
    elif name in plain:
        run(["chpasswd"], "%s:%s\n" % (name, str(plain[name])))
    else:
        warn("User %s has no stored system hash: SFTP/FTP login is unavailable until you enter a new password in the add-on configuration." % name)

    # SMB: the Samba database is persistent (/data/wpro/samba); only touch the password on create / reset
    if SMB:
        if name in plain:
            run(["smbpasswd", "-a", "-s", name], "%s\n%s\n" % (str(plain[name]), str(plain[name])))
            run(["smbpasswd", "-e", name])
        elif run(["pdbedit", "-L", "-u", name]).returncode == 0:
            run(["smbpasswd", "-e", name])
        else:
            warn("User %s is missing from the Samba database: enter a new password in the add-on configuration to recreate the SMB login." % name)

    log("Provisioned account: %s (%s)" % (name, status.get(name, "?")))
USEREOF

SMB_ENABLED_RESOLVED="$SMB_ENABLED" ROOT_ACCESS="$ROOT_ACCESS" python3 /usr/local/bin/wpro_users.py || bashio::exit.nok "Account provisioning failed."

# Sau khi áp dụng, xoá trắng ô mật khẩu trong cấu hình add-on (mật khẩu thật chỉ nằm trong add-on).
# Nếu bước này lỗi thì chỉ cảnh báo: mật khẩu cũ trong cấu hình vẫn KHÔNG bị áp dụng lại ở lần khởi động sau.
CLEAR_FILE=/data/wpro/clear_pw.json
rm -f /data/wpro/cleared_users.json
if [ -s "$CLEAR_FILE" ] && [ "$(jq 'length' "$CLEAR_FILE" 2>/dev/null || echo 0)" -gt 0 ]; then
    NEW_OPTS=$(jq -c --slurpfile cl "$CLEAR_FILE" '.users |= map(if (.username as $u | ($cl[0] | index($u)) != null) then .password = "" else . end)' "$CONFIG_PATH" 2>/dev/null || true)
    if [ -n "$NEW_OPTS" ] && curl -fsS --max-time 10 -X POST \
            -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" \
            -d "{\"options\": ${NEW_OPTS}}" http://supervisor/addons/self/options >/dev/null 2>&1; then
        cp "$CLEAR_FILE" /data/wpro/cleared_users.json 2>/dev/null || true
        bashio::log.info "Password field(s) in the configuration were emptied (the real password is stored by the add-on)."
    else
        bashio::log.warning "Could not empty the password field in the configuration automatically. You can empty it by hand; it will NOT be re-applied."
    fi
fi

# Root lock
if bashio::var.true "$LOCK_ROOT"; then
    chmod 0555 "$ROOT_DIR" || true
else
    chmod 0775 "$ROOT_DIR" || true
fi

# 4. Start SMB / Samba Server (Port 445)
if bashio::var.true "$SMB_ENABLED"; then
    mkdir -p /var/lib/samba/private /var/log/samba /run/samba
    ROOT_WRITABLE="yes"
    bashio::var.true "$LOCK_ROOT" && ROOT_WRITABLE="no"
    cat <<EOF > /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   server string = OmniDrive Pro (Home Assistant)
   security = user
   map to guest = Never
   smb encrypt = desired
   min protocol = SMB2
   unix extensions = no
   wide links = yes
   follow symlinks = yes
   force user = root
   force group = root
   create mask = 0664
   directory mask = 0775
   load printers = no
   printing = bsd
   printcap name = /dev/null
   disable spoolss = yes

[OmniDrive]
   path = ${ROOT_DIR}
   browseable = yes
   writable = ${ROOT_WRITABLE}
   guest ok = no
EOF

    for (( i=0; i<SHARES_COUNT; i++ )); do
        SHARE_NAME=$(jq -r ".shares[$i].name" "$CONFIG_PATH")
        SHARE_PATH=$(jq -r ".shares[$i].path" "$CONFIG_PATH")
        READ_ONLY=$(jq -r ".shares[$i].read_only" "$CONFIG_PATH")
        WRITABLE="yes"
        [ "$READ_ONLY" = "true" ] && WRITABLE="no"
        cat <<EOF >> /etc/samba/smb.conf

[${SHARE_NAME}]
   path = ${SHARE_PATH}
   browseable = yes
   writable = ${WRITABLE}
   guest ok = no
   force user = root
   force group = root
EOF
    done
    smbd --foreground --no-process-group </dev/null >/dev/null 2>&1 &
fi

# 5. Start SFTP / OpenSSH Server (Port 2222)
if bashio::var.true "$SFTP_ENABLED"; then
    ssh-keygen -A >/dev/null 2>&1
    cat <<EOF > /etc/ssh/sshd_config
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
Subsystem sftp internal-sftp
AllowTcpForwarding no
X11Forwarding no
ForceCommand internal-sftp -d ${ROOT_DIR}
EOF
    /usr/sbin/sshd -D -e >/dev/null 2>&1 &
fi

# 6. Start FTP / vsftpd Server
if bashio::var.true "$FTP_ENABLED"; then
    cat <<EOF > /etc/vsftpd/vsftpd.conf
listen=YES
listen_ipv6=NO
listen_port=2121
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
local_root=${ROOT_DIR}
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21002
seccomp_sandbox=NO
EOF
    # Passive mode: vsftpd phải báo IP LAN của host (add-on nằm sau NAT của Docker), nếu không client treo khi liệt kê thư mục
    PASV_ADDR=$(bashio::config 'ftp_pasv_address' 2>/dev/null || true)
    [ "$PASV_ADDR" = "null" ] && PASV_ADDR=""
    [ -z "$PASV_ADDR" ] && PASV_ADDR="$LAN_IP"
    if [[ "$PASV_ADDR" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        echo "pasv_address=${PASV_ADDR}" >> /etc/vsftpd/vsftpd.conf
        bashio::log.info "FTP passive address: ${PASV_ADDR}"
    else
        bashio::log.warning "FTP passive address unknown: set 'ftp_pasv_address' (LAN IP of Home Assistant) or FTP clients may hang when listing folders."
    fi

    # FTPS (explicit TLS): optional (mặc định) | required | off
    FTP_TLS_MODE=$(bashio::config 'ftp_tls' 2>/dev/null || true)
    FTP_TLS_MODE="${FTP_TLS_MODE,,}"
    case "$FTP_TLS_MODE" in optional|required|off) ;; *) FTP_TLS_MODE="optional" ;; esac
    if [ "$FTP_TLS_MODE" != "off" ]; then
        FTP_CRT=""; FTP_KEY=""
        if [ -f "/ssl/${CERTFILE}" ] && [ -f "/ssl/${KEYFILE}" ]; then
            FTP_CRT="/ssl/${CERTFILE}"; FTP_KEY="/ssl/${KEYFILE}"
        else
            FTP_CRT="/data/wpro/ftp-cert.pem"; FTP_KEY="/data/wpro/ftp-key.pem"
            if [ ! -s "$FTP_CRT" ] || [ ! -s "$FTP_KEY" ]; then
                openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=omnidrive-pro" \
                    -keyout "$FTP_KEY" -out "$FTP_CRT" >/dev/null 2>&1 || true
                chmod 600 "$FTP_KEY" 2>/dev/null || true
            fi
        fi
        if [ -s "$FTP_CRT" ] && [ -s "$FTP_KEY" ]; then
            FORCE="NO"
            [ "$FTP_TLS_MODE" = "required" ] && FORCE="YES"
            cat <<EOF >> /etc/vsftpd/vsftpd.conf
ssl_enable=YES
rsa_cert_file=${FTP_CRT}
rsa_private_key_file=${FTP_KEY}
allow_anon_ssl=NO
force_local_logins_ssl=${FORCE}
force_local_data_ssl=${FORCE}
ssl_sslv2=NO
ssl_sslv3=NO
ssl_tlsv1=NO
ssl_tlsv1_1=NO
ssl_tlsv1_2=YES
ssl_ciphers=HIGH
require_ssl_reuse=NO
EOF
            bashio::log.info "FTPS (explicit TLS) enabled, mode: ${FTP_TLS_MODE}."
        elif [ "$FTP_TLS_MODE" = "required" ]; then
            bashio::exit.nok "ftp_tls=required but no TLS certificate could be created."
        else
            bashio::log.warning "Could not create an FTPS certificate: FTP stays unencrypted."
        fi
    else
        bashio::log.warning "ftp_tls=off: FTP passwords and files are sent in clear text."
    fi
    vsftpd /etc/vsftpd/vsftpd.conf >/dev/null 2>&1 &
fi

# 7. SSL
LISTEN_DIRECTIVE="listen ${WEBDAV_PORT};"
SSL_DIRECTIVES=""
if bashio::var.true "$SSL"; then
    LISTEN_DIRECTIVE="listen ${WEBDAV_PORT} ssl;"
    SSL_DIRECTIVES="
        ssl_certificate /ssl/${CERTFILE};
        ssl_certificate_key /ssl/${KEYFILE};
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
    "
fi

# 8. FancyIndex
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

# Root lock rules (Nginx)
ROOT_LOCK_RULES=""
if bashio::var.true "$LOCK_ROOT"; then
    ROOT_LOCK_RULES=$(cat <<'LOCKEOF'
            set $wpro_rl "";
            if ($request_method ~ "^(PUT|MKCOL|DELETE|MOVE)$") { set $wpro_rl "m"; }
            if ($uri ~ "^/[^/]+/?$") { set $wpro_rl "${wpro_rl}u"; }
            if ($wpro_rl = "mu") { return 403 "Blocked: files and folders cannot be created, renamed or deleted directly at Root."; }
            set $wpro_rd "";
            if ($request_method ~ "^(COPY|MOVE)$") { set $wpro_rd "m"; }
            if ($http_destination ~ "^(https?://[^/]+)?/[^/]+/?$") { set $wpro_rd "${wpro_rd}d"; }
            if ($wpro_rd = "md") { return 403 "Blocked: the destination is directly at Root."; }
LOCKEOF
)
fi

git config --system --add safe.directory '*' || true

# 9. Python API (Full Docker Version)
cat << 'PYEOF' > /usr/local/bin/wpro_api.py
#!/usr/bin/env python3
import os, sys, json, time, hmac, hashlib, base64, shutil, secrets, tempfile, subprocess, threading, html, urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from http.cookies import SimpleCookie
from datetime import datetime

ROOT_DIR = "/var/webdav_root"
DATA_DIR = "/data/wpro"
CONFIG_PATH = "/data/options.json"
SHARES_FILE = os.path.join(DATA_DIR, "shares.json")
AUDIT_FILE = os.path.join(DATA_DIR, "audit.jsonl")
SECRET_FILE = os.path.join(DATA_DIR, "session.secret")
SESSIONS_FILE = os.path.join(DATA_DIR, "sessions.json")
DEVICES_FILE = os.path.join(DATA_DIR, "known_devices.json")
USERS_FILE = os.path.join(DATA_DIR, "users.json")

if not os.path.exists(SECRET_FILE):
    with open(SECRET_FILE, "w") as f:
        f.write(secrets.token_hex(32))
try: os.chmod(SECRET_FILE, 0o600)
except Exception: pass
with open(SECRET_FILE, "r") as f:
    SESSION_SECRET = f.read().strip().encode("utf-8")

def get_config():
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
    except Exception:
        cfg = {}
    # Accounts (hashes, password changed on the Web UI) are stored in users.json, not in the Supervisor-owned options.json
    try:
        with open(USERS_FILE, "r", encoding="utf-8") as f:
            users = json.load(f)
        if isinstance(users, list): cfg["users"] = users
    except Exception:
        pass
    return cfg

PW_CACHE = {}
PW_CACHE_KEY = secrets.token_bytes(32)
PW_CACHE_TTL = 300
PW_CACHE_LOCK = threading.Lock()
_DUMMY_HASH = "pbkdf2_sha256$200000$" + "00" * 16 + "$" + "00" * 32

def _pbkdf2_check(stored, password):
    try:
        algo, it, salt, h = stored.split("$")
        if algo != "pbkdf2_sha256": return False
        it = max(1, min(int(it), 5000000))
        calc = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), bytes.fromhex(salt), it).hex()
        return hmac.compare_digest(calc, h)
    except Exception: return False

def verify_credentials(username, password):
    cfg = get_config()
    found = None
    for u in cfg.get("users", []):
        if hmac.compare_digest(str(u.get("username", "")).encode("utf-8"), str(username).encode("utf-8")):
            found = u
    stored = (found or {}).get("password_hash", "") if found else ""
    legacy = (found or {}).get("password", "") if found else ""
    ck = hmac.new(PW_CACHE_KEY, ("%s\0%s\0%s\0%s" % (username, password, stored, legacy)).encode("utf-8"), hashlib.sha256).hexdigest()
    now = time.time()
    with PW_CACHE_LOCK:
        if found and PW_CACHE.get(ck, 0) > now: return True
    if found and stored: ok = _pbkdf2_check(stored, str(password))
    elif found and legacy: ok = hmac.compare_digest(str(legacy).encode("utf-8"), str(password).encode("utf-8"))
    else:
        _pbkdf2_check(_DUMMY_HASH, str(password)); ok = False
    if ok:
        with PW_CACHE_LOCK:
            if len(PW_CACHE) > 2000:
                for k in [k for k, t in PW_CACHE.items() if t <= now]: PW_CACHE.pop(k, None)
            PW_CACHE[ck] = now + PW_CACHE_TTL
    return ok

LOGIN_FAILS, LOGIN_LOCK, MAX_LOGIN_FAILS, LOGIN_WINDOW = {}, threading.Lock(), 10, 300

def login_locked(key):
    now = time.time()
    with LOGIN_LOCK:
        recent = [t for t in LOGIN_FAILS.get(key, []) if now - t < LOGIN_WINDOW]
        LOGIN_FAILS[key] = recent
        return len(recent) >= MAX_LOGIN_FAILS

def login_failed(key):
    with LOGIN_LOCK: LOGIN_FAILS.setdefault(key, []).append(time.time())

def login_ok(key):
    with LOGIN_LOCK: LOGIN_FAILS.pop(key, None)

IS_HA = os.environ.get("WPRO_PLATFORM", "") == "ha"
CLEARED_FILE = os.path.join(DATA_DIR, "cleared_users.json")
TERMINAL_ENABLED = os.environ.get("ENABLE_TERMINAL", "true").lower() == "true"
RUN_AS_ROOT = os.environ.get("ROOT_ACCESS", "false").lower() == "true"
try:
    RUN_UID, RUN_GID = int(os.environ.get("PUID", "1000")), int(os.environ.get("PGID", "1000"))
except: RUN_UID, RUN_GID = 1000, 1000

def run_as_kwargs():
    if RUN_AS_ROOT: return {}
    return {"user": RUN_UID, "group": RUN_GID, "extra_groups": []}

def child_env():
    env = dict(os.environ)
    if not RUN_AS_ROOT: env["HOME"] = "/tmp"
    return env

def user_can_read(path):
    if RUN_AS_ROOT: return True
    try: return subprocess.run(["test", "-r", path], timeout=5, **run_as_kwargs()).returncode == 0
    except: return False

SHARE_ZIP_MAX = int(os.environ.get("SHARE_ZIP_MAX_MB", "2048")) * 1024 * 1024
SESS_LOCK = threading.RLock()
SESSIONS = {}

def _sess_save():
    try:
        tmp = SESSIONS_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f: json.dump(SESSIONS, f)
        os.chmod(tmp, 0o600)
        os.replace(tmp, SESSIONS_FILE)
    except: pass

def _sess_load():
    global SESSIONS
    try:
        with open(SESSIONS_FILE, "r", encoding="utf-8") as f: data = json.load(f)
        SESSIONS = {k: v for k, v in data.items() if v.get("exp", 0) > time.time()}
    except: SESSIONS = {}

_sess_load()

def _sess_sign(sid): return hmac.new(SESSION_SECRET, sid.encode("utf-8"), hashlib.sha256).hexdigest()

def _device_fp(user, ua):
    import re as _re
    norm = _re.sub(r"[0-9._]+", "", ua or "")
    return hashlib.sha256((user + "|" + norm).encode("utf-8")).hexdigest()[:20]

def _is_new_device(user, ua):
    fp = _device_fp(user, ua)
    try:
        with open(DEVICES_FILE, "r", encoding="utf-8") as f: known = json.load(f)
    except: known = []
    new = bool(known) and fp not in known
    if fp not in known:
        known = (known + [fp])[-300:]
        try:
            tmp = DEVICES_FILE + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f: json.dump(known, f)
            os.chmod(tmp, 0o600)
            os.replace(tmp, DEVICES_FILE)
        except: pass
    return new

def create_session(username, ttl, ip, ua):
    now = int(time.time())
    sid = secrets.token_urlsafe(12)
    with SESS_LOCK:
        for k in [k for k, v in SESSIONS.items() if v.get("exp", 0) <= now]: SESSIONS.pop(k, None)
        SESSIONS[sid] = {"user": username, "created": now, "last_seen": now, "exp": now + ttl,
                         "ip": ip, "last_ip": ip, "ua": (ua or "")[:200], "new": _is_new_device(username, ua)}
        _sess_save()
    return sid + "." + _sess_sign(sid)

def rotate_secret():
    global SESSION_SECRET
    with SESS_LOCK:
        new = secrets.token_hex(32)
        tmp_secret = SECRET_FILE + ".tmp"
        with open(tmp_secret, "w") as f: f.write(new)
        try: os.chmod(tmp_secret, 0o600)
        except Exception: pass
        os.replace(tmp_secret, SECRET_FILE)
        SESSION_SECRET = new.encode("utf-8")
        n = len(SESSIONS); SESSIONS.clear(); _sess_save()
        return n

def user_exists(username):
    return any(u.get("username") == username for u in get_config().get("users", []))

def verify_session_token(token, ip=None):
    try:
        sid, sig = token.rsplit(".", 1)
        if not hmac.compare_digest(sig, _sess_sign(sid)): return None, None
        now = int(time.time())
        with SESS_LOCK:
            sess = SESSIONS.get(sid)
            if not sess or sess.get("exp", 0) < now or not user_exists(sess["user"]): return None, None
            if now - sess.get("last_seen", 0) >= 60 or (ip and ip != sess.get("last_ip")):
                sess["last_seen"] = now
                if ip: sess["last_ip"] = ip
                _sess_save()
            return sess["user"], sid
    except: pass
    return None, None

def revoke_session(sid):
    with SESS_LOCK:
        existed = SESSIONS.pop(sid, None) is not None
        if existed: _sess_save()
        return existed

def revoke_other_sessions(keep_sid):
    with SESS_LOCK:
        gone = [k for k in SESSIONS if k != keep_sid]
        for k in gone: SESSIONS.pop(k, None)
        if gone: _sess_save()
        return len(gone)

def list_sessions(current_sid):
    now = int(time.time())
    with SESS_LOCK:
        items = []
        for sid, v in SESSIONS.items():
            if v.get("exp", 0) <= now: continue
            items.append({"sid": sid, "user": v.get("user"), "ip": v.get("ip"), "last_ip": v.get("last_ip"),
                          "ua": v.get("ua", ""), "created": v.get("created"), "last_seen": v.get("last_seen"),
                          "exp": v.get("exp"), "current": sid == current_sid,
                          "new": bool(v.get("new")) and (now - v.get("created", 0) < 604800),
                          "ack": bool(v.get("ack"))})
    items.sort(key=lambda x: (not x["current"], -(x["last_seen"] or 0)))
    return items

SHARE_LOCK = threading.RLock()

def load_shares():
    with SHARE_LOCK:
        try:
            with open(SHARES_FILE, "r", encoding="utf-8") as f: data = json.load(f)
            now = time.time()
            def alive(v):
                mu = int(v.get("max_uses", 0) or 0)
                return v.get("exp", 0) > now and (mu == 0 or int(v.get("uses", 0)) < mu)
            cleaned = {k: v for k, v in data.items() if alive(v)}
            if len(cleaned) != len(data): save_shares(cleaned)
            return cleaned
        except: return {}

def save_shares(data):
    with SHARE_LOCK:
        tmp = SHARES_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f: json.dump(data, f, indent=2)
        try: os.chmod(tmp, 0o600)
        except: pass
        os.replace(tmp, SHARES_FILE)

def hash_share_pw(password, salt=None):
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), bytes.fromhex(salt), 200000).hex()
    return salt, digest

def check_share_pw(info, password):
    salt, expected = info.get("pw_salt"), info.get("pw_hash")
    if not salt or not expected: return True
    return hmac.compare_digest(hash_share_pw(password, salt)[1], expected)

def consume_share_use(token):
    with SHARE_LOCK:
        data = load_shares()
        info = data.get(token)
        if not info: return False
        max_uses = int(info.get("max_uses", 0) or 0)
        uses = int(info.get("uses", 0))
        if max_uses and uses >= max_uses: return False
        info["uses"] = uses + 1
        save_shares(data)
        return True

def content_disposition(fname):
    ascii_name = "".join(c if (32 <= ord(c) < 127 and c not in '"\\;') else "_" for c in fname) or "download"
    return f'attachment; filename="{ascii_name}"; filename*=UTF-8\'\'{urllib.parse.quote(fname)}'

def append_audit(user, method, path, status=200, ip="local"):
    entry = {"time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "user": user or "web", "method": method, "path": urllib.parse.unquote(path), "status": status, "ip": ip}
    try:
        with open(AUDIT_FILE, "a", encoding="utf-8") as f: f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except: pass

def safe_resolve(rel_path):
    clean = urllib.parse.unquote(rel_path or "/").lstrip("/")
    full = os.path.normpath(os.path.join(ROOT_DIR, clean))
    if not full.startswith(ROOT_DIR): raise ValueError("Invalid path")
    return full

def dir_size_du(path):
    try: return int(subprocess.check_output(["du", "-sk", path], stderr=subprocess.DEVNULL, timeout=8).decode().split()[0]) * 1024
    except: return 0

def dir_size_bytes(path):
    try: return int(subprocess.check_output(["du", "-sk", path], stderr=subprocess.DEVNULL, timeout=8).decode().split()[0]) * 1024
    except: return None

CONFIG_LOCK = threading.Lock()

def _make_pw_hash(pw):
    salt = secrets.token_hex(16)
    h = hashlib.pbkdf2_hmac("sha256", pw.encode("utf-8"), bytes.fromhex(salt), 200000).hex()
    return "pbkdf2_sha256$200000$%s$%s" % (salt, h)

def change_user_password(username, new_pw):
    crypt = ""
    try:
        r = subprocess.run(["openssl", "passwd", "-6", "-stdin"], input=new_pw + "\n", capture_output=True, text=True, timeout=20)
        if r.returncode == 0 and r.stdout.startswith("$6$"): crypt = r.stdout.strip()
    except FileNotFoundError: pass
    except Exception: pass
    
    with CONFIG_LOCK:
        try:
            with open(USERS_FILE, "r", encoding="utf-8") as f: users = json.load(f)
        except Exception:
            users = []
        target = None
        for u in users:
            if u.get("username") == username: target = u; break
        if target is None: return False, ["user not found"]
        target["password_hash"] = _make_pw_hash(new_pw)
        target["crypt_hash"] = crypt
        target.pop("password", None)
        # cfg_fp (fingerprint of the last config password) is kept on purpose: the config password is only
        # re-applied when YOU change it there, so a restart never undoes a password changed on the Web UI.
        tmp = USERS_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f: json.dump(users, f, indent=2)
        os.chmod(tmp, 0o600)
        os.replace(tmp, USERS_FILE)
    cfg = get_config()

    warnings = []
    if crypt:
        try:
            r = subprocess.run(["chpasswd", "-e"], input="%s:%s\n" % (username, crypt), capture_output=True, text=True, timeout=20)
            if r.returncode != 0: warnings.append("SFTP/FTP password could not be updated")
        except: warnings.append("SFTP/FTP password could not be updated")
    else:
        try:
            r = subprocess.run(["chpasswd"], input="%s:%s\n" % (username, new_pw), capture_output=True, text=True, timeout=20)
            if r.returncode != 0: warnings.append("SFTP/FTP password could not be updated (fallback)")
        except: warnings.append("SFTP/FTP password could not be updated (fallback)")
        
    if cfg.get("smb_enabled", True):
        try:
            r = subprocess.run(["smbpasswd", "-a", "-s", username], input="%s\n%s\n" % (new_pw, new_pw), capture_output=True, text=True, timeout=20)
            if r.returncode != 0: warnings.append("SMB password could not be updated")
        except: warnings.append("SMB password could not be updated")
    return True, warnings

def config_password_pending(username):
    """Home Assistant only: True while the add-on configuration still shows a password for this user,
    i.e. a restart is needed to tidy it up (the new password itself is already active everywhere)."""
    try:
        with open(CLEARED_FILE, "r", encoding="utf-8") as f:
            if username in json.load(f): return False
    except Exception:
        pass
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            raw = json.load(f)
        for u in raw.get("users", []):
            if u.get("username") == username:
                # Only the untouched default password is "pending": restarting then just empties the field.
                # A different password typed in the configuration would be applied (and override this change) on restart.
                return str(u.get("password") or "") == "changeme_strong_password"
    except Exception:
        pass
    return False

def restart_addon_later():
    def _go():
        time.sleep(1.5)
        try:
            subprocess.run(["curl", "-fsS", "--max-time", "30", "-X", "POST", "-H", "Authorization: Bearer " + os.environ.get("SUPERVISOR_TOKEN", ""),
                            "http://supervisor/addons/self/restart"], capture_output=True, timeout=45)
        except Exception:
            pass
    threading.Thread(target=_go, daemon=True).start()

class WProHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args): return
    def client_ip(self): return self.headers.get("X-Real-IP", self.client_address[0])

    def is_ingress(self):
        tok = os.environ.get("INGRESS_TOKEN", "")
        return bool(tok) and hmac.compare_digest(self.headers.get("X-WPro-Ingress", "").encode("utf-8", "ignore"), tok.encode("utf-8"))

    def get_auth_user(self):
        self.sid = None
        u = self._get_auth_user_real()
        if u: return u
        # Home Assistant Ingress: Supervisor already authenticated the HA user, nginx marks the request with a per-boot secret.
        if self.is_ingress():
            users = get_config().get("users", [])
            if users: return users[0].get("username")
        return None

    def _get_auth_user_real(self):
        self.sid = None
        cookie_hdr = self.headers.get("Cookie", "")
        if cookie_hdr:
            c = SimpleCookie()
            try:
                c.load(cookie_hdr)
                if "wpro_sess" in c:
                    u, sid = verify_session_token(c["wpro_sess"].value, self.client_ip())
                    if u: self.sid = sid; return u
            except: pass
        auth_hdr = self.headers.get("Authorization", "")
        if auth_hdr.startswith("Basic "):
            try:
                decoded = base64.b64decode(auth_hdr[6:].strip()).decode("utf-8")
                uname, upass = decoded.split(":", 1)
                ip = self.client_ip()
                lock_key = ip + "|" + uname.lower()
                if login_locked(lock_key): return None
                if verify_credentials(uname, upass):
                    login_ok(lock_key); return uname
                login_failed(lock_key)
            except: pass
        return None

    def send_json(self, payload, code=200, extra_headers=None):
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        if extra_headers:
            for k, v in extra_headers.items(): self.send_header(k, v)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def share_page(self, token, info, error=None, code=200):
        name = html.escape(info.get("name", "file"))
        err = '<p class="err">' + html.escape(error) + '</p>' if error else ""
        page = ("""<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1, maximum-scale=1, user-scalable=no"><meta name="color-scheme" content="dark">
<title>Password Requires</title><style>
:root { --bg:#0b1933; --card:rgba(24,28,38,.74); --input:rgba(38,44,58,.82); --text:#fff; --muted:#94a3b8; --blue:#0a84ff; }
* { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
body { margin:0; min-height:100vh; display:grid; place-items:center; background-color:var(--bg); color:var(--text);
font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; padding:20px; position:relative; overflow:hidden; }
.ambient { position:fixed; top:-120px; left:-120px; right:-120px; bottom:-120px; z-index:-1; pointer-events:none;
background: radial-gradient(circle at 50% 8%,rgba(14,165,233,.32),transparent 60%), radial-gradient(circle at 18% 35%,rgba(10,132,255,.28),transparent 58%), radial-gradient(circle at 82% 85%,rgba(139,92,246,.32),transparent 60%), linear-gradient(180deg,#0b1933 0%,#0d1f42 50%,#12163b 100%); }
.card { width:100%; max-width:380px; background:var(--card); -webkit-backdrop-filter:saturate(190%) blur(28px); backdrop-filter:saturate(190%) blur(28px);
border:1px solid rgba(255,255,255,.14); border-radius:26px; padding:30px 24px 26px; box-shadow:0 24px 60px rgba(0,0,0,.65); text-align:center; animation:popIn .32s cubic-bezier(.2,.9,.3,1); }
@keyframes popIn { from{opacity:0;transform:scale(.94) translateY(10px)} to{opacity:1;transform:scale(1) translateY(0)} }
h1 { font-size:20px; margin:0 0 6px; display:flex; align-items:center; justify-content:center; gap:8px; color:#fff; }
h1 svg { width:22px; height:22px; color:#e2e8f0; }
p { color:var(--muted); font-size:14px; margin:0 0 22px; word-break:break-word; }
.input-wrap { position:relative; display:flex; align-items:center; margin-bottom:20px; text-align:left; }
.input-wrap svg { position:absolute; left:13px; width:18px; height:18px; color:var(--muted); pointer-events:none; }
input { width:100%; height:46px; border-radius:13px; border:1px solid rgba(255,255,255,.1); background:var(--input);
color:#fff; font-size:16px; padding:0 16px 0 40px; outline:none; transition:border-color .15s, background .15s; }
input:focus { border-color:var(--blue); background:rgba(48,56,74,.95); }
button { width:100%; height:48px; border:0; border-radius:14px; background:var(--blue); color:#fff; font-size:16px; font-weight:600; cursor:pointer;
box-shadow:0 6px 20px rgba(10,132,255,.38); transition:transform .12s, opacity .15s; display:flex; align-items:center; justify-content:center; }
button:active { transform:scale(.98); }
.err { color:#ff6961; margin:0 0 12px; font-size:13px; }
</style></head><body><div class="ambient"></div><div class="card">
<h1><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg> Password Requires</h1>
<p>""" + name + """</p>""" + err + """
<form method="post" action="">
<div class="input-wrap">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
    <input type="password" name="password" placeholder="Enter Password" autocomplete="off" autofocus required>
</div>
<button type="submit">Download</button>
</form></div></body></html>""").encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(page)))
        self.end_headers()
        self.wfile.write(page)

    def share_gone(self, code=404, text=b"Share link expired or invalid."):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(text)

    def serve_share(self, token, info):
        ip = self.client_ip()
        try:
            target = os.path.realpath(safe_resolve(info["path"]))
            is_dir = os.path.isdir(target)
            if not (is_dir or os.path.isfile(target)) or not user_can_read(target): raise FileNotFoundError()
            if is_dir:
                dsz = dir_size_bytes(target)
                if dsz is None or dsz > SHARE_ZIP_MAX:
                    self.share_gone(413, b"Folder is too large to download as a zip."); return
            if not consume_share_use(token): self.share_gone(); return
            append_audit("share-link", "SHARE_DL", info["path"], 200, ip)
            if is_dir:
                folder_name = os.path.basename(target.rstrip("/")) or "archive"
                tmpdir = tempfile.mkdtemp()
                try:
                    if not RUN_AS_ROOT: os.chown(tmpdir, RUN_UID, RUN_GID)
                    tmp_zip = os.path.join(tmpdir, "share.zip")
                    subprocess.run(["zip", "-r", "-q", tmp_zip, ".", "-x", "*.db*", "*.log*"], cwd=target, check=False, timeout=90, **run_as_kwargs())
                    fsize = os.path.getsize(tmp_zip)
                    self.send_response(200)
                    self.send_header("Content-Type", "application/zip")
                    self.send_header("Content-Disposition", content_disposition(folder_name + ".zip"))
                    self.send_header("Content-Length", str(fsize))
                    self.end_headers()
                    with open(tmp_zip, "rb") as f: shutil.copyfileobj(f, self.wfile)
                finally: shutil.rmtree(tmpdir, ignore_errors=True)
                return
            fname = os.path.basename(target)
            fsize = os.path.getsize(target)
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", content_disposition(fname))
            self.send_header("Content-Length", str(fsize))
            self.end_headers()
            with open(target, "rb") as f: shutil.copyfileobj(f, self.wfile)
        except:
            try: self.share_gone()
            except: pass

    def handle_share_post(self, route):
        token = route.split("/s/")[1].split("/")[0]
        ip = self.client_ip()
        info = load_shares().get(token)
        if not info: self.share_gone(); return
        key = "share|" + token + "|" + ip
        if login_locked(key):
            self.share_page(token, info, "Too many wrong attempts.", 429); return
        try:
            length = max(0, min(int(self.headers.get("Content-Length", "0")), 4096))
            form = urllib.parse.parse_qs(self.rfile.read(length).decode("utf-8", "ignore"))
        except: form = {}
        if not check_share_pw(info, form.get("password", [""])[0]):
            login_failed(key)
            append_audit("share-link", "SHARE_PW_FAIL", info["path"], 403, ip)
            time.sleep(0.4)
            self.share_page(token, info, "Wrong password.", 403); return
        login_ok(key)
        self.serve_share(token, info)

    def read_json_body(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0: return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        if route == "/__wpro_api/auth_check":
            user = self.get_auth_user()
            if user:
                self.send_response(200)
                self.send_header("X-WPro-User", user)
                self.end_headers()
            else:
                self.send_response(401)
                self.end_headers()
            return

        if route == "/__wpro_api/protocols":
            cfg = get_config()
            users = cfg.get("users", [])
            first_user = users[0].get("username", "admin") if users else "admin"
            shares = [s.get("name") for s in cfg.get("shares", [])]
            self.send_json({
                "webdav": True, "smb": bool(cfg.get("smb_enabled", True)), "sftp": bool(cfg.get("sftp_enabled", True)),
                "ftp": bool(cfg.get("ftp_enabled", True)), "default_user": first_user, "shares": shares,
                "terminal": TERMINAL_ENABLED, "run_as_root": RUN_AS_ROOT,
                "platform": "ha", "lan_ip": os.environ.get("LAN_IP", ""), "public_url": os.environ.get("PUBLIC_URL", ""),
                "smb_port": int(os.environ.get("SMB_PORT", "445") or 445), "sftp_port": int(os.environ.get("SFTP_PORT", "2222") or 2222),
                "ftp_port": int(os.environ.get("FTP_PORT", "2121") or 2121), "ext_port": int(os.environ.get("EXT_PORT", "8090") or 8090)
            })
            return
            
        if route.startswith("/s/") or route == "/__wpro_api/share_dl":
            token = route.split("/s/")[1].split("/")[0] if route.startswith("/s/") else (qs.get("token", [""])[0])
            info = load_shares().get(token)
            if not info or info.get("exp", 0) < time.time(): self.share_gone(); return
            if info.get("pw_hash"): self.share_page(token, info); return
            self.serve_share(token, info); return

        if route == "/__wpro_api/sessions":
            if not self.get_auth_user(): self.send_json({"error": "Unauthorized"}, 401); return
            self.send_json({"sessions": list_sessions(self.sid)}); return

        if route == "/__wpro_api/disk":
            try:
                disk_ref = "/host_root" if os.path.exists("/host_root") else ROOT_DIR
                total, used, free = shutil.disk_usage(disk_ref)
                folders = []
                for name in sorted(os.listdir(ROOT_DIR)):
                    if name == "host_system": continue
                    fpath = os.path.join(ROOT_DIR, name)
                    if os.path.isdir(fpath):
                        real_p = os.path.realpath(fpath)
                        folders.append({"name": name, "bytes": dir_size_du(real_p)})
                self.send_json({"total": total, "used": used, "free": free, "folders": folders})
            except Exception as e: self.send_json({"error": str(e)}, 500)
            return

        if route == "/__wpro_api/git_status":
            rel = qs.get("path", ["/"])[0]
            try:
                target = os.path.realpath(safe_resolve(rel))
                if not os.path.isdir(target): target = os.path.dirname(target)
                top = subprocess.check_output(["git", "-C", target, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL, timeout=4).decode().strip()
                branch = subprocess.check_output(["git", "-C", target, "rev-parse", "--abbrev-ref", "HEAD"], stderr=subprocess.DEVNULL, timeout=4).decode().strip()
                porcelain = subprocess.check_output(["git", "-C", target, "status", "--porcelain", "-uall"], stderr=subprocess.DEVNULL, timeout=5).decode()
                rel_from_top = os.path.relpath(target, top)
                prefix = "" if rel_from_top == "." else rel_from_top.rstrip("/") + "/"
                statuses = {}
                for line in porcelain.splitlines():
                    if len(line) < 4: continue
                    st = line[:2]; fp = line[3:].strip().strip('"')
                    if " -> " in fp: fp = fp.split(" -> ")[-1].strip('"')
                    if prefix and not fp.startswith(prefix): continue
                    sub = fp[len(prefix):] if prefix else fp
                    first_seg = sub.split("/")[0]
                    if not first_seg: continue
                    kind = "added" if ("?" in st or "A" in st) else "modified"
                    if first_seg not in statuses or kind == "modified": statuses[first_seg] = kind
                self.send_json({"is_git": True, "branch": branch, "statuses": statuses})
            except: self.send_json({"is_git": False, "statuses": {}})
            return

        if route == "/__wpro_api/shares":
            shares = load_shares()
            items = [{"token": k, **{kk: vv for kk, vv in v.items() if kk not in ("pw_hash", "pw_salt")}, "has_password": bool(v.get("pw_hash"))} for k, v in shares.items()]
            items.sort(key=lambda x: x.get("created", 0), reverse=True)
            self.send_json({"shares": items}); return

        if route == "/__wpro_api/audit":
            limit = int(qs.get("limit", ["150"])[0])
            logs = []
            try:
                if os.path.exists(AUDIT_FILE):
                    with open(AUDIT_FILE, "r", encoding="utf-8", errors="ignore") as f: lines = f.readlines()[-limit:]
                    for ln in reversed(lines):
                        ln = ln.strip()
                        if not ln: continue
                        try:
                            obj = json.loads(ln)
                            p_str = obj.get("path", ""); m_str = obj.get("method", "")
                            if p_str.startswith("/.fancyindex") or p_str.startswith("/__wpro_api"): continue
                            if m_str == "GET" and p_str.endswith("/"): continue
                            logs.append(obj)
                        except: pass
            except: pass
            self.send_json({"logs": logs[:100]}); return

        self.send_json({"error": "Not found"}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        if route.startswith("/s/"): self.handle_share_post(route); return
        if self.headers.get("X-WPro-CSRF") != "1": self.send_json({"ok": False, "error": "Missing CSRF header"}, 403); return
        body = self.read_json_body()

        if route == "/__wpro_api/login":
            uname = body.get("username", "").strip()
            upass = body.get("password", "")
            remember = bool(body.get("remember", True))
            ip = self.client_ip()
            lock_key = ip + "|" + uname.lower()
            if login_locked(lock_key):
                append_audit(uname or "unknown", "LOGIN_LOCKED", "/", 429, ip)
                self.send_json({"ok": False, "error": "Too many failed attempts."}, 429); return
            if verify_credentials(uname, upass):
                login_ok(lock_key)
                ttl = 2592000 if remember else 86400
                tok = create_session(uname, ttl, ip, self.headers.get("User-Agent", ""))
                is_https = (self.headers.get("X-Forwarded-Proto", "").lower() == "https" or "https" in self.headers.get("CF-Visitor", "").lower() or bool(get_config().get("ssl")))
                secure = "; Secure" if is_https else ""
                cookie_val = f"wpro_sess={tok}; Path=/; Max-Age={ttl}; HttpOnly; SameSite=Lax{secure}"
                append_audit(uname, "WEB_LOGIN", "/", 200, ip)
                self.send_json({"ok": True, "user": uname}, 200, {"Set-Cookie": cookie_val})
            else:
                login_failed(lock_key); time.sleep(0.4)
                append_audit(uname or "unknown", "LOGIN_FAIL", "/", 401, ip)
                self.send_json({"ok": False, "error": "Invalid username or password"}, 401)
            return

        if route == "/__wpro_api/logout":
            try:
                c = SimpleCookie(); c.load(self.headers.get("Cookie", ""))
                if "wpro_sess" in c: revoke_session(c["wpro_sess"].value.rsplit(".", 1)[0])
            except: pass
            self.send_json({"ok": True}, 200, {"Set-Cookie": "wpro_sess=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"}); return

        if route == "/__wpro_api/change_password":
            user = self.get_auth_user()
            if not user: self.send_json({"ok": False, "error": "Unauthorized"}, 401); return
            if self.sid is None and self.is_ingress():
                want = str(body.get("user", "")).strip()
                if want and user_exists(want): user = want
            ip = self.client_ip()
            old_pw, new_pw = str(body.get("old", "")), str(body.get("new", ""))
            key = "chpw|" + ip + "|" + user.lower()
            if login_locked(key): self.send_json({"ok": False, "error": "Too many wrong attempts."}, 429); return
            if not verify_credentials(user, old_pw):
                login_failed(key); time.sleep(0.4); append_audit(user, "PASSWORD_CHANGE_FAIL", "wrong current password", 403, ip)
                self.send_json({"ok": False, "error": "Current password is wrong" + (". If you just typed a new password in the add-on configuration, restart the add-on first; until then the previous password is still the active one." if IS_HA else "")}, 403); return
            login_ok(key)
            if len(new_pw) < 8 or len(new_pw) > 128 or any(ord(c) < 32 for c in new_pw):
                self.send_json({"ok": False, "error": "New password must be 8-128 characters"}, 400); return
            if new_pw == old_pw: self.send_json({"ok": False, "error": "New password must be different"}, 400); return
            ok, warnings = change_user_password(user, new_pw)
            if not ok: self.send_json({"ok": False, "error": "Could not change the password"}, 500); return
            n = revoke_other_sessions(self.sid)
            append_audit(user, "PASSWORD_CHANGE", "other devices signed out: " + str(n), 200, ip)
            env_override = bool(os.environ.get("OMNI_PASS") or os.environ.get("OMNI_PASS_FILE")) and os.environ.get("OMNI_USER", "") == user
            self.send_json({"ok": True, "revoked": n, "env_override": env_override, "warnings": warnings, "needs_restart": bool(IS_HA and config_password_pending(user))}); return

        if route == "/__wpro_api/restart_addon":
            user = self.get_auth_user()
            if not user: self.send_json({"ok": False, "error": "Unauthorized"}, 401); return
            if not IS_HA: self.send_json({"ok": False, "error": "Not available on this platform"}, 400); return
            append_audit(user, "ADDON_RESTART", "requested from the Web UI", 200, self.client_ip())
            self.send_json({"ok": True})
            restart_addon_later()
            return

        if route == "/__wpro_api/session_ack":
            user = self.get_auth_user()
            if not user: self.send_json({"ok": False, "error": "Unauthorized"}, 401); return
            with SESS_LOCK:
                n = 0
                for k, v in SESSIONS.items():
                    if (body.get("all") or k == str(body.get("sid", ""))) and v.get("new") and not v.get("ack"):
                        v["ack"] = True; n += 1
                if n: _sess_save()
            self.send_json({"ok": True, "acked": n}); return

        if route == "/__wpro_api/session_revoke":
            user = self.get_auth_user()
            if not user: self.send_json({"ok": False, "error": "Unauthorized"}, 401); return
            ip = self.client_ip()
            if body.get("rotate"):
                n = rotate_secret(); append_audit(user, "SESSION_ROTATE", "signing key rotated, " + str(n) + " session(s) ended", 200, ip)
                self.send_json({"ok": True, "revoked": n, "self": True}, 200, {"Set-Cookie": "wpro_sess=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"}); return
            if body.get("all_others"):
                n = revoke_other_sessions(self.sid); append_audit(user, "SESSION_REVOKE", "all other devices (" + str(n) + ")", 200, ip)
                self.send_json({"ok": True, "revoked": n}); return
            sid = str(body.get("sid", ""))
            if revoke_session(sid):
                append_audit(user, "SESSION_REVOKE", "device " + sid[:6], 200, ip)
                extra = {"Set-Cookie": "wpro_sess=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"} if sid == self.sid else None
                self.send_json({"ok": True, "revoked": 1, "self": sid == self.sid}, 200, extra)
            else: self.send_json({"ok": False, "error": "Session not found"}, 404)
            return

        if route == "/__wpro_api/snapshot":
            target_mode = body.get("target", "config")
            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = os.path.realpath(os.path.join(ROOT_DIR, "backup"))
            os.makedirs(backup_dir, exist_ok=True)
            cfg_dir = os.path.realpath(os.path.join(ROOT_DIR, "config"))
            try:
                if target_mode == "automations" and os.path.exists(cfg_dir):
                    zip_name = f"quick_automations_{stamp}.zip"; zip_path = os.path.join(backup_dir, zip_name)
                    cmd = ["zip", "-r", "-q", zip_path, "automations.yaml", "scripts.yaml", "scenes.yaml", "configuration.yaml", "automations", "packages"]
                    subprocess.run(cmd, cwd=cfg_dir, check=False, timeout=60, **run_as_kwargs())
                elif target_mode == "storage":
                    zip_name = f"backup_storage_{stamp}.zip"; zip_path = os.path.join(backup_dir, zip_name)
                    storage_dir = os.path.realpath(os.path.join(ROOT_DIR, "storage"))
                    cmd = ["zip", "-r", "-q", zip_path, ".", "-x", "backup/*", "*.db*", "*.log*"]
                    subprocess.run(cmd, cwd=storage_dir, check=False, timeout=120, **run_as_kwargs())
                elif target_mode == "current":
                    cwd_rel = body.get("cwd", "/")
                    current_dir = os.path.realpath(safe_resolve(cwd_rel))
                    if not os.path.isdir(current_dir): raise Exception("Current folder is not valid.")
                    zip_name = f"backup_current_{stamp}.zip"; zip_path = os.path.join(backup_dir, zip_name)
                    cmd = ["zip", "-r", "-q", zip_path, ".", "-x", "backup/*", "*.db*", "*.log*"]
                    subprocess.run(cmd, cwd=current_dir, check=False, timeout=120, **run_as_kwargs())
                else:
                    zip_name = f"quick_snapshot_{stamp}.zip"; zip_path = os.path.join(backup_dir, zip_name)
                    cmd = ["zip", "-r", "-q", zip_path, ".", "-x", "backup/*", "*.db*", "*.log*"]
                    subprocess.run(cmd, cwd=cfg_dir, check=False, timeout=120, **run_as_kwargs())

                size_kb = round(os.path.getsize(zip_path) / 1024, 1) if os.path.exists(zip_path) else 0
                append_audit("admin", "SNAPSHOT", f"/backup/{zip_name}", 200)
                self.send_json({"ok": True, "filename": zip_name, "path": f"/backup/{zip_name}", "size_kb": size_kb})
            except Exception as e: self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/share":
            action = body.get("action", "create")
            shares = load_shares()
            if action == "revoke":
                tok = body.get("token", "")
                shares.pop(tok, None); save_shares(shares)
                append_audit("admin", "SHARE_REVOKE", tok, 200)
                self.send_json({"ok": True}); return

            rel_path = body.get("path", "")
            try: ttl = max(60, min(int(body.get("ttl", 3600)), 365 * 86400))
            except: ttl = 3600
            try: max_uses = max(0, min(int(body.get("max_uses", 0) or 0), 1000000))
            except: max_uses = 0
            password = str(body.get("password", "") or "")
            if len(password) > 128: self.send_json({"ok": False, "error": "Password is too long"}, 400); return
            try:
                full = safe_resolve(rel_path)
                if not os.path.exists(full): self.send_json({"ok": False, "error": "Target path does not exist"}, 400); return
                is_dir = os.path.isdir(full)
                base_name = os.path.basename(full.rstrip("/")) or "root"
                display_name = (base_name + ".zip") if is_dir else base_name
                token = secrets.token_urlsafe(10)
                now = int(time.time())
                entry = {"path": rel_path, "name": display_name, "is_dir": is_dir, "created": now, "exp": now + ttl, "max_uses": max_uses, "uses": 0}
                if password: entry["pw_salt"], entry["pw_hash"] = hash_share_pw(password)
                with SHARE_LOCK:
                    shares = load_shares(); shares[token] = entry; save_shares(shares)
                append_audit("admin", "SHARE_CREATE", rel_path, 200)
                self.send_json({"ok": True, "token": token, "exp": now + ttl, "name": display_name, "is_dir": is_dir, "max_uses": max_uses, "has_password": bool(password)})
            except Exception as e: self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/audit_clear":
            try:
                open(AUDIT_FILE, "w").close()
                append_audit("admin", "AUDIT_CLEAR", "/", 200)
                self.send_json({"ok": True})
            except Exception as e: self.send_json({"ok": False, "error": str(e)}, 500)
            return

        if route == "/__wpro_api/exec":
            if not TERMINAL_ENABLED: self.send_json({"output": "Web Terminal is disabled.\n", "code": 403}, 403); return
            cmd_str = body.get("cmd", "").strip()
            cwd_rel = body.get("cwd", "/")
            if not cmd_str: self.send_json({"output": ""}); return
            try:
                cwd_full = os.path.realpath(safe_resolve(cwd_rel))
                if not os.path.isdir(cwd_full): cwd_full = ROOT_DIR
                proc = subprocess.run(cmd_str, shell=True, cwd=cwd_full, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=25, text=True, env=child_env(), **run_as_kwargs())
                append_audit("admin", "TERM_CMD", cmd_str[:80], proc.returncode)
                self.send_json({"output": proc.stdout, "code": proc.returncode})
            except subprocess.TimeoutExpired: self.send_json({"output": "Command timed out after 25s.\n", "code": 124})
            except Exception as e: self.send_json({"output": f"Error: {e}\n", "code": 1})
            return

        self.send_json({"error": "Unknown endpoint"}, 404)

if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), WProHandler)
    server.serve_forever()
PYEOF
chmod +x /usr/local/bin/wpro_api.py

python3 /usr/local/bin/wpro_api.py "${API_PORT}" &
bashio::log.info "Started OmniDrive Pro API & Hybrid Auth Engine on 127.0.0.1:${API_PORT}"

# 10. Nginx Configuration
# Ingress: chỉ tin Supervisor (172.30.32.2) để lấy IP thật của client từ X-Forwarded-For
REAL_IP_CONF_INGRESS="
        set_real_ip_from 172.30.32.2;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;"
# Cổng 8090 (WebDAV / Cloudflare Tunnel / reverse proxy): chỉ tin các proxy khai báo trong 'trusted_proxies'
REAL_IP_CONF=""
if [ "${TRUSTED_PROXIES,,}" != "none" ]; then
    IFS=',' read -ra _TP <<< "$TRUSTED_PROXIES"
    for _cidr in "${_TP[@]}"; do
        _cidr="${_cidr// /}"
        if [[ "$_cidr" =~ ^[0-9a-fA-F:./]+$ ]]; then
            REAL_IP_CONF+="        set_real_ip_from ${_cidr};"$'\n'
        elif [ -n "$_cidr" ]; then
            bashio::log.warning "Ignoring invalid trusted_proxies entry: ${_cidr}"
        fi
    done
    if [ -n "$REAL_IP_CONF" ]; then
        REAL_IP_CONF+="        real_ip_header X-Forwarded-For;"$'\n'"        real_ip_recursive on;"
        bashio::log.info "Real client IP enabled for port ${WEBDAV_PORT} (trusted proxies: ${TRUSTED_PROXIES})."
    fi
fi

cat <<EOF > "$NGINX_CONF"
load_module /usr/lib/nginx/modules/ngx_http_dav_ext_module.so;
load_module /usr/lib/nginx/modules/ngx_http_fancyindex_module.so;

user root;
worker_processes auto;
pid /run/nginx/nginx.pid;
error_log /dev/stderr ${LOG_LEVEL};

events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    subrequest_output_buffer_size 512k;

    map \$http_accept \$is_browser_client { default 0; "~*text/html" 1; }
    map \$is_browser_client \$dav_www_auth { 1 ""; 0 'Basic realm="OmniDrive Pro WebDAV"'; }

    log_format wpro_audit escape=json '{"time":"\$time_iso8601","user":"\$upstream_http_x_wpro_user","ip":"\$remote_addr","method":"\$request_method","path":"\$uri","status":\$status}';
    map \$request_method \$is_mutating_or_dl { default 0; PUT 1; DELETE 1; MKCOL 1; COPY 1; MOVE 1; GET 1; }

    access_log /dev/stdout;
    access_log ${WPRO_DATA}/audit.jsonl wpro_audit if=\$is_mutating_or_dl;

    sendfile on; tcp_nopush on; tcp_nodelay on; keepalive_timeout 65; server_tokens off; etag off;
    absolute_redirect off; port_in_redirect off;
    
    client_max_body_size ${MAX_UPLOAD};
    client_body_temp_path /var/lib/nginx/tmp/client_body;

    dav_ext_lock_zone zone=davlock:10m;
    limit_req_zone \$binary_remote_addr zone=dav_auth_limit:10m rate=20r/s;
    limit_req_zone \$binary_remote_addr zone=share_limit:10m rate=5r/s;

    server {
        listen 8099;
        ${REAL_IP_CONF_INGRESS}
        # allow/deny dùng \$remote_addr (đã bị real_ip đổi thành IP client) nên gây 403.
        # Dùng \$realip_remote_addr = địa chỉ kết nối gốc (Supervisor) để kiểm tra,
        # đồng thời vẫn giữ được IP thật của client trong \$remote_addr / X-Real-IP.
        if (\$realip_remote_addr != "172.30.32.2") { return 403; }
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
        location ^~ /.fancyindex/vendor/ { alias /usr/share/nginx/fancyindex/vendor/; access_log off; gzip on; gzip_types application/javascript text/css; gzip_min_length 1024; add_header Cache-Control "public, max-age=604800" always; }
        location /.fancyindex/ { alias /usr/share/nginx/fancyindex/; access_log off; }
        location ^~ /__wpro_api/ { proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; proxy_set_header X-WPro-Ingress "${INGRESS_TOKEN}"; access_log off; }
        location ^~ /s/ { proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; }
        location / {
            root ${ROOT_DIR};
            index __omnidrive_no_index__;
            ${INDEX_CONFIG}
${ROOT_LOCK_RULES}
            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
            dav_ext_lock zone=davlock;
            create_full_put_path on;
            dav_access user:rw group:rw all:r;
            if (-d \$request_filename) { rewrite ^(.*[^/])$ \$1/ break; }
        }
    }

    server {
        ${LISTEN_DIRECTIVE}
        ${SSL_DIRECTIVES}
        server_name _;
        ${REAL_IP_CONF}
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
        location ^~ /.fancyindex/vendor/ { alias /usr/share/nginx/fancyindex/vendor/; access_log off; gzip on; gzip_types application/javascript text/css; gzip_min_length 1024; add_header Cache-Control "public, max-age=604800" always; }
        location ^~ /.fancyindex/ { alias /usr/share/nginx/fancyindex/; access_log off; }
        location = /__wpro_api/login { limit_req zone=dav_auth_limit burst=15 nodelay; proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; access_log off; }
        location = /__wpro_api/logout { proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; access_log off; }
        location = /__wpro_auth_check {
            internal;
            proxy_pass http://127.0.0.1:${API_PORT}/__wpro_api/auth_check;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Cookie \$http_cookie;
            proxy_set_header Authorization \$http_authorization;
        }
        location @login_or_basic {
            add_header WWW-Authenticate \$dav_www_auth always;
            if (\$is_browser_client = 1) { return 302 /.fancyindex/login.html?rd=\$request_uri; }
            return 401 "Authentication required";
        }
        location ^~ /s/ { limit_req zone=share_limit burst=15 nodelay; limit_req_status 429; proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; }
        location ^~ /__wpro_api/ { auth_request /__wpro_auth_check; error_page 401 = @login_or_basic; proxy_pass http://127.0.0.1:${API_PORT}; proxy_set_header Host \$host; proxy_set_header X-Real-IP \$remote_addr; access_log off; }
        ${DOTFILES_RULE}
        location / {
            limit_req zone=dav_auth_limit burst=40 nodelay;
            auth_request /__wpro_auth_check;
            error_page 401 = @login_or_basic;
            root ${ROOT_DIR};
            index __omnidrive_no_index__;
            ${INDEX_CONFIG}
${ROOT_LOCK_RULES}
            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
            dav_ext_lock zone=davlock;
            create_full_put_path on;
            dav_access user:rw group:rw all:r;
            if (-d \$request_filename) { rewrite ^(.*[^/])$ \$1/ break; }
        }
    }
}
EOF

# 12. Validate & Start
bashio::log.info "Checking Nginx configuration syntax..."
if ! nginx -t 2>&1; then
    bashio::log.error "Invalid Nginx configuration, see details above."
    bashio::exit.nok "Stopping add-on."
fi

bashio::log.info "OmniDrive Pro v${ADDON_VERSION} is ready on port ${WEBDAV_PORT} and Ingress!"
exec nginx -g "daemon off;"
