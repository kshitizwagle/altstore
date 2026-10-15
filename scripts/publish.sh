#!/usr/bin/env bash
# Builds the static site/ tree with signed indexes for all four formats.
# Inputs: dist/ (from build-packages.sh). Signing keys come from the environment:
#   GPG_KEY_ID      signing key for apt (reprepro), rpm metadata, and pacman db
#   ALPINE_KEY      path to the private RSA key used by abuild-sign
#   APK_PUBLIC_KEY  path to the matching public key, copied into site/keys/
# Requires: reprepro, createrepo_c, rpm (rpmsign), pacman-package-manager (repo-add), docker (for the Alpine steps).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
SITE="$ROOT/site"
: "${GPG_KEY_ID:?set GPG_KEY_ID}"
: "${ALPINE_KEY:?set ALPINE_KEY}"
: "${APK_PUBLIC_KEY:?set APK_PUBLIC_KEY}"
rm -rf "$SITE"
mkdir -p "$SITE"
touch "$SITE/.nojekyll"
echo "poko.kshitizwagle.com.np" > "$SITE/CNAME"
mkdir -p "$SITE/keys" "$SITE/apt/conf" "$SITE/rpm/x86_64" "$SITE/arch/x86_64" "$SITE/alpine/x86_64"

gpg --armor --export "$GPG_KEY_ID" > "$SITE/keys/repo.asc"
gpg --export "$GPG_KEY_ID" > "$SITE/keys/repo.gpg"
cp "$APK_PUBLIC_KEY" "$SITE/keys/pkgrepo.rsa.pub"

# APT: reprepro builds the index and signed Release files
cat > "$SITE/apt/conf/distributions" <<EOT
Origin: pkgrepo
Label: pkgrepo
Codename: stable
Suite: stable
Architectures: amd64 arm64
Components: main
Description: Package repository
SignWith: $GPG_KEY_ID
EOT
for deb in "$DIST"/*.deb; do
  [ -e "$deb" ] || continue
  reprepro -b "$SITE/apt" includedeb stable "$deb"
done

# RPM: sign packages, build repodata, sign repomd.xml
for rpm in "$DIST"/*.rpm; do
  [ -e "$rpm" ] || continue
  cp "$rpm" "$SITE/rpm/x86_64/"
done
if ls "$SITE/rpm/x86_64/"*.rpm >/dev/null 2>&1; then
  rpmsign --addsign "$SITE/rpm/x86_64/"*.rpm
  createrepo_c "$SITE/rpm/x86_64/"
  gpg --batch --yes --armor --detach-sign --default-key "$GPG_KEY_ID" \
    --output "$SITE/rpm/x86_64/repodata/repomd.xml.asc" \
    "$SITE/rpm/x86_64/repodata/repomd.xml"
fi

# Arch: sign each package, then build the signed database
for pkg in "$DIST"/*.pkg.tar.zst; do
  [ -e "$pkg" ] || continue
  cp "$pkg" "$SITE/arch/x86_64/"
  gpg --batch --yes --detach-sign --default-key "$GPG_KEY_ID" \
    --output "$SITE/arch/x86_64/$(basename "$pkg").sig" "$pkg"
done
if ls "$SITE/arch/x86_64/"*.pkg.tar.zst >/dev/null 2>&1; then
  repo-add -s "$SITE/arch/x86_64/pkgrepo.db.tar.gz" "$SITE/arch/x86_64/"*.pkg.tar.zst
fi

# Alpine: index all .apk files, then sign the index
for apk in "$DIST"/*.apk; do
  [ -e "$apk" ] || continue
  cp "$apk" "$SITE/alpine/x86_64/"
done
if ls "$SITE/alpine/x86_64/"*.apk >/dev/null 2>&1; then
  # apk-tools and abuild aren't in Ubuntu's repos, so run them in an Alpine container.
  # The key directory is mounted so the signature keeps the key's name (pkgrepo.rsa).
  docker run --rm \
    -v "$SITE/alpine/x86_64:/work" \
    -v "$(cd "$(dirname "$ALPINE_KEY")" && pwd):/keys:ro" \
    -w /work alpine:3.20 sh -c "apk add --no-cache abuild apk-tools >/dev/null && apk index -o APKINDEX.tar.gz ./*.apk && abuild-sign -k /keys/$(basename "$ALPINE_KEY") APKINDEX.tar.gz"
fi
# AltStore (iOS) source: served from the same host
# This repo builds source.json itself (update.yml), so it is copied from the checkout.
mkdir -p "$SITE/apple"
cp "$ROOT/altstore/source.json" "$SITE/apple/source.json"
cp -r "$ROOT/altstore/icons" "$SITE/apple/icons"

# Landing page listing every source on this host
cat > "$SITE/index.html" <<'EOT'
<!doctype html>
<meta charset="utf-8">
<title>kshitizwagle repositories</title>
<h1>kshitizwagle repositories</h1>
<h2>Linux packages</h2>
<p>Add the repo for your distro. Public signing keys are in <a href="keys/">keys/</a>.</p>
<ul>
  <li>APT (Ubuntu, Debian): <code>https://poko.kshitizwagle.com.np/apt</code></li>
  <li>DNF / Zypper (Fedora, RHEL, openSUSE): <code>https://poko.kshitizwagle.com.np/rpm/$basearch/</code></li>
  <li>Pacman (Arch): <code>https://poko.kshitizwagle.com.np/arch/$arch</code></li>
  <li>APK (Alpine): <code>https://poko.kshitizwagle.com.np/alpine/x86_64</code></li>
</ul>
<h2>iPhone apps (AltStore)</h2>
<p>In AltStore, go to Browse &rsaquo; Sources &rsaquo; + and add <code>https://poko.kshitizwagle.com.np/apple/source.json</code>.</p>
EOT
echo "site/ ready"
