# kshitizwagle's AltStore source

One AltStore source for all my iPhone apps. In AltStore, go to Browse › Sources › + and add:

```
https://kshitizwagle.com.np/altstore
```

(That redirects to `https://raw.githubusercontent.com/kshitizwagle/altstore/main/source.json`, which works too.)

| App | Repo |
|-----|------|
| Tethercam: iPhone as a Windows webcam over USB | [kshitizwagle/tethercam](https://github.com/kshitizwagle/tethercam) |
| Ninja Links: scan and keep Social Stream and VDO.Ninja links | [kshitizwagle/ninja-links](https://github.com/kshitizwagle/ninja-links) |

## How it works

Each app lives in its own public repo, whose CI publishes an unsigned IPA as a GitHub release.
`apps.json` lists the apps (repo, IPA asset name, store text). `scripts/build_source.py` reads every
release of every app, takes the version, build and minimum iOS from each IPA's Info.plist, and writes
`source.json`. The `update source` workflow runs it hourly and commits any change. An app repo can send
a `release` repository dispatch to update it at once.

To add an app: add an entry to `apps.json` and its icon to `icons/`, then push.
