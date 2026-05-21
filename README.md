# terminal-project-folders

A tiny project manager for macOS. Every project gets its own folder under `~/projects/` and a localhost port that's actually free.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jasontheodorou/terminal-project-folders/main/install.sh | bash
```

Open a new terminal, then:

```bash
newproj my-app   # creates ~/projects/my-app on a free port, drops you in
proj             # list all projects with their ports
proj my-app      # jump back in and resume the last Claude Code session
```

## What you get

| Command | What it does |
|---|---|
| `newproj <name>` | Creates `~/projects/<name>/`, finds a localhost port that isn't in use or already reserved by another project, writes it to `.env`, and `cd`s in. |
| `newproj <name> --port N` | Same, but pin to a specific port (fails if N is taken). |
| `proj` | Lists every project with its port and last modified date. |
| `proj <name>` | `cd`s into the project and runs `claude -c` (resumes the last Claude Code session there). |
| Status line | Shows the current folder, port (from `.env`), and git branch at the bottom of Claude Code. |

Each new project gets:

- `.env` with `PORT=NNNN`
- `CLAUDE.md` with a one-line working agreement and the port
- `README.md`
- `.gitignore` (node_modules, .env, .DS_Store, editor dirs, *.log)

## How port selection works

Walks from port `3001` upwards. Skips any port that:

1. Is currently listening (`lsof -i :PORT -sTCP:LISTEN`).
2. Is already reserved in another project's `.env` (`PORT=NNNN`).

So deleted projects' ports auto-recycle, and conflicts with services already running on your machine are avoided. If you delete `~/projects/old-thing/` and then `newproj` something new, it can pick that freed port.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jasontheodorou/terminal-project-folders/main/uninstall.sh | bash
```

Removes the shell helpers, the status line script, and the `statusLine` setting in `~/.claude/settings.json`. Leaves your projects untouched.

## Requirements

- macOS
- `jq` (pre-installed on macOS Sonoma+; otherwise `brew install jq`)
- `claude` — the Claude Code CLI. Optional, only needed if you want `proj <name>` to auto-resume a session.
- zsh (the default shell on macOS)

## What it does to your machine

- Adds a fenced block to `~/.zshrc` between `# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----` and `# ---- TERMINAL_PROJECT_FOLDERS_END ----`.
- Writes `~/.claude/statusline.sh` (15 lines).
- Sets `statusLine` in `~/.claude/settings.json` to point at that script.
- Creates `~/projects/` if it doesn't exist.

Nothing else. No `~/.config`, no LaunchAgents, no hooks.

## License

MIT.
