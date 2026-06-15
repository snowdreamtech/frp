<#
 Copyright (c) 2026 SnowdreamTech. All rights reserved.
 Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

<#
.SYNOPSIS
    Sets up the plan.md for the current feature.
.DESCRIPTION
    Windows PowerShell equivalent of setup-plan.sh.
    Creates the implementation plan from a template.
.PARAMETER Json
    Output in JSON format.
.EXAMPLE
    .\setup-plan.ps1
    .\setup-plan.ps1 -Json
#>
[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Load common functions
. (Join-Path $PSScriptRoot "common.ps1")

$paths = Get-FeaturePaths

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# Ensure feature directory exists
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# Copy plan template if it exists
$template = Join-Path $paths.REPO_ROOT ".specify\templates\plan-template.md"
if (Test-Path $template) {
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "Copied plan template to $($paths.IMPL_PLAN)"
} else {
    Write-Warning "Plan template not found at $template"
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# Output results
if ($Json) {
    $out = [PSCustomObject]@{
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN    = $paths.IMPL_PLAN
        SPECS_DIR    = $paths.FEATURE_DIR
        BRANCH       = $paths.CURRENT_BRANCH
        HAS_GIT      = $paths.HAS_GIT.ToString().ToLower()
    }
    Write-Output ($out | ConvertTo-Json -Compress)
} else {
    "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    "IMPL_PLAN: $($paths.IMPL_PLAN)"
    "SPECS_DIR: $($paths.FEATURE_DIR)"
    "BRANCH: $($paths.CURRENT_BRANCH)"
    "HAS_GIT: $($paths.HAS_GIT)"
}
