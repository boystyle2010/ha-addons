ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_VERSION
ENV CLOUDFLARED_VERSION=${BUILD_VERSION}

# Tự động nâng cấp toàn bộ gói hệ thống Alpine lên bản mới nhất
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    jq

# Lọc bỏ hậu tố bản vá (nếu có, VD: 2026.10.0-alpine3.20 -> 2026.10.0)
RUN VERSION_CLEAN=$(echo "${CLOUDFLARED_VERSION}" | cut -d'-' -f1) && \
    curl -fL "https://github.com/cloudflare/cloudflared/releases/download/${VERSION_CLEAN}/cloudflared-linux-arm64" -o /usr/bin/cloudflared && \
    chmod +x /usr/bin/cloudflared

# Copy script khởi chạy
COPY run.sh /
RUN chmod a+x /run.sh

# Tự động kiểm tra tiến trình cloudflared mỗi 30 giây (Chống treo ngầm cho Watchdog)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep cloudflared > /dev/null || exit 1

CMD [ "/run.sh" ]
