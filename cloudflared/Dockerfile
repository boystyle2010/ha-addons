ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.21
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ENV CLOUDFLARED_VERSION=${BUILD_VERSION}

# Nâng cấp gói bảo mật Alpine và cài công cụ
RUN apk update && apk upgrade --no-cache && apk add --no-cache curl ca-certificates tzdata jq

# Tải trực tiếp binary cloudflared arm64 từ Cloudflare
RUN VERSION_CLEAN=$(echo "${CLOUDFLARED_VERSION}" | cut -d'-' -f1) && curl -fL "https://github.com/cloudflare/cloudflared/releases/download/${VERSION_CLEAN}/cloudflared-linux-arm64" -o /usr/bin/cloudflared && chmod +x /usr/bin/cloudflared

# Copy script khởi chạy
COPY run.sh /
RUN chmod a+x /run.sh

# Kiểm tra sức khỏe đường hầm mỗi 30 giây (Viết trên 1 dòng để tránh lỗi cú pháp buildx)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD pgrep cloudflared > /dev/null || exit 1

CMD [ "/run.sh" ]
