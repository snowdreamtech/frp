<#
 Copyright (c) 2026 SnowdreamTech. All rights reserved.
 Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

<#
.SYNOPSIS
    Consolidated prerequisite checking script for Spec-Driven Development.
.DESCRIPTION
    Windows PowerShell equivalent of check-prerequisites.sh.
    Validates the environment and outputs paths for the current feature.
.PARAMETER Json
    Output in JSON format.
.PARAMETER RequireTasks
    Require tasks.md to exist (for the implementation phase).
.PARAMETER IncludeTasks
    Include tasks.md in the AVAILABLE_DOCS list.
.PARAMETER PathsOnly
    Only output path variables (no validation).
.EXAMPLE
    .\check-prerequisites.ps1 -Json
    .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
    .\check-prerequisites.ps1 -PathsOnly
#>
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly
)

$ErrorActionPreference = "Stop"

# Load common functions
. (Join-Path $PSScriptRoot "common.ps1")

# Gather paths
$paths = Get-FeaturePaths

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# Paths-only mode
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            BRANCH       = $paths.CURRENT_BRANCH
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        "REPO_ROOT: $($paths.REPO_ROOT)"
        "BRANCH: $($paths.CURRENT_BRANCH)"
        "FEATURE_DIR: $($paths.FEATURE_DIR)"
        "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        "IMPL_PLAN: $($paths.IMPL_PLAN)"
        "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# Validate feature directory
if (-not (Test-Path $paths.FEATURE_DIR)) {
    Write-Error "ERROR: Feature directory not found: $($paths.FEATURE_DIR)`nRun /speckit.specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN)) {
    Write-Error "ERROR: plan.md not found in $($paths.FEATURE_DIR)`nRun /speckit.plan first to create the implementation plan."
    exit 1
}

if ($RequireTasks -and -not (Test-Path $paths.TASKS)) {
    Write-Error "ERROR: tasks.md not found in $($paths.FEATURE_DIR)`nRun /speckit.tasks first to create the task list."
    exit 1
}

# Build available docs list
$docs = @()
if (Test-Path $paths.RESEARCH)   { $docs += "research.md" }
if (Test-Path $paths.DATA_MODEL) { $docs += "data-model.md" }
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue)) {
    $docs += "contracts/"
}
if (Test-Path $paths.QUICKSTART) { $docs += "quickstart.md" }
if ($IncludeTasks -and (Test-Path $paths.TASKS)) { $docs += "tasks.md" }

# Output results
if ($Json) {
    $jsonDocs = ($docs | ForEach-Object { "`"$_`"" }) -join ","
    Write-Output "{`"FEATURE_DIR`":`"$($paths.FEATURE_DIR.Replace('\','/'))`",`"AVAILABLE_DOCS`":[$jsonDocs]}"
} else {
    "FEATURE_DIR:$($paths.FEATURE_DIR)"
    "AVAILABLE_DOCS:"
    Write-CheckFile $paths.RESEARCH   "research.md"
    Write-CheckFile $paths.DATA_MODEL "data-model.md"
    Write-CheckDir  $paths.CONTRACTS_DIR "contracts/"
    Write-CheckFile $paths.QUICKSTART "quickstart.md"
    if ($IncludeTasks) { Write-CheckFile $paths.TASKS "tasks.md" }
}
