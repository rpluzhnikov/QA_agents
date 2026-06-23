# Stop hook for kensa-qa.
# Ensures the Lead runs the save-memory protocol after /new-feature or /update-feature
# before the session is allowed to stop.
#
# Input  (stdin JSON, sent by Claude Code on the Stop event):
#   { "transcript_path": "...jsonl", "stop_hook_active": false, ... }
#
# Output (stdout, JSON):
#   {"decision":"block","reason":"..."}    when a memory checkpoint is owed
#   (nothing)                              otherwise -- stop proceeds
#
# Detection:
#   - Scan the transcript JSONL line-by-line.
#   - Track the LAST line index that mentions /new-feature or /update-feature.
#   - Track the LAST line index that contains the sentinel "memory-checkpoint: done".
#   - Block iff a command line exists and no sentinel line follows it.
#
# Anti-loop:
#   - When stop_hook_active is true the hook already blocked once in this stop
#     cycle; allow the stop regardless so the user can never get wedged.
#
# Failure mode:
#   - Any parse error or missing transcript exits 0 (allow stop) -- the hook never
#     blocks a session because of its own bug.

$ErrorActionPreference = 'Stop'

function Allow-Stop { exit 0 }

# 1. Read stdin payload.
try {
  $rawIn = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($rawIn)) { Allow-Stop }
  $payload = $rawIn | ConvertFrom-Json
} catch { Allow-Stop }

# 2. Break the loop if we already blocked once in this stop cycle.
if ($payload.stop_hook_active) { Allow-Stop }

# 3. Need a transcript to inspect.
$transcript = $payload.transcript_path
if (-not $transcript -or -not (Test-Path -LiteralPath $transcript)) { Allow-Stop }

# 4. Walk transcript, remember the last position of command and sentinel.
$lastCmd = -1
$lastSentinel = -1
$idx = 0

$cmdRegex = [regex]'(?i)/(new-feature|update-feature)\b'
$sentinelRegex = [regex]'(?i)memory-checkpoint:\s*done'

try {
  foreach ($line in [System.IO.File]::ReadLines($transcript)) {
    $idx++
    if ([string]::IsNullOrEmpty($line)) { continue }

    # Cheap substring guards before regex.
    $maybeCmd = ($line.IndexOf('/new-feature') -ge 0) -or ($line.IndexOf('/update-feature') -ge 0)
    $maybeSentinel = $line.IndexOf('memory-checkpoint') -ge 0

    if (-not $maybeCmd -and -not $maybeSentinel) { continue }

    if ($maybeCmd -and $cmdRegex.IsMatch($line)) { $lastCmd = $idx }
    if ($maybeSentinel -and $sentinelRegex.IsMatch($line)) { $lastSentinel = $idx }
  }
} catch { Allow-Stop }

# 5. Decide.
if ($lastCmd -lt 0) { Allow-Stop }              # no qualifying command this session
if ($lastSentinel -ge $lastCmd) { Allow-Stop }  # sentinel covers the latest command

# 6. Block. The reason is fed back to Claude as a system reminder and the turn continues.
$reason = @'
Memory checkpoint owed: run the save-memory protocol (commands/save-memory.md) for the /new-feature or /update-feature in this session, then emit on its own line:
    memory-checkpoint: done
(If nothing to save, append a note, e.g. `memory-checkpoint: done (nothing to save)` -- the hook keys only on the prefix.)
'@

$out = [pscustomobject]@{
  decision = 'block'
  reason   = $reason
} | ConvertTo-Json -Compress -Depth 4

[Console]::Out.Write($out)
exit 0
