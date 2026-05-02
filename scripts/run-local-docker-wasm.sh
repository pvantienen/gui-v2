#!/usr/bin/env bash
# Build gui-v2 WASM via Docker and copy artifacts to ./wasm-dist/ (see docker-compose.wasm.yml).
# Prereq: Docker Desktop running (install with: brew bundle install in this repo; see docs/SETUP.txt).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

if [[ "$(uname -m)" == "arm64" ]] && [[ -x /usr/local/bin/brew ]] && [[ ! -x /opt/homebrew/bin/brew ]]; then
  echo "Note: Intel-only Homebrew (/usr/local) on Apple Silicon installs Intel Docker — wrong chip."
  echo "      Use Apple Silicon Homebrew (/opt/homebrew): https://brew.sh"
  echo "      Or install Docker directly: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
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

# Apple Silicon: docker CLI often shows amd64 when the shell is running under Rosetta.
if [[ "$(uname -m)" == "arm64" ]]; then
  _carch="$(docker version -f '{{.Client.Arch}}' 2>/dev/null || echo "")"
  if [[ "${_carch}" == "amd64" ]]; then
    if [[ -z "${GUI_V2_REEXEC_ARM64:-}" ]]; then
      echo "NOTE: Docker CLI reports amd64 (Rosetta). Re-running this script under native arm64..."
      export GUI_V2_REEXEC_ARM64=1
      exec arch -arm64 /bin/bash "$0" "$@"
    fi
    echo "ERROR: Docker CLI is still amd64. Fix the terminal, not Docker Desktop:"
    echo "  - Terminal.app / iTerm / Cursor: Get Info → uncheck \"Open using Rosetta\", then quit and reopen."
    echo "  Or run:  arch -arm64 /bin/bash -lc 'cd \"${ROOT}\" && ./scripts/run-local-docker-wasm.sh'"
    echo "If you truly installed Intel Docker on Apple Silicon, use: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
    echo "(see docs/SETUP.txt)"
    exit 1
  fi
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
