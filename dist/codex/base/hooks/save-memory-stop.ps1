# Stop hook for kensa-qa (Windows fallback; the Claude engine registers the
# cross-platform save-memory-stop.js — this script is kept for the Codex engine,
# whose hooks.json selects it via commandWindows).
#
# Marker-file protocol:
#   /new-feature and /update-feature create `.tms/.pending-checkpoint` when authoring
#   begins; the save-memory protocol deletes it as its final step. This hook blocks
#   the stop only while the marker exists — no transcript scanning, no chat sentinel,
#   so merely *mentioning* a command never re-arms it.
#
# Input  (stdin JSON, sent on the Stop event):
#   { "cwd": "...", "stop_hook_active": false, ... }
#
# Output (stdout, JSON):
#   {"decision":"block","reason":"..."}    while the marker exists
#   (nothing)                              otherwise -- stop proceeds
#
# Anti-loop:
#   - When stop_hook_active is true the hook already blocked once in this stop
#     cycle; allow the stop regardless so the user can never get wedged.
#
# Failure mode:
#   - Any parse error exits 0 (allow stop) -- the hook never blocks a session
#     because of its own bug.

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

# 3. Locate the marker relative to the session cwd.
$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }
$marker = Join-Path $cwd '.tms\.pending-checkpoint'

try {
  if (-not (Test-Path -LiteralPath $marker)) { Allow-Stop }
} catch { Allow-Stop }

# 4. Block. The reason is fed back to the model and the turn continues.
$reason = 'Memory checkpoint owed: an authoring command (/new-feature or /update-feature) has not been closed out. Run the save-memory protocol (commands/save-memory.md) now, then delete the marker file `.tms/.pending-checkpoint`. If there is nothing worth saving, or `.tms/memory/` does not exist, just delete the marker and finish.'

$out = [pscustomobject]@{
  decision = 'block'
  reason   = $reason
} | ConvertTo-Json -Compress -Depth 4

[Console]::Out.Write($out)
exit 0
