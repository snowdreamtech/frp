<#
  Copyright (c) 2026 SnowdreamTech. All rights reserved.
  Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

# PowerShell installer script for UniRTM (install.ps1)
# Compatible with Windows PowerShell and PowerShell Core
# Usage:
#   Invoke-WebRequest -Uri https://raw.githubusercontent.com/snowdreamtech/UniRTM/main/install.ps1 -OutFile install.ps1; .\install.ps1 --version v0.7.0
#   .\install.ps1 --install-dir $HOME\bin --no-proxy

param(
    [Alias('v')][string]$Version,
    [string]$InstallDir,
    [switch]$NoProxy,
    [Alias('q')][switch]$Quiet,
    [switch]$SkipChecksum,
    [string]$LogFile,
    [Alias('h')][switch]$Help
)

function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [ConsoleColor]$Color
    )
    if ($LogFile) {
        "[$Level] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    if ($Quiet -and ($Level -eq 'INFO' -or $Level -eq 'WARN')) {
        return
    }
    if ($Level -eq 'ERROR') {
        Write-Host "[$Level] $Message" -ForegroundColor $Color
    } else {
        Write-Host "[$Level]  $Message" -ForegroundColor $Color
    }
}

function Write-Info   { param([string]$msg) Write-Log -Level 'INFO' -Message $msg -Color Green }
function Write-Warn   { param([string]$msg) Write-Log -Level 'WARN' -Message $msg -Color Yellow }
function Write-Error  { param([string]$msg) Write-Log -Level 'ERROR' -Message $msg -Color Red }

function Show-Help {
    Write-Info "Usage: install.ps1 [--version <tag>] [--install-dir <dir>] [--no-proxy] [--quiet] [--skip-checksum] [--log-file <path>] [--help]"
    Write-Info "  --version, -v   Target version (default: latest release)"
    Write-Info "  --install-dir   Directory to place the binary (default: `$HOME\bin for normal user, C:\Program Files\UniRTM for admin)"
    Write-Info "  --no-proxy      Disable GitHub proxy"
    Write-Info "  --quiet, -q     Suppress INFO and WARN output"
    Write-Info "  --skip-checksum Skip SHA256 checksum verification"
    Write-Info "  --log-file      Write logs to the specified file"
    Write-Info "  --help, -h      Show this help message"
    exit 0
}

if ($Help) { Show-Help }

# Configuration
$Repo = "snowdreamtech/UniRTM"
$Binary = "unirtm"
$GitHubProxy = $env:GITHUB_PROXY
if (-not $GitHubProxy) { $GitHubProxy = "https://gh-proxy.sn0wdr1am.com/" }
if ($NoProxy) { $GitHubProxy = "" }

# Retry settings for Invoke-WebRequest
$RetryCount = 5
$RetryDelay = 2

