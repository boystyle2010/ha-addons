ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.24
FROM ${BUILD_FROM}

# Nhận diện kiến trúc từ Home Assistant Supervisor (aarch64 hoặc amd64)
ARG BUILD_ARCH

# Phiên bản Cloudflared thật (bot sẽ tự cập nhật dòng này)
ARG CLOUDFLARED_VERSION=2026.11.0

# Cài đặt các gói cần thiết
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache curl ca-certificates tzdata jq

# Tự động chọn đúng binary theo cấu trúc phần cứng (aarch64 -> arm64 | amd64 -> amd64)
RUN ARCH_CHECK="${BUILD_ARCH}" && \
    if [ -z "${ARCH_CHECK}" ]; then ARCH_CHECK="$(uname -m)"; fi && \
    case "${ARCH_CHECK}" in \
        aarch64|arm64) CF_ARCH="arm64" ;; \
        amd64|x86_64)  CF_ARCH="amd64" ;; \
        *) echo "Unsupported architecture: ${ARCH_CHECK}" && exit 1 ;; \
    esac && \
    echo "Downloading Cloudflared v${CLOUDFLARED_VERSION} for architecture: ${CF_ARCH} (Host: ${ARCH_CHECK})" && \
    curl -fL "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${CF_ARCH}" \
    -o /usr/bin/cloudflared && \
    chmod +x /usr/bin/cloudflared

# Copy script khởi chạy và làm sạch định dạng dòng
COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep cloudflared > /dev/null || exit 1

# Ép chạy trực tiếp qua bashio để tránh lỗi syntax "(" của /bin/sh
CMD [ "/usr/bin/with-contenv", "bashio", "/run.sh" ]
