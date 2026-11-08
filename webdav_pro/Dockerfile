ARG BUILD_FROM
FROM $BUILD_FROM

ARG NGINX_VERSION

# Cài đặt Nginx, module WebDAV mở rộng, module giao diện FancyIndex và công cụ mã hóa
RUN apk update && apk add --no-cache \
    nginx \
    nginx-mod-http-dav-ext \
    nginx-mod-http-fancyindex \
    apache2-utils \
    jq \
    bash \
    tzdata

# Khởi tạo các thư mục đệm cho Nginx & WebDAV
RUN mkdir -p \
    /run/nginx \
    /var/lib/nginx/tmp/client_body \
    /var/webdav_root \
    /usr/share/nginx/fancyindex

COPY fancyindex/ /usr/share/nginx/fancyindex/
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
