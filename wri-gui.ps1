<#
    WRI-GUI  -  Windows Runtime Installer (GUI)
    https://wri-gui.top

    One-liner usage (from an elevated or normal PowerShell prompt):

        irm https://wri-gui.top | iex

    What it does
    ------------
    * Presents a GUI where you tick the runtimes you want.
    * Detects what is already installed and shows it, so you don't
      reinstall things you already have.
    * Covers the full range of Microsoft Visual C++ Redistributables
      (2005, 2008, 2010, 2012, 2013 and 2015-2022, both x86 and x64)
      plus a few common extras (DirectX runtime, .NET Framework 4.8).
    * Downloads each package straight from Microsoft and installs it
      silently.
    * When you close the window it recommends a restart so freshly
      installed runtimes are picked up by every process.

    This script is intentionally transparent: no obfuscation, no
    persistence, no hidden behaviour. Read it before you run it.
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# --------------------------------------------------------------------------
#  Self-elevation
# --------------------------------------------------------------------------
# Installing runtimes requires administrator rights. Because the script is
# usually piped straight from the web (irm ... | iex) there is no local file
# to re-launch, so we re-run the same one-liner in an elevated PowerShell.
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host 'Administrator rights are required. Re-launching elevated...' -ForegroundColor Yellow
    $bootstrap = 'irm https://wri-gui.top | iex'
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-Command', $bootstrap
        ) | Out-Null
    } catch {
        Write-Host 'Elevation was cancelled. Please run PowerShell as Administrator and try again.' -ForegroundColor Red
    }
    return
}

# --------------------------------------------------------------------------
#  Load Windows Forms
# --------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --------------------------------------------------------------------------
#  Runtime catalogue
# --------------------------------------------------------------------------
# Each entry describes one installable package:
#   Id       - stable identifier
#   Name     - text shown in the GUI
#   Category - grouping header
#   Arch     - x86 / x64  (used to preselect sensible defaults)
#   Url      - download location (Microsoft)
#   Silent   - silent-install arguments
#   Match    - regex matched against installed programs' DisplayName
#   NotMatch - optional regex that must NOT match (keeps x86 from matching x64)
#   RegKey / RegValue - optional extra detection via a registry value
$script:Catalogue = @(
    # ---- Visual C++ 2005 ----
    @{ Id='vc2005x86'; Name='Visual C++ 2005 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE'
       Silent='/q'; Match='Microsoft Visual C\+\+ 2005 Redistributable'; NotMatch='x64' }
    @{ Id='vc2005x64'; Name='Visual C++ 2005 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://download.microsoft.com/download/9/1/4/914851c6-9141-443b-bdb4-8bad3a57bea9/vcredist_x64.EXE'
       Silent='/q'; Match='Microsoft Visual C\+\+ 2005 Redistributable.*x64' }

    # ---- Visual C++ 2008 ----
    @{ Id='vc2008x86'; Name='Visual C++ 2008 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe'
       Silent='/qb'; Match='Microsoft Visual C\+\+ 2008 Redistributable.*x86'; NotMatch='x64' }
    @{ Id='vc2008x64'; Name='Visual C++ 2008 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'
       Silent='/qb'; Match='Microsoft Visual C\+\+ 2008 Redistributable.*x64' }

    # ---- Visual C++ 2010 ----
    @{ Id='vc2010x86'; Name='Visual C++ 2010 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe'
       Silent='/q /norestart'; Match='Microsoft Visual C\+\+ 2010.*x86.*Redistributable'; NotMatch='x64' }
    @{ Id='vc2010x64'; Name='Visual C++ 2010 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe'
       Silent='/q /norestart'; Match='Microsoft Visual C\+\+ 2010.*x64.*Redistributable' }

    # ---- Visual C++ 2012 (Update 4) ----
    @{ Id='vc2012x86'; Name='Visual C++ 2012 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
       Silent='/install /quiet /norestart'; Match='Microsoft Visual C\+\+ 2012 Redistributable \(x86\)' }
    @{ Id='vc2012x64'; Name='Visual C++ 2012 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'
       Silent='/install /quiet /norestart'; Match='Microsoft Visual C\+\+ 2012 Redistributable \(x64\)' }

    # ---- Visual C++ 2013 ----
    @{ Id='vc2013x86'; Name='Visual C++ 2013 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://aka.ms/highdpimfc2013x86enu'
       Silent='/install /quiet /norestart'; Match='Microsoft Visual C\+\+ 2013 Redistributable \(x86\)' }
    @{ Id='vc2013x64'; Name='Visual C++ 2013 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://aka.ms/highdpimfc2013x64enu'
       Silent='/install /quiet /norestart'; Match='Microsoft Visual C\+\+ 2013 Redistributable \(x64\)' }

    # ---- Visual C++ 2015-2022 (latest v14x, supersedes 2015/2017/2019) ----
    @{ Id='vc2015_2022x86'; Name='Visual C++ 2015-2022 Redistributable (x86)'; Category='Visual C++ Redistributables'; Arch='x86'
       Url='https://aka.ms/vs/17/release/vc_redist.x86.exe'
       Silent='/install /quiet /norestart'
       Match='Microsoft Visual C\+\+ (2015|2017|2019|2022|2015-20\d\d) Redistributable \(x86\)'
       RegKey='HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86'; RegValue='Installed' }
    @{ Id='vc2015_2022x64'; Name='Visual C++ 2015-2022 Redistributable (x64)'; Category='Visual C++ Redistributables'; Arch='x64'
       Url='https://aka.ms/vs/17/release/vc_redist.x64.exe'
       Silent='/install /quiet /norestart'
       Match='Microsoft Visual C\+\+ (2015|2017|2019|2022|2015-20\d\d) Redistributable \(x64\)'
       RegKey='HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'; RegValue='Installed' }

    # ---- Extras ----
    @{ Id='dotnet48'; Name='.NET Framework 4.8'; Category='Other runtimes'; Arch='x64'
       Url='https://go.microsoft.com/fwlink/?linkid=2088631'
       Silent='/q /norestart'; Match='Microsoft \.NET Framework 4\.8'
       RegKey='HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'; RegValue='Release'; RegMin=528040 }
    @{ Id='directx'; Name='DirectX End-User Runtime (web)'; Category='Other runtimes'; Arch='x86'
       Url='https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe'
       Silent='/Q'; Match='__never__'  # DirectX web installer always runs; it no-ops when current
       AlwaysOffer=$true }
)

