# ==================================================
# Windows Runtime Installer (WRI) - GUI Edition
# VC++ 2005-2022 + DirectX + .NET + More
# Works with PowerShell 5.1+ or PowerShell 7+
# ==================================================

# Require admin elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $null }

    if ($scriptPath) {
        # Saved as a .ps1 file - relaunch that file elevated. This is the same
        # elevation the original script used and is not what antivirus objects
        # to (it runs a local file, not a re-download).
        try {
            $shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
            Start-Process $shell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        } catch { }
    } else {
        # Piped from the web (irm | iex) with no file on disk. Deliberately do
        # NOT auto-elevate here by re-downloading and re-running ourselves -
        # that self-re-download-with-bypass pattern is what antivirus flags as
        # dropper behaviour. Ask the user to start an elevated PowerShell.
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "This installer needs to run as Administrator.`n`n" +
            "1. Press Start and type: PowerShell`n" +
            "2. Right-click Windows PowerShell and choose 'Run as administrator'`n" +
            "3. Paste and run:  irm https://wri-gui.top | iex",
            "Administrator required", "OK", "Information") | Out-Null
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# =====================
# Redistributable Data (inline - no external dependency)
# =====================
# NOTE: the x86 and x64 arrays are index-paired: entry N in x86 and entry N
# in x64 are the same product, and the installer walks them by index.
$Redists = @{
    x86 = @(
        @{ Name="Visual C++ 2005";      Version="8.0.61001";  Url="https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE"; Args="/q" }
        @{ Name="Visual C++ 2008";      Version="9.0.30729";  Url="https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"; Args="/qb" }
        @{ Name="Visual C++ 2010";      Version="10.0.40219"; Url="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"; Args="/q /norestart" }
        @{ Name="Visual C++ 2012";      Version="11.0.61030"; Url="https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"; Args="/install /quiet /norestart" }
        @{ Name="Visual C++ 2013";      Version="12.0.40664"; Url="https://aka.ms/highdpimfc2013x86enu"; Args="/install /quiet /norestart" }
        @{ Name="Visual C++ 2015-2022"; Version="14.x";       Url="https://aka.ms/vs/17/release/vc_redist.x86.exe"; Args="/install /quiet /norestart" }
    )
    x64 = @(
        @{ Name="Visual C++ 2005";      Version="8.0.61001";  Url="https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE"; Args="/q" }
        @{ Name="Visual C++ 2008";      Version="9.0.30729";  Url="https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"; Args="/qb" }
        @{ Name="Visual C++ 2010";      Version="10.0.40219"; Url="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"; Args="/q /norestart" }
        @{ Name="Visual C++ 2012";      Version="11.0.61030"; Url="https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"; Args="/install /quiet /norestart" }
        @{ Name="Visual C++ 2013";      Version="12.0.40664"; Url="https://aka.ms/highdpimfc2013x64enu"; Args="/install /quiet /norestart" }
        @{ Name="Visual C++ 2015-2022"; Version="14.x";       Url="https://aka.ms/vs/17/release/vc_redist.x64.exe"; Args="/install /quiet /norestart" }
    )
    dotnet = @(
        @{ Name=".NET Framework 3.5";  Version="3.5";   Type="framework"; IsDism=$true; Args="" }
        @{ Name=".NET Framework 4.8";  Version="4.8";   Type="framework"; Url="https://go.microsoft.com/fwlink/?linkid=2088631"; Args="/q /norestart" }
        @{ Name=".NET Desktop Runtime 6"; Version="6.0"; Type="runtime"
           Url_x86="https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x86.exe"
           Url_x64="https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x64.exe"; Args="/install /quiet /norestart" }
        @{ Name=".NET Desktop Runtime 8"; Version="8.0"; Type="runtime"
           Url_x86="https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x86.exe"
           Url_x64="https://aka.ms/dotnet/8.0/windowsdesktop-runtime-win-x64.exe"; Args="/install /quiet /norestart" }
        @{ Name=".NET Desktop Runtime 9"; Version="9.0"; Type="runtime"
           Url_x86="https://aka.ms/dotnet/9.0/windowsdesktop-runtime-win-x86.exe"
           Url_x64="https://aka.ms/dotnet/9.0/windowsdesktop-runtime-win-x64.exe"; Args="/install /quiet /norestart" }
    )
    extras = @(
        @{ Name="DirectX End-User Runtime (June 2010)"; Version="9.29.1974"; IsDirectX=$true
           Url="https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"; Args="" }
        @{ Name="OpenAL"; Version="2.1.0.0"; IsOpenAL=$true
           Url="https://openal.org/downloads/oalinst.zip"; Args="/silent" }
        @{ Name="XNA Framework Redistributable 4.0"; Version="4.0.20823"; IsMsi=$true
           Url="https://download.microsoft.com/download/A/C/2/AC2C903B-E6E8-42C2-9FD7-BEBAC362A930/xnafx40_redist.msi"; Args="/quiet /norestart" }
    )
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:failures = @()
$script:installCompleted = $false

function Test-VCRedistInstalled {
    param([string]$Name)

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths) {
        foreach ($item in Get-ItemProperty $path -ErrorAction SilentlyContinue) {

            if (-not $item.DisplayName) { continue }

            # Normalize both strings for safer matching
            $installed = $item.DisplayName.ToLower()
            $target    = $Name.ToLower()

            if ($installed -like "*$target*") {
                return $true
            }

            # Special case: 2015–2022 unified runtime
            if ($target -match "2015" -and $installed -match "2015|2017|2019|2022") {
                # VCRUNTIME140_1.dll was added in v14.28 (VS2019 16.8); an old 2015
                # install won't have it even though the name matches, so check the DLL.
                if ((Test-Path "$env:SystemRoot\System32\VCRUNTIME140_1.dll") -or
                    (Test-Path "$env:SystemRoot\SysWOW64\VCRUNTIME140_1.dll")) {
                    return $true
                }
            }
        }
    }

    return $false
}


