# Qwen3.8 27B on one RTX 5090 with local web search

This is the tested local-agent setup:

- Qwen3.8 27B NVFP4 served by SGLang at `http://127.0.0.1:30000/v1`
- DFlash speculative decoding, FP8 KV cache, and 122,880-token configured context
- DeepSeek Harness as the browser UI and agent loop
- private SearXNG at `http://127.0.0.1:8888`
- a read-only MCP adapter for web search and public-page snapshots
- offline Mermaid rendering through pinned `dsh-better-markdown@0.1.2`
- working text, image, and function-tool input
- no DeepSeek API/search dependency and no automatic startup

There is also an optional native-262K profile. It uses a measured EXL3 K5/K6
context build with FP8 KV, MTP-3, vision, reasoning, and tool parsing. It is a
separate target and does not change the working SGLang default.

The complete, secret-free files are in
[`examples/local-qwen-harness/`](../../examples/local-qwen-harness/).

## Restore on a new Linux installation

Install and verify:

1. A current NVIDIA driver (`nvidia-smi` must show the GPU).
2. Docker Engine and Docker Compose v2.
3. NVIDIA Container Toolkit configured for Docker.
4. Node.js 20 or newer, pnpm, curl, sed, and OpenSSL.
5. A running systemd user manager (`systemctl --user`).

Then:

```bash
git clone https://github.com/pedroribeiro1718/personal-tech-wiki.git
cd personal-tech-wiki/examples/local-qwen-harness
./bootstrap.sh
```

The bootstrap script restores the Harness profile under `~/.dsh`, installs
the JavaScript dependencies, pulls the pinned container images, creates the
Hugging Face cache volume, and installs `~/.local/bin/local-ai`. It starts
nothing and enables no boot service. If pnpm asks which trusted Harness
packages may run build scripts, select the required packages and continue.

Model weights are intentionally not stored in Git. The first start downloads
the pinned main and draft snapshots into the Docker volume.

## Everyday use

```bash
# Start all three components
local-ai start

# Or start/stop any additive subset, in any order
local-ai start qwen harness
local-ai stop harness searxng

# Optional full native context; use instead of qwen
local-ai prepare qwen-full
local-ai stop qwen
local-ai start qwen-full harness

# Inspect Harness, container, and GPU status
local-ai status

# Inspect recent Harness output
local-ai logs

# Release VRAM without touching Harness or SearXNG
local-ai stop qwen

# Load it again
local-ai start qwen

# Stop Harness, Qwen, and SearXNG
local-ai stop
```

Harness runs as a transient user-systemd service so its complete process tree
can be stopped reliably. It is created only by the manual command and is not
enabled at boot. Valid targets are `qwen`, `qwen-full`, `harness`, and
`searxng`. Omitting targets starts the normal three-component stack; stopping
with no targets also stops the alternate model if it exists. The two model
targets cannot share the single GPU.

The direct GPU-unload command is `docker stop qwen38`. The next
`docker start qwen38` reloads the cached model.

## Native 262K test profile

```bash
local-ai prepare qwen-full       # pinned overlays and image; starts nothing
local-ai stop qwen
local-ai start qwen-full harness # first start downloads the 20.7 GB snapshot
./test-full-context.mjs          # direct ~250K-token three-needle test
local-ai stop qwen-full          # release VRAM
```

In Harness, select `qwen3.8-27b-full`. It is served at
`http://127.0.0.1:30001/v1` with a 262,144-token limit, FP8 KV, MTP-3,
single-request scheduling, and image input. Its dedicated cache volume is
`qwen38-full-hf-cache`.

`local-ai` refuses to start this target unless at least 95.5% of VRAM is free.
Close GPU applications and, if necessary, stop the graphical session first.
This protects the driver from a repeat of the previous VRAM-exhaustion failure.

The measured starting point is `gpu-memory-utilization=0.955`. RTX 5090 cards
can differ by a few MiB; if startup says the KV allocation narrowly misses,
raise it to `0.956` in `qwen-full.compose.yaml`. Prefix caching stays disabled
because it does not fit alongside the native window and qualified vision
ceiling on 32 GB. The test proves capacity plus basic retrieval, not general
long-context reasoning.

## Important pinned settings

The authoritative command is
[`qwen.compose.yaml`](../../examples/local-qwen-harness/qwen.compose.yaml).
Its main choices are:

- main model: `gittensor-model-hub/Qwen3.8-27B-NVFP4-RTX5090`
- draft model: `gittensor-model-hub/Qwen3.8-27B-DSpark-NVFP4`
- context: `122880`
- KV cache: `fp8_e4m3`
- memory fraction: `0.86`
- concurrent requests: `1`
- chunked prefill: `1024`
- attention backend: `flashinfer`
- reasoning parser: `qwen3`
- tool-call parser: `qwen3_coder`

The SGLang/SearXNG image digests and both Hugging Face revisions are pinned.
See [`VERSIONS.md`](../../examples/local-qwen-harness/VERSIONS.md) before
updating them.

## Vision and search notes

Harness does not infer modalities from an OpenAI-compatible `/v1/models`
response. The custom route therefore declares `input: [text, image]` in
`bootstrap/harness/settings.yaml`. This exact endpoint was verified with a PNG;
SGLang returned HTTP 200 and accounted for image tokens.

Search results come from the local SearXNG MCP tool. The companion `fetch_page`
tool captures size-limited plain text from important results before they are
cited. It rejects credentials, local/private networks, nonstandard ports,
binary content, redirect abuse, oversized bodies, and slow responses; it pins
validated DNS for each request and never executes HTML.
The default `local-standard` preset mirrors the pinned Standard mode with its
native `web_search` and `web_fetch` schemas disabled, so the model sees only
the working SearXNG alternatives.

Harness renders fenced `mermaid` blocks through the pinned
`dsh-better-markdown` plugin. Its Mermaid runtime is bundled locally rather
than fetched from a CDN. If the plugin was just installed or restored, reload
the Harness page once.

## Security and backup

- Services bind only to loopback.
- DeepSeek's native search provider is disabled.
- `.env`, model weights, dependencies, credentials, and runtime state are not
  committed.
- `bootstrap.sh` generates a fresh SearXNG secret and reinstalls dependencies.
- Both containers use `restart: "no"`; startup is always manual.
