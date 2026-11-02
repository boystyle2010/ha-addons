ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.20
ARG TAILSCALE_VERSION=v1.104.1

FROM tailscale/tailscale:${TAILSCALE_VERSION} AS tailscale-upstream

FROM ${BUILD_FROM}

RUN apk add --no-cache \
    ca-certificates \
    iptables \
    ip6tables \
    iproute2 \
    ethtool \
    jq \
    bash

COPY --from=tailscale-upstream /usr/local/bin/tailscale /usr/bin/tailscale
COPY --from=tailscale-upstream /usr/local/bin/tailscaled /usr/bin/tailscaled

COPY run.sh /
RUN chmod a+x /run.sh

# Kiểm tra sức khỏe đường truyền mỗi 60 giây cho Home Assistant Watchdog
HEALTHCHECK --interval=60s --timeout=10s --start-period=45s --retries=3 \
    CMD tailscale --socket=/var/run/tailscale/tailscaled.sock status --json | jq -e '.BackendState == "Running" or .BackendState == "NeedsLogin"' >/dev/null || exit 1

CMD [ "/run.sh" ]