function Test-DotNetRuntimeInstalled {
    param([string]$Major)

    $keys = @(
        "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.NETCore.App",
        "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.NETCore.App",
        "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App",
        "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.WindowsDesktop.App",
        "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.NETCore.App",
        "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.NETCore.App",
        "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App",
        "HKLM:\SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x86\sharedfx\Microsoft.WindowsDesktop.App"
    )

    foreach ($key in $keys) {
        if (Test-Path $key) {
            $values = (Get-ItemProperty $key | Get-Member -MemberType NoteProperty).Name
            foreach ($v in $values) {
                if ($v -match "^$Major\.") {
                    return $true
                }
            }
        }
    }

    return $false
}

function Test-DirectXInstalled {
    $dxFiles = @(
        "$env:WINDIR\System32\d3dx9_43.dll",
        "$env:WINDIR\SysWOW64\d3dx9_43.dll",
        "$env:WINDIR\System32\XAudio2_7.dll",
        "$env:WINDIR\SysWOW64\XAudio2_7.dll"
    )

    foreach ($file in $dxFiles) {
        if (Test-Path $file) {
            return $true
        }
    }

    return $false
}

function Test-ProgramInstalled {
    param([string]$DisplayName)

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths) {
        foreach ($item in Get-ItemProperty $path -ErrorAction SilentlyContinue) {
            if ($item.DisplayName -and $item.DisplayName -like "*$DisplayName*") {
                return $true
            }
        }
    }
    return $false
}

function Test-DotNetFramework35Installed {
    $key = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
    if (Test-Path $key) {
        $p = Get-ItemProperty $key -ErrorAction SilentlyContinue
        return ($p.Install -eq 1)
    }
    return $false
}

function Test-DotNetFramework4Installed {
    param([int]$MinRelease = 0)

    $base = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4"

    if (Test-Path "$base\Full") {
        $p = Get-ItemProperty "$base\Full" -ErrorAction SilentlyContinue
        if ($p.Install -eq 1 -and $p.Release -ge $MinRelease) { return $true }
    }

    return $false
}


# =====================
# Main Form
# =====================
$form = New-Object System.Windows.Forms.Form
$form.Text = "AG Windows Runtime Installer (WRI) GUI"
$form.Size = New-Object System.Drawing.Size(700, 720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "AG Windows Runtime Installer GUI"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 219)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(0, 12)
$form.Controls.Add($titleLabel)

