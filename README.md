# poko

Package repositories and app sources for kshitizwagle's projects, served from
`https://poko.kshitizwagle.com.np`.

- **Linux:** apt, dnf/zypper, pacman, and apk repos, signed with GPG (apt, rpm, pacman) and an RSA key (apk).
- **iPhone:** an AltStore source, built from the apps' GitHub releases.

## Install from the Linux repos

Public keys are in [`keys/`](keys/). Each repo below is served from `https://poko.kshitizwagle.com.np`.

**Debian / Ubuntu (apt)**

```sh
curl -fsSL https://poko.kshitizwagle.com.np/keys/repo.gpg | sudo tee /usr/share/keyrings/pkgrepo-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/pkgrepo-archive-keyring.gpg] https://poko.kshitizwagle.com.np/apt stable main" | sudo tee /etc/apt/sources.list.d/pkgrepo.list
sudo apt update
```

**Fedora / RHEL / openSUSE (dnf, zypper)**

```sh
sudo curl -fsSL https://poko.kshitizwagle.com.np/keys/repo.asc -o /etc/pki/rpm-gpg/RPM-GPG-KEY-pkgrepo
sudo tee /etc/yum.repos.d/pkgrepo.repo >/dev/null <<'REPO'
[pkgrepo]
name=poko
baseurl=https://poko.kshitizwagle.com.np/rpm/$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://poko.kshitizwagle.com.np/keys/repo.asc
REPO
```

**Arch (pacman)** — add to `/etc/pacman.conf`:

```ini
[pkgrepo]
SigLevel = Required
Server = https://poko.kshitizwagle.com.np/arch/$arch
```

**Alpine (apk)**

```sh
sudo curl -fsSL https://poko.kshitizwagle.com.np/keys/pkgrepo.rsa.pub -o /etc/apk/keys/pkgrepo.rsa.pub
echo "https://poko.kshitizwagle.com.np/alpine/x86_64" | sudo tee -a /etc/apk/repositories
sudo apk update
```

Then install packages with your package manager as usual.

## iPhone apps (AltStore)

In AltStore, go to Browse › Sources › + and add `https://poko.kshitizwagle.com.np/apple`.

| App | Repo |
|-----|------|
| Tethercam: iPhone as a Windows webcam over USB | [kshitizwagle/tethercam](https://github.com/kshitizwagle/tethercam) |
| Ninja Links: scan and keep Social Stream and VDO.Ninja links | [kshitizwagle/ninja-links](https://github.com/kshitizwagle/ninja-links) |

Each app repo publishes an unsigned IPA as a GitHub release. `altstore/apps.json` lists the apps, and
`altstore/scripts/build_source.py` (run hourly by `altstore/update.yml`) writes `altstore/source.json` from those releases.
To add an app, add an entry to `altstore/apps.json` and its icon to `altstore/icons/`.

## Repository layout

| Path | What it is |
|------|------------|
| `packages/<name>/nfpm.yaml` | One package's definition. Copy `packages/_template/` to start a new one. |
| `packaging/repo-config/` | The `pkgrepo-config` package that sets up apt on a client. |
| `scripts/build-packages.sh` | Builds every package into `dist/` for deb, rpm, apk, and Arch. |
| `scripts/build-config-deb.sh` | Builds the apt config package into `dist/`. |
| `scripts/publish.sh` | Builds the signed indexes for all four formats, plus the AltStore files, into `site/`. |
| `keys/` | Public signing keys, served to clients. |
| `altstore/` | AltStore source: `apps.json`, `source.json`, icons, and the build script. |
| `.github/workflows/release.yml` | Builds `site/` and deploys it to GitHub Pages on a `v*` tag. |

## Releasing

Publishing runs on a `v*` tag, for example `v0.1.0`. The workflow builds the packages, signs the indexes,
and deploys `site/` to GitHub Pages.

It needs these repository secrets:

- `GPG_PRIVATE_KEY`: the armored private signing key for apt, rpm, and pacman.
- `GPG_KEY_ID`: the key ID for that key.
- `ALPINE_PRIVATE_KEY`: the RSA private key for apk signing. Its public half is in `keys/pkgrepo.rsa.pub`.

GitHub Pages serves `poko.kshitizwagle.com.np` through a CNAME record that points to `kshitizwagle.github.io`.
The record is set to DNS only, not proxied through Cloudflare.
