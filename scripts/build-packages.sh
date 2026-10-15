#!/usr/bin/env bash
# Builds every package in packages/*/ (skipping _template) into dist/
# for deb, rpm, apk and archlinux. Needs nfpm on PATH.
# Each package expects its binary at packages/<name>/dist/... as set in nfpm.yaml.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist"
mkdir -p "$OUT"
for dir in "$ROOT"/packages/*/; do
  name="$(basename "$dir")"
  [ "$name" = "_template" ] && continue
  [ -f "$dir/nfpm.yaml" ] || continue
  for fmt in deb rpm apk archlinux; do
    echo "== $name ($fmt)"
    (cd "$dir" && nfpm pkg -f nfpm.yaml -p "$fmt" -t "$OUT")
  done
done
