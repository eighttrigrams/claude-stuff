# Docker Claude Container

A Docker-based setup that runs Claude Code inside an isolated container. The container only has access to the mounted project directory — nothing else on the host filesystem.

## What's Inside

- **Clojure** (temurin-21, tools-deps, Alpine) — the base image
- **Node.js + npm** — needed to run Claude Code CLI
- **Claude Code CLI** — installed globally via npm
- **git, gh, curl, jq** — basic dev tools

## Files

```
docker-claude/
├── .gitignore          # ignores the token file
├── Dockerfile
├── claude-config.json  # pre-baked config to skip onboarding
├── docker-compose.yml
├── run.sh              # reads token, starts container
└── token               # OAuth token (not committed)
```

## Setup

### 1. Generate an OAuth token

On the host, run:

```bash
claude setup-token
```

Save the output (a `sk-ant-oat01-...` string) to `docker-claude/token`. This file is gitignored.

### 2. Build

```bash
cd docker-claude
docker compose build
```

### 3. Run

```bash
./run.sh
```

This drops you into a bash shell inside the container with `CLAUDE_CODE_OAUTH_TOKEN` set. Then run `claude` to start Claude Code.

## How It Works

- `docker-compose.yml` mounts the current directory (`.`) as `/workspace` inside the container
- `run.sh` reads the token from `docker-claude/token` and passes it as `CLAUDE_CODE_OAUTH_TOKEN`
- `claude-config.json` is baked into the image as `~/.claude.json` to skip the onboarding/welcome screen
- Claude Code picks up the env var and authenticates

## Config Storage

- `/root/.claude.json` — global config, baked from `claude-config.json` at build time. Ephemeral; reset on each `docker compose run --rm`.
- `/root/.claude/` — session data and settings. Also ephemeral.
- `/workspace/.claude/` and `/workspace/CLAUDE.md` — project-level config that Claude Code may create. Since `/workspace` is the mounted directory, these persist on the host.

## Adapting for Other Projects

Copy the `docker-claude/` directory into your project. By default the volume mount is `.:/workspace:rw` (mounts the docker-claude dir itself). Change this to `..:/workspace:rw` to mount the parent project directory instead. Run `claude setup-token` to generate a new token file.

## Known Limitations

- **`/usage` not available**: The `setup-token` token lacks the `user:profile` scope, so `/usage` shows an error inside the container. Usage is still tracked — check it from the host or claude.ai.
- **Token refresh**: The `setup-token` token is long-lived but may eventually expire. Regenerate with `claude setup-token` if needed.
- **Network restrictions**: Blocking outbound HTTP (except to Anthropic API) is not yet implemented.
- **GitHub access**: `gh` CLI is installed but not yet authenticated inside the container.
