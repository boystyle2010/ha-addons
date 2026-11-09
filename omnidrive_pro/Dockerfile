ARG BUILD_FROM
FROM $BUILD_FROM

ARG NGINX_VERSION

# Install Nginx + WebDAV/FancyIndex, Python3, Git, Zip, plus Samba (SMB), OpenSSH (SFTP) & vsftpd (FTP)
RUN apk update && apk add --no-cache \
    nginx \
    nginx-mod-http-dav-ext \
    nginx-mod-http-fancyindex \
    apache2-utils \
    jq \
    bash \
    tzdata \
    python3 \
    git \
    zip \
    samba \
    openssh \
    vsftpd \
    shadow

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
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
