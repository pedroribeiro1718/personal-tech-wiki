# Local Qwen + SearXNG + DeepSeek Harness

This directory is the reproducible source of truth for the working RTX 5090
setup. It contains the pinned Qwen/SGLang runtime, private SearXNG service,
read-only MCP search adapter, Harness model/profile settings, and manual
management helper. Harness uses a pinned local Markdown renderer for Mermaid
diagrams. The custom model route explicitly declares text and image input; the
pinned checkpoint's vision path was verified through SGLang.

An optional `qwen-full` recipe adds the model's native 262,144-token window.
It uses the measured EXL3 K5/K6 context build, FP8 KV, MTP-3, and the BF16
vision tower through a digest-pinned Gilded Gnosis/vLLM image. It does not
replace or alter the default 122,880-token SGLang service.

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
local-ai prepare qwen-full       # fetch the optional pinned runtime image
local-ai start qwen-full harness # use the alternate model instead of qwen
./test-full-context.mjs          # direct 250K-token retrieval test
local-ai status
local-ai logs
local-ai stop qwen               # release VRAM only
local-ai start qwen              # reload the model only
local-ai stop                    # all three
```

The valid targets are `qwen`, `qwen-full`, `harness`, and `searxng`; list one
or several in any order. With no targets, `start` starts the original `qwen`,
Harness, and SearXNG. `stop` also stops `qwen-full` if it exists. Harness
runs as a transient user-systemd service, and `local-ai logs` reads its journal.
The transient unit provides reliable process-tree cleanup without installing or
enabling a boot service. Nothing starts at boot, and both Docker services use
`restart: "no"`.

`local-ai stop qwen` releases its CUDA allocation while leaving Harness and
SearXNG alone. `model-start` and `model-stop` remain as compatibility aliases.
The two model targets are mutually exclusive on the single GPU. Select
`qwen3.8-27b-full` in Harness after starting `qwen-full`.

## Optional native 262K profile

Prepare once, then start it when needed:

```bash
local-ai prepare qwen-full
local-ai stop qwen
local-ai start qwen-full harness
```

Preparation downloads and verifies four pinned runtime overlays and pulls the
pinned image; it starts nothing. The first start downloads the pinned 20.7 GB
model snapshot into a separate Docker volume. The service binds only to
`http://127.0.0.1:30001/v1` and keeps the normal service at port 30000 intact.

The profile is deliberately single-user: 262,144 context, FP8 KV, MTP-3,
`max-num-seqs=1`, and an 8.4-megapixel vision ceiling. Prefix caching is off
because the measured full-window-plus-vision profile does not have enough
headroom for it. `gpu-memory-utilization=0.955` was qualified on one physical
RTX 5090; if startup misses by a few MiB on this card, change it to `0.956` in
`qwen-full.compose.yaml` and record that change here.

Because vLLM must reserve 95.5% of the card, `local-ai` checks free VRAM and
refuses to start this target unless that budget is available. On a KDE desktop,
close GPU applications and stop the graphical session if necessary. This guard
avoids turning an expected startup refusal into another driver-level VRAM OOM.

Run the direct long-context smoke test only after the endpoint is ready:

```bash
./test-full-context.mjs          # targets about 250,000 prompt-content tokens
./test-full-context.mjs 200000   # quicker, smaller run
```

It plants codes near the start, middle, and end, sizes the prompt with the
server tokenizer, and requires exact retrieval. This proves that the long
window is usable; it is not a general long-context reasoning benchmark.

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

See `qwen.compose.yaml` and `qwen-full.compose.yaml` for every inference
parameter, and `VERSIONS.md` for captured image/model revisions. Model caches
are large and are not part of this bundle; a fresh machine downloads them into
Docker volumes.
