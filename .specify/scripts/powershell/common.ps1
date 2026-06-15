<#
 Copyright (c) 2026 SnowdreamTech. All rights reserved.
 Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

# common.ps1
# Common functions and variables for all PowerShell scripts
# Equivalent to common.sh

function Get-RepoRoot {
    try {
        $root = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $root) {
            return $root.Trim()
        }
    } catch {}

    # Fallback: walk up from script location looking for .git or .specify
    $dir = Split-Path -Parent $PSScriptRoot
    while ($dir -ne (Split-Path -Qualifier $dir) + '\') {
        if ((Test-Path (Join-Path $dir ".git")) -or (Test-Path (Join-Path $dir ".specify"))) {
            return $dir
        }
        $dir = Split-Path -Parent $dir
    }
    return $null
}

function Get-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-CurrentBranch {
    # Check environment variable first
    if ($env:SPECIFY_FEATURE) {
        return $env:SPECIFY_FEATURE
    }

    # Try git
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            return $branch.Trim()
        }
    } catch {}

    # Fallback: find latest numbered spec directory
    $repoRoot = Get-RepoRoot
    if ($repoRoot) {
        $specsDir = Join-Path $repoRoot "specs"
        if (Test-Path $specsDir) {
            $latest = Get-ChildItem $specsDir -Directory |
                Where-Object { $_.Name -match '^\d{3}-' } |
                Sort-Object { [int]($_.Name -replace '-.*', '') } |
                Select-Object -Last 1
            if ($latest) { return $latest.Name }
        }
    }

    return "main"
}

function Get-FeaturePaths {
    $repoRoot  = Get-RepoRoot
    $branch    = Get-CurrentBranch
    $hasGit    = Get-HasGit

    # Find spec dir by numeric prefix (same logic as bash)
    $specsDir  = Join-Path $repoRoot "specs"
    $featureDir = $null

    if ($branch -match '^(\d{3})-') {
        $prefix = $Matches[1]
        $match  = Get-ChildItem $specsDir -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match "^$prefix-" } |
                    Select-Object -First 1
        $featureDir = if ($match) { $match.FullName } else { Join-Path $specsDir $branch }
    } else {
        $featureDir = Join-Path $specsDir $branch
    }

    return [PSCustomObject]@{
        REPO_ROOT    = $repoRoot
        CURRENT_BRANCH = $branch
        HAS_GIT      = $hasGit
        FEATURE_DIR  = $featureDir
        FEATURE_SPEC = Join-Path $featureDir "spec.md"
        IMPL_PLAN    = Join-Path $featureDir "plan.md"
        TASKS        = Join-Path $featureDir "tasks.md"
        RESEARCH     = Join-Path $featureDir "research.md"
        DATA_MODEL   = Join-Path $featureDir "data-model.md"
        QUICKSTART   = Join-Path $featureDir "quickstart.md"
        CONTRACTS_DIR = Join-Path $featureDir "contracts"
    }
}

function Test-FeatureBranch {
    param([string]$Branch, [bool]$HasGit)

    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }

    if ($Branch -notmatch '^\d{3}-') {
        Write-Error "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Error "Feature branches should be named like: 001-feature-name"
        return $false
    }
    return $true
}

function Write-CheckFile {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) { Write-Output "  $([char]0x2713) $Label" }
    else                  { Write-Output "  $([char]0x2717) $Label" }
}

function Write-CheckDir {
    param([string]$Path, [string]$Label)
    if ((Test-Path $Path) -and (Get-ChildItem $Path -ErrorAction SilentlyContinue)) {
        Write-Output "  $([char]0x2713) $Label"
    } else {
        Write-Output "  $([char]0x2717) $Label"
    }
}