# Center horizontally
$titleLabel.Left = ($form.ClientSize.Width - $titleLabel.Width) / 2


$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "VC++ / DirectX / .NET Runtimes / Extras"
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = New-Object System.Drawing.Point(0, 48)
$form.Controls.Add($subtitleLabel)
$subtitleLabel.Left = ($form.ClientSize.Width - $subtitleLabel.Width) / 2


$headerPanel = New-Object System.Windows.Forms.TableLayoutPanel
$headerPanel.Size = New-Object System.Drawing.Size($form.ClientSize.Width, 20)
$headerPanel.Location = New-Object System.Drawing.Point(0, 68)
$headerPanel.ColumnCount = 3
$headerPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "Percent", 33))
$headerPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "Percent", 34))
$headerPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle "Percent", 33))

$adminLabel = New-Object System.Windows.Forms.Label
$adminLabel.Text = "[OK] Running as Administrator"
$adminLabel.ForeColor = [System.Drawing.Color]::FromArgb(0,180,0)
$adminLabel.Anchor = "None"
$adminLabel.AutoSize = $true

$headerPanel.Controls.Add($adminLabel, 1, 0)
$form.Controls.Add($headerPanel)


$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(20, 95)
$tabControl.Size = New-Object System.Drawing.Size(640, 405)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($tabControl)

$installPanel = New-Object System.Windows.Forms.Panel
$installHeader = New-Object System.Windows.Forms.Label
$installHeader.Text = "Installing Windows Runtime Components"
$installHeader.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$installHeader.ForeColor = [System.Drawing.Color]::FromArgb(0,174,219)
$installHeader.AutoSize = $true
$installHeader.Location = New-Object System.Drawing.Point(0, 0)
$installHeader.Left = ($installPanel.Width - $installHeader.Width) / 2
$installPanel.Controls.Add($installHeader)
$installPanel.Location = $tabControl.Location
$installPanel.Size = $tabControl.Size
$installPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$installPanel.Visible = $false
$form.Controls.Add($installPanel)

$form.Add_Shown({
    $installHeader.Left = ($installPanel.ClientSize.Width - $installHeader.Width) / 2
})


$tabVC = New-Object System.Windows.Forms.TabPage
$tabVC.Text = "  Visual C++  "
$tabVC.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

$tabDotNet = New-Object System.Windows.Forms.TabPage
$tabDotNet.Text = "  .NET Framework & Runtime  "
$tabDotNet.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

$tabExtras = New-Object System.Windows.Forms.TabPage
$tabExtras.Text = "  Extras  "
$tabExtras.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

$tabControl.TabPages.AddRange(@($tabVC, $tabDotNet, $tabExtras))

$script:allCheckboxes = @()

function Add-RuntimeCheckbox {
    param($Parent, $Name, $Version, $Y, $Tag)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = "$Name"
    $cb.Tag = $Tag
    $cb.Location = New-Object System.Drawing.Point(20, $Y)
    $cb.Size = New-Object System.Drawing.Size(300, 22)
    $cb.ForeColor = [System.Drawing.Color]::White
    $cb.FlatStyle = "Flat"
    [void]$Parent.Controls.Add($cb)
    
    $verLabel = New-Object System.Windows.Forms.Label
    $verLabel.Text = "v$Version"
    $verLabel.Location = New-Object System.Drawing.Point(330, ($Y + 2))
    $verLabel.Size = New-Object System.Drawing.Size(180, 20)
    $verLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    [void]$Parent.Controls.Add($verLabel)
    $installed = $false

	switch ($Tag.Type) {
		"VC" {
			$installed = Test-VCRedistInstalled $Name
		}

		"DotNetFramework" {
			switch ($Name) {
				".NET Framework 3.5"  { $installed = Test-DotNetFramework35Installed }
				".NET Framework 4.7.2" { $installed = Test-DotNetFramework4Installed -MinRelease 461808 }
				".NET Framework 4.8"   { $installed = Test-DotNetFramework4Installed -MinRelease 528040 }
				default { $installed = $false }
			}
		}

		"DotNetRuntime" {
			$major = ($Version -split '\.')[0]
			$installed = Test-DotNetRuntimeInstalled $major
        }
		"Extra" {
			if ($Tag.IsDirectX) {
				$installed = Test-DirectXInstalled
			} else {
				$installed = Test-ProgramInstalled $Name
			}
		}
	}


	if ($installed) {
		$cb.Checked = $false
		$cb.Enabled = $false
		$cb.Text += " (Installed)"
		$cb.ForeColor = [System.Drawing.Color]::Gray
	}

    $script:allCheckboxes += $cb
}

