# WRI-GUI — Windows Runtime Installer (GUI)

A single-file PowerShell tool that installs the common Microsoft runtimes a
lot of Windows software depends on. Run it with one command:

```powershell
irm https://wri-gui.top | iex
```

It opens a small GUI where you tick what you want, skips anything already
installed, downloads each package straight from Microsoft, and installs it
silently.

## Features

- **Pick what you want** — checkboxes for every package, plus *Select all* /
  *Select none*.
- **Detects what's already there** — reads the registry (uninstall entries,
  the VC++ 14 `Runtimes` keys, and the .NET release value) and greys out
  anything already installed so you don't reinstall it.
- **Full range of Visual C++ Redistributables** — 2005, 2008, 2010, 2012,
  2013 and 2015–2022, in both x86 and x64.
- **A few common extras** — .NET Framework 4.8 and the DirectX End-User
  Runtime.
- **Self-elevating** — if you're not admin it re-launches itself elevated.
- **Restart prompt on close** — after installing, closing the window offers a
  restart (with a 60-second, cancellable countdown) so every process picks up
  the new runtime files.

## What's included

| Category | Packages |
|----------|----------|
| Visual C++ Redistributables | 2005, 2008, 2010, 2012 (Update 4), 2013, 2015–2022 — x86 and x64 |
| Other runtimes | .NET Framework 4.8, DirectX End-User Runtime (web) |

The 2015–2022 package is the current combined `v14x` redistributable, which
supersedes the separate 2015, 2017 and 2019 versions.

## How detection works

The script reads the installed-programs list once from:

- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
- `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`

Each catalogue entry is matched against those display names (with an x86/x64
guard). The 2015–2022 redistributables and .NET 4.8 additionally check a
specific registry value for a more reliable result.

## Exit codes handled

- `0` — installed OK
- `3010` — installed OK, reboot required (flags the restart prompt)
- `1638` — a newer version is already present (treated as success)

## Deployment

For `irm https://wri-gui.top | iex` to work, the web server at that domain
must return the **raw** contents of [`wri-gui.ps1`](./wri-gui.ps1) as text at
the site root (`Content-Type: text/plain` is ideal; `iex` will also accept
`text/html` as long as the body is only the script).

Options:

- Serve `wri-gui.ps1` directly as the root document, or
- Redirect `/` to the raw file (e.g. GitHub raw, a CDN, or your own host).

The self-elevation step re-runs the same one-liner, so keep the URL stable.

## Safety notes

- The script is deliberately plain — no obfuscation, no persistence, nothing
  hidden. Read it before you run it; `irm | iex` runs whatever the URL
  returns.
- All downloads come from `microsoft.com` / `aka.ms` / `go.microsoft.com`.
- It never restarts your PC without you clicking **Yes**, and the restart
  uses a 60-second countdown you can cancel with `shutdown /a`.

## License

MIT — see [`LICENSE`](./LICENSE).
