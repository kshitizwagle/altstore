"""Builds source.json, the AltStore source, from the GitHub releases of every app in apps.json.

Usage: python scripts/build_source.py
Each release that has the app's IPA asset becomes a version, newest first. The version, build number and
minimum iOS come from the IPA's own Info.plist, so the source always matches the binary. IPAs already
listed in source.json aren't downloaded again. Set GITHUB_TOKEN to raise the API rate limit.
"""
import io
import json
import os
import plistlib
import re
import sys
import urllib.error
import urllib.request
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG = os.path.join(ROOT, "apps.json")
SOURCE = os.path.join(ROOT, "source.json")


def get(url, accept="application/vnd.github+json"):
    req = urllib.request.Request(url, headers={"Accept": accept, "User-Agent": "altstore-source-builder"})
    token = os.environ.get("GITHUB_TOKEN")
    if token and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=120) as res:
        return res.read()


def releases(repo):
    page = 1
    while True:
        try:
            batch = json.loads(get(f"https://api.github.com/repos/{repo}/releases?per_page=100&page={page}"))
        except urllib.error.HTTPError as e:
            if e.code == 404:  # repo not created or not public yet: no versions
                print(f"  {repo} not found", file=sys.stderr)
                return
            raise
        yield from batch
        if len(batch) < 100:
            return
        page += 1


def ipa_info(data):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        name = next(n for n in z.namelist() if n.startswith("Payload/") and n.endswith(".app/Info.plist")
                    and n.count("/") == 2)
        return plistlib.loads(z.read(name))


def label(version, tag):
    """0.1.0 for tag v0.1.0-alpha.1 becomes 0.1.0a1 (b for beta); other pre-release tags keep their suffix."""
    m = re.fullmatch(r"v?" + re.escape(version) + r"-(alpha|beta|rc)\.?(\d*)", tag)
    if not m:
        return version
    kind = {"alpha": "a", "beta": "b", "rc": "rc"}[m.group(1)]
    return f"{version}{kind}{m.group(2)}"


def versions(entry, known):
    app = entry["app"]
    result = []
    for rel in releases(entry["repo"]):
        if rel.get("draft"):
            continue
        asset = next((a for a in rel.get("assets", []) if a["name"] == entry["asset"]), None)
        if not asset:
            continue
        url = asset["browser_download_url"]
        if url in known:
            v = dict(known[url])
            v["version"] = label(v["version"], rel["tag_name"])
            result.append(v)
            continue
        print(f"  reading {url}", file=sys.stderr)
        info = ipa_info(get(url, accept="application/octet-stream"))
        if info.get("CFBundleIdentifier") != app["bundleIdentifier"]:
            print(f"  skipped: bundle id {info.get('CFBundleIdentifier')} isn't {app['bundleIdentifier']}", file=sys.stderr)
            continue
        result.append({
            "version": label(info["CFBundleShortVersionString"], rel["tag_name"]),
            "buildVersion": str(info["CFBundleVersion"]),
            "date": rel["published_at"] or rel["created_at"],
            "localizedDescription": rel.get("name") or rel["tag_name"],
            "downloadURL": url,
            "size": asset["size"],
            "minOSVersion": info.get("MinimumOSVersion", "16.0"),
        })
    result.sort(key=lambda v: v["date"], reverse=True)
    # Releases that still share a version and build (e.g. a re-tag): keep the newest.
    seen = set()
    unique = []
    for v in result:
        key = (v["version"], v["buildVersion"])
        if key not in seen:
            seen.add(key)
            unique.append(v)
    return unique


def main():
    with open(CONFIG, encoding="utf-8") as f:
        config = json.load(f)
    known = {}
    if os.path.exists(SOURCE):
        with open(SOURCE, encoding="utf-8") as f:
            for app in json.load(f).get("apps", []):
                for v in app.get("versions", []):
                    known[v["downloadURL"]] = v
    apps = []
    for entry in config["apps"]:
        print(entry["repo"], file=sys.stderr)
        apps.append({**entry["app"], "versions": versions(entry, known)})
    source = {**config["source"], "apps": apps, "news": config.get("news", [])}
    with open(SOURCE, "w", encoding="utf-8", newline="\n") as f:
        json.dump(source, f, indent=2, ensure_ascii=False)
        f.write("\n")
    for app in apps:
        latest = app["versions"][0]["version"] if app["versions"] else "no releases yet"
        print(f"{app['name']}: {len(app['versions'])} versions, latest {latest}")


if __name__ == "__main__":
    main()
