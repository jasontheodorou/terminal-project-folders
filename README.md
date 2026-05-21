# terminal-project-folders

A tiny project manager for macOS. Every project gets its own folder under `~/projects/`, a localhost port that's actually free, and its own Claude Code working agreement.

Once installed, you mostly talk to it in plain English from inside Claude.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jasontheodorou/terminal-project-folders/main/install.sh | bash
```

Open a new terminal and run `claude`. Then ask in plain English:

- *"list my projects"*
- *"create new project"*
- *"open project X"*

That's the whole interface. The shell helpers below still exist for terminal-only use.

## How "open project X" works

Sub-processes can't change their parent shell's working directory, so Claude can't directly cd you anywhere or restart your session. The installer wraps `claude` in a small zsh function. When you ask Claude to open a project, it writes the name to `~/.terminal-project-folders/hop` and asks you to press Ctrl+D (or type `/exit`). The wrapper sees the hop note, cd's into that project, and starts a fresh Claude session — picking up that project's `CLAUDE.md` as the working agreement.

## Shell helpers (optional)

| Command | What it does |
|---|---|
| `newproj <name>` | Creates `~/projects/<name>/`, finds a free localhost port, writes it to `.env`, and `cd`s in. |
| `newproj <name> --port N` | Same, but pin to a specific port (fails if N is taken). |
| `proj` | Lists every project with its port and last-modified date. |
| `proj <name>` | `cd`s into the project and runs `claude -c` (resumes the last Claude Code session there). |
| `proj help` | Shows the welcome banner with the plain-English commands. |

Each new project gets:

- `.env` with `PORT=NNNN`
- `CLAUDE.md` with a short working agreement and the port
- `README.md`
- `.gitignore` (node_modules, .env, .DS_Store, editor dirs, *.log)

## How port selection works

Walks from port `3001` upwards. Skips any port that:

1. Is currently listening (`lsof -i :PORT -sTCP:LISTEN`).
2. Is already reserved in another project's `.env` (`PORT=NNNN`).

So deleted projects' ports auto-recycle, and conflicts with services already running on your machine are avoided.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jasontheodorou/terminal-project-folders/main/uninstall.sh | bash
```

Removes the shell helpers, the `claude` wrapper, the status line script, the `statusLine` setting in `~/.claude/settings.json`, the global CLAUDE.md fragment, and the hop directory. Leaves your projects untouched.

## Requirements

- macOS
- `jq` (pre-installed on macOS Sonoma+; otherwise `brew install jq`)
- `claude` — the Claude Code CLI
- zsh (the default shell on macOS)

## What it does to your machine

- Adds a fenced block to `~/.zshrc` between `# ---- TERMINAL_PROJECT_FOLDERS_BEGIN ----` and `# ---- TERMINAL_PROJECT_FOLDERS_END ----`.
- Writes `~/.claude/statusline.sh` (~15 lines).
- Sets `statusLine` in `~/.claude/settings.json` to point at that script.
- Adds a fenced block to `~/.claude/CLAUDE.md` between `<!-- TERMINAL_PROJECT_FOLDERS_BEGIN -->` and `<!-- TERMINAL_PROJECT_FOLDERS_END -->` so Claude understands the plain-English commands.
- Creates `~/projects/` and `~/.terminal-project-folders/` if they don't exist.

Nothing else. No LaunchAgents, no hooks, no telemetry.

## License

MIT.
