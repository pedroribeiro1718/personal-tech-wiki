#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mapfile -d '' files < <(find "$ROOT" -type f -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' -not -name '*.md' -not -name '.env' \
  -not -name '.gitignore' -print0)
lines="$(wc -l "${files[@]}" | tail -1 | awk '{print $1}')"
(( lines <= 1800 )) || { echo "Code budget exceeded: $lines/1800 lines" >&2; exit 1; }
(( $(wc -l < "$ROOT/local-ai") <= 400 )) || { echo "local-ai exceeds 400 lines" >&2; exit 1; }

bash -n "$ROOT/local-ai" "$ROOT/bootstrap.sh" "$ROOT/github-mcp-launcher.sh"
rg -q '"\$STACK/local-ai" sync' "$ROOT/bootstrap.sh"
python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$ROOT/dashboard.py"
python3 -m json.tool "$ROOT/bootstrap/harness/package.json" >/dev/null
for file in "$ROOT"/qwen-*.compose.yaml; do
  QWEN_FULL_PATCH_DIR=/tmp QWEN_NINFER_MODEL_FILE=/tmp/model \
  QWEN_MODEL_DIR=/tmp QWEN_MODEL_FILE=/tmp/model docker compose -f "$file" config -q
done
rg -q 'dsh-searxng' "$ROOT/bootstrap/harness/package.json"
rg -q '@j0hanz/fetch-url-mcp' "$ROOT/bootstrap/harness/package.json"
rg -q 'reasoningEfforts:' "$ROOT/bootstrap/harness/settings.yaml"
rg -q 'thinkingFormat: chat-template' "$ROOT/local-ai"
rg -q '"@playwright/cli": "0.1.18"' "$ROOT/bootstrap/harness/package.json"
rg -q 'playwright-cli' "$ROOT/bootstrap/harness-work/agent-presets/local-code-work/agent.cordis.yml"
for preset in "$ROOT/bootstrap/harness/agent-presets/local-standard/agent.cordis.yml" \
  "$ROOT/bootstrap/harness-work/agent-presets/local-code-work/agent.cordis.yml"; do
  rg -q 'Never use npx' "$preset"
done
rg -q -- '--sampling-defaults' "$ROOT/qwen-sglang-nvfp4-122880.compose.yaml"
rg -q -- '--generation-config' "$ROOT/qwen-vllm-exl3-k5k6-262144.compose.yaml"
rg -q -- '--presence-penalty' "$ROOT/qwen-llamacpp-ud-q4-k-xl-262144.compose.yaml"
rg -q -- '--temperature' "$ROOT/qwen-ninfer-groupwise-int-262144.compose.yaml"
rg -q -- '--presence-penalty' "$ROOT/qwen-ninfer-groupwise-int-262144.compose.yaml"
"$ROOT/local-ai" recipes | awk '/^[+|]/{if(length != 81) exit 1}'
printf 'OK: syntax, Compose, integration pins, and code budget (%s/1800).\n' "$lines"
