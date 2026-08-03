# AG-WRI-GUI — Windows Runtime Installer (GUI)

A single-file PowerShell tool that installs the common Microsoft runtimes a
lot of Windows software (especially games) depends on. Run it with one
command:

```powershell
irm https://wri-gui.top | iex
```

This repo is the restored original WRI-GUI (recovered from the live
deployment after the original GitHub account was deleted), with the one
thing that broke it fixed: the package list used to be fetched from a
`redists.json` on the deleted account, and is now inlined into the script so
it has **no external dependencies** besides Microsoft's own download servers.

## Features

- **Tabbed GUI** — Visual C++ / .NET Framework & Runtime / Extras tabs, dark
  theme, with per-package checkboxes and version labels.
- **Preset buttons** — Select All, Select None, VC++ Only, Essentials
  (VC++ + DirectX), Gaming (VC++ + DirectX + OpenAL + XNA).
- **Detects what's already installed** — registry uninstall entries, .NET
  release values, `VCRUNTIME140_1.dll` presence for the unified 2015–2022
  runtime, DirectX DLL checks — and greys out anything already present.
- **Progress screen** — progress bar plus a colored status log while
  installing.
- **Self-elevating** — works both when piped from the web (`irm | iex`
  re-runs the one-liner elevated) and when run from a saved `.ps1` file.
- **Restart prompt on close** — after installing, closing the window shows a
  plain Yes/No "A Windows restart is strongly advised. Restart?" prompt.
  It never restarts without you clicking **Yes**.

## What's included

| Tab | Packages |
|-----|----------|
| Visual C++ | 2005, 2008, 2010, 2012 (U4), 2013, 2015–2022 — each installs x86 + x64 |
| .NET | Framework 3.5 (via DISM), Framework 4.8, Desktop Runtime 6 / 8 / 9 |
| Extras | DirectX End-User Runtime (June 2010, full redist), OpenAL, XNA Framework 4.0 |

Install exit codes `0`, `1638`, `3010`, `1641`, `5100` are treated as
success (already installed / newer present / reboot pending).

## Deploying to wri-gui.top

The domain's DNS lives at Hostinger (`ns*.dnsowl.com`) and points at
**Netlify** — the site itself is a Netlify deploy. To update it:

1. Log in at [app.netlify.com](https://app.netlify.com) and open the site
   that has `wri-gui.top` as its custom domain.
2. Go to **Deploys** and drag-and-drop the [`deploy/`](./deploy) folder from
   this repo onto the page (or connect this repo with publish directory
   `deploy`).
3. Done — `deploy/netlify.toml` rewrites `/` to `wri-gui.ps1` and serves it
   as `text/plain`, which is exactly what `irm | iex` needs.

Verify with:

```powershell
irm https://wri-gui.top   # should print the script, starting with the WRI banner
```

No Hostinger changes are needed; DNS already points at Netlify.

## Repo layout

| Path | Purpose |
|------|---------|
| `wri-gui.ps1` | The script (source of truth) |
| `deploy/` | Ready-to-drop Netlify folder (script + `netlify.toml`) |
| `recovered/wri-gui.original.ps1` | Byte-for-byte copy of the old live script, for reference |

If you edit `wri-gui.ps1`, copy it over `deploy/wri-gui.ps1` before
redeploying.

## Safety notes

- The script is plain and readable — no obfuscation, no persistence. Read it
  before you run it; `irm | iex` runs whatever the URL returns.
- All downloads come from `microsoft.com` / `aka.ms` / `go.microsoft.com`
  (plus `openal.org` for OpenAL).
- Downloaded executables are checked for a valid `MZ` header before running.

## License

MIT — see [`LICENSE`](./LICENSE).