# --------------------------------------------------------------------------
#  Detection
# --------------------------------------------------------------------------
# Cache the installed-programs list once (reading the registry per item is slow).
function Get-InstalledPrograms {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($path in $paths) {
        try {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                ForEach-Object { $names.Add([string]$_.DisplayName) }
        } catch { }
    }
    return $names
}

function Test-RuntimeInstalled {
    param($Item, [string[]]$Installed)

    # DirectX web installer has no reliable single registry marker; treat as
    # always-offer (it self-detects and no-ops when nothing is needed).
    if ($Item.AlwaysOffer) { return $false }

    # Extra registry-value based detection (e.g. VC 14 Runtimes / .NET release).
    if ($Item.RegKey) {
        try {
            $val = (Get-ItemProperty -Path $Item.RegKey -Name $Item.RegValue -ErrorAction Stop).$($Item.RegValue)
            if ($null -ne $val) {
                if ($Item.ContainsKey('RegMin')) {
                    if ([int]$val -ge [int]$Item.RegMin) { return $true }
                } elseif ([int]$val -ge 1) {
                    return $true
                }
            }
        } catch { }
    }

    # DisplayName regex match against installed programs.
    foreach ($name in $Installed) {
        if ($name -match $Item.Match) {
            if ($Item.NotMatch -and ($name -match $Item.NotMatch)) { continue }
            return $true
        }
    }
    return $false
}

# --------------------------------------------------------------------------
#  Install a single package
# --------------------------------------------------------------------------
function Install-Runtime {
    param($Item, [scriptblock]$Log)

    $tmp = Join-Path $env:TEMP ("wri_" + $Item.Id + [IO.Path]::GetExtension($Item.Url))
    if ([string]::IsNullOrWhiteSpace([IO.Path]::GetExtension($tmp)) -or [IO.Path]::GetExtension($tmp).Length -gt 5) {
        $tmp = Join-Path $env:TEMP ("wri_" + $Item.Id + '.exe')
    }

    & $Log ("Downloading {0} ..." -f $Item.Name)
    try {
        $old = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Item.Url -OutFile $tmp -UseBasicParsing
        $ProgressPreference = $old
    } catch {
        & $Log ("  ! Download failed: {0}" -f $_.Exception.Message)
        return $false
    }

    & $Log ("Installing {0} ..." -f $Item.Name)
    try {
        $p = Start-Process -FilePath $tmp -ArgumentList $Item.Silent -Wait -PassThru
        $code = $p.ExitCode
    } catch {
        & $Log ("  ! Install failed to start: {0}" -f $_.Exception.Message)
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        return $false
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }

    # 0 = success, 3010 = success but reboot required, 1638 = newer already installed
    switch ($code) {
        0     { & $Log ("  + Installed {0}" -f $Item.Name); return $true }
        3010  { & $Log ("  + Installed {0} (reboot required)" -f $Item.Name); $script:RebootNeeded = $true; return $true }
        1638  { & $Log ("  = A newer version of {0} is already present" -f $Item.Name); return $true }
        default { & $Log ("  ! {0} exit code {1}" -f $Item.Name, $code); return $false }
    }
}

