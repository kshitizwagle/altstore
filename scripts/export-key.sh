#!/usr/bin/env bash
# Exports the repo signing key to the keyring file shipped in the config package.
# Usage: scripts/export-key.sh <gpg-key-id-or-email>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
gpg --export "$1" > "$ROOT/packaging/repo-config/usr/share/keyrings/pkgrepo-archive-keyring.gpg"
echo "exported key for $1"
