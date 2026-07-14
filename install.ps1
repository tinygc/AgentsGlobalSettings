$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeTarget = Join-Path $HOME ".claude"
$CodexTarget = Join-Path $HOME ".codex"
$AgentsSkillsTarget = Join-Path (Join-Path $HOME ".agents") "skills"
$CodexAgentsTarget = Join-Path $CodexTarget "agents"
$CopilotWorkspaceTarget = Join-Path (Join-Path $HOME ".github") "copilot-instructions.md"
$CopilotCliTarget = Join-Path (Join-Path $HOME ".copilot") "copilot-instructions.md"
$CopilotVsCodeTarget = Join-Path (Join-Path (Join-Path $HOME ".copilot") "instructions") "agents-global.instructions.md"
$BackupRoot = Join-Path $HOME ".settings-backup"
$BackupDir = Join-Path $BackupRoot (Get-Date -Format "yyyyMMdd-HHmmss")

function Copy-FileStrict {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "missing source file: $Source"
  }

  $parent = Split-Path -Parent $Destination
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-DirectoryStrict {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "missing source directory: $Source"
  }

  $parent = Split-Path -Parent $Destination
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Write-CopilotInstructions {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [Parameter(Mandatory = $false)][bool]$IncludeFrontmatter = $false
  )

  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "missing source file: $Source"
  }

  $parent = Split-Path -Parent $Destination
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $header = @()
  if ($IncludeFrontmatter) {
    $header += @(
      "---",
      "applyTo: ""**""",
      "---",
      ""
    )
  }
  $header += @(
    "# GitHub Copilot instructions",
    "",
    "This file mirrors the shared global agent instructions used by Claude Code and OpenAI Codex.",
    "",
    "> Source of truth: ``AGENTS.md``",
    ""
  )
  $body = Get-Content -LiteralPath $Source -Encoding UTF8
  Set-Content -LiteralPath $Destination -Value ($header + $body) -Encoding UTF8
}

function ConvertTo-TomlBasicString {
  param([Parameter(Mandatory = $true)][string]$Value)

  return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Get-AgentFrontmatterValue {
  param(
    [Parameter(Mandatory = $true)][string[]]$Lines,
    [Parameter(Mandatory = $true)][string]$Key
  )

  if ($Lines.Count -eq 0 -or $Lines[0].TrimEnd("`r") -ne "---") {
    return $null
  }

  for ($i = 1; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i].TrimEnd("`r")
    if ($line -eq "---") {
      break
    }
    if ($line -match "^$([regex]::Escape($Key)):\s*(.*)$") {
      $value = $Matches[1].Trim()
      if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
        return $Matches[1]
      }
      return $value
    }
  }

  return $null
}

function Get-AgentBody {
  param([Parameter(Mandatory = $true)][string[]]$Lines)

  if ($Lines.Count -eq 0 -or $Lines[0].TrimEnd("`r") -ne "---") {
    return $Lines
  }

  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i].TrimEnd("`r") -eq "---") {
      if ($i + 1 -lt $Lines.Count) {
        return $Lines[($i + 1)..($Lines.Count - 1)]
      }
      return @()
    }
  }

  return $Lines
}

function Write-CodexAgent {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "missing source file: $Source"
  }

  $lines = @(Get-Content -LiteralPath $Source -Encoding UTF8)
  $sourceLeaf = Split-Path -Leaf $Source
  $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($sourceLeaf))
  $agentName = Get-AgentFrontmatterValue -Lines $lines -Key "name"
  if (-not $agentName) {
    $agentName = $fileBaseName
  }
  $description = Get-AgentFrontmatterValue -Lines $lines -Key "description"
  if (-not $description) {
    $description = "Imported from Claude agent $fileBaseName."
  }
  $body = Get-AgentBody -Lines $lines

  $parent = Split-Path -Parent $Destination
  if ($parent) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }

  $content = @(
    "name = `"$(ConvertTo-TomlBasicString $agentName)`"",
    "description = `"$(ConvertTo-TomlBasicString $description)`"",
    "developer_instructions = '''"
  ) + $body + @("'''", "")

  Set-Content -LiteralPath $Destination -Value $content -Encoding UTF8
}

