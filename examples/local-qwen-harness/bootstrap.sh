#!/usr/bin/env bash
set -euo pipefail
umask 077
STACK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PERSONAL="${DSH_DIR:-$HOME/.dsh}"
WORK="${WORK_DSH_DIR:-$HOME/.dsh-work}"

for cmd in docker git gh node pnpm python3 curl sed awk openssl sha256sum systemctl systemd-run journalctl; do
  command -v "$cmd" >/dev/null || { printf 'Missing prerequisite: %s\n' "$cmd" >&2; exit 1; }
done
systemctl --user show-environment >/dev/null || { echo "A systemd user manager is required." >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required." >&2; exit 1; }

[[ -f "$STACK/.env" ]] || { printf 'SEARXNG_SECRET=%s\n' "$(openssl rand -hex 32)" >"$STACK/.env"; }

backup() {
  local src="$1" dst="$2"
  [[ ! -f "$dst" ]] || cmp -s "$src" "$dst" || cp -a "$dst" "$dst.before-local-ai"
}

install_profile() {
  local home="$1" kind="$2" preset="$3" profile target template rendered
  profile="$home/profiles/web"; target="$home/.agent-presets/$preset"
  template="$STACK/bootstrap/$kind/cordis.patch.yml.in"
  mkdir -p "$profile" "$target"
  rendered="$(mktemp)"
  sed -e "s|__STACK_DIR__|${STACK//&/\\&}|g" \
      -e "s|__NODE_BIN__|$(command -v node)|g" \
      -e "s|__PROFILE_DIR__|${profile//&/\\&}|g" "$template" >"$rendered"
  local pair src dst
  for pair in \
    "$STACK/bootstrap/$kind/settings.yaml:$home/settings.yaml" \
    "$STACK/bootstrap/harness/package.json:$profile/package.json" \
    "$STACK/bootstrap/harness/pnpm-workspace.yaml:$profile/pnpm-workspace.yaml" \
    "$rendered:$profile/cordis.patch.yml" \
    "$STACK/bootstrap/$kind/agent-presets/$preset/agent.cordis.yml:$target/agent.cordis.yml" \
    "$STACK/bootstrap/$kind/agent-presets/$preset/preset.yml:$target/preset.yml"; do
    src="${pair%%:*}"; dst="${pair#*:}"; backup "$src" "$dst"; install -m 0644 "$src" "$dst"
  done
  rm -f "$rendered"
  pnpm --dir "$profile" install
}

install_profile "$PERSONAL" harness local-standard
install_profile "$WORK" harness-work local-code-work
PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/local-qwen-harness/playwright-browsers" \
  pnpm --dir "$PERSONAL/profiles/web" exec playwright-cli install-browser chromium
docker compose -f "$STACK/qwen-sglang-nvfp4-122880.compose.yaml" pull
docker compose -f "$STACK/compose.yaml" pull
docker pull "ghcr.io/github/github-mcp-server:v1.11.0@sha256:48b071b92a297eb9b8ddb8dd87ccb4c75dbca6b0867eff034de4148722e0d164"
mkdir -p "$HOME/.local/bin"
ln -sfn "$STACK/local-ai" "$HOME/.local/bin/local-ai"
curl -fsS --max-time 2 http://127.0.0.1:30000/v1/models >/dev/null 2>&1 &&
  "$STACK/local-ai" sync

cat <<EOF
Bootstrap complete. Nothing was started or enabled at boot.

  local-ai recipes
  local-ai start
  local-ai prepare udq4
  local-ai prepare a3b
  local-ai start --work --recipe a3b --desktop-use
  local-ai stop qwen
EOF
