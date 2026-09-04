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
python3 -m py_compile "$ROOT/dashboard.py"
python3 -m json.tool "$ROOT/bootstrap/harness/package.json" >/dev/null
for file in "$ROOT"/qwen-*.compose.yaml; do
  QWEN_FULL_PATCH_DIR=/tmp QWEN_NINFER_MODEL_FILE=/tmp/model \
  QWEN_MODEL_DIR=/tmp QWEN_MODEL_FILE=/tmp/model docker compose -f "$file" config -q
done
rg -q 'dsh-searxng' "$ROOT/bootstrap/harness/package.json"
rg -q '@j0hanz/fetch-url-mcp' "$ROOT/bootstrap/harness/package.json"
rg -q 'reasoningEfforts:' "$ROOT/bootstrap/harness/settings.yaml"
rg -q 'thinkingFormat: chat-template' "$ROOT/local-ai"
printf 'OK: syntax, Compose, integration pins, and code budget (%s/1800).\n' "$lines"