function Backup-Existing {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Name
  )

  if (Test-Path -LiteralPath $Source) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    Copy-Item -LiteralPath $Source -Destination (Join-Path $BackupDir $Name) -Recurse -Force
    Write-Host "Backed up $Source to $(Join-Path $BackupDir $Name)"
  }
}

Backup-Existing $ClaudeTarget "claude"
Remove-Item -LiteralPath $ClaudeTarget -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $ClaudeTarget | Out-Null

Copy-FileStrict (Join-Path $RootDir "AGENTS.md") (Join-Path $HOME "AGENTS.md")
Backup-Existing $CopilotWorkspaceTarget "github-copilot-instructions.md"
Write-CopilotInstructions (Join-Path $RootDir "AGENTS.md") $CopilotWorkspaceTarget
Backup-Existing $CopilotCliTarget "copilot-copilot-instructions.md"
Write-CopilotInstructions (Join-Path $RootDir "AGENTS.md") $CopilotCliTarget
Backup-Existing $CopilotVsCodeTarget "copilot-vscode-agents-global.instructions.md"
Write-CopilotInstructions (Join-Path $RootDir "AGENTS.md") $CopilotVsCodeTarget $true
Copy-FileStrict (Join-Path (Join-Path $RootDir ".claude") "CLAUDE.md") (Join-Path $ClaudeTarget "CLAUDE.md")
Copy-FileStrict (Join-Path (Join-Path $RootDir ".claude") "settings.json") (Join-Path $ClaudeTarget "settings.json")

$ClaudeLocalSettings = Join-Path (Join-Path $RootDir ".claude") "settings.local.json"
if (Test-Path -LiteralPath $ClaudeLocalSettings -PathType Leaf) {
  Copy-FileStrict $ClaudeLocalSettings (Join-Path $ClaudeTarget "settings.local.json")
}

Copy-DirectoryStrict (Join-Path (Join-Path $RootDir ".claude") "rules") (Join-Path $ClaudeTarget "rules")
Copy-DirectoryStrict (Join-Path (Join-Path $RootDir ".claude") "agents") (Join-Path $ClaudeTarget "agents")
Copy-DirectoryStrict (Join-Path (Join-Path $RootDir ".claude") "hooks") (Join-Path $ClaudeTarget "hooks")
Copy-DirectoryStrict (Join-Path (Join-Path $RootDir ".claude") "skills") (Join-Path $ClaudeTarget "skills")

Write-Host "Installed settings to $ClaudeTarget"
Write-Host "Installed GitHub Copilot workspace instructions to $CopilotWorkspaceTarget"
Write-Host "Installed GitHub Copilot CLI instructions to $CopilotCliTarget"
Write-Host "Installed GitHub Copilot VS Code instructions to $CopilotVsCodeTarget"

Backup-Existing (Join-Path $CodexTarget "AGENTS.md") "codex-AGENTS.md"
Copy-FileStrict (Join-Path $RootDir "AGENTS.md") (Join-Path $CodexTarget "AGENTS.md")

Write-Host "Installed Codex instructions to $(Join-Path $CodexTarget "AGENTS.md")"

Backup-Existing $CodexAgentsTarget "codex-agents"
New-Item -ItemType Directory -Force -Path $CodexAgentsTarget | Out-Null
$SourceAgents = Join-Path (Join-Path $RootDir ".claude") "agents"
Get-ChildItem -LiteralPath $SourceAgents -Filter "*.agent.md" -File | ForEach-Object {
  $AgentName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($_.Name))
  $AgentTarget = Join-Path $CodexAgentsTarget "$AgentName.toml"
  Write-CodexAgent $_.FullName $AgentTarget
}

Write-Host "Installed Codex agents to $CodexAgentsTarget"

Backup-Existing $AgentsSkillsTarget "agents-skills"
New-Item -ItemType Directory -Force -Path $AgentsSkillsTarget | Out-Null
$SourceSkills = Join-Path (Join-Path $RootDir ".claude") "skills"
Get-ChildItem -LiteralPath $SourceSkills -Directory | ForEach-Object {
  $SkillTarget = Join-Path $AgentsSkillsTarget $_.Name
  Remove-Item -LiteralPath $SkillTarget -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item -LiteralPath $_.FullName -Destination $SkillTarget -Recurse -Force
}

Write-Host "Installed skills to $AgentsSkillsTarget"
