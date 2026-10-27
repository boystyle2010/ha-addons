ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ENV CLOUDFLARED_VERSION=${BUILD_VERSION}

# Tự động nâng cấp toàn bộ gói hệ thống Alpine lên bản mới nhất và cài đặt công cụ
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    jq

# Lọc bỏ hậu tố bản vá (nếu có, VD: 2026.10.0-alpine3.21 -> 2026.10.0) để tải đúng binary Cloudflared
RUN VERSION_CLEAN=$(echo "${CLOUDFLARED_VERSION}" | sed 's/^v//' | cut -d'-' -f1) && \
    curl -fL "https://github.com/cloudflare/cloudflared/releases/download/${VERSION_CLEAN}/cloudflared-linux-arm64" -o /usr/bin/cloudflared && \
    chmod +x /usr/bin/cloudflared

# Copy script khởi chạy
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

