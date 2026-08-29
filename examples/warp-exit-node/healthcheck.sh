#!/bin/sh
set -eu

wg show wg-warp latest-handshakes |
  awk '$2 > 0 { found=1 } END { exit !found }'

tailscale status --peers=false >/dev/null

curl --fail --silent --show-error \
  --proxy http://127.0.0.1:8888 \
  --max-time 10 \
  https://www.cloudflare.com/cdn-cgi/trace |
  grep -qx 'warp=on'
