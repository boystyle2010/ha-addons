ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.24
ARG TAILSCALE_VERSION=v1.104.5

FROM ${BUILD_FROM}

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
    && TS_VER="${TAILSCALE_VERSION#v}" \
    && curl -sfL "https://pkgs.tailscale.com/stable/tailscale_${TS_VER}_arm64.tgz" \
       | tar -xzf - -C /tmp \
    && mv "/tmp/tailscale_${TS_VER}_arm64/tailscale" /usr/bin/tailscale \
    && mv "/tmp/tailscale_${TS_VER}_arm64/tailscaled" /usr/bin/tailscaled \
    && chmod a+x /usr/bin/tailscale /usr/bin/tailscaled \
    && rm -rf /tmp/tailscale_*

COPY run.sh /
RUN chmod a+x /run.sh

HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
    CMD tailscale --socket=/var/run/tailscale/tailscaled.sock status --json | jq -e '.BackendState == "Running" or .BackendState == "NeedsLogin"' >/dev/null || exit 1

CMD [ "/run.sh" ]
