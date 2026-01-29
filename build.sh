#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found. Install Docker Desktop and try again." >&2
  exit 1
fi

image="${OPENSCAD_DOCKER_IMAGE:-openscad/openscad:bookworm}"
platform="${OPENSCAD_DOCKER_PLATFORM:-}"
if [ -z "$platform" ]; then
  arch="$(uname -m)"
  if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    platform="linux/amd64"
  fi
fi
platform_args=()
if [ -n "$platform" ]; then
  platform_args=(--platform "$platform")
fi

docker run --rm   --user "$(id -u):$(id -g)"   "${platform_args[@]}"   -v "$root_dir:/workspace"   -w /workspace   "$image"   bash /workspace/scripts/docker-build.sh
