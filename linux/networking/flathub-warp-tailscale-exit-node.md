# Fixing pathological Flathub downloads with a WARP-backed Tailscale exit node

This is a field report and a reusable container recipe for a problem that looked
like poor Internet performance, but was actually a bad route to Flathub's CDN.

The end result is a lightweight Docker container that combines:

- a Cloudflare WARP WireGuard tunnel;
- a Tailscale exit node reachable from laptops and desktops; and
- an optional general-purpose HTTP/HTTPS proxy for routing only selected tools
  (including a system Flatpak remote) through WARP.

It was built for Unraid, but uses ordinary Docker, Linux policy routing,
WireGuard, iptables, Tailscale, and Tinyproxy.

> **Important:** Never publish your WARP WireGuard profile, private key, or
> Tailscale state. Generate your own profile and keep it mode `0600`.

## What the diagnosis showed

A browser speed test was fast, but package downloads were not. Direct tests
showed very different results over the same Internet connection:

| Target/workload | Observed result before WARP |
| --- | ---: |
| Flathub summary, direct ISP path | about 87 KB/s |
| CachyOS CDN, direct ISP path | about 3.6 MB/s |
| Flathub through one VPN region | about 184 KB/s |
| CachyOS CDN through that same VPN region | about 23 MB/s |
| Flathub across 16 other VPN nodes | mostly 19-128 KB/s |

That combination ruled out a simple LAN, disk, CPU, or general ISP-capacity
problem. The failing dimension was the path to Flathub/Fastly.

Useful isolated tests:

```bash
curl -4 -L -o /dev/null --max-time 30 \
  -w 'Flathub: %{speed_download} B/s\n' \
  'https://dl.flathub.org/repo/summary?test=1'

curl -4 -L -o /dev/null --max-time 30 \
  --range 0-67108863 \
  -w 'CDN: %{speed_download} B/s\n' \
  'https://cdn77.cachyos.org/'
```

The second URL is only a path-control example; substitute a current large file
when benchmarking.

## Results after routing through WARP

Representative cold-cache results from the finished gateway:

| Workload | Result |
| --- | ---: |
| Flathub summary | 32.2 MB/s |
| Obsidian Flatpak pull | 230.3 MB in 4 seconds |
| Freedesktop SDK pull | 606.7 MB in 9 seconds |
| Sustained 20 MB/s transfer | about 0.8% container CPU, 59 MiB RAM |

These are observations from one network at one point in time, not guaranteed
service benchmarks.

## Architecture

```text
Tailscale client
      |
      v
  tailscale0
      |
      +---- LAN and tailnet destinations ----> normal route
      |
      +---- public Internet -----------------> wg-warp ----> WARP

Tinyproxy process -- packet mark -----------> wg-warp ----> WARP
Tailscale transport ------------------------> normal route
```

Keeping Tailscale's own transport on the normal route avoids nesting Tailscale
inside WARP. Only exit-node traffic and Tinyproxy's process traffic use the WARP
policy table.

## Prerequisites

- `/dev/net/tun` and kernel WireGuard support
- Docker capability `NET_ADMIN`
- IPv4 forwarding (and IPv6 forwarding if used)
- a persistent directory for Tailscale state
- a WARP WireGuard profile

[`wgcf`](https://github.com/ViRb3/wgcf) is an unofficial tool that can generate
a WARP WireGuard profile:

```bash
wgcf register
wgcf generate
install -m 600 wgcf-profile.conf /path/to/warp-exit/wg0.conf
```

Review the tool and Cloudflare's applicable terms before using it.

## Build and run

Put `Dockerfile`, `entrypoint.sh`, `healthcheck.sh`, and `tinyproxy.conf` in one
directory, then build:

```bash
docker build -t local/warp-exit:1 .
```

Example container creation:

```bash
docker run -d \
  --name WarpExit \
  --hostname warp-exit \
  --restart unless-stopped \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --dns 1.1.1.1 \
  -p '<NAS_LAN_IP>:28888:8888/tcp' \
  -e TS_HOSTNAME=warp-exit \
  -e TS_STATE_DIR=/var/lib/tailscale \
  -e LAN_CIDR='<YOUR_LAN_CIDR>' \
  -v '/path/to/tailscale-state:/var/lib/tailscale' \
  -v '/path/to/wg0.conf:/config/wg0.conf:ro' \
  --health-cmd /usr/local/bin/warp-exit-healthcheck \
  --health-interval 30s \
  --health-timeout 15s \
  --health-retries 3 \
  --health-start-period 20s \
  local/warp-exit:1
```

On first start, inspect the logs and follow the Tailscale authentication URL:

```bash
docker logs -f WarpExit
```

Then approve the advertised exit node in the Tailscale admin console. Tailscale
requires both advertising and administrative approval before clients may select
an exit node. See the official [exit-node
documentation](https://tailscale.com/docs/features/exit-nodes).

## Client use

Route all client traffic through the WARP exit node:

```bash
tailscale set --exit-node=warp-exit --exit-node-allow-lan-access=true
```

Stop using it:

```bash
tailscale set --exit-node=
```

The optional proxy is available at:

```text
http://<WARP_EXIT_TAILSCALE_IP>:8888
http://<NAS_LAN_IP>:28888
```

Do not expose Tinyproxy on an Internet-facing address. Restrict it with your
tailnet ACLs and host firewall.

## Persistent Flatpak routing for Bazaar, Discover, and the CLI

An OSTree remote can store its own proxy setting, so graphical Flatpak managers
work without a wrapper script:

```bash
sudo ostree --repo=/var/lib/flatpak/repo \
  config set --group='remote "flathub"' \
  proxy 'http://<WARP_EXIT_TAILSCALE_IP>:8888'
```

Inspect the setting:

```bash
ostree --repo=/var/lib/flatpak/repo \
  config get --group='remote "flathub"' proxy
```

The included `flatpak-cold-cache-test.sh` performs a real isolated OSTree pull,
uses `--no-deploy`, and deletes its temporary repository afterward.

## Subtle routing bugs worth checking

1. **Do not send tailnet return destinations to the normal main table.** The
   main table contains a default route, so replies can leak out the Docker
   interface instead of returning through `tailscale0`. Route
   `100.64.0.0/10` and `fd7a:115c:a1e0::/48` through Tailscale's table `52`.
2. **Exempt the WARP peer endpoint from the WARP policy table.** Otherwise the
   outer WireGuard packets recursively try to enter their own tunnel.
3. **Put WARP masquerading before Tailscale's `ts-postrouting` jump.** Tailscale
   installs its chains after startup, so the entrypoint reorders this once
   `tailscale0` is ready.
4. **Account for MTU.** WARP profiles commonly start at 1280. Validate rather
   than assuming a larger MTU is safe.
5. **Test the application protocol, not only a speed-test site.** A fast nearby
   speed-test server says little about a specific CDN route.

## Scope and limitations

- WARP changes routing; it does not repair the original ISP/CDN peering path.
- A route that helps Flathub might be slower for a CDN already well peered with
  the ISP.
- Domain-aware selective routing requires a DNS-to-IP-set design and is not
  included here.
- This is not a substitute for a torrent VPN that provides inbound port
  forwarding.
- The profile generator is unofficial; this recipe is not affiliated with or
  endorsed by Cloudflare, Tailscale, Flathub, or Unraid.

## References

- [Tailscale exit nodes](https://tailscale.com/docs/features/exit-nodes)
- [Tailscale Docker configuration](https://tailscale.com/docs/features/containers/docker/docker-params)
- [wgcf](https://github.com/ViRb3/wgcf)
