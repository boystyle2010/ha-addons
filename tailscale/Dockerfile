ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.24
ARG TAILSCALE_VERSION=v1.104.7

FROM ${BUILD_FROM}

ARG BUILD_ARCH=aarch64
ARG TAILSCALE_VERSION

RUN apk add --no-cache \
    ca-certificates \
    iptables \
    ip6tables \
    iproute2 \
    ethtool \
    nginx \
    curl \
    jq \
    bash \
    && ARCH_CHECK="${BUILD_ARCH}" \
    && if [ -z "${ARCH_CHECK}" ]; then ARCH_CHECK="$(uname -m)"; fi \
    && case "${ARCH_CHECK}" in \
        aarch64|arm64) TS_ARCH="arm64" ;; \
        amd64|x86_64)  TS_ARCH="amd64" ;; \
        *) echo "Unsupported architecture: ${ARCH_CHECK}" && exit 1 ;; \
       esac \
    && TS_VER="${TAILSCALE_VERSION#v}" \
    && echo "Downloading Tailscale v${TS_VER} for architecture: ${TS_ARCH}" \
    && curl -sfL "https://pkgs.tailscale.com/stable/tailscale_${TS_VER}_${TS_ARCH}.tgz" \
       | tar -xzf - -C /tmp \
    && mv "/tmp/tailscale_${TS_VER}_${TS_ARCH}/tailscale" /usr/bin/tailscale \
    && mv "/tmp/tailscale_${TS_VER}_${TS_ARCH}/tailscaled" /usr/bin/tailscaled \
    && chmod a+x /usr/bin/tailscale /usr/bin/tailscaled \
    && rm -rf /tmp/tailscale_*

COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh && chmod a+x /run.sh

HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
    CMD tailscale --socket=/var/run/tailscale/tailscaled.sock status --json | jq -e '.BackendState == "Running" or .BackendState == "NeedsLogin"' >/dev/null || exit 1

CMD [ "/usr/bin/with-contenv", "bashio", "/run.sh" ]
