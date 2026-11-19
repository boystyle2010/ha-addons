# Base image đa kiến trúc (aarch64 + amd64) - thay thế hoàn toàn build.yaml
FROM ghcr.io/home-assistant/base:3.24

ARG NGINX_VERSION=1.30.7-r0

# Install Nginx + WebDAV/FancyIndex, Python3, Git, Zip, plus Samba (SMB), OpenSSH (SFTP) & vsftpd (FTP)
RUN apk update && apk add --no-cache \
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
    openssl

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
COPY run.sh /
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

CMD [ "/run.sh" ]
