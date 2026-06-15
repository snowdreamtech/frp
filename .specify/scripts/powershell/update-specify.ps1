$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")

$TargetVersion = "0.10.2"
$CurrentVersion = "0.0.0"

try {
    $specifyVersionOutput = specify --version 2>$null
    if ($specifyVersionOutput -match "(\d+\.\d+\.\d+)") {
        $CurrentVersion = $matches[1]
    }
} catch {
    # specify not found
}

Write-Host "Current specify version: $CurrentVersion"
Write-Host "Target specify version: $TargetVersion"

if ([version]$CurrentVersion -lt [version]$TargetVersion) {
    Write-Host "Upgrading specify-cli to version $TargetVersion..."
    uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git@v$TargetVersion" --force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to upgrade specify-cli to version $TargetVersion."
        exit 1
    }
}

Set-Location $RepoRoot
specify init . --force --script ps --integration generic --integration-options="--commands-dir .specify/commands/"