# --------------------------------------------------------------------------
#  Build the GUI
# --------------------------------------------------------------------------
$script:RebootNeeded = $false
$script:DidInstall   = $false

$installed = Get-InstalledPrograms

$form = New-Object System.Windows.Forms.Form
$form.Text          = 'WRI-GUI  -  Windows Runtime Installer'
$form.Size          = New-Object System.Drawing.Size(640, 620)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize   = New-Object System.Drawing.Size(560, 520)
$form.BackColor     = [System.Drawing.Color]::FromArgb(245, 246, 248)
$form.Font          = New-Object System.Drawing.Font('Segoe UI', 9)

$header = New-Object System.Windows.Forms.Label
$header.Text      = 'Windows Runtime Installer'
$header.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 15)
$header.AutoSize  = $true
$header.Location  = New-Object System.Drawing.Point(16, 12)
$form.Controls.Add($header)

$sub = New-Object System.Windows.Forms.Label
$sub.Text     = 'Tick the runtimes you want, then click Install. Already-installed items are greyed out.'
$sub.AutoSize = $false
$sub.Size     = New-Object System.Drawing.Size(600, 20)
$sub.Location = New-Object System.Drawing.Point(18, 46)
$sub.ForeColor= [System.Drawing.Color]::FromArgb(90, 90, 96)
$form.Controls.Add($sub)

# Scrollable panel that holds the checkboxes
$panel = New-Object System.Windows.Forms.Panel
$panel.Location    = New-Object System.Drawing.Point(16, 74)
$panel.Size        = New-Object System.Drawing.Size(596, 320)
$panel.AutoScroll  = $true
$panel.BorderStyle = 'FixedSingle'
$panel.BackColor   = [System.Drawing.Color]::White
$panel.Anchor      = 'Top,Left,Right,Bottom'
$form.Controls.Add($panel)

$osArch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }

$script:CheckBoxes = @()
$y = 8
$lastCategory = ''
foreach ($item in $script:Catalogue) {
    if ($item.Category -ne $lastCategory) {
        $lastCategory = $item.Category
        $cat = New-Object System.Windows.Forms.Label
        $cat.Text     = $item.Category
        $cat.Font     = New-Object System.Drawing.Font('Segoe UI Semibold', 10)
        $cat.ForeColor= [System.Drawing.Color]::FromArgb(0, 90, 158)
        $cat.AutoSize = $true
        $cat.Location = New-Object System.Drawing.Point(10, $y)
        $panel.Controls.Add($cat)
        $y += 26
    }

    $isInstalled = Test-RuntimeInstalled -Item $item -Installed $installed

    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.AutoSize = $false
    $cb.Size     = New-Object System.Drawing.Size(540, 22)
    $cb.Location = New-Object System.Drawing.Point(24, $y)
    $cb.Tag      = $item
    if ($isInstalled) {
        $cb.Text    = ("{0}   -  installed" -f $item.Name)
        $cb.Checked = $false
        $cb.Enabled = $false
        $cb.ForeColor = [System.Drawing.Color]::FromArgb(120, 140, 120)
    } else {
        $cb.Text    = $item.Name
        # Preselect packages that match the OS architecture (x86 always useful).
        $cb.Checked = ($item.Arch -eq $osArch -or $item.Arch -eq 'x86')
    }
    $panel.Controls.Add($cb)
    $script:CheckBoxes += $cb
    $y += 26
}

# Select All / None buttons
$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text     = 'Select all'
$btnAll.Size     = New-Object System.Drawing.Size(90, 28)
$btnAll.Location = New-Object System.Drawing.Point(16, 402)
$btnAll.Anchor   = 'Left,Bottom'
$btnAll.Add_Click({ foreach ($c in $script:CheckBoxes) { if ($c.Enabled) { $c.Checked = $true } } })
$form.Controls.Add($btnAll)

