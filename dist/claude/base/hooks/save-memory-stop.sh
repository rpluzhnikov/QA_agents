#!/usr/bin/env sh
# Stop hook for kensa-qa — POSIX port of save-memory-stop.ps1.
#
# Identical contract on Codex CLI and Claude Code:
#   stdin  : JSON { "transcript_path": "...", "stop_hook_active": false, ... }
#   stdout : {"decision":"block","reason":"..."}  when a memory checkpoint is owed
#            (nothing)                             otherwise -- stop proceeds
#
# Ensures the Lead runs the save-memory protocol after /new-feature or
# /update-feature before the session is allowed to stop. Scans the transcript:
# block iff a command line exists and no "memory-checkpoint: done" line follows it.
#
# Anti-loop: when stop_hook_active is true we already blocked once this cycle --
# allow the stop so the user can never get wedged.
# Fail-open: any parse error or missing transcript exits 0 (allow stop).
#
# Runs on macOS/Linux. On Windows the Codex hook uses commandWindows -> the .ps1.

set -u

input=$(cat 2>/dev/null) || exit 0
[ -z "$input" ] && exit 0

# Anti-loop.
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

# Extract transcript_path (unix path -- no embedded quotes/backslashes on this OS).
transcript=$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0

# Walk the transcript, remember the last line index of command and sentinel.
last_cmd=0
last_sentinel=0
idx=0
while IFS= read -r line || [ -n "$line" ]; do
  idx=$((idx + 1))
  case "$line" in
    *"/new-feature"*|*"/update-feature"*) last_cmd=$idx ;;
  esac
  case "$line" in
    *"memory-checkpoint: done"*|*"memory-checkpoint:done"*) last_sentinel=$idx ;;
  esac
done < "$transcript"

# Decide.
[ "$last_cmd" -eq 0 ] && exit 0                 # no qualifying command this session
[ "$last_sentinel" -ge "$last_cmd" ] && exit 0  # sentinel covers the latest command

# Block. \n stays literal in the %s arg -> valid JSON escaped newlines.
reason='Memory checkpoint owed: run the save-memory protocol (commands/save-memory.md) for the /new-feature or /update-feature in this session, then emit on its own line:\n    memory-checkpoint: done\n(If nothing to save, append a note, e.g. `memory-checkpoint: done (nothing to save)` -- the hook keys only on the prefix.)'

printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0
