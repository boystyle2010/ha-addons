ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.24
FROM ${BUILD_FROM}

# Phiên bản Cloudflared thật (bot sẽ tự cập nhật dòng này)
ARG CLOUDFLARED_VERSION=2026.10.7

# Cài đặt các gói cần thiết
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache curl ca-certificates tzdata jq

# Tải binary cloudflared arm64
RUN curl -fL "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-arm64" \
    -o /usr/bin/cloudflared && \
    chmod +x /usr/bin/cloudflared

# Copy script khởi chạy
COPY run.sh /
RUN chmod a+x /run.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep cloudflared > /dev/null || exit 1

CMD [ "/run.sh" ]
