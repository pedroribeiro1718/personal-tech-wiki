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
- an optional isolated work Harness with safe public search and read-only GitHub

There is also an optional native-262K profile. It uses a measured EXL3 K5/K6
context build with FP8 KV, MTP-3, vision, reasoning, and tool parsing. It is a
separate recipe and does not change the working SGLang default.

A third, experimental NInfer profile trades 3.5% of the native window for a
252,928-token text route with INT8 KV and MTP-3. It is also separate and keeps
the first two recipes intact. All recipes use `http://127.0.0.1:30000/v1` and
only one may run at a time.

The complete, secret-free files are in
[`examples/local-qwen-harness/`](../../examples/local-qwen-harness/).

## Restore on a new Linux installation

Install and verify:

1. A current NVIDIA driver (`nvidia-smi` must show the GPU).
2. Docker Engine and Docker Compose v2.
3. NVIDIA Container Toolkit configured for Docker.
4. Git, GitHub CLI, Node.js 20 or newer, pnpm, curl, sed, OpenSSL, and `sha256sum`.
5. A running systemd user manager (`systemctl --user`).

Then:

```bash
git clone https://github.com/pedroribeiro1718/personal-tech-wiki.git
cd personal-tech-wiki/examples/local-qwen-harness
./bootstrap.sh
```

The bootstrap script restores the personal and work Harness profiles under
`~/.dsh` and `~/.dsh-work`, installs
the JavaScript dependencies, pulls the pinned container images, creates the
Hugging Face cache volume, and installs `~/.local/bin/local-ai`. It starts
nothing and enables no boot service. If pnpm asks which trusted Harness
packages may run build scripts, select the required packages and continue.

Model weights are intentionally not stored in Git. The default and EXL3 model
snapshots download into Docker volumes; NInfer's artifact downloads during its
explicit `prepare` command.

## Everyday use

```bash
# Start all three components
local-ai start

# Or start/stop any additive subset, in any order
local-ai start qwen harness
local-ai stop harness searxng

# Optional full native context; use the EXL3 recipe
local-ai prepare exl3
local-ai stop qwen
local-ai start --recipe exl3 qwen harness

# Experimental NInfer 252,928-token text profile
local-ai prepare ninfer
local-ai stop qwen
local-ai start --recipe ninfer qwen harness

# Leave room for KDE and an accelerated browser
local-ai stop qwen
local-ai start --recipe ninfer --desktop-use qwen harness

# Inspect Harness, container, and GPU status
local-ai status

# Compare the available model recipes
local-ai recipes

# Open the interactive services, logs, and GPU dashboard
local-ai dashboard

# Inspect recent Harness output
local-ai logs

# Or inspect one component directly
local-ai logs qwen

# Release VRAM without touching Harness or SearXNG
local-ai stop qwen

# Load it again
local-ai start qwen

# Stop Harness, Qwen, and SearXNG
local-ai stop
```

For a company repository, authenticate and explicitly start the isolated work
Harness from that checkout:

```bash
local-ai github-login
local-ai github-status
cd /path/to/company/repository
local-ai start --recipe exl3 qwen harness-work searxng
# Open http://127.0.0.1:3081
```

