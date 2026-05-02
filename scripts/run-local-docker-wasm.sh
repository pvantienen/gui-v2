#!/usr/bin/env bash
# Build gui-v2 WASM via Docker and copy artifacts to ./wasm-dist/ (see docker-compose.wasm.yml).
# Requires: Docker engine running (Docker Desktop, or Colima from native arm64 Homebrew).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f docker-compose.wasm.yml "$@"
  else
    docker-compose -f docker-compose.wasm.yml "$@"
  fi
}

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running or not installed."
  echo
  echo "Pick one:"
  echo "  1) Install Docker Desktop for Mac and start it."
  echo "  2) Apple Silicon: install Homebrew to /opt/homebrew (native), then:"
  echo "       brew install colima docker docker-compose"
  echo "       colima start --cpu 4 --memory 8 --disk 100"
  echo "     Re-run this script from a native arm64 shell (not Rosetta)."
  echo
  echo "If you see 'limactl is running under rosetta': your terminal or brew is x86_64."
  echo "Use Terminal.app with Rosetta disabled for Cursor/iTerm, or migrate to /opt/homebrew."
  exit 1
fi

echo ">>> Building Docker image (wasm-build)..."
compose build

echo ">>> Running WASM build (first time: 30–60+ minutes; uses cached Qt volume on repeat)..."
compose run --rm wasm-build

echo
echo ">>> Build output: ${ROOT}/wasm-dist/build-wasm_files_to_copy/wasm/"
echo ">>> Serve locally (pick a free port):"
echo "    cd \"${ROOT}/wasm-dist/build-wasm_files_to_copy/wasm\" && python3 -m http.server 8765"
echo "Then open: http://localhost:8765/"
echo "Connect the UI to your Cerbo MQTT broker (same LAN or VPN/Tailscale as needed)."
