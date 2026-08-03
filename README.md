# Windows Runtime Installer (WRI-GUI)

Installs the common Microsoft runtimes that a lot of Windows software —
especially games — needs to run: the full range of Visual C++
Redistributables, .NET, DirectX and more. Pick what you want from a simple
window and it downloads and installs everything for you, straight from
Microsoft.

## How to run it

1. Press **Start**, type **PowerShell**.
2. **Right-click Windows PowerShell → Run as administrator.**
3. Paste this and press Enter:

   ```powershell
   irm https://wri-gui.top | iex
   ```

A window opens. Tick the runtimes you want (or use a preset button), click
**Install Selected**, and wait for it to finish. Administrator rights are
required because installing system runtimes needs them.

## Using the window

- **Tabs** — the runtimes are grouped into **Visual C++**, **.NET Framework
  & Runtime**, and **Extras**.
- **Already installed items are greyed out** — the installer checks your PC
  first and won't reinstall things you already have.
- **Preset buttons** so you don't have to tick everything by hand:
  - **Select All** / **Select None**
  - **VC++ Only** — every Visual C++ Redistributable
  - **Essentials** — Visual C++ + DirectX
  - **Gaming** — Visual C++ + DirectX + OpenAL + XNA
- A progress bar and a log show what's downloading and installing.
- When it's done, or when you close the window, it will recommend a
  **restart** so every program picks up the new runtime files. It never
  restarts without you clicking **Yes**.

## What it can install

| Tab | Runtimes |
|-----|----------|
| **Visual C++** | 2005, 2008, 2010, 2012, 2013, and 2015–2022 — each in both 32-bit and 64-bit |
| **.NET** | .NET Framework 3.5, .NET Framework 4.8, and .NET Desktop Runtime 6 / 8 / 9 |
| **Extras** | DirectX End-User Runtime (June 2010), OpenAL, XNA Framework 4.0 |

Everything is downloaded from Microsoft (and `openal.org` for OpenAL).

## If your antivirus warns about it

Because the command downloads and runs installers, some antivirus tools
(including Windows Defender/SmartScreen) may warn about it or block it. That
warning is about *the kind of command it is*, not because it contains
anything harmful — it only downloads official Microsoft runtimes. If you
trust this source, you can allow it in your antivirus and run it again. If
you'd rather not, you can always install any of these runtimes manually from
Microsoft's website.

## Is it safe?

- It only downloads runtimes from Microsoft's own servers.
- It doesn't change any system settings, doesn't run in the background, and
  doesn't stay on your PC after it closes.
- Every download is checked to be a real installer before it runs.
- The command runs whatever the website sends, so — as with any
  `irm … | iex` command — only run it if you trust the source.

## License

MIT.