$btnNone = New-Object System.Windows.Forms.Button
$btnNone.Text     = 'Select none'
$btnNone.Size     = New-Object System.Drawing.Size(90, 28)
$btnNone.Location = New-Object System.Drawing.Point(112, 402)
$btnNone.Anchor   = 'Left,Bottom'
$btnNone.Add_Click({ foreach ($c in $script:CheckBoxes) { if ($c.Enabled) { $c.Checked = $false } } })
$form.Controls.Add($btnNone)

# Log box
$log = New-Object System.Windows.Forms.TextBox
$log.Multiline   = $true
$log.ScrollBars  = 'Vertical'
$log.ReadOnly    = $true
$log.Location    = New-Object System.Drawing.Point(16, 438)
$log.Size        = New-Object System.Drawing.Size(596, 90)
$log.Anchor      = 'Left,Right,Bottom'
$log.BackColor   = [System.Drawing.Color]::FromArgb(30, 30, 34)
$log.ForeColor   = [System.Drawing.Color]::FromArgb(210, 210, 210)
$log.Font        = New-Object System.Drawing.Font('Consolas', 8.5)
$form.Controls.Add($log)

$logWriter = {
    param($msg)
    $log.AppendText((Get-Date -Format 'HH:mm:ss') + '  ' + $msg + "`r`n")
    $log.SelectionStart = $log.Text.Length
    $log.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}.GetNewClosure()

# Install button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text      = 'Install selected'
$btnInstall.Size      = New-Object System.Drawing.Size(150, 34)
$btnInstall.Location  = New-Object System.Drawing.Point(462, 536)
$btnInstall.Anchor    = 'Right,Bottom'
$btnInstall.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnInstall.ForeColor = [System.Drawing.Color]::White
$btnInstall.FlatStyle = 'Flat'
$btnInstall.Font      = New-Object System.Drawing.Font('Segoe UI Semibold', 9.5)
$form.Controls.Add($btnInstall)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text     = 'Close'
$btnClose.Size     = New-Object System.Drawing.Size(90, 34)
$btnClose.Location = New-Object System.Drawing.Point(364, 536)
$btnClose.Anchor   = 'Right,Bottom'
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

$btnInstall.Add_Click({
    $selected = @($script:CheckBoxes | Where-Object { $_.Enabled -and $_.Checked } | ForEach-Object { $_.Tag })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Nothing selected. Tick at least one runtime.', 'WRI-GUI',
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }

    $btnInstall.Enabled = $false; $btnAll.Enabled = $false; $btnNone.Enabled = $false
    & $logWriter ("Starting install of {0} package(s)..." -f $selected.Count)

    $ok = 0; $fail = 0
    foreach ($item in $selected) {
        if (Install-Runtime -Item $item -Log $logWriter) { $ok++ } else { $fail++ }
    }
    $script:DidInstall = $true
    & $logWriter ("Done. {0} succeeded, {1} failed." -f $ok, $fail)

    # Refresh the list so newly-installed items grey out.
    $fresh = Get-InstalledPrograms
    foreach ($c in $script:CheckBoxes) {
        if (Test-RuntimeInstalled -Item $c.Tag -Installed $fresh) {
            $c.Checked = $false; $c.Enabled = $false
            $c.Text = ("{0}   -  installed" -f $c.Tag.Name)
            $c.ForeColor = [System.Drawing.Color]::FromArgb(120, 140, 120)
        }
    }

    $btnInstall.Enabled = $true; $btnAll.Enabled = $true; $btnNone.Enabled = $true
})

# --------------------------------------------------------------------------
#  Restart recommendation when the window closes
# --------------------------------------------------------------------------
$form.Add_FormClosing({
    if (-not $script:DidInstall) { return }

    $msg = "Runtimes were installed.`r`n`r`n" +
           "A restart is recommended so every program picks up the new " +
           "runtime files. Some installers also flagged that a reboot is " +
           "required to finish.`r`n`r`n" +
           "Restart now? (You'll get a 60-second countdown you can cancel " +
           "by running:  shutdown /a )"

    $res = [System.Windows.Forms.MessageBox]::Show(
        $msg, 'Restart recommended',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1)

    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Start-Process -FilePath 'shutdown.exe' -ArgumentList '/r','/t','60','/c','"Restarting to finish installing runtimes (run: shutdown /a  to cancel)"' -WindowStyle Hidden
        } catch { }
    }
})

# --------------------------------------------------------------------------
#  Show it
# --------------------------------------------------------------------------
[void]$form.ShowDialog()
