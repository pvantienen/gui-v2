#!/usr/bin/env bash
# Build gui-v2 WASM inside Docker without modifying the host working tree (rsync to /tmp).
set -euo pipefail

SRC="${GUIV2_SRC:-/src/gui-v2}"
WORK="/tmp/gui-v2-work"

if [[ ! -f "${SRC}/scripts/build-wasm.sh" ]]; then
  echo "ERROR: ${SRC} does not look like gui-v2 (missing scripts/build-wasm.sh)."
  exit 1
fi

echo ">>> Syncing sources to ${WORK} (excluding .git, build-wasm*)..."
mkdir -p "${WORK}"
rsync -a "${SRC}/" "${WORK}/" \
  --exclude .git \
  --exclude build-wasm \
  --exclude build-wasm_files_to_copy

cd "${WORK}"

echo ">>> Patching install script: skip snap yq (use image /usr/local/bin/yq)..."
python3 << 'PY'
from pathlib import Path
p = Path("/tmp/gui-v2-work/scripts/build-wasm-install-requirements.sh")
text = p.read_text()
start = text.find("# Install yq\n")
if start < 0:
    raise SystemExit("patch: start anchor not found")
end = text.find("\n# Set up Python 3.x", start)
if end < 0:
    raise SystemExit("patch: end anchor not found")
repl = """# Install yq (docker image provides /usr/local/bin/yq; snap not used)
echo -e "\\n\\n*** Installing yq ***"
if ! command -v yq &> /dev/null; then
    echo "ERROR: yq not found in PATH"
    exit 1
fi
echo "✓ yq installed successfully"
"""
p.write_text(text[:start] + repl + text[end:])
PY

QT_VERSION="$(grep -E '^QT_VERSION=' scripts/.env | head -1 | cut -d= -f2)"
if [[ "${SKIP_INSTALL:-0}" != "1" ]]; then
  if [[ ! -f "/opt/venus/build-gx-hostedtoolcache/Qt/${QT_VERSION}/wasm_singlethread/bin/qmake" ]]; then
    echo ">>> Running build-wasm-install-requirements.sh (first run: downloads Qt + emsdk; 30–60+ min)..."
    bash scripts/build-wasm-install-requirements.sh
  else
    echo ">>> Toolchain present in cache volume; skipping install."
  fi
else
  echo ">>> SKIP_INSTALL=1 set; skipping toolchain install."
fi

echo ">>> Building WASM..."
if [[ $# -eq 0 ]]; then
  set -- -P
fi
bash scripts/build-wasm.sh "$@"

echo ">>> Output: ${WORK}/build-wasm_files_to_copy/wasm/"
ls -la "${WORK}/build-wasm_files_to_copy/wasm/" | head -20

if [[ -n "${COPY_OUT:-}" ]]; then
  echo ">>> Copying build-wasm_files_to_copy to ${COPY_OUT}/"
  rm -rf "${COPY_OUT}/build-wasm_files_to_copy" 2>/dev/null || true
  cp -a "${WORK}/build-wasm_files_to_copy" "${COPY_OUT}/"
fi
