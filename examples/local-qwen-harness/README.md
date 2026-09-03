# Local Qwen + SearXNG + DeepSeek Harness

This directory is the reproducible source of truth for the working RTX 5090
setup. It contains the pinned Qwen/SGLang runtime, private SearXNG service,
read-only MCP search adapter, Harness model/profile settings, and manual
management helper. Harness uses a pinned local Markdown renderer for Mermaid
diagrams. The custom model route explicitly declares text and image input; the
pinned checkpoint's vision path was verified through SGLang.

## Restore on a new installation

Prerequisites:

- NVIDIA driver working in `nvidia-smi`
- Docker Engine, Docker Compose v2, and NVIDIA Container Toolkit
- Node.js, pnpm, curl, sed, and OpenSSL
- a running systemd user manager (`systemctl --user`)

From this directory, run:

```bash
./bootstrap.sh
```

This installs dependencies, restores the Harness files under `~/.dsh`, pulls
the pinned images, creates the model-cache volume, and installs
`~/.local/bin/local-ai`. It does **not** start anything or enable autostart.
Existing Harness files that differ are retained as `*.before-local-ai`.

## Service commands

```bash
local-ai start                   # all three
local-ai start qwen harness      # any additive subset
local-ai status
local-ai logs
local-ai stop qwen               # release VRAM only
local-ai start qwen              # reload the model only
local-ai stop                    # all three
```

The valid targets are `qwen`, `harness`, and `searxng`; list one or several in
any order. With no targets, `start` and `stop` operate on all three. Harness
runs as a transient user-systemd service, and `local-ai logs` reads its journal.
The transient unit provides reliable process-tree cleanup without installing or
enabling a boot service. Nothing starts at boot, and both Docker services use
`restart: "no"`.

`local-ai stop qwen` releases its CUDA allocation while leaving Harness and
SearXNG alone. `model-start` and `model-stop` remain as compatibility aliases.

The SearXNG browser interface is available at
`http://127.0.0.1:8888`.

## Adapter

The MCP adapter is started by Harness over stdio. It exposes two read-only
tools:

- `mcp__searxng__web_search` queries the local SearXNG JSON API.
- `mcp__searxng__fetch_page` captures size-limited plain text from a public
  HTTP(S) page so the agent can verify a search result before citing it.

The page tool blocks credentials, private/local networks, nonstandard ports,
binary content, redirect abuse, oversized bodies, and slow responses. DNS is
validated and pinned for each request, and HTML is never executed.
The default `local-standard` agent preset mirrors Harness's pinned Standard
mode with its native `web_search` and `web_fetch` schemas disabled, so the
model is offered only the working SearXNG tools.

Harness renders fenced `mermaid` blocks through
`dsh-better-markdown@0.1.2`. Mermaid is bundled with the plugin, so diagram
rendering does not depend on a CDN. After restoring or changing the plugin,
reload the Harness page once.

See `qwen.compose.yaml` for every inference parameter and `VERSIONS.md` for
the captured image/model revisions. The model cache itself is large and is
not part of this bundle; a fresh machine downloads it into the Docker volume.
