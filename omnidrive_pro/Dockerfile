# Base image đa kiến trúc (aarch64 + amd64) - thay thế hoàn toàn build.yaml
FROM ghcr.io/home-assistant/base:3.24

# Phiên bản nginx mà workflow đã kiểm tra trên Alpine. Không ghim cứng trong apk (Alpine xóa bản -rN cũ khỏi kho,
# ghim sẽ làm hỏng build), nhưng dùng ARG trong RUN để làm mới cache khi đổi và in ra bản thực sự được cài.
ARG NGINX_VERSION=1.30.7-r0
# Dấu vân tay phiên bản các gói Alpine quan trọng (Samba, OpenSSH, vsftpd, OpenSSL...). Workflow cập nhật giá trị
# này mỗi khi Alpine phát hành bản vá -> lớp cài gói bên dưới được build lại với 'apk upgrade'.
ARG APK_FINGERPRINT=d4cf421b5a0721d9

# Install Nginx + WebDAV/FancyIndex, Python3, Git, Zip, plus Samba (SMB), OpenSSH (SFTP) & vsftpd (FTP)
RUN echo "Target nginx package: ${NGINX_VERSION} | packages: ${APK_FINGERPRINT}" \
    && apk update && apk upgrade --no-cache && apk add --no-cache \
    nginx \
    nginx-mod-http-dav-ext \
    nginx-mod-http-fancyindex \
    jq \
    bash \
    tzdata \
    python3 \
    git \
    zip \
    samba \
    openssh \
    vsftpd \
    shadow \
    openssl \
    && echo "Installed: $(nginx -v 2>&1)"

# Create working directories for Nginx, Multi-Protocol daemons & Pro API
RUN mkdir -p \
    /run/nginx \
    /var/lib/nginx/tmp/client_body \
    /var/webdav_root \
    /usr/share/nginx/fancyindex \
    /data/wpro \
    /var/run/vsftpd/empty \
    /etc/ssh

COPY fancyindex/ /usr/share/nginx/fancyindex/
COPY icon.png /usr/share/nginx/fancyindex/icon.png

# Front-end libraries (Ace, marked, DOMPurify, js-yaml, JSZip, pdf.js, xterm.js): pinned versions, SHA-256 verified
COPY vendor-fetch.sh /tmp/vendor-fetch.sh
RUN sh /tmp/vendor-fetch.sh /usr/share/nginx/fancyindex/vendor && rm -f /tmp/vendor-fetch.sh

COPY run.sh /
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

CMD [ "/run.sh" ]
