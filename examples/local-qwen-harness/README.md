# Local Qwen stack for one RTX 5090

Reproducible, manually started local-agent stack:

- one OpenAI-compatible Qwen server at `http://127.0.0.1:30000/v1`
- DeepSeek Harness at `http://127.0.0.1:3080`
- isolated work Harness at `http://127.0.0.1:3081`
- private SearXNG at `http://127.0.0.1:8888`
- native Harness search, restricted public-page fetch, Mermaid, and optional
  read-only GitHub integration

Nothing is enabled at boot. Only one model recipe runs at a time.

## Recover on another Linux installation

Install a working NVIDIA driver, Docker Engine/Compose v2, NVIDIA Container
Toolkit, Git, GitHub CLI, Node.js, pnpm, curl, sed, OpenSSL, and `sha256sum`.
`nvidia-smi`, `docker compose version`, and `systemctl --user` must work.

```bash
git clone https://github.com/pedroribeiro1718/personal-tech-wiki.git
cd personal-tech-wiki/examples/local-qwen-harness
./bootstrap.sh
```

Bootstrap restores `~/.dsh` and `~/.dsh-work`, installs pinned Harness
plugins, pulls/builds pinned runtimes, and links `~/.local/bin/local-ai`. It
does not start services or enable autostart. Model weights remain in local
caches and are downloaded separately.

## Everyday commands

```bash
local-ai recipes
local-ai start                                      # default SGLang stack
local-ai start --recipe a3b --desktop-use           # all targets, A3B
local-ai start --recipe udq4 --desktop-use qwen harness
local-ai stop qwen                                  # release GPU memory
local-ai stop harness searxng                       # additive targets
local-ai dashboard                                  # status/log/GPU TUI
local-ai logs qwen                                  # also harness or searxng
local-ai test                                       # syntax, pins, Compose, budgets
```

Targets are `qwen`, `harness`, and `searxng`; omit them for all three. Start a
new Harness session after switching recipes. The live Harness catalog contains
only the last started model and its actual context limit. Harness requires a
default model entry, so that one entry remains visible while its endpoint is
stopped.

## Recipes

| Name | Engine / weights | KV | Normal context | Desktop context | Vision | Reasoning | Draft |
| --- | --- | --- | ---: | ---: | --- | --- | --- |
| `sglang` | SGLang / NVFP4 | FP8 | 122,880 | 122,880 | yes | four levels | DSpark-7 |
| `exl3` | vLLM / EXL3 K5/K6 | FP8 | 262,144 | 155,648 | yes | four levels | MTP-3 |
| `ninfer` | NInfer / NVFP4 | INT8 | 252,928 | 172,032 | no | four levels | MTP-3 |
| `udq4` | llama.cpp / Unsloth UD-Q4_K_XL | Q8_0 | 262,144 | 196,608 | yes | four levels | MTP-3 |
| `a3b` | NInfer / Qwen3.6 35B-A3B groupwise-int | INT8 | 262,144 | 245,760 | yes | default only | MTP-3 |

Use `local-ai prepare NAME` to fetch/build a recipe without starting it.
Preparation is resumable and verifies pinned artifact sizes and SHA-256 hashes.

The two newest profiles were acceptance-tested on this machine:

- `udq4 --desktop-use`: 30,091 MiB used, 2,058 MiB free at 196,608.
- `udq4` full: 31,384 MiB used, 765 MiB free at 262,144.
- `a3b --desktop-use`: 27,553 MiB used, 4,595 MiB free at 245,760.
- `a3b` full: 27,686 MiB used, 4,463 MiB free at 262,144.

Those are snapshots, not guarantees: KDE, browsers, video, WebGL/WebGPU, and
games change available VRAM. The startup guard checks current free memory and
refuses unsafe launches. `sglang` was already qualified for normal desktop use,
so `--desktop-use` deliberately leaves it unchanged.

The full `udq4` profile keeps the language model, Q8 KV, and MTP on GPU but
places its 888-MiB BF16 vision projector in system RAM. This preserves text
precision and throughput while making 262K fit, but large-image preprocessing
can be very slow. Its 196K desktop profile keeps that projector on GPU and is
the practical multimodal setting. The full `a3b` profile retains GPU vision
with materially better headroom.

Canonical served IDs include model, engine, quantization, and normal context;
`local-ai recipes` prints them. Compose files contain every inference flag and
[`VERSIONS.md`](VERSIONS.md) records immutable sources.

## Reasoning levels

Qwen 3.8 recipes expose `Off`, `Low`, `Medium`, and `Xhigh` in Harness's model
menu. NInfer receives its native `reasoning_effort`; SGLang, vLLM, and
llama.cpp receive the equivalent Qwen chat-template arguments. `Xhigh` is the
Qwen 3.8 default. The selected level is saved by Harness for later sessions.

The Qwen3.6 35B-A3B artifact can reason by default, but its embedded template
rejects graded levels. Its recipe therefore does not advertise a broken level
picker. Starting it also clears any saved Qwen 3.8 level from the Harness
default. Start a fresh session after switching recipes, and choose the desired
level before its first message.

## Harness tools

Ready-made integrations are used before custom code:

- [`dsh-searxng`](https://github.com/rogerdigital/dsh-searxng) supplies the
  native `web_search` provider against local SearXNG.
- [`@j0hanz/fetch-url-mcp`](https://github.com/j0hanz/fetch-url-mcp) supplies
  read-only `mcp__fetch__fetch-url`, with DNS/IP/redirect checks and no
  JavaScript execution.
- `dsh-better-markdown` renders Mermaid locally.
- the work profile launches GitHub's official MCP server in read-only,
  lockdown mode.

The old custom search/fetch adapter was removed. The generic Harness `web`
plugin may still expose a `web_search` schema, but `dsh-searxng` is its
registered provider; `web-search-deepseek` stays disabled.

For company work:

```bash
local-ai github-login
local-ai github-status
cd /path/to/repository
local-ai start --work --recipe a3b --desktop-use qwen harness searxng
# open http://127.0.0.1:3081 and select that repository as the workspace
```

The work instance has separate state and GitHub credentials. Its official
GitHub MCP exposes only `context,repos,issues,pull_requests`, with writes and
remote command execution disabled. General web search remains available, but
never send proprietary code, internal URLs, credentials, issue text, or logs
to a public search engine.

## Operations and maintenance

Harness runs as transient user-systemd services; Docker services use
`restart: "no"`. `local-ai stop qwen` sends Docker SIGTERM with a 60-second
grace period. Some backends print cancellation/NCCL cleanup traces during an
otherwise successful stop; confirm with `local-ai status` and `nvidia-smi`.

The dashboard is dependency-free. Use `Tab` or `1`–`6` for tabs, arrows/Page
keys to scroll, `f` to follow, `r` to refresh, and `q` to quit.

Maintenance rules are enforced by `test.sh`: existing maintained plugins/MCP
servers first, custom code only when strictly necessary, `local-ai` at most
400 physical lines, and all maintained operational code/configuration at most
1,800 physical lines. Prose docs are the only exclusion; generated files,
splitting, and moving logic into configuration are not loopholes.