# Visual C++ Tab
$vcLabel = New-Object System.Windows.Forms.Label
$vcLabel.Text = "Visual C++ Redistributables (x86 + x64)"
$vcLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$vcLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 219)
$vcLabel.Location = New-Object System.Drawing.Point(20, 15)
$vcLabel.AutoSize = $true
$tabVC.Controls.Add($vcLabel)

$yPos = 50
for ($i = 0; $i -lt $Redists.x86.Count; $i++) {
    $item = $Redists.x86[$i]
    Add-RuntimeCheckbox -Parent $tabVC -Name $item.Name -Version $item.Version -Y $yPos -Tag @{Type="VC"; Index=$i}
    $yPos += 32
}

# .NET Tab
$dotnetLabel = New-Object System.Windows.Forms.Label
$dotnetLabel.Text = ".NET Framework and Runtime"
$dotnetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$dotnetLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 219)
$dotnetLabel.Location = New-Object System.Drawing.Point(20, 15)
$dotnetLabel.AutoSize = $true
$tabDotNet.Controls.Add($dotnetLabel)

$yPos = 50
for ($i = 0; $i -lt $Redists.dotnet.Count; $i++) {
    $item = $Redists.dotnet[$i]
    $dotnetType = if ($item.type -eq "framework") { "DotNetFramework" } else { "DotNetRuntime" }

Add-RuntimeCheckbox -Parent $tabDotNet -Name $item.Name -Version $item.Version -Y $yPos -Tag @{
    Type  = $dotnetType
    Index = $i
}
    $yPos += 32
}

# Extras Tab
$extrasLabel = New-Object System.Windows.Forms.Label
$extrasLabel.Text = "DirectX, OpenAL, XNA and More"
$extrasLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$extrasLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 174, 219)
$extrasLabel.Location = New-Object System.Drawing.Point(20, 15)
$extrasLabel.AutoSize = $true
$tabExtras.Controls.Add($extrasLabel)

$yPos = 50
for ($i = 0; $i -lt $Redists.extras.Count; $i++) {
    $item = $Redists.extras[$i]
    $ver = if ($item.Version) { $item.Version } else { "Latest" }
    Add-RuntimeCheckbox -Parent $tabExtras -Name $item.Name -Version $ver -Y $yPos -Tag @{
		Type = "Extra"
		Index = $i
		IsDirectX = $item.IsDirectX
	}

    $yPos += 32
}

# Bottom Panel
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(20, 510)
$bottomPanel.Size = New-Object System.Drawing.Size(640, 160)
$bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
$form.Controls.Add($bottomPanel)

$installStartBtn = New-Object System.Windows.Forms.Button
$installStartBtn.Text = "Install Selected"
$installStartBtn.Location = New-Object System.Drawing.Point(180, 60)
$installStartBtn.Size = New-Object System.Drawing.Size(200, 45)
$installStartBtn.FlatStyle = "Flat"
$installStartBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$installStartBtn.ForeColor = [System.Drawing.Color]::White
$installStartBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$installStartBtn.FlatAppearance.BorderSize = 0
$bottomPanel.Controls.Add($installStartBtn)
$installStartBtn.Left = ($bottomPanel.Width - $installStartBtn.Width) / 2

$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "Select All"
$selectAllBtn.Location = New-Object System.Drawing.Point(0, 0)
$selectAllBtn.Size = New-Object System.Drawing.Size(100, 30)
$selectAllBtn.FlatStyle = "Flat"
$selectAllBtn.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$selectAllBtn.ForeColor = [System.Drawing.Color]::White
$selectAllBtn.Add_Click({ $script:allCheckboxes |
Where-Object { $_.Enabled } |
ForEach-Object { $_.Checked = $true } | Out-Null })
$bottomPanel.Controls.Add($selectAllBtn)

