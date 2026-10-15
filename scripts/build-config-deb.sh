#!/usr/bin/env bash
# Builds pkgrepo-config_<version>_all.deb from packaging/repo-config.
# Needs the signing key exported to packaging/repo-config/usr/share/keyrings/
# (see scripts/export-key.sh) before building a release.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/packaging/repo-config"
OUT="$ROOT/dist"
mkdir -p "$OUT"
[ -s "$SRC/usr/share/keyrings/pkgrepo-archive-keyring.gpg" ] || { echo "missing keyring; run scripts/export-key.sh" >&2; exit 1; }
chmod 0755 "$SRC/DEBIAN"
find "$SRC" -type d -exec chmod 0755 {} +
find "$SRC" -type f ! -path "$SRC/DEBIAN/*" -exec chmod 0644 {} +
VERSION="$(sed -n 's/^Version: //p' "$SRC/DEBIAN/control")"
dpkg-deb --root-owner-group --build "$SRC" "$OUT/pkgrepo-config_${VERSION}_all.deb"
