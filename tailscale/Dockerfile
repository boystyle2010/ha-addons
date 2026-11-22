ARG TAILSCALE_VERSION=v1.104.7

# Base image đa kiến trúc (aarch64 + amd64) - thay thế hoàn toàn build.yaml đã bị loại bỏ
FROM ghcr.io/home-assistant/base:3.24

ARG TARGETARCH
ARG BUILD_ARCH
ARG TAILSCALE_VERSION

# Tải Tailscale và kiểm tra SHA-256 chính thức (file .sha256 cạnh mỗi gói): sai hash -> dừng build
RUN apk upgrade --no-cache && apk add --no-cache \
    ca-certificates \
    iptables \
    ip6tables \
    iproute2 \
    ethtool \
    nginx \
    curl \
    jq \
    bash \
    && ARCH_CHECK="${TARGETARCH:-${BUILD_ARCH}}" \
    && if [ -z "${ARCH_CHECK}" ]; then ARCH_CHECK="$(uname -m)"; fi \
    && case "${ARCH_CHECK}" in \
        aarch64|arm64) TS_ARCH="arm64" ;; \
        amd64|x86_64)  TS_ARCH="amd64" ;; \
        *) echo "Unsupported architecture: ${ARCH_CHECK}" && exit 1 ;; \
       esac \
    && TS_VER="${TAILSCALE_VERSION#v}" \
    && echo "Downloading Tailscale v${TS_VER} for architecture: ${TS_ARCH}" \
    && TGZ="tailscale_${TS_VER}_${TS_ARCH}.tgz" \
    && curl -fsSL --retry 5 --retry-delay 3 -o "/tmp/${TGZ}" "https://pkgs.tailscale.com/stable/${TGZ}" \
    && EXPECTED="$( (curl -fsSL --retry 3 "https://pkgs.tailscale.com/stable/${TGZ}.sha256" || true) | awk 'NR == 1 {print $1}')" \
    && if [ "${#EXPECTED}" -eq 64 ]; then \
           echo "${EXPECTED}  /tmp/${TGZ}" | sha256sum -c - ; \
       else \
           echo "WARNING: official SHA-256 for ${TGZ} unavailable, checksum NOT verified" ; \
       fi \
    && tar -xzf "/tmp/${TGZ}" -C /tmp \
    && mv "/tmp/tailscale_${TS_VER}_${TS_ARCH}/tailscale" /usr/bin/tailscale \
    && mv "/tmp/tailscale_${TS_VER}_${TS_ARCH}/tailscaled" /usr/bin/tailscaled \
    && chmod a+x /usr/bin/tailscale /usr/bin/tailscaled \
    && rm -rf /tmp/tailscale_*

COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
    CMD tailscale --socket=/var/run/tailscale/tailscaled.sock status --json | jq -e '.BackendState == "Running" or .BackendState == "NeedsLogin"' >/dev/null || exit 1

CMD [ "/usr/bin/with-contenv", "bashio", "/run.sh" ]
