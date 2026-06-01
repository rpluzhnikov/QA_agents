#!/usr/bin/env sh
# PostToolUse hook for kensa-qa: keep .tms/config.yaml id counters in sync
# (POSIX port of kensa-sync.ps1). Runs on macOS/Linux; on Windows the hook uses
# commandWindows -> the .ps1.
#
# When an agent writes a suites/**/<id>.md case file directly, the id counter in
# <project>/.tms/config.yaml goes stale until the Kensa IDE's next allocation.
# This hook runs `kensa-cli sync` to recompute the counters from disk, then a
# non-fatal `kensa-cli doctor` advisory check.
#
# Requires `kensa-cli` on PATH (the hook runs in the agent host process, not
# Kensa's embedded terminal). If kensa-cli is absent, the hook no-ops. Never
# blocks the tool call -- always exits 0.

set -u

input=$(cat 2>/dev/null) || exit 0
[ -z "$input" ] && exit 0

field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }

# Locate the project root. Prefer payload.cwd; fall back to current dir.
cwd=$(field cwd)
[ -z "$cwd" ] && cwd=$(pwd)

# Only engage in Kensa projects -- config.yaml is what `sync` operates on.
[ -f "$cwd/.tms/config.yaml" ] || exit 0

# Cheap path filter: only sync when the edited file is under suites/ or .tms/.
# If the path can't be determined, fall through and sync anyway.
fp=$(field file_path)
if [ -n "$fp" ]; then
  case "$fp" in
    *suites/*|*.tms/*) : ;;
    *) exit 0 ;;
  esac
fi

# Require kensa-cli on PATH; if missing, no-op.
command -v kensa-cli >/dev/null 2>&1 || exit 0

# Recompute counters, then advisory integrity check. Both non-fatal.
kensa-cli -C "$cwd" sync   --quiet >/dev/null 2>&1 || true
kensa-cli -C "$cwd" doctor --quiet >/dev/null 2>&1 || true

exit 0
