# codex-detect.ps1 — print exactly 'codex' or 'internal', always exit 0.
#
# Used by the Test Lead before delegating QA work in hybrid mode. Resolution
# order (fail-closed — anything uncertain resolves to 'internal'):
#   1. If .tms/memory/codex.yaml sets `codex_role: off`     -> internal
#   2. Else if `codex --version` runs (binary on PATH)      -> codex
#   3. Otherwise                                            -> internal
#
# The verdict is cached (for transparency / debugging) to .tms/.codex-availability
# — gitignored, re-written every run, never committed.
#
# IMPORTANT: this checks only that the binary EXISTS and runs. It does NOT
# validate `codex exec` against the API — a default model your account can't use
# (e.g. gpt-5 on a ChatGPT login) passes this check but fails at call time, and
# the Lead then degrades to internal. See CODEX_INTEGRATION.md.
#
# Optional arg: $args[0] = project directory (defaults to the current directory).

$ErrorActionPreference = 'SilentlyContinue'

$projectDir = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { (Get-Location).Path }

function Emit([string]$verdict) {
  $tms = Join-Path $projectDir '.tms'
  if (Test-Path -LiteralPath $tms) {
    try {
      $stamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
      Set-Content -LiteralPath (Join-Path $tms '.codex-availability') `
        -Value "$verdict`t$stamp" -Encoding utf8 -Force
    } catch { }
  }
  Write-Output $verdict
  exit 0
}

# 1. Honor the explicit 'off' preference.
$pref = Join-Path $projectDir '.tms\memory\codex.yaml'
if (Test-Path -LiteralPath $pref) {
  try {
    foreach ($line in Get-Content -LiteralPath $pref) {
      if ($line -match '^\s*codex_role\s*:\s*off\b') { Emit 'internal' }
    }
  } catch { }
}

# 2. Probe the binary.
try {
  $null = & codex --version 2>$null
  if ($LASTEXITCODE -eq 0) { Emit 'codex' }
} catch { }

# 3. Default.
Emit 'internal'
