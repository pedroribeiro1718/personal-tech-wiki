#!/bin/sh
set -eu

warp_source=${WARP_CONFIG:-/config/wg0.conf}
warp_runtime=/tmp/wg-warp.conf
warp_table=${WARP_TABLE:-51820}
proxy_mark=${PROXY_MARK:-0x77}
lan_cidr=${LAN_CIDR:?Set LAN_CIDR to the LAN subnet reachable from the host}
tailnet_v4=100.64.0.0/10
tailnet_v6=fd7a:115c:a1e0::/48
tailscaled_pid=
tailscale_up_pid=
tinyproxy_pid=

cleanup() {
    trap - INT TERM EXIT
    test -z "$tinyproxy_pid" || kill "$tinyproxy_pid" 2>/dev/null || true
    test -z "$tailscale_up_pid" || kill "$tailscale_up_pid" 2>/dev/null || true
    test -z "$tailscaled_pid" || kill "$tailscaled_pid" 2>/dev/null || true
    wg-quick down "$warp_runtime" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

if ! test -r "$warp_source"; then
    echo "WARP configuration is missing: $warp_source" >&2
    exit 1
fi

# Keep wg-quick from replacing the container's default route.
cp "$warp_source" "$warp_runtime"
sed -i '/^[[:space:]]*DNS[[:space:]]*=/d; /^[[:space:]]*Table[[:space:]]*=/d' "$warp_runtime"
sed -i '/^[[:space:]]*\[Peer\][[:space:]]*$/i Table = off' "$warp_runtime"
chmod 0600 "$warp_runtime"

wg-quick up "$warp_runtime"
ip route replace table "$warp_table" default dev wg-warp
ip -6 route replace table "$warp_table" default dev wg-warp

docker_subnet=$(ip -4 route show dev eth0 scope link | awk 'NR == 1 { print $1 }')
proxy_uid=$(id -u tinyproxy)
warp_endpoint_value=$(sed -n 's/^[[:space:]]*Endpoint[[:space:]]*=[[:space:]]*//p' "$warp_runtime" | head -n 1)
warp_endpoint=${warp_endpoint_value%:*}

# Lower numeric priorities win. Keep tunnel control traffic, LAN traffic, and
# tailnet traffic out of the WARP policy table.
ip rule add priority 790 to "$warp_endpoint"/32 lookup main
ip rule add priority 800 to "$docker_subnet" lookup main
ip rule add priority 810 to "$lan_cidr" lookup main
ip rule add priority 820 to "$tailnet_v4" lookup 52
ip rule add priority 900 fwmark "$proxy_mark" lookup "$warp_table"

ip -6 rule add priority 810 to "$tailnet_v6" lookup 52
ip -6 rule add priority 900 fwmark "$proxy_mark" lookup "$warp_table"

# Mark only Tinyproxy's locally generated traffic for WARP.
iptables -t mangle -I OUTPUT 1 \
  -m owner --uid-owner "$proxy_uid" -j MARK --set-mark "$proxy_mark"
ip6tables -t mangle -I OUTPUT 1 \
  -m owner --uid-owner "$proxy_uid" -j MARK --set-mark "$proxy_mark"

# This initial rule is moved back to the front after Tailscale creates its own
# postrouting chain.
iptables -t nat -I POSTROUTING 1 -o wg-warp -j MASQUERADE
ip6tables -t nat -I POSTROUTING 1 -o wg-warp -j MASQUERADE

tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf &
tinyproxy_pid=$!

tailscaled \
    --state="${TS_STATE_DIR:-/var/lib/tailscale}/tailscaled.state" \
    --socket=/var/run/tailscale/tailscaled.sock &
tailscaled_pid=$!

for second in $(seq 1 30); do
    test -S /var/run/tailscale/tailscaled.sock && break
    kill -0 "$tailscaled_pid" 2>/dev/null || wait "$tailscaled_pid"
    sleep 1
done

# Without an auth key, the first attempt prints an interactive authentication
# URL to the container logs. Persistent state prevents re-authentication later.
(
    while ! tailscale up \
        --hostname="${TS_HOSTNAME:-warp-exit}" \
        --advertise-exit-node \
        --accept-dns=false; do
        sleep 10
    done
) &
tailscale_up_pid=$!

(
    while ! ip link show tailscale0 >/dev/null 2>&1 || \
          ! iptables -t nat -S ts-postrouting >/dev/null 2>&1; do
        sleep 1
    done

    # Public traffic arriving from Tailscale uses WARP. LAN destinations remain
    # local, and tailnet return traffic uses Tailscale's table 52.
    ip rule add priority 830 iif tailscale0 to "$lan_cidr" lookup main
    ip rule add priority 840 iif tailscale0 to "$tailnet_v4" lookup 52
    ip rule add priority 1000 iif tailscale0 lookup "$warp_table"

    ip -6 rule add priority 840 iif tailscale0 to "$tailnet_v6" lookup 52
    ip -6 rule add priority 1000 iif tailscale0 lookup "$warp_table"

    iptables -I FORWARD 1 -i tailscale0 -o wg-warp -j ACCEPT
    iptables -I FORWARD 1 -i wg-warp -o tailscale0 \
      -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ip6tables -I FORWARD 1 -i tailscale0 -o wg-warp -j ACCEPT
    ip6tables -I FORWARD 1 -i wg-warp -o tailscale0 \
      -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

    # Tailscale inserts its jump at position 1 after startup. WARP SNAT must be
    # first so exit traffic reaches WireGuard with the WARP interface address.
    iptables -t nat -D POSTROUTING -o wg-warp -j MASQUERADE 2>/dev/null || true
    iptables -t nat -I POSTROUTING 1 -o wg-warp -j MASQUERADE
    ip6tables -t nat -D POSTROUTING -o wg-warp -j MASQUERADE 2>/dev/null || true
    ip6tables -t nat -I POSTROUTING 1 -o wg-warp -j MASQUERADE
) &

wait "$tailscaled_pid"
