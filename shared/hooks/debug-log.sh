#!/usr/bin/env sh
# Stop hook for kensa-qa: write a per-session debug log (POSIX port of debug-log.ps1).
#
# Activates only when the working directory is a kensa project (has .tms/memory/).
# Writes two files into <project>/.tms/debug/ keyed by session_id:
#   session-<id>.md     readable digest (commands, files written, worker spawns)
#   session-<id>.jsonl  snapshot of the transcript for issue reports
#
# Never blocks the stop. Any failure exits 0 silently.
# Runs on macOS/Linux. On Windows the Codex hook uses commandWindows -> the .ps1.

set -u

input=$(cat 2>/dev/null) || exit 0
[ -z "$input" ] && exit 0

# Don't double-write during a hook chain (e.g. save-memory blocked once).
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }

transcript=$(field transcript_path)
session=$(field session_id)
cwd=$(field cwd)
[ -z "$transcript" ] && exit 0
[ -f "$transcript" ] || exit 0
[ -z "$cwd" ] && cwd=$(pwd)
[ -z "$session" ] && session=unknown

# Only engage in kensa projects.
[ -d "$cwd/.tms/memory" ] || exit 0

debugdir="$cwd/.tms/debug"
mkdir -p "$debugdir" 2>/dev/null || exit 0
cp -f "$transcript" "$debugdir/session-$session.jsonl" 2>/dev/null || true

# Scan the transcript once.
commands=""
files=""
turns=0
workers=0
featurecmds=0
while IFS= read -r line || [ -n "$line" ]; do
  turns=$((turns + 1))
  case "$line" in
    *"/new-feature"*)    commands="$commands- /new-feature at line $turns
";    featurecmds=$((featurecmds + 1)) ;;
    *"/update-feature"*) commands="$commands- /update-feature at line $turns
"; featurecmds=$((featurecmds + 1)) ;;
    *"/save-memory"*)    commands="$commands- /save-memory at line $turns
" ;;
    *"/setup"*)          commands="$commands- /setup at line $turns
" ;;
  esac
  case "$line" in
    *'"tool_name":"Task"'*) workers=$((workers + 1)) ;;
  esac
  case "$line" in
    *'"tool_name":"Write"'*|*'"tool_name":"Edit"'*)
      p=$(printf '%s' "$line" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
      case "$p" in
        *".tms/"*|*'.tms\'*) files="$files- \`$p\`
" ;;
      esac ;;
  esac
done < "$transcript"

[ -z "$commands" ] && commands="_(no kensa-qa slash commands this session)_"
if [ -n "$files" ]; then
  files=$(printf '%s' "$files" | sort -u)
else
  files="_(no files written in .tms/ this session)_"
fi

now=$(date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || echo '')
snapshot="$debugdir/session-$session.jsonl"

stuck=""
if [ "$featurecmds" -ge 3 ] && [ "$files" = "_(no files written in .tms/ this session)_" ]; then
  stuck="
> **STUCK SESSION** — \`/new-feature\` / \`/update-feature\` invoked $featurecmds times but 0 files written under \`.tms/\`.
> Common causes: source-of-truth MCP not connected; Lead stuck on a wiki overview page; an unresolved scope question parking the session.
> Open the \`.jsonl\` snapshot and search for the last \`Task\` spawn to see where the run stalled.
"
fi

{
  printf '# Session %s\n%s\n' "$session" "$stuck"
  printf '| Field | Value |\n|-------|-------|\n'
  printf '| Updated | %s |\n' "$now"
  printf '| Project | `%s` |\n' "$cwd"
  printf '| Transcript (snapshot, share this) | `%s` |\n' "$snapshot"
  printf '| Turns observed | %s |\n' "$turns"
  printf '| Worker spawns (Task tool) | %s |\n' "$workers"
  printf '| Feature cmds invoked | %s |\n\n' "$featurecmds"
  printf '## Commands invoked\n\n%s\n\n' "$commands"
  printf '## Files written or edited under .tms/\n\n%s\n\n' "$files"
  printf -- '---\n\n_Written automatically by the kensa-qa `debug-log` Stop hook. When reporting an issue, attach this file plus the `.jsonl` snapshot._\n'
} > "$debugdir/session-$session.md" 2>/dev/null || true

exit 0
