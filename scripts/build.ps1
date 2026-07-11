#!/usr/bin/env pwsh
# Assemble self-contained, IDE-droppable plugin folders under dist/<engine>,
# split into an always-installed BASE and optional, additive BUNDLES.
#
# Source of truth:
#   catalog.json                      base + bundle membership (which skills/agents/commands go where)
#   shared/{skills,hooks,templates}   engine-agnostic payload, routed per catalog
#   engines/claude/*                  Claude-specific (.claude-plugin, CLAUDE.md, agents, commands)
#   engines/codex/*                   Codex-specific (.codex-plugin, AGENTS.md, .codex/agents, .codex/prompts)
#
# Logical-name convention (see catalog.json):
#   agent  'x' -> engines/claude/agents/x.md            + engines/codex/.codex/agents/x.toml
#   command 'y'-> engines/claude/commands/y.md          + engines/codex/.codex/prompts/kensa-y.md
#   skill  's' -> shared/skills/s/
#
# Output (committed, this is what the IDE downloads):
#   dist/<engine>/base/            ALWAYS installed (engine.source in engines.json)
#   dist/<engine>/bundles/<id>/    optional add-ons (engineSources in engines.json)
#
# Usage:  pwsh scripts/build.ps1   (or: powershell.exe -File scripts/build.ps1)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$shared  = Join-Path $root 'shared'
$dist    = Join-Path $root 'dist'
$catalog = Get-Content (Join-Path $root 'catalog.json') -Raw | ConvertFrom-Json

$engines = @('claude', 'codex')

function New-Dir($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null }

function Copy-Skill($name, $dstSkillsDir) {
    $src = Join-Path $shared "skills\$name"
    if (-not (Test-Path $src)) { throw "skill not found: shared/skills/$name" }
    New-Dir $dstSkillsDir
    Copy-Item -Path $src -Destination $dstSkillsDir -Recurse -Force
}

# Place one engine's agent/command file for a logical name into $dstRoot.
function Copy-EngineAgent($engine, $name, $dstRoot) {
    if ($engine -eq 'claude') {
        $src = Join-Path $root "engines\claude\agents\$name.md"
        $dst = Join-Path $dstRoot 'agents'
    } else {
        $src = Join-Path $root "engines\codex\.codex\agents\$name.toml"
        $dst = Join-Path $dstRoot '.codex\agents'
    }
    if (-not (Test-Path $src)) { throw "agent not found for ${engine}: $name" }
    New-Dir $dst
    Copy-Item -Path $src -Destination $dst -Force
}

function Copy-EngineCommand($engine, $name, $dstRoot) {
    if ($engine -eq 'claude') {
        $src = Join-Path $root "engines\claude\commands\$name.md"
        $dst = Join-Path $dstRoot 'commands'
    } else {
        $src = Join-Path $root "engines\codex\.codex\prompts\kensa-$name.md"
        $dst = Join-Path $dstRoot '.codex\prompts'
    }
    if (-not (Test-Path $src)) { throw "command not found for ${engine}: $name" }
    New-Dir $dst
    Copy-Item -Path $src -Destination $dst -Force
}

# ---- assemble ----------------------------------------------------------------
foreach ($engine in $engines) {
    $engOut = Join-Path $dist $engine
    if (Test-Path $engOut) { Remove-Item -Recurse -Force $engOut }
    New-Dir $engOut

    $base = Join-Path $engOut 'base'
    New-Dir $base

    # 1) engine-specific base files, EXCLUDING the membership-filtered dirs
    $src = Join-Path $root "engines\$engine"
    $exclude = if ($engine -eq 'claude') { @('agents', 'commands') } else { @('.codex') }
    Get-ChildItem -Force $src | Where-Object { $exclude -notcontains $_.Name } |
        ForEach-Object { Copy-Item -Path $_.FullName -Destination $base -Recurse -Force }

    # 2) base agents + commands (membership-filtered)
    foreach ($a in $catalog.base.agents)   { Copy-EngineAgent   $engine $a $base }
    foreach ($c in $catalog.base.commands) { Copy-EngineCommand $engine $c $base }

    # 3) base shared payload: skills, hooks, templates
    foreach ($s in $catalog.base.skills) { Copy-Skill $s (Join-Path $base 'skills') }
    foreach ($p in @('hooks', 'templates')) {
        Copy-Item -Path (Join-Path $shared $p) -Destination $base -Recurse -Force
    }
    # Claude registers the Stop hook inline in .claude-plugin/plugin.json
    # (expanding ${CLAUDE_PLUGIN_ROOT}); the shared hooks/hooks.json is a
    # Codex-only registration. Shipping it in the Claude build makes Claude
    # auto-discover it and fire the Stop hook twice. Ship only scripts for Claude.
    if ($engine -eq 'claude') {
        Remove-Item -Force (Join-Path $base 'hooks\hooks.json') -ErrorAction SilentlyContinue
    }

    # 4) bundles
    foreach ($b in $catalog.bundles) {
        $bOut = Join-Path $engOut "bundles\$($b.id)"
        New-Dir $bOut
        if ($b.skills)   { foreach ($s in $b.skills)   { Copy-Skill $s (Join-Path $bOut 'skills') } }
        if ($b.agents)   { foreach ($a in $b.agents)   { Copy-EngineAgent   $engine $a $bOut } }
        if ($b.commands) { foreach ($c in $b.commands) { Copy-EngineCommand $engine $c $bOut } }
    }

    Write-Host "built dist/$engine (base + $($catalog.bundles.Count) bundles)" -ForegroundColor Green
}

