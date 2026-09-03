#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DSH_DIR="${DSH_DIR:-${HOME}/.dsh}"
PROFILE_DIR="${DSH_DIR}/profiles/web"
PRESET_DIR="${DSH_DIR}/.agent-presets/local-standard"
BIN_DIR="${HOME}/.local/bin"

for command_name in docker git node pnpm curl sed openssl sha256sum systemctl systemd-run journalctl; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'Missing prerequisite: %s\n' "${command_name}" >&2
    exit 1
  fi
done

if ! systemctl --user show-environment >/dev/null 2>&1; then
  printf 'A running systemd user manager is required for background Harness control.\n' >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  printf 'Docker Compose v2 is required (the `docker compose` command).\n' >&2
  exit 1
fi

mkdir -p "${PROFILE_DIR}" "${PRESET_DIR}" "${BIN_DIR}"

backup_if_changed() {
  local source_file="$1"
  local destination_file="$2"
  if [[ -f "${destination_file}" ]] && ! cmp -s "${source_file}" "${destination_file}"; then
    cp -a "${destination_file}" "${destination_file}.before-local-ai"
  fi
}

if [[ ! -f "${STACK_DIR}/.env" ]]; then
  umask 077
  printf 'SEARXNG_SECRET=%s\n' "$(openssl rand -hex 32)" >"${STACK_DIR}/.env"
  printf 'Generated %s/.env\n' "${STACK_DIR}"
fi

settings_source="${STACK_DIR}/bootstrap/harness/settings.yaml"
package_source="${STACK_DIR}/bootstrap/harness/package.json"
patch_template="${STACK_DIR}/bootstrap/harness/cordis.patch.yml.in"
preset_source="${STACK_DIR}/bootstrap/harness/agent-presets/local-standard/agent.cordis.yml"
preset_metadata_source="${STACK_DIR}/bootstrap/harness/agent-presets/local-standard/preset.yml"
rendered_patch="$(mktemp)"
trap 'rm -f "${rendered_patch}"' EXIT

escaped_stack_dir="$(printf '%s' "${STACK_DIR}" | sed 's/[&|\\]/\\&/g')"
node_bin="$(command -v node)"
escaped_node_bin="$(printf '%s' "${node_bin}" | sed 's/[&|\\]/\\&/g')"
sed \
  -e "s|__STACK_DIR__|${escaped_stack_dir}|g" \
  -e "s|__NODE_BIN__|${escaped_node_bin}|g" \
  "${patch_template}" >"${rendered_patch}"

backup_if_changed "${settings_source}" "${DSH_DIR}/settings.yaml"
backup_if_changed "${package_source}" "${PROFILE_DIR}/package.json"
backup_if_changed "${rendered_patch}" "${PROFILE_DIR}/cordis.patch.yml"
backup_if_changed "${preset_source}" "${PRESET_DIR}/agent.cordis.yml"
backup_if_changed "${preset_metadata_source}" "${PRESET_DIR}/preset.yml"
install -m 0644 "${settings_source}" "${DSH_DIR}/settings.yaml"
install -m 0644 "${package_source}" "${PROFILE_DIR}/package.json"
install -m 0644 "${rendered_patch}" "${PROFILE_DIR}/cordis.patch.yml"
install -m 0644 "${preset_source}" "${PRESET_DIR}/agent.cordis.yml"
install -m 0644 "${preset_metadata_source}" "${PRESET_DIR}/preset.yml"

pnpm --dir "${STACK_DIR}/mcp" install --frozen-lockfile
pnpm --dir "${PROFILE_DIR}" install

docker volume inspect qwen38-hf-cache >/dev/null 2>&1 || docker volume create qwen38-hf-cache >/dev/null
docker compose -f "${STACK_DIR}/qwen.compose.yaml" pull
docker compose -f "${STACK_DIR}/compose.yaml" pull

ln -sfn "${STACK_DIR}/local-ai" "${BIN_DIR}/local-ai"

cat <<EOF

Bootstrap complete. Nothing was started and nothing is configured for autostart.

Manual commands:
  ${BIN_DIR}/local-ai start
  ${BIN_DIR}/local-ai prepare exl3
  ${BIN_DIR}/local-ai start --recipe exl3 qwen harness
  ${BIN_DIR}/local-ai prepare ninfer
  ${BIN_DIR}/local-ai start --recipe ninfer qwen harness
  ${BIN_DIR}/local-ai stop qwen
  ${BIN_DIR}/local-ai start qwen
  ${BIN_DIR}/local-ai stop
  ${BIN_DIR}/local-ai status
  ${BIN_DIR}/local-ai logs
EOF
