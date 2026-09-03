# Local Qwen agent stack on an RTX 5090

This is a manually started, single-GPU setup with one model endpoint
(`127.0.0.1:30000`), DeepSeek Harness, private SearXNG, restricted page fetch,
Mermaid rendering, and an isolated read-only GitHub work profile. It has no
DeepSeek API dependency and no autostart.

The complete secret-free bundle is in
[`examples/local-qwen-harness/`](../../examples/local-qwen-harness/).

## Recovery

Install an NVIDIA driver, Docker Engine/Compose v2, NVIDIA Container Toolkit,
Git, GitHub CLI, Node.js, pnpm, curl, sed, OpenSSL, and `sha256sum`. Verify
`nvidia-smi`, `docker compose version`, and `systemctl --user`, then:

```bash
git clone https://github.com/pedroribeiro1718/personal-tech-wiki.git
cd personal-tech-wiki/examples/local-qwen-harness
./bootstrap.sh
```

Bootstrap restores both Harness profiles and pinned dependencies but starts
nothing. Model weights/caches are deliberately excluded from Git.

## Commands

```bash
local-ai recipes                                  # compare recipes
local-ai start                                    # default SGLang stack
local-ai start --recipe a3b --desktop-use         # practical long context
local-ai start --recipe udq4 --desktop-use qwen harness
local-ai stop qwen                                # release VRAM
local-ai stop harness searxng                     # additive targets
local-ai dashboard                                # status/log/GPU TUI
local-ai logs qwen                                # harness and searxng also work
local-ai test                                     # validation and line budgets
```

Targets are `qwen`, `harness`, and `searxng`; no target means all. Only one
recipe may run at once, all use `http://127.0.0.1:30000/v1`, and a new Harness
session should be started after changing recipes. Harness retains the one
last-used catalog entry while the endpoint is stopped because it requires a
default model.

| Recipe | Engine / quantization | KV | Normal | Desktop | Image |
| --- | --- | --- | ---: | ---: | --- |
| `sglang` | SGLang NVFP4 | FP8 | 122,880 | 122,880 | yes |
| `exl3` | vLLM EXL3 K5/K6 | FP8 | 262,144 | 155,648 | yes |
| `ninfer` | NInfer NVFP4 | INT8 | 252,928 | 172,032 | no |
| `udq4` | llama.cpp Unsloth UD-Q4_K_XL | Q8_0 | 262,144 | 196,608 | yes |
| `a3b` | NInfer Qwen3.6 35B-A3B groupwise-int | INT8 | 262,144 | 245,760 | yes |

`local-ai prepare NAME` downloads/builds a recipe without starting it and
verifies pinned artifact sizes and hashes.

Measured with KDE and a lightly loaded Zen browser:

| Recipe/mode | Context | Used | Free |
| --- | ---: | ---: | ---: |
| `udq4 --desktop-use` | 196,608 | 30,091 MiB | 2,058 MiB |
| `udq4` | 262,144 | 31,384 MiB | 765 MiB |
| `a3b --desktop-use` | 245,760 | 27,553 MiB | 4,595 MiB |
| `a3b` | 262,144 | 27,686 MiB | 4,463 MiB |

Browser/video/WebGL/game use changes these numbers; startup checks current
free VRAM. SGLang's base profile was already qualified for desktop use, so the
flag does not reduce its context.

At full context, `udq4` puts only the 888-MiB BF16 vision projector in system
RAM. Text precision/speed are retained, but large images preprocess slowly.
Its 196K desktop mode keeps the projector on GPU. For full context plus routine
vision, `a3b` is the better-balanced option.

## Search, pages, diagrams, and GitHub

The stack prefers maintained integrations:

- `dsh-searxng` registers local SearXNG as Harness's native `web_search`.
- `@j0hanz/fetch-url-mcp` provides restricted, read-only
  `mcp__fetch__fetch-url` with SSRF defenses and no JavaScript execution.
- `dsh-better-markdown` renders Mermaid locally.
- the official GitHub MCP server serves the work profile read-only and in
  lockdown mode.

The earlier custom search/fetch MCP was removed. DeepSeek search stays
disabled. Native search plus page-fetch execution was acceptance-tested in
Harness with both new recipes.

For a company checkout:

```bash
local-ai github-login
local-ai github-status
cd /path/to/company/repository
local-ai start --work --recipe a3b --desktop-use qwen harness searxng
# open http://127.0.0.1:3081 and select the checkout as its workspace
```

The work Harness uses `~/.dsh-work` and separate GitHub CLI credentials. Its
official server exposes `context,repos,issues,pull_requests`; remote writes and
command execution are disabled. Public search remains enabled, but never send
proprietary code, internal URLs, credentials, issue contents, or logs to it.

## Maintenance

Nothing starts at boot. Harness uses transient user-systemd units and model
containers use `restart: "no"`. `local-ai stop qwen` gives Docker 60 seconds
for SIGTERM cleanup; verify release with `local-ai status` or `nvidia-smi`.

The repository rule is ready-made solutions first, custom code only when no
suitable maintained option exists. `test.sh` enforces `local-ai` at no more
than 400 physical lines and total maintained operational code/configuration at
no more than 1,800 lines, with no generated/config/file-splitting loopholes.
Exact source revisions, images, and model hashes are in
[`VERSIONS.md`](../../examples/local-qwen-harness/VERSIONS.md).
