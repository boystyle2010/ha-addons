ARG BUILD_FROM
FROM $BUILD_FROM

ARG NGINX_VERSION

# Install Nginx, WebDAV & FancyIndex modules, plus Python3, Git, Zip, and ttyd (WebSocket Terminal)
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
    ttyd

# Create working directories for Nginx, WebDAV & Pro API
RUN mkdir -p \
    /run/nginx \
    /var/lib/nginx/tmp/client_body \
    /var/webdav_root \
    /usr/share/nginx/fancyindex \
    /data/wpro

COPY fancyindex/ /usr/share/nginx/fancyindex/
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
