# docker-claude

A reusable recipe for **running Claude Code inside a Docker container in
"dangerously-allow-permissions" mode** so it can freely edit files, run
build tools, start dev servers, and execute end-to-end tests (e.g.
Playwright) without being interrupted by permission prompts.

## Quick demo (60 seconds)

```bash
# 1. One-time: get an OAuth token (interactive; copy ONLY the sk-ant-oat01-… line)
claude setup-token
echo 'sk-ant-oat01-…paste-here…' > docker-claude/token
chmod 600 docker-claude/token

# 2. Build the image
cd docker-claude
docker compose build

# 3. Open an interactive shell with claude pre-authenticated and pre-approved
./run.sh
#   inside the container:
#   $ claude            # interactive — all tools auto-approved on /workspace

# 4. Or: drive the included demo headlessly (clojure server + playwright screenshot)
export CLAUDE_CODE_OAUTH_TOKEN=$(cat token)
docker compose run --rm -T claude -lc '
  cd /workspace && npm install --silent
  claude --dangerously-skip-permissions -p "
    Edit src/poc/server.clj: change the H1 text to \"Hello from Headless Claude\".
    Update screenshot.js assertion to match.
    Start: clj -M -m poc.server &
    Wait until curl http://localhost:8080/ responds.
    Run: node screenshot.js
  "
'
open screenshot.png   # see the rendered page
```

## Intent

What I want from this setup:

1. `./run.sh` opens a Bash shell into a container that has everything a
   Clojure + browser-test workflow needs (JDK 21, `clj`, Node, npm,
   Chromium, Playwright deps, `claude` CLI).
2. From that shell I can run `claude` interactively, **or** invoke it
   headlessly with `--dangerously-skip-permissions` to let it modify the
   project, start a server, and run a Playwright test that takes a
   screenshot — all hands-off.
3. The container is a *jail* for Claude's filesystem and shell access
   (it can only see `/workspace` = the bind-mounted project) so granting
   it full permissions inside is acceptable.
4. The pattern is portable: copy `Dockerfile`, `docker-compose.yml`,
   `run.sh`, `claude-config.json` into another project, tweak the apt/apk
   line for project-specific tooling, and you're done.

## Why it works (and the gotchas you need to know)

These are the things I had to discover the hard way. Save yourself the
trouble:

### 1. Claude refuses `--dangerously-skip-permissions` as root

> `--dangerously-skip-permissions cannot be used with root/sudo
> privileges for security reasons`

So the container **must run as a non-root user**. The Dockerfile
creates a `claude` user. To make bind-mounted files writable from
inside, the user's UID/GID match the host (501/20 on macOS by default,
overridable via `USER_UID` / `USER_GID` build args).

### 2. macOS host UID 501 / GID 20 collides with Alpine defaults

GID 20 is `dialout` on Alpine, and UID 501 is unused — so you can't
blindly `addgroup -g 20`. The Dockerfile reuses the existing GID 20
group (`dialout`) and creates the user with UID 501 inside it. Files
written by the container show up as `daniel:staff` on the host.

### 3. Playwright + Alpine = use system Chromium, not bundled

Playwright's bundled Chromium is glibc-only — it won't run on Alpine
(musl). The fix:

- Install Chromium via `apk` (`chromium`, plus `nss`, `freetype`,
  `harfbuzz`, `ca-certificates`, `ttf-freefont`, `font-noto-emoji`).
- Use `playwright-core` (NOT `playwright`) so no browser auto-download.
- Set `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`.
- In code, pass `executablePath: '/usr/bin/chromium'` to
  `chromium.launch`.
- Launch with `--no-sandbox --disable-dev-shm-usage` (sandbox needs
  capabilities the container doesn't have; `/dev/shm` is tiny by
  default).

If you'd rather use bundled browsers, swap the base image for a
Debian/Ubuntu one (e.g. `clojure:temurin-21-tools-deps` without
`-alpine`) and run `npx playwright install --with-deps chromium`.

### 4. Authentication: OAuth token, not API key

Claude Code authenticates via an OAuth token in
`CLAUDE_CODE_OAUTH_TOKEN`. Generate one on the host with `claude
setup-token` and **save only the bare `sk-ant-oat01-…` string** to
`./token`. If you redirect the whole TUI output to a file you'll get
~400 lines of escape sequences, which is not a valid token. `run.sh`
reads `./token` and exports it for the container.

### 5. Pre-accept the trust dialog & onboarding

`claude-config.json` is copied to `~/.claude.json` inside the image and
pre-marks `/workspace` as trusted with all tools approved
(`hasTrustDialogAccepted`, `hasAllToolsApproved`) and onboarding as
completed. Without this, `claude` blocks on first-run prompts even in
non-interactive mode.

### 6. Playwright **MCP server** needs three extras vs. a normal host setup

A typical host `.mcp.json` for the Playwright MCP looks like:

