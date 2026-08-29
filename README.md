# Personal Technical Wiki

A living collection of Linux notes, networking investigations, homelab designs,
troubleshooting records, benchmarks, and reproducible technical solutions.

The emphasis is on evidence: isolate variables, record the failed approaches,
explain the final design, and keep reusable commands or code beside the article.

## Linux

### Networking

- [Fixing pathological Flathub downloads with a WARP-backed Tailscale exit
  node](linux/networking/flathub-warp-tailscale-exit-node.md)

## Reusable examples

- [`examples/warp-exit-node/`](examples/warp-exit-node/) — a lightweight Docker
  container combining a WARP WireGuard tunnel, a Tailscale exit node, policy
  routing, and an optional HTTP/HTTPS proxy.
- [`scripts/flatpak-cold-cache-test.sh`](scripts/flatpak-cold-cache-test.sh) — an
  isolated real-world Flatpak/OSTree download test that does not deploy the
  downloaded runtime.

## Intended future topics

- Linux desktop and system administration
- Networking, VPNs, DNS, routing, and performance diagnostics
- Unraid and homelab infrastructure
- Containers and self-hosted services
- Hardware, media, and other technical experiments

## Repository hygiene

- Never commit VPN keys, authentication tokens, private profiles, or state
  databases.
- Replace public, LAN, and tailnet addresses with documented placeholders.
- Prefer commands that are safe to rerun and explain destructive operations.
- Label observations as observations rather than universal benchmarks.

