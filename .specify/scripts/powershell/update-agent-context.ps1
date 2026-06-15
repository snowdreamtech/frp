<#
 Copyright (c) 2026 SnowdreamTech. All rights reserved.
 Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

<#
.SYNOPSIS
    Updates AI agent context files with current feature information.
.DESCRIPTION
    Windows PowerShell equivalent of update-agent-context.sh.
    Parses plan.md and updates or creates agent-specific context files
    (Claude, Gemini, Copilot, Cursor, Windsurf, Kilo Code, Augment, etc.).
.PARAMETER AgentType
    Optional. Specific agent to update: claude|gemini|copilot|cursor-agent|qwen|
    opencode|codex|windsurf|kilocode|auggie|roo|codebuddy|qoder|amp|shai|q|agy|bob
    If omitted, all existing agent files are updated.
.EXAMPLE
    .\update-agent-context.ps1
    .\update-agent-context.ps1 claude
    .\update-agent-context.ps1 gemini
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$AgentType = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$paths    = Get-FeaturePaths
$NewPlan  = $paths.IMPL_PLAN

#------------------------------------------------------
# Logging
#------------------------------------------------------
function Write-Info    { param([string]$m) Write-Output "INFO: $m" }
function Write-Success { param([string]$m) Write-Output "$([char]0x2713) $m" }
function Write-Err     { param([string]$m) Write-Output "ERROR: $m"  }
function Write-Warn    { param([string]$m) Write-Output "WARNING: $m" -ForegroundColor Yellow }

#------------------------------------------------------
# Validation
#------------------------------------------------------
function Invoke-ValidateEnvironment {
    if (-not $paths.CURRENT_BRANCH) {
        Write-Err "Unable to determine current feature."
        exit 1
    }
    if (-not (Test-Path $NewPlan)) {
        Write-Err "No plan.md found at $NewPlan"
        exit 1
    }
}

#------------------------------------------------------
# Plan Parsing
#------------------------------------------------------
$NewLang = ""; $NewFramework = ""; $NewDb = ""; $NewProjectType = ""

function Get-PlanField {
    param([string]$FieldPattern, [string]$PlanFile)
    $line = (Get-Content $PlanFile -Raw) -split "`n" |
            Where-Object { $_ -match "^\*\*$FieldPattern\*\*: " } |
            Select-Object -First 1
    if ($line) {
        return ($line -replace "^\*\*$FieldPattern\*\*: ", '').Trim()
    }
    return ""
}

function Invoke-ParsePlanData {
    Write-Info "Parsing plan data from $NewPlan"
    $script:NewLang        = Get-PlanField "Language/Version"     $NewPlan
    $script:NewFramework   = Get-PlanField "Primary Dependencies" $NewPlan
    $script:NewDb          = Get-PlanField "Storage"              $NewPlan
    $script:NewProjectType = Get-PlanField "Project Type"         $NewPlan
    if ($NewLang)        { Write-Info "Found language: $NewLang" }
    if ($NewFramework)   { Write-Info "Found framework: $NewFramework" }
    if ($NewDb -and $NewDb -ne "N/A") { Write-Info "Found database: $NewDb" }
}

#------------------------------------------------------
# Content helpers
#------------------------------------------------------
function Get-TechStack {
    $parts = @()
    if ($NewLang      -and $NewLang -ne "NEEDS CLARIFICATION")      { $parts += $NewLang }
    if ($NewFramework -and $NewFramework -notin @("NEEDS CLARIFICATION","N/A")) { $parts += $NewFramework }
    return $parts -join " + "
}

function Get-ProjectStructure {
    if ($NewProjectType -match "web") { return "backend/`nfrontend/`ntests/" }
    return "src/`ntests/"
}

function Get-BuildCommands {
    switch -Wildcard ($NewLang) {
        "*Python*"     { return "cd src && pytest && ruff check ." }
        "*Rust*"       { return "cargo test && cargo clippy" }
        "*JavaScript*" { return "npm test && npm run lint" }
        "*TypeScript*" { return "npm test && npm run lint" }
        default        { return "# Add commands for $NewLang" }
    }
}

