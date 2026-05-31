#!/usr/bin/env sh
# kensa-qa installer (macOS/Linux) — deploy the plugin for Claude Code, Codex, or both.
#
# Interactive by default; also scriptable:
#   ./install.sh --claude [--symlink|--copy]
#   ./install.sh --codex
#   ./install.sh --both   [--symlink|--copy]
#   ./install.sh --hybrid [--symlink|--copy]
#   ./install.sh --marketplace      # just print the classic marketplace commands
# Re-runnable (idempotent). Fail-soft: a problem with one engine doesn't abort the other.

set -u

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude/plugins/kensa-qa"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
STAGE="$CODEX_HOME/.kensa-marketplace"
MARKET="kensa-local"

TARGET=""
STRATEGY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --claude) TARGET=claude ;;
    --codex) TARGET=codex ;;
    --both) TARGET=both ;;
    --hybrid) TARGET=hybrid ;;
    --marketplace) TARGET=marketplace ;;
    --symlink) STRATEGY=symlink ;;
    --copy) STRATEGY=copy ;;
    -h|--help) TARGET=help ;;
    *) printf 'Unknown option: %s\n' "$1" ;;
  esac
  shift
done

say()  { printf '%s\n' "$*"; }
have_claude() { [ -d "$HOME/.claude" ]; }
have_codex()  { command -v codex >/dev/null 2>&1; }

ask() { # prompt -> echoes the typed line
  printf '%s' "$1" >&2
  read -r _ans || _ans=""
  printf '%s' "$_ans"
}

copy_tree() { rm -rf "$2"; mkdir -p "$2"; cp -R "$1/." "$2/"; }

print_marketplace() {
  say ""
  say "Classic marketplace install (no installer needed):"
  say ""
  say "  Claude Code:"
  say "    /plugin marketplace add rpluzhnikov/QA_agents"
  say "    /plugin install kensa-qa@rpluzhnikov"
  say ""
  say "  Codex (local, via this checkout):"
  say "    ./install.sh --codex        # stages the plugin and runs 'codex plugin add'"
  say ""
}

install_claude() {
  strat="$1"
  mkdir -p "$(dirname "$CLAUDE_DIR")"
  if [ "$strat" = symlink ]; then
    rm -rf "$CLAUDE_DIR"
    if ln -s "$REPO" "$CLAUDE_DIR" 2>/dev/null; then
      say "  Symlinked $CLAUDE_DIR -> $REPO"
    else
      say "  Symlink failed; copying instead."
      copy_tree "$REPO" "$CLAUDE_DIR"; say "  Copied to $CLAUDE_DIR"
    fi
  else
    copy_tree "$REPO" "$CLAUDE_DIR"; say "  Copied to $CLAUDE_DIR"
  fi
  say "  -> Restart Claude Code fully, then run /setup in your project."
}

install_codex() {
  if ! have_codex; then say "  Codex CLI not found on PATH — skipping."; return; fi
  say "  Staging native Codex plugin in $STAGE ..."
  rm -rf "$STAGE"
  mkdir -p "$STAGE/plugins/kensa-qa/.codex-plugin" "$STAGE/.agents/plugins"
  cp "$REPO/.codex-plugin/plugin.json" "$STAGE/plugins/kensa-qa/.codex-plugin/plugin.json"
  cp -R "$REPO/skills" "$STAGE/plugins/kensa-qa/skills"
  cp -R "$REPO/hooks"  "$STAGE/plugins/kensa-qa/hooks"
  cp "$REPO/codex/marketplace.template.json" "$STAGE/.agents/plugins/marketplace.json"

  codex plugin marketplace add "$STAGE" >/dev/null 2>&1 \
    || codex plugin marketplace add "$STAGE" || say "  (marketplace add reported an issue)"
  if codex plugin add "kensa-qa@$MARKET" 2>/dev/null; then
    say "  Installed plugin kensa-qa@$MARKET (skills + Stop hooks)."
  else
    say "  Plugin add reported an issue (already installed?) — continuing."
  fi

  mkdir -p "$CODEX_HOME/agents" "$CODEX_HOME/prompts"
  cp "$REPO/.codex/agents/"*.toml "$CODEX_HOME/agents/" 2>/dev/null || true
  for f in "$REPO/prompts/"*.md; do [ -f "$f" ] && cp "$f" "$CODEX_HOME/prompts/"; done
  say "  Subagents -> $CODEX_HOME/agents/ ; prompts -> $CODEX_HOME/prompts/ (use /kensa-...)."
  say "  Notes: review & trust the plugin's Stop hooks in Codex (/plugins). The"
  say "  sequential-thinking MCP is optional: 'codex mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking'."
  say "  Consider merging this repo's AGENTS.md into your project's AGENTS.md."
}

codex_smoke_test() {
  have_codex || return
  ans=$(ask "  Run a Codex 'codex exec' smoke test now? [y/N] ")
  case "$ans" in
    y|Y)
      say "  Testing (model from ~/.codex/config.toml) ..."
      out=$(printf 'Reply with exactly the single word: PONG\n' | codex exec --sandbox read-only --skip-git-repo-check --cd "$(pwd)" - 2>&1)
      if printf '%s' "$out" | grep -q 'PONG'; then
        say "  OK — codex exec works."
      else
        say "  codex exec did NOT return PONG. If you saw a 400, set model = \"gpt-5.5\" in ~/.codex/config.toml (ChatGPT logins). See CODEX_INTEGRATION.md."
      fi ;;
    *) : ;;
  esac
}

choose_strategy() {
  [ -n "$STRATEGY" ] && return
  ans=$(ask "Install strategy — [c]opy (default, safe) or [s]ymlink (dev)? ")
  case "$ans" in s|S) STRATEGY=symlink ;; *) STRATEGY=copy ;; esac
}

main_menu() {
  say "kensa-qa installer"
  say "  Claude Code detected: $(have_claude && echo yes || echo no)"
  say "  Codex CLI detected:   $(have_codex && echo yes || echo no)"
  say ""
  say "  1) Claude Code plugin"
  say "  2) Codex native plugin"
  say "  3) Both"
  say "  4) Hybrid (Claude + Codex delegation; /setup wires the role per project)"
  say "  5) Marketplace instructions only"
  say "  q) quit"
  ans=$(ask "Choose: ")
  case "$ans" in
    1) TARGET=claude ;; 2) TARGET=codex ;; 3) TARGET=both ;;
    4) TARGET=hybrid ;; 5) TARGET=marketplace ;; q|Q) exit 0 ;;
    *) say "Nothing chosen."; exit 0 ;;
  esac
}

[ "$TARGET" = help ] && { say "See header of $0 for flags."; exit 0; }
[ -z "$TARGET" ] && main_menu

case "$TARGET" in
  marketplace) print_marketplace ;;
  claude)  choose_strategy; say "Installing for Claude Code..."; install_claude "$STRATEGY" ;;
  codex)   say "Installing for Codex...";       install_codex ;;
  both)    choose_strategy; say "Installing for Claude Code...";    install_claude "$STRATEGY"
           say "Installing for Codex...";       install_codex ;;
  hybrid)  choose_strategy; say "Installing for Claude Code (hybrid)..."; install_claude "$STRATEGY"
           say "Hybrid mode: /setup will detect Codex and ask how to use it (worker / reviewer / off)."
           codex_smoke_test ;;
esac

say ""
say "Done."
