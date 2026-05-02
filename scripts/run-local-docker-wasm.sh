#!/usr/bin/env bash
# Build gui-v2 WASM via Docker and copy artifacts to ./wasm-dist/ (see docker-compose.wasm.yml).
# Prereq: Docker Desktop running (install with: brew bundle install in this repo; see docs/SETUP.txt).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [[ "$(uname -m)" == "arm64" ]] && [[ -x /usr/local/bin/brew ]] && [[ ! -x /opt/homebrew/bin/brew ]]; then
  echo "Note: You only have Intel Homebrew (/usr/local) on Apple Silicon."
  echo "      For fewer Docker/Lima issues, install Homebrew for arm64: https://brew.sh"
  echo "      Then: cd /path/to/gui-v2 && brew bundle install"
  echo
fi

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f docker-compose.wasm.yml "$@"
  else
    docker-compose -f docker-compose.wasm.yml "$@"
  fi
}

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running or the CLI cannot reach the engine."
  echo
  if [[ -d "/Applications/Docker.app" ]]; then
    echo "Docker Desktop is installed. Start it and wait until the whale menu shows \"running\":"
    echo "    open -a Docker"
    echo "First launch can take a minute; accept any permission prompts."
    echo
  elif [[ -f "${ROOT}/Brewfile" ]] && command -v brew >/dev/null 2>&1; then
    echo "Install the app (if you have not): from this repo run"
    echo "    brew bundle install"
    echo "Then: open -a Docker"
    echo
  fi
  echo "Check:  docker info"
  echo "Full steps: docs/SETUP.txt"
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
