#!/bin/bash
# terminal-project-folders — uninstaller
# Removes shell helpers, status line script, and statusLine setting.
# Does NOT touch ~/projects/<your-projects>/.

set -u

ZSHRC="$HOME/.zshrc"
STATUSLINE="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

MARKER_BEGIN="# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----"
MARKER_END="# ---- TERMINAL_PROJECT_FOLDERS_END ----"

echo ""
echo "terminal-project-folders — uninstall"
echo ""

# Strip the shell block
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

echo ""
echo "Uninstalled. Your projects under ~/projects/ are untouched."
echo "Open a new terminal for shell changes to take effect."
