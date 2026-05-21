#!/bin/bash
# terminal-project-folders — installer
# Adds `proj` and `newproj` to your zsh shell, plus a small Claude Code status line.
# Idempotent: re-running cleanly replaces any previous install.

set -eu

ZSHRC="$HOME/.zshrc"
CLAUDE_DIR="$HOME/.claude"
STATUSLINE="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
PROJECTS_DIR="$HOME/projects"

MARKER_BEGIN="# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----"
MARKER_END="# ---- TERMINAL_PROJECT_FOLDERS_END ----"

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
RESET='\033[0m'

ok()    { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn()  { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
fatal() { printf "  ${RED}✗${RESET} %s\n" "$1" >&2; exit 1; }

echo ""
printf "${BOLD}terminal-project-folders — install${RESET}\n"
echo ""

# Preflight
[ "$(uname)" = "Darwin" ] || warn "Not macOS (detected $(uname)); install may work but is unsupported."
command -v jq >/dev/null 2>&1 || fatal "jq not found. Install with: brew install jq"
command -v claude >/dev/null 2>&1 || warn "claude CLI not found. Install from https://claude.com/claude-code if you want \`proj <name>\` to resume sessions."

mkdir -p "$PROJECTS_DIR" "$CLAUDE_DIR"

# 1. Write the Claude Code status line script
cat > "$STATUSLINE" <<'STATUSLINE_EOF'
#!/bin/bash
# Claude Code status line: shows folder name, port (if .env defines one), and git branch.
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

PROJECT=$(basename "$CWD")

PORT=""
if [ -f "$CWD/.env" ]; then
  PORT=$(grep -E '^PORT=' "$CWD/.env" 2>/dev/null | head -1 | cut -d= -f2)
  [ -n "$PORT" ] && PORT=" · :$PORT"
fi

BRANCH=""
if git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
  [ -n "$BRANCH" ] && BRANCH=" · $BRANCH"
fi

printf "\033[36m%s\033[0m%s%s" "$PROJECT" "$PORT" "$BRANCH"
STATUSLINE_EOF
chmod +x "$STATUSLINE"
ok "Status line installed: $STATUSLINE"

# 2. Patch ~/.claude/settings.json
[ -f "$SETTINGS" ] || echo "{}" > "$SETTINGS"
tmp=$(mktemp)
jq --arg cmd "$STATUSLINE" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
ok "Status line wired into $SETTINGS"

# 3. Patch ~/.zshrc — replace any previous block
[ -f "$ZSHRC" ] || touch "$ZSHRC"
if grep -q "$MARKER_BEGIN" "$ZSHRC"; then
  tmp=$(mktemp)
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
fi

cat >> "$ZSHRC" <<'ZSHRC_EOF'

# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----
# proj — list projects, or jump into one and resume the last Claude Code session.
proj() {
  local PROJECTS_DIR="$HOME/projects"
  if [ $# -eq 0 ]; then
    printf "\n  %-30s  %-5s  %s\n" "PROJECT" "PORT" "LAST MODIFIED"
    printf "  %-30s  %-5s  %s\n" "------------------------------" "-----" "--------------"
    local count=0
    for dir in "$PROJECTS_DIR"/*/; do
      [ -d "$dir" ] || continue
      local name=$(basename "$dir")
      [[ "$name" = .* ]] && continue
      count=$((count + 1))
      local port="—"
      if [ -f "$dir/.env" ]; then
        local p=$(grep -E '^PORT=' "$dir/.env" 2>/dev/null | head -1 | cut -d= -f2)
        [ -n "$p" ] && port="$p"
      fi
      local last=$(/bin/date -r "$dir" "+%Y-%m-%d" 2>/dev/null || echo "—")
      printf "  %-30s  %-5s  %s\n" "$name" "$port" "$last"
    done
    echo ""
    [ "$count" -eq 0 ] && echo "  No projects yet.  Create one with:  newproj <name>" && echo ""
    return 0
  fi

  local name="$1"
  if [ ! -d "$PROJECTS_DIR/$name" ]; then
    echo "No project '$name'. Run 'proj' to list."
    return 1
  fi
  cd "$PROJECTS_DIR/$name" && claude -c
}

# newproj <name> [--port N] — scaffold a new project with a guaranteed-free port.
newproj() {
  local PROJECTS_DIR="$HOME/projects"
  local name=""
  local requested=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --port) requested="$2"; shift 2 ;;
      --port=*) requested="${1#--port=}"; shift ;;
      -h|--help)
        echo "Usage: newproj <name> [--port N]"
        echo "  Creates ~/projects/<name>/ with a CLAUDE.md, README, .gitignore, .env (PORT=...)."
        echo "  --port N pins to a specific port (fails if it's in use or already reserved)."
        return 0
        ;;
      *) name="$1"; shift ;;
    esac
  done

  [ -z "$name" ] && { echo "Usage: newproj <name> [--port N]"; return 1; }
  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "Error: project name must be lowercase alphanumeric with hyphens." >&2
    return 1
  fi

  local dir="$PROJECTS_DIR/$name"
  [ -d "$dir" ] && { echo "Error: $dir already exists." >&2; return 1; }

  _tpf_port_free() {
    local p="$1"
    /usr/sbin/lsof -i ":$p" -sTCP:LISTEN >/dev/null 2>&1 && return 1
    local env_file
    for env_file in "$PROJECTS_DIR"/*/.env; do
      [ -f "$env_file" ] || continue
      grep -qE "^PORT=$p\$" "$env_file" && return 1
    done
    return 0
  }

  local port
  if [ -n "$requested" ]; then
    if ! [[ "$requested" =~ ^[0-9]+$ ]]; then
      echo "Error: --port must be a number." >&2; return 1
    fi
    if ! _tpf_port_free "$requested"; then
      echo "Error: port $requested is in use or already reserved by another project." >&2; return 1
    fi
    port="$requested"
  else
    port=3001
    while ! _tpf_port_free "$port"; do
      port=$((port + 1))
      [ "$port" -gt 9999 ] && { echo "Error: no free port found in 3001-9999." >&2; return 1; }
    done
  fi

  mkdir -p "$dir"
  echo "PORT=$port" > "$dir/.env"
  cat > "$dir/.gitignore" <<EOF
node_modules/
.env
.env.local
.DS_Store
.vscode/
.idea/
*.log
EOF
  cat > "$dir/CLAUDE.md" <<EOF
# Working agreement — $name

Terse responses. No trailing summaries. Match scope to what was asked.

This project runs on http://localhost:$port (port set in \`.env\`).
EOF
  cat > "$dir/README.md" <<EOF
# $name

Runs on http://localhost:$port — see \`.env\`.
EOF

  unset -f _tpf_port_free
  echo "✓ Created $dir on port $port"
  cd "$dir"
}
# ---- TERMINAL_PROJECT_FOLDERS_END ----
ZSHRC_EOF
ok "Shell helpers added to $ZSHRC"

echo ""
printf "${GREEN}${BOLD}Installed.${RESET}\n"
echo ""
echo "Open a new terminal, then:"
echo ""
echo "  newproj my-thing       # create a project on a free port"
echo "  proj                   # list your projects"
echo "  proj my-thing          # jump in and resume the last Claude Code session"
echo ""