$selectNoneBtn = New-Object System.Windows.Forms.Button
$selectNoneBtn.Text = "Select None"
$selectNoneBtn.Location = New-Object System.Drawing.Point(110, 0)
$selectNoneBtn.Size = New-Object System.Drawing.Size(100, 30)
$selectNoneBtn.FlatStyle = "Flat"
$selectNoneBtn.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$selectNoneBtn.ForeColor = [System.Drawing.Color]::White
$selectNoneBtn.Add_Click({ $script:allCheckboxes | Where-Object { $_.Enabled } | ForEach-Object { $_.Checked = $false } | Out-Null })
$bottomPanel.Controls.Add($selectNoneBtn)

$selectVCBtn = New-Object System.Windows.Forms.Button
$selectVCBtn.Text = "VC++ Only"
$selectVCBtn.Size = New-Object System.Drawing.Size(120, 30)
$selectVCBtn.FlatStyle = "Flat"
$selectVCBtn.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$selectVCBtn.ForeColor = [System.Drawing.Color]::White
$selectVCBtn.Add_Click({
    $script:allCheckboxes |
        Where-Object {
            $_.Enabled -and $_.Tag.Type -eq "VC"
        } |
        ForEach-Object { $_.Checked = $true } | Out-Null
})

$bottomPanel.Controls.Add($selectVCBtn)

$selectEssentialBtn = New-Object System.Windows.Forms.Button
$selectEssentialBtn.Text = "Essentials"
$selectEssentialBtn.Location = New-Object System.Drawing.Point(220, 0)
$selectEssentialBtn.Size = New-Object System.Drawing.Size(110, 30)
$selectEssentialBtn.FlatStyle = "Flat"
$selectEssentialBtn.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$selectEssentialBtn.ForeColor = [System.Drawing.Color]::Cyan
$selectEssentialBtn.Add_Click({
    $script:allCheckboxes |
        Where-Object {
            $_.Enabled -and (
                $_.Tag.Type -eq "VC" -or
                $_.Text -match "DirectX"
            )
        } |
        ForEach-Object { $_.Checked = $true } | Out-Null
})
$bottomPanel.Controls.Add($selectEssentialBtn)

$selectGamingBtn = New-Object System.Windows.Forms.Button
$selectGamingBtn.Text = "Gaming"
$selectGamingBtn.Location = New-Object System.Drawing.Point(340, 0)
$selectGamingBtn.Size = New-Object System.Drawing.Size(100, 30)
$selectGamingBtn.FlatStyle = "Flat"
$selectGamingBtn.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$selectGamingBtn.ForeColor = [System.Drawing.Color]::Magenta
$selectGamingBtn.Add_Click({
    $script:allCheckboxes |
        Where-Object {
            $_.Enabled -and (
                $_.Tag.Type -eq "VC" -or
                $_.Text -match "DirectX|OpenAL|XNA"
            )
        } |
        ForEach-Object { $_.Checked = $true } | Out-Null
})

