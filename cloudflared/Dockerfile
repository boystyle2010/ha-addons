# Base image đa kiến trúc (aarch64 + amd64) - thay thế hoàn toàn build.yaml đã bị loại bỏ
FROM ghcr.io/home-assistant/base:3.24

# Kiến trúc: TARGETARCH do BuildKit tự điền (arm64/amd64), BUILD_ARCH là dự phòng, cuối cùng là uname -m
ARG TARGETARCH
ARG BUILD_ARCH

# Phiên bản Cloudflared thật (bot sẽ tự cập nhật dòng này)
ARG CLOUDFLARED_VERSION=2026.11.1

# Cài đặt các gói cần thiết
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache curl ca-certificates tzdata jq

# Tự động chọn đúng binary theo cấu trúc phần cứng (aarch64 -> arm64 | amd64 -> amd64)
RUN ARCH_CHECK="${TARGETARCH:-${BUILD_ARCH}}" && \
    if [ -z "${ARCH_CHECK}" ]; then ARCH_CHECK="$(uname -m)"; fi && \
    case "${ARCH_CHECK}" in \
        aarch64|arm64) CF_ARCH="arm64" ;; \
        amd64|x86_64)  CF_ARCH="amd64" ;; \
        *) echo "Unsupported architecture: ${ARCH_CHECK}" && exit 1 ;; \
    esac && \
    echo "Downloading Cloudflared v${CLOUDFLARED_VERSION} for architecture: ${CF_ARCH} (Host: ${ARCH_CHECK})" && \
    BIN="cloudflared-linux-${CF_ARCH}" && \
    curl -fL --retry 5 --retry-delay 3 "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/${BIN}" \
    -o /usr/bin/cloudflared && \
    EXPECTED="$( (curl -fsSL --retry 3 "https://api.github.com/repos/cloudflare/cloudflared/releases/tags/${CLOUDFLARED_VERSION}" || true) \
        | jq -r '.body // ""' 2>/dev/null | tr -d '\r' | awk -v b="${BIN}:" '$1 == b && !f {print $2; f=1}')" && \
    if [ "${#EXPECTED}" -eq 64 ]; then \
        echo "${EXPECTED}  /usr/bin/cloudflared" | sha256sum -c - ; \
    else \
        echo "WARNING: SHA-256 for ${BIN} not found in the release notes, checksum NOT verified" ; \
    fi && \
    chmod +x /usr/bin/cloudflared

# Copy script khởi chạy và làm sạch định dạng dòng
COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep cloudflared > /dev/null || exit 1

# Ép chạy trực tiếp qua bashio để tránh lỗi syntax "(" của /bin/sh
CMD [ "/usr/bin/with-contenv", "bashio", "/run.sh" ]
