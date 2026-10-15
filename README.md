# poko

One host, `https://poko.kshitizwagle.com.np`, serves every package and app source I publish.

## Linux packages

| Distro family | Repo URL |
|---|---|
| Ubuntu, Debian (apt) | `https://poko.kshitizwagle.com.np/apt` |
| Fedora, RHEL, openSUSE (dnf, zypper) | `https://poko.kshitizwagle.com.np/rpm/$basearch/` |
| Arch (pacman) | `https://poko.kshitizwagle.com.np/arch/$arch` |
| Alpine (apk) | `https://poko.kshitizwagle.com.np/alpine/x86_64` |

Packages are built from `packages/<name>/nfpm.yaml` by `scripts/build-packages.sh`, and `scripts/publish.sh`
builds the signed indexes for all four formats into `site/`. `.github/workflows/release.yml` runs both on a `v*` tag.
Start a new package by copying `packages/_template/`. Bootstrap config for apt lives in `packaging/repo-config/`.

## iPhone apps (AltStore)

Add `https://poko.kshitizwagle.com.np/apple/source.json` in AltStore under Browse › Sources › +.

| App | Repo |
|-----|------|
| Tethercam: iPhone as a Windows webcam over USB | [kshitizwagle/tethercam](https://github.com/kshitizwagle/tethercam) |
| Ninja Links: scan and keep Social Stream and VDO.Ninja links | [kshitizwagle/ninja-links](https://github.com/kshitizwagle/ninja-links) |

Each app repo publishes an unsigned IPA as a GitHub release. `altstore/apps.json` lists the apps, and
`altstore/scripts/build_source.py` (run hourly by `update.yml`) writes `source.json` from those releases. To add an app,
add an entry to `altstore/apps.json` and its icon to `altstore/icons/`.