$bottomPanel.Controls.Add($selectGamingBtn)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Location = New-Object System.Drawing.Point(0, 45)
$progressLabel.Size = New-Object System.Drawing.Size(640, 25)
$progressLabel.TextAlign = "MiddleCenter"
$progressLabel.ForeColor = [System.Drawing.Color]::White
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$progressLabel.Text = "Idle"
$installPanel.Controls.Add($progressLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(0, 75)
$progressBar.Size = New-Object System.Drawing.Size(640, 25)
$progressBar.Style = "Continuous"
$installPanel.Controls.Add($progressBar)

$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(0, 110)
$statusBox.Size = New-Object System.Drawing.Size(640, 285)
$statusBox.ReadOnly = $true
$statusBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$statusBox.ForeColor = [System.Drawing.Color]::LightGreen
$statusBox.BorderStyle = "FixedSingle"
$statusBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$statusBox.ScrollBars = "Vertical"
$statusBox.Text = "Ready - Select items and click Install`r`n"
$installPanel.Controls.Add($statusBox)

$buttons = @(
    $selectAllBtn,
    $selectNoneBtn,
    $selectVCBtn,
    $selectEssentialBtn,
    $selectGamingBtn
)

$spacing = 10
$totalWidth = ($buttons | Measure-Object Width -Sum).Sum + ($spacing * ($buttons.Count - 1))
$startX = ($bottomPanel.Width - $totalWidth) / 2
$y = 0

foreach ($btn in $buttons) {
    $btn.Location = New-Object System.Drawing.Point($startX, $y)
    $startX += $btn.Width + $spacing
}

$form.Add_Shown({
    $installStartBtn.Left = ($bottomPanel.ClientSize.Width - $installStartBtn.Width) / 2
})

function Update-Status {
    param(
        [string]$Text,
        [string]$Color = "Green"
    )

    switch ($Color) {
        "Green"  { $statusBox.SelectionColor = [System.Drawing.Color]::LightGreen }
        "Yellow" { $statusBox.SelectionColor = [System.Drawing.Color]::Gold }
        "Red"    { $statusBox.SelectionColor = [System.Drawing.Color]::Tomato }
        "Cyan"   { $statusBox.SelectionColor = [System.Drawing.Color]::Cyan }
        default  { $statusBox.SelectionColor = [System.Drawing.Color]::White }
    }

    $statusBox.AppendText($Text + "`r`n")
    $statusBox.SelectionStart = $statusBox.Text.Length
    $statusBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Check-AllRedistsInstalled {
    return -not ($script:allCheckboxes | Where-Object { $_.Enabled })
}

function Install-Package { param([string]$Name, [string]$Url, [string]$Arguments, [bool]$IsMsi = $false, [bool]$IsDirectX = $false, [bool]$IsOpenAL = $false)

    Update-Status "Downloading $Name..." "Yellow"

    $webHeaders = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if ($IsDirectX) {
			$dxExe = Join-Path $env:TEMP "directx_jun2010_redist.exe"
			$dxRoot = Join-Path $env:TEMP "DX_REDIST"

			Invoke-WebRequest -Uri $Url -OutFile $dxExe -UseBasicParsing -Headers $webHeaders -ErrorAction Stop

			Update-Status "Extracting $Name..." "Cyan"

			if (Test-Path $dxRoot) { Remove-Item $dxRoot -Recurse -Force }
			New-Item -ItemType Directory -Path $dxRoot | Out-Null

			Start-Process -FilePath $dxExe -ArgumentList "/Q /T:`"$dxRoot`"" -Wait -WindowStyle Hidden

			$dxSetup = Get-ChildItem -Path $dxRoot -Filter DXSETUP.exe -Recurse | Select-Object -First 1

			if (-not $dxSetup) {
				throw "DXSETUP.exe not found after extraction"
			}

			Update-Status "Installing $Name..." "Cyan"
			Start-Process -FilePath $dxSetup.FullName -ArgumentList "/silent" -Wait -WindowStyle Hidden

			Remove-Item $dxExe -Force -ErrorAction SilentlyContinue
			Remove-Item $dxRoot -Recurse -Force -ErrorAction SilentlyContinue

			return @{ Success = $true; Message = "" }
		}

        
        if ($IsOpenAL) {
            $zipPath = Join-Path $env:TEMP "oalinst.zip"
            $extractPath = Join-Path $env:TEMP "OpenAL"
            Invoke-WebRequest -Uri $Url -OutFile $zipPath -UseBasicParsing -Headers $webHeaders -ErrorAction Stop
            Update-Status "Extracting $Name..." "Cyan"
            if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
            Update-Status "Installing $Name..." "Cyan"
            $installer = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Select-Object -First 1
            if ($installer) { $null = Start-Process -FilePath $installer.FullName -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden }
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            return @{Success=$true; Message=""}
        }
        
        $ext = if ($IsMsi) { ".msi" } else { ".exe" }
        $fileName = ($Name -replace '[^\w\-]', '_') + $ext
        $filePath = Join-Path $env:TEMP $fileName
		Invoke-WebRequest -Uri $Url -OutFile $filePath -UseBasicParsing -Headers $webHeaders -ErrorAction Stop

        $magic = [System.IO.File]::ReadAllBytes($filePath)
        if ($magic.Length -lt 2 -or $magic[0] -ne 0x4D -or $magic[1] -ne 0x5A) {
            Remove-Item $filePath -Force -ErrorAction SilentlyContinue
            throw "Downloaded file is not a valid executable. The URL may have returned an error page."
        }

        Update-Status "Installing $Name..." "Cyan"
        
        if ($IsMsi) { $proc = Start-Process "msiexec.exe" -ArgumentList "/i `"$filePath`" $Arguments" -Wait -PassThru -WindowStyle Hidden }
        else { $proc = Start-Process -FilePath $filePath -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden }
        $exitCode = $proc.ExitCode
        Remove-Item $filePath -Force -ErrorAction SilentlyContinue
        if ($exitCode -in @(0, 1638, 3010, 1641, 5100)) { return @{Success=$true; Message=""} }
        return @{Success=$false; Message="Exit code: $exitCode"}
    } catch { return @{Success=$false; Message=$_.Exception.Message} }
}

$installStartBtn.Add_Click({
    if ($script:installCompleted) {
        $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to restart your computer?", "Confirm Reboot", "YesNo", "Question")
        if ($result -eq "Yes") { Restart-Computer -Force }
        return
    }
    
    $selected = @($script:allCheckboxes | Where-Object { $_.Checked })
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please select at least one item to install.", "Nothing Selected", "OK", "Warning"); return }
    
	$tabControl.Visible = $false
	$bottomPanel.Visible = $false
	$installPanel.Visible = $true
	$form.Refresh()

	$script:failures = @()
    $selectAllBtn.Enabled = $false
    $selectNoneBtn.Enabled = $false
    $selectEssentialBtn.Enabled = $false
    $selectGamingBtn.Enabled = $false
    $script:allCheckboxes | ForEach-Object { $_.Enabled = $false } | Out-Null
    
    $progressBar.Value = 0
    $progressBar.Maximum = $selected.Count
    $successCount = 0
    $is64Bit = [Environment]::Is64BitOperatingSystem
    $form.ControlBox = $false
	$progressBar.Style = "Continuous"

    foreach ($cb in $selected) {
		$tag = $cb.Tag
		$itemSuccess = $false

		# UPDATE PROGRESS LABEL HERE
		$progressLabel.Text = "Installing $($cb.Text) ($($progressBar.Value + 1)/$($progressBar.Maximum))"

		[System.Windows.Forms.Application]::DoEvents()

		switch ($tag.Type) {
			"VC" {
				$x86 = $Redists.x86[$tag.Index]
				$x64 = $Redists.x64[$tag.Index]
				$result = Install-Package -Name "$($x86.Name) x86" -Url $x86.Url -Arguments $x86.Args
				if ($result.Success) {
					if ($is64Bit) {
						$x64Result = Install-Package -Name "$($x64.Name) x64" -Url $x64.Url -Arguments $x64.Args
						if (-not $x64Result.Success) {
							$script:failures += @{Name="$($x64.Name) x64"; Error=$x64Result.Message}
						}
					}
					$itemSuccess = $true
				}
				else {
					$script:failures += @{Name="$($x86.Name) x86"; Error=$result.Message}
				}
			}
            "DotNetRuntime" {
                $item = $Redists.dotnet[$tag.Index]
                if ($item.Url) { $result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args; $itemSuccess = $result.Success; if (-not $result.Success) { $script:failures += @{Name=$item.Name; Error=$result.Message} } }
                elseif ($item.Url_x86 -and $item.Url_x64) {
                    $result = Install-Package -Name "$($item.Name) x86" -Url $item.Url_x86 -Arguments $item.Args
                    if ($result.Success) { if ($is64Bit) { $null = Install-Package -Name "$($item.Name) x64" -Url $item.Url_x64 -Arguments $item.Args }; $itemSuccess = $true }
                    else { $script:failures += @{Name=$item.Name; Error=$result.Message} }
                }
            }
			"DotNetFramework" {
				$item = $Redists.dotnet[$tag.Index]
				if ($item.IsDism) {
					# .NET Framework 3.5 is a Windows feature, not a download
					Update-Status "Enabling $($item.Name) via DISM (needs internet / Windows Update)..." "Yellow"
					$proc = Start-Process "dism.exe" -ArgumentList "/online /enable-feature /featurename:NetFx3 /All /norestart" -Wait -PassThru -WindowStyle Hidden
					if ($proc.ExitCode -in @(0, 3010)) { $itemSuccess = $true }
					else { $script:failures += @{ Name=$item.Name; Error="DISM exit code: $($proc.ExitCode)" } }
				} else {
					$result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args
					$itemSuccess = $result.Success
					if (-not $result.Success) {
						$script:failures += @{ Name=$item.Name; Error=$result.Message }
					}
				}
			}
            "Extra" {
                $item = $Redists.extras[$tag.Index]
                if ($item.Url_x86 -and $item.Url_x64) { $url = if ($is64Bit) { $item.Url_x64 } else { $item.Url_x86 }; $result = Install-Package -Name $item.Name -Url $url -Arguments $item.Args }
                elseif ($item.IsDirectX) { $result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args -IsDirectX $true }
                elseif ($item.IsOpenAL) { $result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args -IsOpenAL $true }
                elseif ($item.IsMsi) { $result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args -IsMsi $true }
                else { $result = Install-Package -Name $item.Name -Url $item.Url -Arguments $item.Args }
                $itemSuccess = $result.Success
                if (-not $result.Success) { $script:failures += @{Name=$item.Name; Error=$result.Message} }
            }
		}

		if ($itemSuccess) { $successCount++ }
		$progressBar.Value++
		[System.Windows.Forms.Application]::DoEvents()
	}
	
    $progressBar.Style = "Blocks"
	$progressBar.Value = $progressBar.Maximum
    $progressLabel.Text = "All selected packages have finished installing. Please Reboot"
	$installHeader.Text = "Installation Complete"
	$installHeader.Left = ($installPanel.ClientSize.Width - $installHeader.Width) / 2
	
    $failCount = $script:failures.Count
    if ($failCount -eq 0) { Update-Status "Complete! All $successCount packages installed successfully." "Green"; $message = "Installation complete!`n`nAll $successCount packages installed successfully.`n`nA reboot is recommended." }
    else { Update-Status "Complete with $failCount failure(s). See details." "Yellow"; $failList = ($script:failures | ForEach-Object { "- $($_.Name): $($_.Error)" }) -join "`n"; $message = "Installation complete!`n`nSuccessful: $successCount`nFailed: $failCount`n`nFailed packages:`n$failList`n`nA reboot is recommended." }
    [System.Windows.Forms.MessageBox]::Show($message, "Installation Complete", "OK", "Information")
    $script:installCompleted = $true
	$form.ControlBox = $true
	$bottomPanel.Visible = $true
    $installStartBtn.Text = "Reboot System"
	$installStartBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 80, 0)
	$installStartBtn.Enabled = $true
	$installStartBtn.Visible = $true
})

$form.Add_FormClosing({ param($sender, $e)
    if ($script:installCompleted) {
        $result = [System.Windows.Forms.MessageBox]::Show("A Windows restart is strongly advised.`n`nRestart?", "Restart Recommended", "YesNo", "Warning")
        if ($result -eq "Yes") { Restart-Computer -Force }
    }
})

$form.Add_Shown({
    if (Check-AllRedistsInstalled) {

        $tabControl.Enabled = $false
        $installStartBtn.Enabled = $false
        $selectAllBtn.Enabled = $false
        $selectNoneBtn.Enabled = $false
        $selectVCBtn.Enabled = $false
        $selectEssentialBtn.Enabled = $false
        $selectGamingBtn.Enabled = $false

        [System.Windows.Forms.MessageBox]::Show(
            "Congratulations! 🎉`n`n" +
            "All redistributables this installer provides are already installed on your system.`n`n" +
            "You may close the program, pat yourself on the back, and enjoy knowing your PC is ready for all types of bullshit.",
            "All Runtimes Installed",
            "OK",
            "Information"
        )
    }
})

[void]$form.ShowDialog()