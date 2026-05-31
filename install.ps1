<#
.SYNOPSIS
  kensa-qa installer (Windows) - deploy the plugin for Claude Code, Codex, or both.
.DESCRIPTION
  Interactive by default; also scriptable:
    .\install.ps1 -Claude [-Symlink|-Copy]
    .\install.ps1 -Codex
    .\install.ps1 -Both   [-Symlink|-Copy]
    .\install.ps1 -Hybrid [-Symlink|-Copy]
    .\install.ps1 -Marketplace
  Re-runnable (idempotent). Fail-soft: a problem with one engine doesn't abort the other.
#>
[CmdletBinding()]
param(
  [switch]$Claude, [switch]$Codex, [switch]$Both, [switch]$Hybrid, [switch]$Marketplace,
  [switch]$Symlink, [switch]$Copy
)

$ErrorActionPreference = 'Continue'
$REPO       = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir  = Join-Path $env:USERPROFILE '.claude\plugins\kensa-qa'
$CodexHome  = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$Stage      = Join-Path $CodexHome '.kensa-marketplace'
$Market     = 'kensa-local'

function Have-Claude { Test-Path (Join-Path $env:USERPROFILE '.claude') }
function Have-Codex  { [bool](Get-Command codex -ErrorAction SilentlyContinue) }

function Copy-Tree($src, $dst) {
  if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  Copy-Item -Recurse -Force (Join-Path $src '*') $dst
}

function Print-Marketplace {
  Write-Host ""
  Write-Host "Classic marketplace install (no installer needed):"
  Write-Host ""
  Write-Host "  Claude Code:"
  Write-Host "    /plugin marketplace add rpluzhnikov/QA_agents"
  Write-Host "    /plugin install kensa-qa@rpluzhnikov"
  Write-Host ""
  Write-Host "  Codex (local, via this checkout):"
  Write-Host "    .\install.ps1 -Codex     # stages the plugin and runs 'codex plugin add'"
  Write-Host ""
}

function Install-Claude($strategy) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ClaudeDir) | Out-Null
  if ($strategy -eq 'symlink') {
    if (Test-Path $ClaudeDir) { Remove-Item -Recurse -Force $ClaudeDir }
    try {
      New-Item -ItemType SymbolicLink -Path $ClaudeDir -Target $REPO -ErrorAction Stop | Out-Null
      Write-Host "  Symlinked $ClaudeDir -> $REPO"
    } catch {
      Write-Host "  Symlink failed (need Developer Mode or admin); copying instead."
      Copy-Tree $REPO $ClaudeDir; Write-Host "  Copied to $ClaudeDir"
    }
  } else {
    Copy-Tree $REPO $ClaudeDir; Write-Host "  Copied to $ClaudeDir"
  }
  Write-Host "  -> Restart Claude Code fully, then run /setup in your project."
}

function Install-Codex {
  if (-not (Have-Codex)) { Write-Host "  Codex CLI not found on PATH - skipping."; return }
  Write-Host "  Staging native Codex plugin in $Stage ..."
  if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
  $pluginDir = Join-Path $Stage 'plugins\kensa-qa'
  New-Item -ItemType Directory -Force -Path (Join-Path $pluginDir '.codex-plugin') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $Stage '.agents\plugins') | Out-Null
  Copy-Item -Force (Join-Path $REPO '.codex-plugin\plugin.json') (Join-Path $pluginDir '.codex-plugin\plugin.json')
  Copy-Item -Recurse -Force (Join-Path $REPO 'skills') (Join-Path $pluginDir 'skills')
  Copy-Item -Recurse -Force (Join-Path $REPO 'hooks')  (Join-Path $pluginDir 'hooks')
  Copy-Item -Force (Join-Path $REPO 'codex\marketplace.template.json') (Join-Path $Stage '.agents\plugins\marketplace.json')

  & codex plugin marketplace add "$Stage" 2>&1 | Out-Null
  $added = & codex plugin add "kensa-qa@$Market" 2>&1
  if ($LASTEXITCODE -eq 0) { Write-Host "  Installed plugin kensa-qa@$Market (skills + Stop hooks)." }
  else { Write-Host "  Plugin add reported an issue (already installed?) - continuing." }

  New-Item -ItemType Directory -Force -Path (Join-Path $CodexHome 'agents')  | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $CodexHome 'prompts') | Out-Null
  Copy-Item -Force (Join-Path $REPO '.codex\agents\*.toml') (Join-Path $CodexHome 'agents') -ErrorAction SilentlyContinue
  Copy-Item -Force (Join-Path $REPO 'prompts\*.md')        (Join-Path $CodexHome 'prompts') -ErrorAction SilentlyContinue
  Write-Host "  Subagents -> $CodexHome\agents\ ; prompts -> $CodexHome\prompts\ (use /kensa-...)."
  Write-Host "  Notes: review & trust the plugin's Stop hooks in Codex (/plugins). The"
  Write-Host "  sequential-thinking MCP is optional. Consider merging this repo's AGENTS.md into your project's."
}

