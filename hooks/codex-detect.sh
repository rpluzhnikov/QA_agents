#!/usr/bin/env sh
# codex-detect.sh — print exactly 'codex' or 'internal', always exit 0.
#
# POSIX twin of codex-detect.ps1 (same contract). Used by the Test Lead before
# delegating QA work in hybrid mode. Resolution order (fail-closed):
#   1. If .tms/memory/codex.yaml sets `codex_role: off`     -> internal
#   2. Else if `codex --version` runs (binary on PATH)      -> codex
#   3. Otherwise                                            -> internal
#
# Verdict is cached to .tms/.codex-availability (gitignored). Checks only that
# the binary exists and runs — NOT that `codex exec` works against the API.
#
# Optional arg: $1 = project directory (defaults to the current directory).

set -u

PROJECT_DIR="${1:-$(pwd)}"

emit() {
  verdict="$1"
  if [ -d "$PROJECT_DIR/.tms" ]; then
    stamp="$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || echo '')"
    printf '%s\t%s\n' "$verdict" "$stamp" > "$PROJECT_DIR/.tms/.codex-availability" 2>/dev/null || true
  fi
  printf '%s\n' "$verdict"
  exit 0
}

# 1. Honor the explicit 'off' preference.
if [ -f "$PROJECT_DIR/.tms/memory/codex.yaml" ]; then
  if grep -Eq '^[[:space:]]*codex_role[[:space:]]*:[[:space:]]*off([[:space:]]|$)' \
       "$PROJECT_DIR/.tms/memory/codex.yaml" 2>/dev/null; then
    emit internal
  fi
fi

# 2. Probe the binary.
if command -v codex >/dev/null 2>&1 && codex --version >/dev/null 2>&1; then
  emit codex
fi

# 3. Default.
emit internal