function Invoke-WithRetry {
    param(
        [string]$Uri,
        [string]$OutFile = $null
    )
    $attempt = 0
    while ($attempt -lt $RetryCount) {
        try {
            if ($OutFile) {
                Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop | Out-Null
                return $true
            } else {
                # Return response content as string so callers can parse it directly
                return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction Stop).Content
            }
        } catch {
            $attempt++
            Write-Warn "Download attempt $attempt failed for $Uri. Retrying in $RetryDelay seconds..."
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $null
}

# Resolve version
if ($Version) {
    if (-not $Version.StartsWith('v')) { $Version = "v$Version" }
    Write-Info "Target version: $Version"
} else {
    Write-Info "Fetching latest release from GitHub API..."
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    # Apply proxy prefix to GitHub API URL
    $proxiedApiUrl = if ($GitHubProxy) { "$GitHubProxy$apiUrl" } else { $apiUrl }
    $responseContent = Invoke-WithRetry -Uri $proxiedApiUrl
    if (-not $responseContent) {
        # Fallback: retry without proxy
        if ($proxiedApiUrl -ne $apiUrl) {
            Write-Warn "Proxy API request failed, retrying without proxy..."
            $responseContent = Invoke-WithRetry -Uri $apiUrl
        }
        if (-not $responseContent) {
            Write-Error "Failed to fetch latest version. Specify with --version"; exit 1
        }
    }
    $json = $responseContent | ConvertFrom-Json
    $Version = $json.tag_name
    Write-Info "Latest version: $Version"
}

# Detect platform and architecture
$os = $(Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$archEnv = $env:PROCESSOR_ARCHITECTURE
if ($archEnv -eq "AMD64") {
    $archName = "x86_64"
} elseif ($archEnv -eq "ARM64") {
    $archName = "arm64"
} else {
    $archName = "i386"
}
Write-Info "Detected platform: Windows/${archName}"

# Build URLs
$archiveName = "${Binary}_Windows_${archName}.zip"
$archiveUrl = "https://github.com/${Repo}/releases/download/${Version}/${archiveName}"
$checksumUrl = "https://github.com/${Repo}/releases/download/${Version}/checksums.txt"
if ($GitHubProxy) { $archiveUrl = "$GitHubProxy$archiveUrl"; $checksumUrl = "$GitHubProxy$checksumUrl" }

# Temporary folder
$tmpDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name ([System.Guid]::NewGuid().ToString()) -Force
# Ensure cleanup on exit
$script:cleanup = { Remove-Item -Recurse -Force $tmpDir }
Register-EngineEvent PowerShell.Exiting -Action $cleanup | Out-Null

# Download archive
$archivePath = Join-Path $tmpDir $archiveName
Write-Info "Downloading $archiveName..."
if (-not (Invoke-WithRetry -Uri $archiveUrl -OutFile $archivePath)) {
    Write-Error "Failed to download archive"; exit 1
}
if (-not (Test-Path $archivePath) -or (Get-Item $archivePath).Length -eq 0) {
    Write-Error "Downloaded archive is empty"; exit 1
}

# Download checksum file
if ($SkipChecksum) {
    Write-Warn "Skipping checksum verification due to --skip-checksum flag."
} else {
    $checksumPath = Join-Path $tmpDir "checksums.txt"
    Write-Info "Downloading checksums..."
    $checksumOk = Invoke-WithRetry -Uri $checksumUrl -OutFile $checksumPath
    if ($checksumOk) {
        $expected = (Select-String -Path $checksumPath -Pattern "\s$archiveName$" | ForEach-Object { $_.Line.Split(' ')[0] })
        if ($expected) {
            $actual = (Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash.ToLower()
            if ($expected.ToLower() -ne $actual) {
                Write-Error "Checksum mismatch! Expected $expected, got $actual"
                exit 1
            }
            Write-Info "Checksum verified OK."
        } else {
            Write-Warn "Checksum entry not found for $archiveName, skipping verification."
        }
    } else {
        Write-Warn "Could not download checksums.txt, skipping verification."
    }
}

# Determine install directory
if (-not $InstallDir) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        $InstallDir = "C:\Program Files\UniRTM"
    } else {
        $InstallDir = "$HOME\bin"
    }
}
Write-Info "Installing to $InstallDir..."
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Extract archive (zip)
Expand-Archive -Path $archivePath -DestinationPath $tmpDir -Force
# Find binary
$binaryPath = Get-ChildItem -Path $tmpDir -Recurse -Filter "$Binary.exe" -File | Select-Object -First 1
if (-not $binaryPath) { Write-Error "Binary '$Binary' not found in archive"; exit 1 }
# Move/replace binary
$targetPath = Join-Path $InstallDir "$Binary.exe"
if (Test-Path $targetPath) {
    Move-Item -Path $targetPath -Destination "${targetPath}.old" -Force
}
Copy-Item -Path $binaryPath.FullName -Destination $targetPath -Force
# Ensure executable flag (Windows binaries are executable by default)

# Cleanup old backup if succeeded
if (Test-Path "${targetPath}.old") { Remove-Item "${targetPath}.old" -Force }

Write-Info "Installed $Binary to $targetPath"

# PATH hint
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $InstallDir })) {
    Write-Warn "Add the following to your PowerShell profile to include the install directory in PATH:"
    Write-Host "    `$env:Path = `"$InstallDir;`$env:Path`""
}

# Verify installation
if (Test-Path $targetPath) {
    try {
        $verOutput = & $targetPath version 2>$null | Out-String
        $installedVer = $verOutput -split "`n" | Where-Object { $_ -match "^unirtm version" } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($installedVer)) { $installedVer = "unknown" }
        Write-Info "Installed version: $installedVer"
        Write-Info "Installation complete!"
    } catch {
        Write-Error "Verification failed: unable to execute installed binary"
        exit 1
    }
} else {
    Write-Error "Verification failed: binary not found at $targetPath"
    exit 1
}
