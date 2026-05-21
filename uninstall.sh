#!/bin/bash
# terminal-project-folders — uninstaller
# Removes shell helpers, the claude wrapper, the status line script, the
# statusLine setting, the global CLAUDE.md fragment, and the hop directory.
# Does NOT touch ~/projects/<your-projects>/.

set -u

ZSHRC="$HOME/.zshrc"
STATUSLINE="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
HOP_DIR="$HOME/.terminal-project-folders"

MARKER_BEGIN="# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----"
MARKER_END="# ---- TERMINAL_PROJECT_FOLDERS_END ----"
CLAUDE_MD_BEGIN="<!-- TERMINAL_PROJECT_FOLDERS_BEGIN -->"
CLAUDE_MD_END="<!-- TERMINAL_PROJECT_FOLDERS_END -->"

echo ""
echo "terminal-project-folders — uninstall"
echo ""

# Strip the shell block (proj, newproj, claude wrapper)
if [ -f "$ZSHRC" ] && grep -q "$MARKER_BEGIN" "$ZSHRC"; then
  tmp=$(mktemp)
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
  echo "  ✓ Removed shell helpers from $ZSHRC"
else
  echo "  • No shell block to remove."
fi

# Remove statusline.sh
if [ -f "$STATUSLINE" ]; then
  rm -f "$STATUSLINE"
  echo "  ✓ Removed $STATUSLINE"
fi

# Strip statusLine from settings.json
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "  ✓ Removed statusLine from $SETTINGS"
fi

# Strip the CLAUDE.md fragment
if [ -f "$CLAUDE_MD" ] && grep -q "$CLAUDE_MD_BEGIN" "$CLAUDE_MD"; then
  tmp=$(mktemp)
  awk -v b="$CLAUDE_MD_BEGIN" -v e="$CLAUDE_MD_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$CLAUDE_MD" > "$tmp" && mv "$tmp" "$CLAUDE_MD"
  echo "  ✓ Removed CLAUDE.md fragment from $CLAUDE_MD"
fi

# Remove the hop directory (it only holds a tiny coordination file)
if [ -d "$HOP_DIR" ]; then
  rm -rf "$HOP_DIR"
  echo "  ✓ Removed $HOP_DIR"
fi

echo ""
echo "Uninstalled. Your projects under ~/projects/ are untouched."
echo "Open a new terminal for shell changes to take effect."
