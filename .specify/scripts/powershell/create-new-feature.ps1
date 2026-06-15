<#
 Copyright (c) 2026 SnowdreamTech. All rights reserved.
 Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

<#
.SYNOPSIS
    Creates a new feature branch and spec directory.
.DESCRIPTION
    Windows PowerShell equivalent of create-new-feature.sh.
    Auto-generates a branch name from the description and creates the spec directory.
.PARAMETER FeatureDescription
    The human-readable description of the feature (required).
.PARAMETER Json
    Output in JSON format.
.PARAMETER ShortName
    Optional: provide a custom 2-4 word short name for the branch suffix.
.PARAMETER Number
    Optional: specify the branch number manually (overrides auto-detection).
.EXAMPLE
    .\create-new-feature.ps1 "Add user authentication system"
    .\create-new-feature.ps1 "Add user authentication system" -ShortName "user-auth" -Json
    .\create-new-feature.ps1 "Implement OAuth2 integration" -Number 5
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FeatureDescription,

    [switch]$Json,

    [string]$ShortName = "",

    [int]$Number = 0
)

$ErrorActionPreference = "Stop"

# Load common functions
. (Join-Path $PSScriptRoot "common.ps1")

#----------------------------------------------------------
# Helper: clean a string to a valid branch slug
#----------------------------------------------------------
function ConvertTo-BranchSlug {
    param([string]$Name)
    $Name = $Name.ToLower() -replace '[^a-z0-9]', '-'
    $Name = $Name -replace '-+', '-'
    $Name = $Name.Trim('-')
    return $Name
}

#----------------------------------------------------------
# Helper: generate a brief slug from a description
#----------------------------------------------------------
function New-BranchName {
    param([string]$Description)

    $stopWords = '^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$'

    $words = ($Description.ToLower() -replace '[^a-z0-9]', ' ') -split '\s+' |
        Where-Object { $_ -and $_ -notmatch $stopWords -and $_.Length -ge 3 } |
        Select-Object -First 4

    if ($words.Count -gt 0) {
        return ($words -join '-')
    }

    # Fallback
    return (ConvertTo-BranchSlug $Description) -split '-' | Where-Object { $_ } | Select-Object -First 3 | Join-String -Separator '-'
}

#----------------------------------------------------------
# Helper: highest number from git branches
#----------------------------------------------------------
function Get-HighestFromBranches {
    $highest = 0
    try {
        $branches = git branch -a 2>$null
        foreach ($b in $branches) {
            $b = $b -replace '^\*?\s+', '' -replace '^remotes/[^/]+/', ''
            if ($b -match '^(\d{3})-') {
                $n = [int]$Matches[1]
                if ($n -gt $highest) { $highest = $n }
            }
        }
    } catch {}
    return $highest
}

#----------------------------------------------------------
# Helper: highest number from specs directory
#----------------------------------------------------------
function Get-HighestFromSpecs {
    param([string]$SpecsDir)
    $highest = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)-') {
                $n = [int]$Matches[1]
                if ($n -gt $highest) { $highest = $n }
            }
        }
    }
    return $highest
}

#----------------------------------------------------------
# Main
#----------------------------------------------------------

# Resolve repo root
$hasGit = Get-HasGit
$repoRoot = Get-RepoRoot
if (-not $repoRoot) {
    Write-Error "Error: Could not determine repository root."
    exit 1
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot "specs"
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# Generate branch suffix
if ($ShortName) {
    $branchSuffix = ConvertTo-BranchSlug $ShortName
} else {
    $branchSuffix = New-BranchName $FeatureDescription
}

# Determine branch number
if ($Number -gt 0) {
    $branchNumber = $Number
} elseif ($hasGit) {
    try { git fetch --all --prune 2>$null } catch {}
    $highBranch = Get-HighestFromBranches
    $highSpec   = Get-HighestFromSpecs $specsDir
    $branchNumber = [Math]::Max($highBranch, $highSpec) + 1
} else {
    $branchNumber = (Get-HighestFromSpecs $specsDir) + 1
}

$featureNum  = $branchNumber.ToString("D3")
$branchName  = "$featureNum-$branchSuffix"

# Enforce GitHub 244-char limit
if ($branchName.Length -gt 244) {
    $maxSuffix  = 244 - 4   # 3 digits + hyphen
    $branchSuffix = $branchSuffix.Substring(0, $maxSuffix).TrimEnd('-')
    $branchName  = "$featureNum-$branchSuffix"
    Write-Warning "[specify] Branch name truncated to: $branchName"
}

# Create git branch
if ($hasGit) {
    git checkout -b $branchName
} else {
    Write-Warning "[specify] Warning: Git not detected; skipped branch creation for $branchName"
}

# Create feature directory and spec file
$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot ".specify\templates\spec-template.md"
$specFile  = Join-Path $featureDir "spec.md"
if (Test-Path $template) { Copy-Item $template $specFile -Force } else { New-Item -ItemType File -Path $specFile -Force | Out-Null }

# Set environment variable for current session
$env:SPECIFY_FEATURE = $branchName

# Output
if ($Json) {
    Write-Output "{`"BRANCH_NAME`":`"$branchName`",`"SPEC_FILE`":`"$($specFile.Replace('\','/'))`",`"FEATURE_NUM`":`"$featureNum`"}"
} else {
    "BRANCH_NAME: $branchName"
    "SPEC_FILE: $specFile"
    "FEATURE_NUM: $featureNum"
    "SPECIFY_FEATURE environment variable set to: $branchName"
}
