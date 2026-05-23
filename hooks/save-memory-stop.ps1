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
Auto-checkpoint required before stop.

A /new-feature or /update-feature ran in this session and no memory checkpoint
has been written for it. Run the save-memory protocol per commands/save-memory.md:

  1. Identify candidate learnings (conventions, glossary, patterns, shared steps,
     tags) from this session.
  2. If .tms/memory/project.md sets `auto_save_learnings: true`, apply silently
     and report what was saved. Otherwise present all candidates to the user in
     a single message (yes/no/edit per item) and apply confirmed ones.
  3. After applying -- or after deciding there is nothing to save -- emit the
     sentinel on its own line, verbatim:

         memory-checkpoint: done

     (If nothing was saved, append a short note, e.g.
     `memory-checkpoint: done (nothing to save)` -- the Stop hook only keys on
     the prefix.)

The Stop hook keys on that exact prefix; without it the next Stop will block
again.
'@

$out = [pscustomobject]@{
  decision = 'block'
  reason   = $reason
} | ConvertTo-Json -Compress -Depth 4

[Console]::Out.Write($out)
exit 0
