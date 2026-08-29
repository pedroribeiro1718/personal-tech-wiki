FROM tailscale/tailscale:stable

RUN apk add --no-cache \
      ca-certificates \
      curl \
      iproute2 \
      iptables \
      tinyproxy \
      wireguard-tools

COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
COPY entrypoint.sh /usr/local/bin/warp-exit-entrypoint
COPY healthcheck.sh /usr/local/bin/warp-exit-healthcheck

RUN chmod 0755 \
      /usr/local/bin/warp-exit-entrypoint \
      /usr/local/bin/warp-exit-healthcheck

ENTRYPOINT ["/usr/local/bin/warp-exit-entrypoint"]