```json
{ "mcpServers": { "playwright": {
  "command": "npx",
  "args": ["@playwright/mcp@latest", "--headless", "--isolated", "--viewport-size=1400x900"]
}}}
```

That won't work as-is inside this Alpine container. You need to add:

- `--executable-path=/usr/bin/chromium` — point at the system Chromium
  (bundled one is glibc-only, see #3).
- `--no-sandbox` — Chromium's sandbox needs capabilities the container
  doesn't have.
- `enabledMcpjsonServers: ["playwright"]` under the project entry in
  `~/.claude.json` so Claude doesn't prompt to enable the MCP on first
  use (this image's `claude-config.json` does it for `/workspace`).

See `.mcp.json` at the repo root for a working example.

### 7. Bind-mount, don't `COPY`

`docker-compose.yml` mounts the project directory at `/workspace` so
edits Claude makes inside the container appear on the host
immediately, and host edits are visible to Claude without rebuilds.

## Files in this directory

| File | Purpose |
|---|---|
| `Dockerfile` | Alpine + JDK 21 + clj + Node/npm + Chromium + claude CLI. Creates non-root `claude` user with host-matching UID/GID. |
| `docker-compose.yml` | Bind-mounts `.` to `/workspace`, passes `CLAUDE_CODE_OAUTH_TOKEN`, gives a TTY. |
| `run.sh` | Loads token from `./token`, runs `docker compose run --rm claude`. |
| `claude-config.json` | Pre-accepts onboarding/trust so non-interactive `claude` doesn't prompt. |
| `token` | (gitignored) bare OAuth token from `claude setup-token`. |
| `deps.edn`, `src/poc/server.clj` | Demo Clojure HTTP server (zero deps). |
| `package.json`, `screenshot.js` | Demo Playwright script (uses system Chromium). |
| `.mcp.json` | Pre-wired Playwright MCP server (system Chromium, no-sandbox). |

## Usage

### One-time setup

```bash
claude setup-token       # on host; copy ONLY the sk-ant-oat01-… line
echo 'sk-ant-oat01-…' > docker-claude/token
chmod 600 docker-claude/token
docker compose -f docker-claude/docker-compose.yml build
```

### Interactive shell (most common)

```bash
cd docker-claude
./run.sh
# inside the container:
claude                   # interactive Claude Code, all tools pre-approved on /workspace
```

### Headless — let Claude drive end-to-end

```bash
cd docker-claude
export CLAUDE_CODE_OAUTH_TOKEN=$(cat token)
docker compose run --rm -T claude -lc '
  cd /workspace
  claude --dangerously-skip-permissions -p "Edit src/poc/server.clj … then run node screenshot.js"
'
```

## Demo project layout

The repo root *is* the demo project — `deps.edn` + `src/` at top-level
to mimic a real Clojure app:

```
deps.edn
src/poc/server.clj   ← zero-dep Java HttpServer serving a tiny HTML page
package.json         ← playwright-core dep
screenshot.js        ← navigates with Chromium, asserts heading, saves screenshot.png
.mcp.json            ← Playwright MCP server (system chromium, no-sandbox)
```

End-to-end demo: headless Claude was given a prompt to change the H1
text, restart the server, and re-run the screenshot — it did, and the
resulting `screenshot.png` shows the new heading. Repeat with:

```bash
docker compose run --rm -T claude -lc '
  cd /workspace
  claude --dangerously-skip-permissions -p "
    1. Change the H1 in src/poc/server.clj from X to Y, update screenshot.js assertion to match.
    2. Start: clj -M -m poc.server &
    3. Wait for http://localhost:8080/.
    4. node screenshot.js
  "
'
```

## Adapting this for another project

1. Copy `Dockerfile`, `docker-compose.yml`, `run.sh`, `claude-config.json`,
   `.gitignore` into the new project (or a `docker-claude/` subdir).
2. In the `Dockerfile`, swap the base image and the `apk add` line for
   whatever your stack needs (Python? `python3 py3-pip`. Postgres
   client? `postgresql-client`.)
3. If your host is Linux, override the build args to your UID/GID:

   ```yaml
   # docker-compose.yml
   services:
     claude:
       build:
         context: .
         args:
           USER_UID: "1000"
           USER_GID: "1000"
   ```

4. Drop `claude-config.json` in unchanged — the `/workspace` key works
   for any project because it's the in-container path.
5. Generate a token, save it to `./token`, and you're good.

## Security notes

- The container runs as a non-root user, can't see anything outside
  `/workspace`, has no host network access by default beyond outbound
  HTTP, and the OAuth token is scoped to your Claude account
  (revocable). That's the *jail* that justifies the
  "dangerously-skip-permissions" flag inside it.
- Don't commit `./token`. It's in `.gitignore`.
- If a token is ever exposed (e.g. printed to a terminal that's logged
  somewhere), revoke it from your Claude account settings and generate
  a new one.