The work instance uses `~/.dsh-work`, keeps the personal Harness on port 3080
untouched, and stores its GitHub CLI login separately under
`$XDG_CONFIG_HOME/gh-work` (or `~/.config/gh-work`). It uses the
[official GitHub MCP server](https://github.com/github/github-mcp-server) with
`context,repos,issues,pull_requests` only, forced read-only and lockdown modes.
Company SSO may require separate authorization. No credential is stored in the
wiki.

The work profile still has general SearXNG web search and restricted public-page
snapshots. Never place proprietary code, credentials, internal URLs, company
issue text, or logs in a public search query; use local and GitHub tools for
company material. Stop or inspect it with `local-ai stop harness-work` and
`local-ai logs harness-work`.

Each Harness runs as a transient user-systemd service so its complete process
tree can be stopped reliably. It is created only by the manual command and is
not enabled at boot. Valid targets are `qwen`, `harness`, `harness-work`, and
`searxng`; Qwen's recipe values are `sglang` (default), `exl3`, and `ninfer`.
Omitting targets starts the selected recipe plus personal Harness and SearXNG.
The default `all` does not start the work Harness; it must be explicit.
`local-ai stop qwen` stops every recipe unless a specific `--recipe` is
supplied. Only one recipe can use the single GPU at a time. Harness neither
filters its static catalog by the loaded model nor reliably derives custom
limits from `/v1/models`. The
committed template retains all three definitions for recovery; every successful
`local-ai start ... qwen` replaces the live catalog and default with only the
active recipe and its actual normal/desktop capacity. `stop qwen` retains that
single last-used entry because Harness requires a default while the endpoint is
offline. Start a new Harness session after switching recipes; existing sessions
retain their original model selection.
Use `local-ai recipes` to print each canonical served ID, engine, weight/KV
formats, context limits, vision support, and speculative-decoding method.

`local-ai dashboard` provides Overview, Qwen log, both Harness logs, SearXNG log, and
GPU tabs using Python's standard-library terminal UI. Switch with `Tab` or
`1`–`6`; scroll with arrow/Page keys; use `f` to follow, `r` to refresh, and `q`
to quit. Keep `status` and `logs [qwen|harness|harness-work|searxng]` for
scripts and direct diagnostics.

The supported GPU-unload command is `local-ai stop qwen`; start the desired
recipe again to reload the cached model.

## Desktop-use mode

`--desktop-use` retains roughly 5 GiB of the card for the graphical session
when using EXL3 or NInfer. SGLang remains unchanged because its normal profile
was already qualified during ordinary desktop use:

| Recipe | Normal target context | Desktop-use context | Desktop adjustments | Approximate VRAM left outside the model |
| --- | ---: | ---: | --- | ---: |
| `sglang` | 122,880 | 122,880 | unchanged; already desktop-qualified | ~4.6 GiB |
| `exl3` | 262,144 | 155,648 | memory fraction 0.85; prefill 1,024; 4-Mpx images | 4.9 GiB |
| `ninfer` | 252,928 | 172,032 | fixed INT8 KV; concurrency 1; prefill 512 | 5.0 GiB |

The measured KDE plus lightly loaded Zen baseline was 3,185 MiB. EXL3 and
NInfer leave roughly another 1.3 GiB for normal browser growth, but cannot guarantee
headroom for video, WebGL/WebGPU, or games. A startup preflight refuses the
selected profile if current free VRAM is insufficient. Omitting the flag keeps
the original high-context settings unchanged.

EXL3 and NInfer complete local runtime/model preparation before the final VRAM
check so its result remains close to container launch. If a model container
exits before the API is ready, `local-ai` stops waiting immediately and prints
its last 40 log lines.

## Native 262K test profile

```bash
local-ai prepare exl3            # pinned overlays and image; starts nothing
local-ai stop qwen
local-ai start --recipe exl3 qwen harness # first start downloads the 20.7 GB snapshot
./test-full-context.mjs          # direct ~250K-token three-needle test
local-ai stop --recipe exl3 qwen # release VRAM
```

In Harness, select `Qwen 3.8 27B · vLLM · EXL3 K5/K6 · 262,144`. It is served at
`http://127.0.0.1:30000/v1` with a 262,144-token limit, FP8 KV, MTP-3,
single-request scheduling, and image input. Its dedicated cache volume is
`qwen38-full-hf-cache`.

Without `--desktop-use`, `local-ai` refuses to start unless at least 95.5% of
VRAM is free. Close GPU applications and, if necessary, stop the graphical session first.
This protects the driver from a repeat of the previous VRAM-exhaustion failure.

The measured starting point is `gpu-memory-utilization=0.955`. RTX 5090 cards
can differ by a few MiB; if startup says the KV allocation narrowly misses,
raise it to `0.956` in `qwen-vllm-exl3-k5k6-262144.compose.yaml`. Prefix caching stays disabled
because it does not fit alongside the native window and qualified vision
ceiling on 32 GB. The test proves capacity plus basic retrieval, not general
long-context reasoning.

## NInfer 252,928-token test profile

```bash
local-ai prepare ninfer             # pinned source build + verified 20.02-GiB artifact
local-ai stop qwen
local-ai start --recipe ninfer qwen harness

QWEN_TEST_MODEL=qwen3.8-27b-ninfer-nvfp4-252928 \
  ./test-full-context.mjs 245000

local-ai stop --recipe ninfer qwen # release VRAM
```

Select `Qwen 3.8 27B · NInfer · NVFP4 · 252,928` in Harness. The
OpenAI-compatible endpoint is
`http://127.0.0.1:30000/v1`. The profile uses 252,928 context, INT8 KV,
MTP-3, two-request scheduling, and prefix reuse. It supports reasoning and
tool calls; Harness remains responsible for executing the SearXNG tools.

This route is deliberately text-only. NInfer can enable Qwen vision, but its
qualified vision allocation reduces the available context to 81,920 tokens,
which defeats this recipe's purpose. The full-context startup guard requires
all but about 1,080 MiB of the 5090's VRAM to be free.

`prepare` starts nothing. It checks out the pinned NInfer commit, builds the
CUDA 13.1 container, downloads a resumable `.ninfer` artifact, and verifies
its exact size and SHA-256. The model and build caches are not committed.

## Important pinned settings

The authoritative command is
[`qwen-sglang-nvfp4-122880.compose.yaml`](../../examples/local-qwen-harness/qwen-sglang-nvfp4-122880.compose.yaml).
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

The SGLang/SearXNG image digests and Hugging Face/source revisions are pinned.
See [`VERSIONS.md`](../../examples/local-qwen-harness/VERSIONS.md) before
updating them.

## Vision and search notes

Harness does not reliably infer modalities or capacity from an
OpenAI-compatible `/v1/models` response. The custom route therefore declares
`input` and `contextWindow` in `bootstrap/harness/settings.yaml`. When switching
profiles, the helper atomically publishes only the active definition to the
live settings; Harness hot-reloads the file. This exact endpoint was verified with a PNG;
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
- All containers use `restart: "no"`; startup is always manual.