function Codex-SmokeTest {
  if (-not (Have-Codex)) { return }
  $ans = Read-Host "  Run a Codex 'codex exec' smoke test now? [y/N]"
  if ($ans -match '^(y|Y)') {
    Write-Host "  Testing (model from ~/.codex/config.toml) ..."
    $out = "Reply with exactly the single word: PONG" | & codex exec --sandbox read-only --skip-git-repo-check --cd (Get-Location).Path - 2>&1
    if ("$out" -match 'PONG') { Write-Host '  OK - codex exec works.' }
    else { Write-Host '  codex exec did NOT return PONG. If you saw a 400, set model = "gpt-5.5" in ~/.codex/config.toml (ChatGPT logins). See CODEX_INTEGRATION.md.' }
  }
}

function Choose-Strategy {
  if ($Symlink) { return 'symlink' }
  if ($Copy)    { return 'copy' }
  $ans = Read-Host "Install strategy - [c]opy (default, safe) or [s]ymlink (dev)?"
  if ($ans -match '^(s|S)') { 'symlink' } else { 'copy' }
}

# Resolve target.
$target = $null
if ($Marketplace) { $target = 'marketplace' }
elseif ($Both)    { $target = 'both' }
elseif ($Hybrid)  { $target = 'hybrid' }
elseif ($Claude)  { $target = 'claude' }
elseif ($Codex)   { $target = 'codex' }

if (-not $target) {
  Write-Host "kensa-qa installer"
  Write-Host ("  Claude Code detected: " + $(if (Have-Claude) {'yes'} else {'no'}))
  Write-Host ("  Codex CLI detected:   " + $(if (Have-Codex)  {'yes'} else {'no'}))
  Write-Host ""
  Write-Host "  1) Claude Code plugin"
  Write-Host "  2) Codex native plugin"
  Write-Host "  3) Both"
  Write-Host "  4) Hybrid (Claude + Codex delegation; /setup wires the role per project)"
  Write-Host "  5) Marketplace instructions only"
  Write-Host "  q) quit"
  switch (Read-Host "Choose") {
    '1' { $target = 'claude' }      '2' { $target = 'codex' }
    '3' { $target = 'both' }        '4' { $target = 'hybrid' }
    '5' { $target = 'marketplace' } default { Write-Host "Nothing chosen."; exit 0 }
  }
}

switch ($target) {
  'marketplace' { Print-Marketplace }
  'claude' { $s = Choose-Strategy; Write-Host "Installing for Claude Code..."; Install-Claude $s }
  'codex'  { Write-Host "Installing for Codex...";        Install-Codex }
  'both'   { $s = Choose-Strategy; Write-Host "Installing for Claude Code..."; Install-Claude $s
             Write-Host "Installing for Codex...";        Install-Codex }
  'hybrid' { $s = Choose-Strategy; Write-Host "Installing for Claude Code (hybrid)..."; Install-Claude $s
             Write-Host "Hybrid mode: /setup will detect Codex and ask how to use it (worker / reviewer / off)."
             Codex-SmokeTest }
}

Write-Host ""
Write-Host "Done."