#------------------------------------------------------
# Agent File Update
#------------------------------------------------------
function Update-AgentFile {
    param([string]$TargetFile, [string]$AgentName)

    Write-Info "Updating $AgentName context file: $TargetFile"

    $projectName  = Split-Path $paths.REPO_ROOT -Leaf
    $currentDate  = Get-Date -Format "yyyy-MM-dd"
    $targetDir    = Split-Path $TargetFile -Parent

    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    $templateFile = Join-Path $paths.REPO_ROOT ".specify\templates\agent-file-template.md"

    if (-not (Test-Path $TargetFile)) {
        # Create new from template
        if (-not (Test-Path $templateFile)) {
            Write-Err "Template not found: $templateFile"
            return
        }
        $tech   = Get-TechStack
        $struct = Get-ProjectStructure
        $cmds   = Get-BuildCommands
        $content = Get-Content $templateFile -Raw
        $content = $content -replace '\[PROJECT NAME\]',        $projectName
        $content = $content -replace '\[DATE\]',                $currentDate
        $content = $content -replace '\[EXTRACTED FROM ALL PLAN\.MD FILES\]', "- $tech ($($paths.CURRENT_BRANCH))"
        $content = $content -replace '\[ACTUAL STRUCTURE FROM PLANS\]',       $struct
        $content = $content -replace '\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]', $cmds
        $content = $content -replace '\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]', "$NewLang : Follow standard conventions"
        $content = $content -replace '\[LAST 3 FEATURES AND WHAT THEY ADDED\]', "- $($paths.CURRENT_BRANCH): Added $tech"
        Set-Content $TargetFile $content -Encoding UTF8
        Write-Success "Created new $AgentName context file"
    } else {
        # Update existing file
        $techStack   = Get-TechStack
        $changeEntry = if ($techStack) { "- $($paths.CURRENT_BRANCH): Added $techStack" } else { "" }
        $lines       = Get-Content $TargetFile
        $newLines    = [System.Collections.Generic.List[string]]::new()
        $inTech = $false; $inChanges = $false
        $techAdded = $false; $existingChanges = 0

        foreach ($line in $lines) {
            if ($line -eq "## Active Technologies") {
                $newLines.Add($line); $inTech = $true; continue
            }
            if ($inTech -and $line -match "^## ") {
                if (-not $techAdded -and $techStack -and -not ($lines -contains "- $techStack ($($paths.CURRENT_BRANCH))")) {
                    $newLines.Add("- $techStack ($($paths.CURRENT_BRANCH))")
                    $techAdded = $true
                }
                $inTech = $false
            }
            if ($line -eq "## Recent Changes") {
                $newLines.Add($line)
                if ($changeEntry) { $newLines.Add($changeEntry) }
                $inChanges = $true; continue
            }
            if ($inChanges -and $line -match "^## ") { $inChanges = $false }
            if ($inChanges -and $line -match "^- ") {
                if ($existingChanges -lt 2) { $newLines.Add($line); $existingChanges++ }
                continue
            }
            if ($line -match "\*\*Last updated\*\*:.*\d{4}-\d{2}-\d{2}") {
                $newLines.Add(($line -replace '\d{4}-\d{2}-\d{2}', $currentDate))
            } else {
                $newLines.Add($line)
            }
        }
        Set-Content $TargetFile $newLines -Encoding UTF8
        Write-Success "Updated existing $AgentName context file"
    }
}

#------------------------------------------------------
# Agent file paths
#------------------------------------------------------
$r = $paths.REPO_ROOT
$agentFiles = @{
    claude       = @{ path = "$r\CLAUDE.md";                              name = "Claude Code" }
    gemini       = @{ path = "$r\GEMINI.md";                              name = "Gemini CLI" }
    copilot      = @{ path = "$r\.github\agents\copilot-instructions.md"; name = "GitHub Copilot" }
    "cursor-agent" = @{ path = "$r\.cursor\rules\specify-rules.mdc";      name = "Cursor IDE" }
    qwen         = @{ path = "$r\QWEN.md";                                name = "Qwen Code" }
    opencode     = @{ path = "$r\AGENTS.md";                              name = "opencode" }
    codex        = @{ path = "$r\AGENTS.md";                              name = "Codex CLI" }
    windsurf     = @{ path = "$r\.windsurf\rules\specify-rules.md";       name = "Windsurf" }
    kilocode     = @{ path = "$r\.kilocode\rules\specify-rules.md";       name = "Kilo Code" }
    auggie       = @{ path = "$r\.augment\rules\specify-rules.md";        name = "Auggie CLI" }
    roo          = @{ path = "$r\.roo\rules\specify-rules.md";            name = "Roo Code" }
    codebuddy    = @{ path = "$r\CODEBUDDY.md";                           name = "CodeBuddy CLI" }
    qoder        = @{ path = "$r\QODER.md";                               name = "Qoder CLI" }
    amp          = @{ path = "$r\AGENTS.md";                              name = "Amp" }
    shai         = @{ path = "$r\SHAI.md";                                name = "SHAI" }
    q            = @{ path = "$r\AGENTS.md";                              name = "Amazon Q Developer CLI" }
    agy          = @{ path = "$r\.agent\rules\specify-rules.md";          name = "Antigravity" }
    bob          = @{ path = "$r\AGENTS.md";                              name = "IBM Bob" }
}

#------------------------------------------------------
# Main
#------------------------------------------------------
Invoke-ValidateEnvironment
Write-Info "=== Updating agent context files for feature $($paths.CURRENT_BRANCH) ==="
Invoke-ParsePlanData

if ($AgentType) {
    if (-not $agentFiles.ContainsKey($AgentType)) {
        Write-Err "Unknown agent type '$AgentType'. Expected: $($agentFiles.Keys -join '|')"
        exit 1
    }
    Update-AgentFile $agentFiles[$AgentType].path $agentFiles[$AgentType].name
} else {
    $found = $false
    foreach ($key in $agentFiles.Keys) {
        $info = $agentFiles[$key]
        if (Test-Path $info.path) {
            Update-AgentFile $info.path $info.name
            $found = $true
        }
    }
    if (-not $found) {
        Write-Info "No existing agent files found, creating default Claude file..."
        Update-AgentFile $agentFiles["claude"].path $agentFiles["claude"].name
    }
}

Write-Output ""
Write-Info "Summary of changes:"
if ($NewLang)      { Write-Output "  - Added language: $NewLang" }
if ($NewFramework) { Write-Output "  - Added framework: $NewFramework" }
if ($NewDb -and $NewDb -ne "N/A") { Write-Output "  - Added database: $NewDb" }
Write-Output ""
Write-Success "Agent context update completed successfully"
