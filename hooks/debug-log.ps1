# Stop hook for kensa-qa: write a debug log of the current session.
#
# Activates only when the working directory looks like a kensa project (it has
# .tms/memory/). Writes two files into <project>/.tms/debug/ keyed by
# session_id:
#
#   session-<id>.md     readable digest: commands invoked, files written,
#                       worker spawns, transcript pointers
#   session-<id>.jsonl  fresh snapshot of the full transcript so the user can
#                       attach it when reporting issues
#
# Never blocks the stop. Any failure exits 0 silently -- debug logging must
# never get in the user's way.

$ErrorActionPreference = 'SilentlyContinue'

function Quit { exit 0 }

# 1. Parse payload.
try {
  $rawIn = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($rawIn)) { Quit }
  $payload = $rawIn | ConvertFrom-Json
} catch { Quit }

# Don't double-write during a hook chain (e.g. save-memory blocked once).
if ($payload.stop_hook_active) { Quit }

$transcript = $payload.transcript_path
$sessionId  = $payload.session_id
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { Quit }
if (-not $sessionId) { $sessionId = 'unknown' }

# 2. Locate the project root. Prefer payload.cwd; fall back to current dir.
$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }

# Only engage in kensa projects. The presence of .tms/memory/ is the signal.
$memoryRoot = Join-Path $cwd '.tms\memory'
if (-not (Test-Path -LiteralPath $memoryRoot)) { Quit }

# 3. Scan the transcript once, collect everything we want in the digest.
$commands     = New-Object System.Collections.Generic.List[string]
$filesWritten = New-Object System.Collections.Generic.List[string]
$workerSpawns = 0
$turnCount    = 0

$cmdRegex   = [regex]'(?i)/(new-feature|update-feature|save-memory|setup)\b'
$pathRegex  = [regex]'"file_path"\s*:\s*"([^"]+)"'

try {
  $idx = 0
  foreach ($line in [System.IO.File]::ReadLines($transcript)) {
    $idx++
    if ([string]::IsNullOrEmpty($line)) { continue }

    # Each JSONL line is approximately one event. Counting them is a coarse proxy for "turns".
    $turnCount++

    # Cheap substring guards first.
    if ($line.IndexOf('/new-feature') -ge 0 -or
        $line.IndexOf('/update-feature') -ge 0 -or
        $line.IndexOf('/save-memory') -ge 0 -or
        $line.IndexOf('/setup') -ge 0) {
      $m = $cmdRegex.Match($line)
      if ($m.Success) {
        [void]$commands.Add("$($m.Value) at line $idx")
      }
    }

    if ($line.IndexOf('"tool_name":"Task"') -ge 0) { $workerSpawns++ }

    if ($line.IndexOf('"tool_name":"Write"') -ge 0 -or
        $line.IndexOf('"tool_name":"Edit"')  -ge 0) {
      $pm = $pathRegex.Match($line)
      if ($pm.Success) {
        $p = $pm.Groups[1].Value -replace '\\\\', '\'
        # Only care about files inside .tms/ -- that's the plugin's output surface.
        if ($p -match '\.tms[\\/]') { [void]$filesWritten.Add($p) }
      }
    }
  }
} catch { Quit }

# 4. Ensure debug dir and snapshot the transcript.
$debugDir = Join-Path $cwd '.tms\debug'
if (-not (Test-Path -LiteralPath $debugDir)) {
  try { New-Item -ItemType Directory -Path $debugDir -Force | Out-Null } catch { Quit }
}

$snapshotPath = Join-Path $debugDir "session-$sessionId.jsonl"
try { Copy-Item -LiteralPath $transcript -Destination $snapshotPath -Force } catch { }

# 5. Render the digest.
$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'

if ($commands.Count -gt 0) {
  $commandList = ($commands | ForEach-Object { "- $_" }) -join "`r`n"
} else {
  $commandList = '_(no kensa-qa slash commands this session)_'
}

$uniqueFiles = $filesWritten | Sort-Object -Unique
if ($uniqueFiles.Count -gt 0) {
  $fileList = ($uniqueFiles | ForEach-Object { "- ``$_``" }) -join "`r`n"
} else {
  $fileList = '_(no files written in .tms/ this session)_'
}

# Stuck-session heuristic: /new-feature or /update-feature was invoked but
# nothing landed in .tms/. Common causes: MCP not connected, Lead stuck on
# an overview page, scope question never resolved. Emit a banner so the
# user notices when reading the digest later.
$featureCmdCount = ($commands | Where-Object { $_ -match '^/(new-feature|update-feature)' }).Count
$stuckBanner = ''
if (($featureCmdCount -ge 3) -and ($uniqueFiles.Count -eq 0)) {
  $stuckBanner = @"

> **STUCK SESSION** — ``/new-feature`` / ``/update-feature`` invoked $featureCmdCount times but 0 files written under ``.tms/``.
> Common causes: MCP for the source-of-truth not connected; Lead stuck on a wiki overview page without finding the actual specs; an unresolved scope question silently parking the session.
> Open the ``.jsonl`` snapshot below and search for the last ``Task`` tool spawn — its absence (or its early failure) shows where the run stalled.

"@
}

$digest = @"
# Session $sessionId
$stuckBanner
| Field | Value |
|-------|-------|
| Updated | $now |
| Project | ``$cwd`` |
| Transcript (live, may rotate) | ``$transcript`` |
| Transcript (snapshot, share this) | ``$snapshotPath`` |
| Turns observed | $turnCount |
| Worker spawns (Task tool) | $workerSpawns |
| Feature cmds invoked | $featureCmdCount |

## Commands invoked

$commandList

## Files written or edited under .tms/

$fileList

---

_Written automatically by the kensa-qa ``debug-log`` Stop hook.
When reporting an issue or sending feedback, attach this file plus the ``.jsonl`` snapshot referenced above._
"@

$digestPath = Join-Path $debugDir "session-$sessionId.md"
try { Set-Content -LiteralPath $digestPath -Value $digest -Encoding utf8 -Force } catch { }

Quit
