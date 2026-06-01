# PostToolUse hook for kensa-qa: keep .tms/config.yaml id counters in sync.
#
# When an agent writes a `suites/**/<id>.md` case file directly (instead of the
# Kensa IDE creating it), the id counter in <project>/.tms/config.yaml
# (project.next_id, plus next_shared_step_id / next_plan_id) goes stale until
# the IDE's next allocation. This hook runs `kensa-cli sync` to recompute the
# counters from disk, then a non-fatal `kensa-cli doctor` advisory check.
#
# Requires `kensa-cli` on PATH (the hook runs in the Claude Code process, NOT
# Kensa's embedded terminal, so Kensa's PATH injection does not apply). If
# kensa-cli is absent, the hook no-ops. Never blocks the tool call -- any
# failure exits 0 silently.

$ErrorActionPreference = 'SilentlyContinue'

function Quit { exit 0 }

# 1. Parse the PostToolUse payload from stdin.
try {
  $rawIn = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($rawIn)) { Quit }
  $payload = $rawIn | ConvertFrom-Json
} catch { Quit }

# 2. Locate the project root. Prefer payload.cwd; fall back to current dir.
#    (CLAUDE_PROJECT_DIR is Claude-only; cwd from the payload works everywhere.)
$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }

# 3. Only engage in Kensa projects -- .tms/config.yaml is what `sync` operates on.
#    Absent => not a Kensa project => no-op (never fail the tool call).
$configPath = Join-Path $cwd '.tms\config.yaml'
if (-not (Test-Path -LiteralPath $configPath)) { Quit }

# 4. Cheap path filter: only sync when the edited file is under suites/ or .tms/.
#    sync is idempotent + cheap, so this just skips obviously-unrelated edits.
#    If we cannot determine the path, fall through and sync anyway.
$fp = $null
try { $fp = $payload.tool_input.file_path } catch {}
if (-not $fp) { try { $fp = $payload.tool_response.filePath } catch {} }
if ($fp -and ($fp -notmatch '(?i)(^|[\\/])(suites|\.tms)[\\/]')) { Quit }

# 5. Require kensa-cli on PATH; if missing, no-op.
if (-not (Get-Command kensa-cli -ErrorAction SilentlyContinue)) { Quit }

# 6. Recompute counters, then advisory integrity check. Both non-fatal.
try { & kensa-cli -C "$cwd" sync   --quiet 2>$null | Out-Null } catch {}
try { & kensa-cli -C "$cwd" doctor --quiet 2>$null | Out-Null } catch {}

Quit
