#!/bin/sh
set -eu

test_root=$(mktemp -d /tmp/flatpak-warp-test.XXXXXX)

cleanup() {
    case "$test_root" in
        /tmp/flatpak-warp-test.*) rm -rf -- "$test_root" ;;
    esac
}
trap cleanup EXIT HUP INT TERM

export FLATPAK_USER_DIR="$test_root/flatpak"

trace=$(curl -4fsS https://www.cloudflare.com/cdn-cgi/trace)
printf '%s\n' "$trace" | grep -E '^(ip|colo|loc|warp)='
printf '%s\n' "$trace" | grep -qx 'warp=on'

flatpak --user remote-add \
  flathub-test \
  https://dl.flathub.org/repo/flathub.flatpakrepo

start_time=$(date +%s)

flatpak --user install \
  --runtime \
  --no-deploy \
  --no-related \
  --assumeyes \
  flathub-test \
  org.freedesktop.Sdk//25.08

elapsed=$(( $(date +%s) - start_time ))
repository_size=$(du -sh "$FLATPAK_USER_DIR" | cut -f1)

printf '\nTemporary OSTree repository size: %s\n' "$repository_size"
printf 'Elapsed time: %ss\n' "$elapsed"
