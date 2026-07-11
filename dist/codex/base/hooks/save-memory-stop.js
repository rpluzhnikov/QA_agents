#!/usr/bin/env node
// Stop hook for kensa-qa (Claude Code registration — see .claude-plugin/plugin.json).
//
// Marker-file protocol:
//   /new-feature and /update-feature create `.tms/.pending-checkpoint` when authoring
//   begins; the save-memory protocol deletes it as its final step. This hook blocks
//   the stop only while the marker exists — no transcript scanning, no chat sentinel,
//   so merely *mentioning* a command never re-arms it.
//
// Input  (stdin JSON, sent by Claude Code on the Stop event):
//   { "cwd": "...", "stop_hook_active": false, ... }
//
// Output (stdout, JSON):
//   {"decision":"block","reason":"..."}   while the marker exists
//   (nothing)                             otherwise — stop proceeds
//
// Anti-loop:
//   - stop_hook_active true → we already blocked once in this stop cycle; allow.
//   - Claude Code force-stops after 8 consecutive blocks regardless.
//
// Failure mode: any error → exit 0 (allow stop). The hook never wedges a session
// because of its own bug.

'use strict';

const fs = require('fs');
const path = require('path');

function allowStop() {
  process.exit(0);
}

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => { raw += chunk; });
process.stdin.on('error', allowStop);
process.stdin.on('end', () => {
  let payload;
  try {
    payload = JSON.parse(raw.replace(/^﻿/, '').trim());
  } catch {
    allowStop();
  }

  if (!payload || payload.stop_hook_active) allowStop();

  const cwd = typeof payload.cwd === 'string' && payload.cwd ? payload.cwd : process.cwd();
  const marker = path.join(cwd, '.tms', '.pending-checkpoint');

  let owed = false;
  try {
    owed = fs.existsSync(marker);
  } catch {
    allowStop();
  }
  if (!owed) allowStop();

  const reason = [
    'Memory checkpoint owed: an authoring command (/new-feature or /update-feature) has not',
    'been closed out. Run the save-memory protocol (commands/save-memory.md) now, then delete',
    'the marker file `.tms/.pending-checkpoint`. If there is nothing worth saving, or',
    '`.tms/memory/` does not exist, just delete the marker and finish.',
  ].join(' ');

  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
  process.exit(0);
});
