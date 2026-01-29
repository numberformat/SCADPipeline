#!/usr/bin/env bash
# Copyright (c) 2026 NOAMi (https://noami.us)
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

if [ -d "site" ]; then
  rm -rf site
  echo "Removed ./site"
else
  echo "No ./site directory to remove"
fi
