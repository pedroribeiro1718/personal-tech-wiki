# Local Qwen + SearXNG + DeepSeek Harness

This directory is the reproducible source of truth for the working RTX 5090
setup. It contains the pinned Qwen/SGLang runtime, private SearXNG service,
read-only MCP search adapter, Harness model/profile settings, and manual
management helper. The custom model route explicitly declares text and image
input; the pinned checkpoint's vision path was verified through SGLang.

## Restore on a new installation

Prerequisites:

- NVIDIA driver working in `nvidia-smi`
- Docker Engine, Docker Compose v2, and NVIDIA Container Toolkit
- Node.js, pnpm, curl, sed, and OpenSSL

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
local-ai start
local-ai status
local-ai model-stop
local-ai model-start
local-ai stop
```

`local-ai start` launches SearXNG and Qwen, waits for the model endpoint, then
runs the Harness UI in the foreground. Keep that terminal open and use Ctrl+C
to stop the UI. Both Docker services use `restart: "no"`.

`local-ai model-stop` stops only Qwen and releases its CUDA allocation.
SearXNG may remain available. `local-ai model-start` loads Qwen again.

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

See `qwen.compose.yaml` for every inference parameter and `VERSIONS.md` for
the captured image/model revisions. The model cache itself is large and is
not part of this bundle; a fresh machine downloads it into the Docker volume.
