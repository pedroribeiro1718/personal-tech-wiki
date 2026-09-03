# Qwen3.8 27B on one RTX 5090 with local web search

This is the tested local-agent setup:

- Qwen3.8 27B NVFP4 served by SGLang at `http://127.0.0.1:30000/v1`
- DFlash speculative decoding, FP8 KV cache, and 122,880-token configured context
- DeepSeek Harness as the browser UI and agent loop
- private SearXNG at `http://127.0.0.1:8888`
- a read-only MCP adapter for web search and public-page snapshots
- working text, image, and function-tool input
- no DeepSeek API/search dependency and no automatic startup

The complete, secret-free files are in
[`examples/local-qwen-harness/`](../../examples/local-qwen-harness/).

## Restore on a new Linux installation

Install and verify:

1. A current NVIDIA driver (`nvidia-smi` must show the GPU).
2. Docker Engine and Docker Compose v2.
3. NVIDIA Container Toolkit configured for Docker.
4. Node.js 20 or newer, pnpm, curl, sed, and OpenSSL.

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
# Start SearXNG + Qwen, wait for Qwen, then run Harness in this terminal
local-ai start

# Inspect container and GPU usage
local-ai status

# Release the model's VRAM without deleting its cache or configuration
local-ai model-stop

# Load it again
local-ai model-start

# Stop Qwen and SearXNG; use Ctrl+C for Harness
local-ai stop
```

The direct GPU-unload command is `docker stop qwen38`. The next
`docker start qwen38` reloads the cached model.

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

## Security and backup

- Services bind only to loopback.
- DeepSeek's native search provider is disabled.
- `.env`, model weights, dependencies, credentials, and runtime state are not
  committed.
- `bootstrap.sh` generates a fresh SearXNG secret and reinstalls dependencies.
- Both containers use `restart: "no"`; startup is always manual.
