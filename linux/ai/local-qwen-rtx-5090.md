# Local Qwen agent stack on an RTX 5090

This is a manually started, single-GPU setup with one model endpoint
(`127.0.0.1:30000`), DeepSeek Harness, private SearXNG, restricted page fetch,
Mermaid rendering, Playwright browser acceptance, and an isolated read-only
GitHub work profile. It has no DeepSeek API dependency and no autostart.

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
nothing. If a model is already serving, it resynchronizes that model and its
actual context into both Harness catalogs after reinstalling the static
templates. Model weights/caches are deliberately excluded from Git.

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
default model. `local-ai` reloads active personal/work Harness processes after
a model switch because a browser refresh does not reload Harness's cached
catalog.

| Recipe | Base model | Engine | Quantization | Source | KV | Normal | Desktop | Image | Reasoning |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- |
| `sglang` | Qwen3.8-27B | SGLang | NVFP4 | GitTensor | FP8 | 122,880 | 122,880 | yes | four levels |
| `exl3` | Qwen3.8-27B | vLLM | EXL3 K5/K6 | malaiwah | FP8 | 262,144 | 155,648 | yes | four levels |
| `ninfer` | Qwen3.8-27B | NInfer | NVFP4 | Neroued | INT8 | 252,928 | 172,032 | no | four levels |
| `udq4` | Qwen3.8-27B | llama.cpp | UD-Q4_K_XL | Unsloth | Q8_0 | 262,144 | 196,608 | yes | four levels |
| `a3b` | Qwen3.6-35B-A3B | NInfer | groupwise-int | Neroued | INT8 | 262,144 | 245,760 | yes | default only |

`local-ai prepare NAME` downloads/builds a recipe without starting it and
verifies pinned artifact sizes and hashes.

Model files are not stored in Git. NInfer/A3B artifacts, Unsloth GGUFs, NInfer
source, and EXL3 overlays use `~/.cache/local-qwen-harness/`. Container-side
Hugging Face downloads use Docker volumes `qwen38-hf-cache` (SGLang) and
`qwen38-full-hf-cache` (vLLM/EXL3). Inspect them with:

```bash
du -sh ~/.cache/local-qwen-harness
docker system df -v
docker volume inspect qwen38-hf-cache qwen38-full-hf-cache
```

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

## Reasoning controls

The Qwen 3.8 recipes expose `Off`, `Low`, `Medium`, and `Xhigh` in Harness's
model menu (`Xhigh` is the model default). NInfer uses its native
`reasoning_effort`; SGLang, vLLM, and llama.cpp use Qwen chat-template
arguments. Begin a new session after switching recipes, and choose its level
before sending the first message.

Qwen3.6 35B-A3B still reasons by default, but its embedded template rejects
graded levels, so that recipe deliberately has no level picker. Switching to
it clears any saved Qwen 3.8 level instead of presenting a control that fails.

## Search, pages, diagrams, and GitHub

The stack prefers maintained integrations:

- `dsh-searxng` registers local SearXNG as Harness's native `web_search`.
- `@j0hanz/fetch-url-mcp` provides restricted, read-only
  `mcp__fetch__fetch-url` with SSRF defenses and no JavaScript execution.
- `dsh-better-markdown` renders Mermaid locally.
- Microsoft `playwright-cli` and its official bundled skill give both Harness
  profiles browser automation through Bash. Harness must validate locator
  uniqueness and behavior, check console errors, and report exact verification.
  Existing project Playwright tests take priority.
- the official GitHub MCP server serves the work profile read-only and in
  lockdown mode.

The CLI is deliberately used instead of a custom browser plugin or Playwright
MCP: it is Microsoft's recommended, lower-context option for coding agents.
`./bootstrap.sh` keeps the official guide and references behind a concise
Harness-specific entrypoint, with one shared pinned Chromium in the stack cache.
Harness's bundled persistent Bash tool keeps CLI browsers alive across calls.
Direct commands are preferred; `run-code` is reserved for checks they cannot
express. Agents avoid `npx`, ad-hoc DOM scrapers, and unrequested inspection
artifacts.

Harness rc.2 cannot send the complete Qwen sampling tuple, so sampling is
owned by each model server. Qwen3.8 uses its official mode-aware defaults. The
NInfer A3B recipe explicitly pins Qwen3.6-35B-A3B's precise-coding profile:
temperature `0.6`, top-p `0.95`, top-k `20`, min-p `0`, and zero presence and
frequency penalties. Harness leaves temperature unset, so it does not override
the backend. No custom sampling adapter is required.

All recipes cap a response at 8,192 tokens, matching Qwen Code's normal first
request budget. Qwen3.8 retains Harness's 80% compaction threshold; A3B uses
65% after observed long-session degeneration. After a repetitive response,
start a fresh session. For deterministic Gherkin table alignment, pin
`@cucumber/gherkin-utils` in the test repository and run its `format` command
instead of asking the model to align whitespace.

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
