ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.20
ARG TAILSCALE_VERSION=v1.104.1

FROM tailscale/tailscale:${TAILSCALE_VERSION} AS tailscale-upstream

FROM ${BUILD_FROM}

# Cài đặt gói mạng lõi + ethtool để tự động tối ưu tốc độ UDP GRO trên Pi 5
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

CMD [ "/run.sh" ]