# ---- per-engine drop README --------------------------------------------------
$claudeReadme = @'
# kensa-qa -- Claude Code engine (built artifact)

Generated by `scripts/build.ps1` -- do not edit by hand. Edit `catalog.json`,
`shared/`, and `engines/claude/`, then rebuild.

## Layout
```
dist/claude/
  base/                          ALWAYS installed (engines.json engine.source)
    .claude-plugin/plugin.json   # hooks + bundled sequential-thinking MCP
    CLAUDE.md
    agents/ commands/ skills/ hooks/ templates/
  bundles/<id>/                  optional add-ons, merged in on selection
    agents/ commands/ skills/
```
Kensa copies `base/` on every install and each selected `bundles/<id>/` on top.
'@

$codexReadme = @'
# kensa-qa -- Codex engine (built artifact)

Generated by `scripts/build.ps1` -- do not edit by hand. Edit `catalog.json`,
`shared/`, and `engines/codex/`, then rebuild.

## Layout
```
dist/codex/
  base/                          ALWAYS installed (engines.json engine.source)
    .codex/agents/*.toml .codex/prompts/*.md
    .codex-plugin/plugin.json  AGENTS.md  skills/ hooks/ templates/
  bundles/<id>/                  optional add-ons, merged into project root
    .codex/agents/*.toml .codex/prompts/*.md skills/
```
'@

Set-Content -Path (Join-Path $dist 'claude\README.md') -Value $claudeReadme -Encoding utf8
Set-Content -Path (Join-Path $dist 'codex\README.md')  -Value $codexReadme  -Encoding utf8

# ---- validation --------------------------------------------------------------
$errors = @()
$sharedSkillCount = (Get-ChildItem -Recurse (Join-Path $shared 'skills') -Filter 'SKILL.md').Count

# catalog covers every shared skill exactly once
$catalogSkills = @($catalog.base.skills)
foreach ($b in $catalog.bundles) { if ($b.skills) { $catalogSkills += $b.skills } }
$dupes = $catalogSkills | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
if ($dupes) { $errors += "catalog.json: skill(s) listed in more than one place: $($dupes -join ', ')" }
if ($catalogSkills.Count -ne $sharedSkillCount) {
    $errors += "catalog.json maps $($catalogSkills.Count) skills but shared/skills has $sharedSkillCount"
}

foreach ($engine in $engines) {
    $engOut = Join-Path $dist $engine
    $base   = Join-Path $engOut 'base'

    # total skills across base+bundles materialize 1:1 with shared
    $n = (Get-ChildItem -Recurse (Join-Path $engOut '') -Filter 'SKILL.md').Count
    if ($n -ne $sharedSkillCount) {
        $errors += "dist/${engine}: SKILL.md count $n != shared $sharedSkillCount"
    }

    # base manifest parses + version present
    $manifestDir = if ($engine -eq 'claude') { '.claude-plugin' } else { '.codex-plugin' }
    $manifest = Join-Path $base "$manifestDir\plugin.json"
    if (-not (Test-Path $manifest)) {
        $errors += "dist/${engine}/base: missing $manifestDir/plugin.json"
    } else {
        try {
            $m = Get-Content $manifest -Raw | ConvertFrom-Json
            if (-not $m.version) { $errors += "dist/${engine}/base: plugin.json has no version" }
        } catch { $errors += "dist/${engine}/base: plugin.json invalid JSON: $_" }
    }

    # hook scripts ship in base; hooks.json registration is Codex-only
    # (.js is the Claude registration; .sh/.ps1 remain for Codex hooks.json)
    foreach ($script in @('save-memory-stop.js', 'save-memory-stop.sh', 'save-memory-stop.ps1')) {
        if (-not (Test-Path (Join-Path $base "hooks\$script"))) {
            $errors += "dist/${engine}/base: missing hooks/$script"
        }
    }
    if ($engine -eq 'codex') {
        if (-not (Test-Path (Join-Path $base 'hooks\hooks.json'))) {
            $errors += "dist/${engine}/base: missing hooks/hooks.json"
        }
    } else {
        if (Test-Path (Join-Path $base 'hooks\hooks.json')) {
            $errors += "dist/${engine}/base: stray hooks/hooks.json (Claude hook is inline in plugin.json -- would double-fire)"
        }
        if ((Get-Content $manifest -Raw) -notmatch '"Stop"') {
            $errors += "dist/${engine}/base: plugin.json missing Stop hook"
        }
    }
}

# Codex subagents (base + bundles) must carry the three required TOML fields
foreach ($toml in Get-ChildItem -Recurse (Join-Path $dist 'codex') -Filter '*.toml' -ErrorAction SilentlyContinue) {
    $body = Get-Content $toml.FullName -Raw
    foreach ($field in @('name', 'description', 'developer_instructions')) {
        if ($body -notmatch "(?m)^\s*$field\s*=") {
            $errors += "$($toml.Name): missing required field '$field'"
        }
    }
}

# every catalog bundle produced a dir for each engine
foreach ($engine in $engines) {
    foreach ($b in $catalog.bundles) {
        $bDir = Join-Path $dist "$engine\bundles\$($b.id)"
        if (-not (Test-Path $bDir)) { $errors += "dist/${engine}: bundle '$($b.id)' produced no directory" }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`nVALIDATION FAILED:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "`nOK -- $sharedSkillCount skills across base+bundles in each engine; manifests valid." -ForegroundColor Green
