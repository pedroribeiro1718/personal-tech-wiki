# Local Qwen stack for one RTX 5090

Reproducible, manually started local-agent stack:

- one OpenAI-compatible Qwen server at `http://127.0.0.1:30000/v1`
- DeepSeek Harness at `http://127.0.0.1:3080`
- isolated work Harness at `http://127.0.0.1:3081`
- private SearXNG at `http://127.0.0.1:8888`
- native Harness search, restricted public-page fetch, Mermaid, Playwright
  browser acceptance, and optional read-only GitHub integration

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
stopped. Model switches automatically reload any active personal/work Harness
processes because Harness reads the catalog only at process startup; refreshing
the browser alone is insufficient.

## Recipes

| Name | Base model | Engine | Quantization | Artifact source | KV | Normal context | Desktop context | Vision | Reasoning | Draft |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- | --- |
| `sglang` | Qwen3.8-27B | SGLang | NVFP4 | GitTensor | FP8 | 122,880 | 122,880 | yes | four levels | DSpark-7 |
| `exl3` | Qwen3.8-27B | vLLM | EXL3 K5/K6 | malaiwah | FP8 | 262,144 | 155,648 | yes | four levels | MTP-3 |
| `ninfer` | Qwen3.8-27B | NInfer | NVFP4 | Neroued | INT8 | 252,928 | 172,032 | no | four levels | MTP-3 |
| `udq4` | Qwen3.8-27B | llama.cpp | UD-Q4_K_XL | Unsloth | Q8_0 | 262,144 | 196,608 | yes | four levels | MTP-3 |
| `a3b` | Qwen3.6-35B-A3B | NInfer | groupwise-int | Neroued | INT8 | 262,144 | 245,760 | yes | default only | MTP-3 |

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

## Model cache locations

Downloaded NInfer/A3B artifacts, Unsloth GGUFs, NInfer source, and the small
EXL3 runtime overlays live in `~/.cache/local-qwen-harness/`. Hugging Face
weights downloaded inside the SGLang and vLLM containers live in Docker named
volumes `qwen38-hf-cache` and `qwen38-full-hf-cache` respectively. Inspect them
without assuming Docker's distro-specific storage path:

```bash
du -sh ~/.cache/local-qwen-harness ~/.cache/local-qwen-harness/*
docker system df -v
docker volume inspect qwen38-hf-cache qwen38-full-hf-cache
```

Model data is deliberately excluded from Git and is recreated by
`local-ai prepare RECIPE` or the first corresponding start.

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
- Microsoft `playwright-cli` provides token-efficient browser automation to
  both profiles through the existing Bash tool. Harness is instructed to run
  it for browser-facing changes and not claim success without exercising the
  behavior and checking console errors.
- the work profile launches GitHub's official MCP server in read-only,
  lockdown mode.

The official CLI was chosen instead of a custom Harness plugin or Playwright
MCP. Microsoft recommends CLI+skills for coding agents because it avoids large
MCP tool schemas; Harness can discover its commands with `playwright-cli
--help`. Bootstrap installs one shared pinned Chromium under
`~/.cache/local-qwen-harness/playwright-browsers`. Projects that already contain
Playwright tests keep using their own suite; repeatable ad-hoc checks can import
the installed `playwright` package from Node without another project install.
Because Harness isolates Bash calls, a CLI browser is opened, inspected, and
closed in one call. Agents must validate locator uniqueness and behavior, never
invoke `npx`, and remove unrequested inspection artifacts.

## Sampling defaults

Harness `0.1.1-rc.2` can send `temperature`, but its provider-neutral request
contract cannot send `top_p`, `top_k`, `min_p`, or penalties. The Qwen3.8
SGLang/vLLM recipes therefore explicitly load the model's generation config;
the llama.cpp recipe pins Qwen3.8's thinking defaults (`1.0`, `0.95`, `20`,
`0`, presence `0`, repetition `1`) at the server. Client-supplied values still
win. The pinned NInfer release selects Qwen3.8's official defaults from the
resolved thinking mode. The `a3b` recipe instead pins Qwen3.6-35B-A3B's
precise-coding profile (`0.6`, `0.95`, `20`, `0`, presence/frequency `0`) with
NInfer's supported process flags. Harness leaves temperature unset by default,
so these backend values remain effective. No sampling adapter is needed.

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
