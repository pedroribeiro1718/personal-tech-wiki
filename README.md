# Personal Technical Wiki

A living collection of Linux notes, networking investigations, homelab designs,
troubleshooting records, benchmarks, and reproducible technical solutions.

The emphasis is on evidence: isolate variables, record the failed approaches,
explain the final design, and keep reusable commands or code beside the article.

## Linux

### AI

- [Qwen3.8 27B on one RTX 5090 with local web
  search](linux/ai/local-qwen-rtx-5090.md)

### Desktop

- [Install the patched Wallpaper Engine KDE plugin on
  CachyOS](linux/desktop/cachyos-wallpaper-engine-kde-patched.md)
- [PlasmaZones on KDE: Omarchy tiling and FancyZones
  snapping](linux/desktop/cachyos-kde-plasmazones-omarchy.md)

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
- [`examples/plasmazones/omarchy-on-kde-profile.json`](examples/plasmazones/omarchy-on-kde-profile.json)
  — an importable two-mode profile with automatic tiling, fixed-zone snapping,
  keyboard navigation, and a mixed-DPI-safe Steam exception.
- [`examples/plasmazones/plasmazones-mode-toggle`](examples/plasmazones/plasmazones-mode-toggle)
  — an all-monitor, two-state switch between Omarchy auto-tiling and
  FancyZones snapping, with a matching KDE desktop action.
- [`examples/local-qwen-harness/`](examples/local-qwen-harness/) — pinned
  Docker, Harness, SearXNG, and MCP configuration with a manual bootstrap and
  GPU unload helper.

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
