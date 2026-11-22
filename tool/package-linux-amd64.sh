#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build linux --release --target-platform=linux-x64
bundle=build/linux/x64/release/bundle

# The runner alone does not establish the architecture of the Dart AOT code.
check_amd64() {
  local header
  header=$(LC_ALL=C readelf -h "$1")
  if ! grep -Eq 'Class:[[:space:]]+ELF64' <<<"$header" ||
     ! grep -Eq 'Machine:[[:space:]]+Advanced Micro Devices X86-64' <<<"$header"; then
    echo "ELF Linux AMD64 attendu : $1" >&2
    exit 1
  fi
}
check_amd64 "$bundle/wf_quick_add"
check_amd64 "$bundle/lib/libapp.so"
for library in "$bundle"/lib/*.so*; do check_amd64 "$library"; done

mkdir -p build/dist
tar -czf build/dist/wf-quick-add-linux-amd64.tar.gz -C "$bundle" .
