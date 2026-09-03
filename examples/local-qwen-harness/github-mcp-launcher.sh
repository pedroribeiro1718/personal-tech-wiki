#!/usr/bin/env bash
set -euo pipefail

GITHUB_MCP_IMAGE="ghcr.io/github/github-mcp-server:v1.11.0@sha256:48b071b92a297eb9b8ddb8dd87ccb4c75dbca6b0867eff034de4148722e0d164"
GH_CONFIG_DIR="${GITHUB_WORK_GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/gh-work}"
export GH_CONFIG_DIR

if ! command -v gh >/dev/null 2>&1; then
  printf 'GitHub MCP unavailable: install GitHub CLI, then run local-ai github-login\n' >&2
  exit 1
fi
if ! gh auth status -h github.com >/dev/null 2>&1; then
  printf 'GitHub MCP unavailable: run local-ai github-login\n' >&2
  exit 1
fi
if ! token="$(gh auth token -h github.com 2>/dev/null)" || [[ -z "${token}" ]]; then
  printf 'GitHub MCP unavailable: run local-ai github-login\n' >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="${token}"
export GITHUB_TOOLSETS="${GITHUB_TOOLSETS:-context,repos,issues,pull_requests}"
export GITHUB_READ_ONLY=1
export GITHUB_LOCKDOWN_MODE=1

exec docker run --rm -i \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  -e GITHUB_TOOLSETS \
  -e GITHUB_READ_ONLY \
  -e GITHUB_LOCKDOWN_MODE \
  "${GITHUB_MCP_IMAGE}"
