#!/usr/bin/env sh
# Stop hook for kensa-qa — POSIX port of save-memory-stop.ps1 (kept for the Codex
# engine; the Claude engine registers the cross-platform save-memory-stop.js).
#
# Marker-file protocol:
#   /new-feature and /update-feature create `.tms/.pending-checkpoint` when authoring
#   begins; the save-memory protocol deletes it as its final step. This hook blocks
#   the stop only while the marker exists — no transcript scanning, no chat sentinel,
#   so merely *mentioning* a command never re-arms it.
#
#   stdin  : JSON { "cwd": "...", "stop_hook_active": false, ... }
#   stdout : {"decision":"block","reason":"..."}  while the marker exists
#            (nothing)                             otherwise -- stop proceeds
#
# Anti-loop: when stop_hook_active is true we already blocked once this cycle --
# allow the stop so the user can never get wedged.
# Fail-open: any parse error exits 0 (allow stop).
#
# Runs on macOS/Linux. On Windows the Codex hook uses commandWindows -> the .ps1.

set -u

input=$(cat 2>/dev/null) || exit 0
[ -z "$input" ] && exit 0

# Anti-loop.
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

# Extract cwd (unix path -- no embedded quotes/backslashes on this OS).
cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
[ -z "$cwd" ] && cwd=$(pwd)

# Block only while the marker exists.
[ -f "$cwd/.tms/.pending-checkpoint" ] || exit 0

reason='Memory checkpoint owed: an authoring command (/new-feature or /update-feature) has not been closed out. Run the save-memory protocol (commands/save-memory.md) now, then delete the marker file `.tms/.pending-checkpoint`. If there is nothing worth saving, or `.tms/memory/` does not exist, just delete the marker and finish.'

printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0
