---
name: develop-tracker-bot
description: How to run, test and develop the natural-language Telegram bot that queries tracker. The bot is NOT in tracker — it lives in the plurama umbrella app (plurama/src/plurama/app/agent). Covers the agent architecture, the secrets/config it needs, the locked-box egress-proxy gotcha, seeding a testable conversation, and driving it from the host as if you were Telegram.
---

# Developing the tracker Telegram bot

The bot lets a user query (and write to) their whole tracker in natural
language over Telegram: *"what do I need to do in the next 5 hours?"*, *"how
many LifeCheq meetings in the next 3 days?"*, *"do I have duplicate YouTube
subscriptions?"*. Bot development is infrequent, so the steps below are an
**ad-hoc, reproducible runbook** rather than baked-in infrastructure.

## Where the bot actually lives

It is **not** in `tracker`. It lives in **plurama** (the umbrella app), under
`plurama/src/plurama/app/agent/`:

| file            | role |
|-----------------|------|
| `telegram.clj`  | Ring handler for `POST /webhook/telegram`. Validates the `x-telegram-bot-api-secret-token` header, maps the sender, handles `/clear` and the `t`/`tt`/`n` prefix shortcuts, otherwise calls the AI loop and sends the reply back via Telegram `sendMessage`. |
| `ai.clj`        | The conversation loop. Calls the **Anthropic Messages API** (`x-api-key`, model `claude-haiku-4-5-20251001`) with one `app_request` tool, runs tool calls, returns the final text. Persists turns; keeps the last 5 turns of context. |
| `tools.clj`     | Defines the single `app_request` tool — a generic authenticated HTTP call into a configured app's `/api/*` surface. |
| `app_client.clj`| Per-app HTTP client: `POST /api/auth/login {username,password}` → bearer token (cached), then `Authorization: Bearer` on calls. Refreshes on 401. |
| `db.clj`        | plurama-side tables: `telegram_users` (telegram id → plurama user), `user_app_credentials` (per-user, per-app username/password), `agent_messages` (conversation turns). |

Tracker is just one downstream **app** the agent talks to over HTTP. The agent
is multi-app: per user, it can reach the intersection of the apps configured
in plurama's `:agent` block × the user's rows in `user_app_credentials`.

## What the bot needs to run

plurama `server.clj` `build-agent-ctx` reads three **env vars** and one
**config block**:

- `ANTHROPIC_API_KEY` — `(System/getenv "ANTHROPIC_API_KEY")`. The bot brain.
  This is an Anthropic **API key** (`sk-ant-api…`), *not* the Claude Code
  OAuth token. Keep it in a gitignored file (e.g. `plurama/anthropic_api_key`)
  and inject it at launch.
- `TELEGRAM_WEBHOOK_SECRET` — gates `/webhook/telegram`.
- `TELEGRAM_BOT_TOKEN` — used for outbound `sendMessage`.
  Both Telegram values live in a gitignored `.env` (currently `tracker/.env`).
- `config.edn` `:agent` block — which apps the bot may call. It must exist
  (the live `config.edn` is gitignored and easily drifts; compare against
  `config.edn.template`, which has the correct top-level `:db` / `:agent` /
  `:mail` structure). Local shape:
  ```clojure
  :agent {:tracker        {:base-url "http://127.0.0.1:3110"
                           :skill   "../claude-stuff/plugins/tracker/skills/tracker-api/SKILL.md"}
          :tracker-direct {:base-url "http://127.0.0.1:3110"}}
  ```
  `:tracker` is the AI-visible app; its `:skill` markdown becomes the agent's
  per-app guidance (see "Making it answer well"). `:tracker-direct` is a
  separate message-only tracker user for the `t`/`tt`/`n` prefix shortcuts and
  is hidden from the AI tool surface.

The agent system prompt is built once at boot from `base-system` + each app's
`:skill` file, so **changing the skill requires a plurama restart**.

## Running it in the devbox (`make box`)

`make start` for plurama is just `clj -X:run`; it sources no env file, so
inject everything at launch. Make plurama reachable from the host by binding
`0.0.0.0:3100` (the box publishes 3100 for plurama and runs a plurama ingress
sidecar):

```clojure
;; plurama/config.edn
:server {:port 3100 :host "0.0.0.0"}
```

### The locked-box egress-proxy gotcha (important)

In **locked** mode (`make box`, the default) the container has no direct
internet — outbound HTTPS must go through the `egress` tinyproxy
(`HTTPS_PROXY=http://egress:8888`), and only `api.anthropic.com` +
`tracker.eighttrigrams.net` are whitelisted. `curl` honours `HTTPS_PROXY`, but
**Java's `HttpClient` does not**, so the agent's Anthropic call dies with
`java.net.ConnectException` while its `127.0.0.1` tracker calls work fine.

Fix — **startup-only, no source or box-config change**: launch plurama with
proxy *system properties* (the default `HttpClient` honours these), keeping
loopback direct so tracker calls bypass the proxy:

```bash
cd /workspace/plurama
export ANTHROPIC_API_KEY="$(cat anthropic_api_key)"
set -a && . /workspace/tracker/.env && set +a   # TELEGRAM_* into env
export JDK_JAVA_OPTIONS="-Dhttps.proxyHost=egress -Dhttps.proxyPort=8888 \
  -Dhttp.proxyHost=egress -Dhttp.proxyPort=8888 \
  -Dhttp.nonProxyHosts=localhost|127.0.0.1"
make start   # clj -X:run, backgrounded
```

(Outbound to `api.telegram.org` is *not* whitelisted in locked mode, so real
`sendMessage` returns a 403 from the proxy — harmless for local testing, since
you read replies from the log. For real Telegram delivery, run the box
unlocked: `make box internet=true`, where no proxy is needed at all.)

## Seeding a testable conversation

The bot stays silent for unmapped Telegram users, so seed plurama's DB plus a
tracker login:

1. **tracker**: create a user with a known username + password that
   `POST /api/auth/login` accepts and returns a `:token` for (a machine user
   is ideal). Seed some persona data via the tracker API.
2. **plurama** (`plurama/data/plurama.db`): a `users` row (the conversation
   owner), a `telegram_users` row (`telegram_user_id` string → that user), and
   `user_app_credentials` rows for `tracker` and `tracker-direct` holding the
   tracker username/password.

Verify the creds before testing:
```bash
curl -s -X POST http://127.0.0.1:3110/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"…","password":"…"}'   # expect {"token":"…"}
```

## Driving it from the host (be the Telegram bot)

The webhook returns `{"ok":true}` regardless; the actual reply is sent to
Telegram (and printed to plurama's log). **Read replies from the
bind-mounted log** (`plurama/logs/…`): the agent prints `Tool invoked: …`,
`LLM final reply length: …`, and `Telegram out [ <chat> ]: <reply>`.

```bash
SECRET=$(grep '^TELEGRAM_WEBHOOK_SECRET=' tracker/.env | cut -d= -f2-)
curl -s -X POST http://localhost:3100/webhook/telegram \
  -H "Content-Type: application/json" \
  -H "x-telegram-bot-api-secret-token: $SECRET" \
  -d '{"message":{"chat":{"id":1},"from":{"id":<seeded-telegram-id>},"text":"what is on my today board?"}}'
# then read the new "Telegram out [...]" line from plurama/logs/<boot-log>
```

Webhook auth sanity: no secret header → `403`; bad secret → `403`; correct
secret → `200 {"ok":true}`. Send `/clear` (as the bot user) to reset
conversation history between unrelated test queries — stale context biases
the agent toward whatever endpoint it used last.

## Making it answer well (the bot's "brain" is the tracker-api skill)

The agent's competence is gated by the `:skill` markdown
(`tracker-api`), which becomes its per-app guidance. Observed failure modes
and where to fix them — **prefer fixing the skill over the code**:

- **Refusing in-scope questions** (e.g. "do I have duplicate YouTube subs?" →
  "that's outside the tracker"): the model's prior overrides generic "consult
  `/api/describe`" advice. Fix by stating scope explicitly in `tracker-api`
  SKILL.md — tasks, meets, journals, **resources, and "sources" (YouTube
  subscriptions, podcasts, RSS feeds)** are all in tracker.
- **Over-reliance on `/api/today-board`** for broad questions (it only covers
  *today*): tell the skill to prefer the specific resource endpoint
  (`/api/tasks`, `/api/meets`, `/api/resources`, `/api/sources/...`).
- **Fuzzy time reasoning** ("next 5 hours", "overdue"): the agent needs to
  know *now*. `ai.clj` injects the current date/time into the system prompt at
  chat time (`now-context`); without it the model mislabels tasks due later
  today as overdue. It also can't reliably do calendar arithmetic ("which
  date is Monday?") — so `now-context` additionally emits the **next ~8 days
  as a weekday→date table**, and the skill tells it to resolve weekday names
  against that table rather than computing dates itself.
- **Undercounting "all X"**: two distinct causes, both reproduced with a
  machine-user login (regular users are uncapped, so this is invisible
  otherwise):
  1. **The `?limit=10` machine-user cap** on list reads — fix via the skill's
     contextual-limit rule (bounded vs. explicit-count vs. open-ended; prefer
     uncapped aggregates like `/api/today-board` for "today"; pass a high
     `?limit` for full enumeration; aggregate across `/api/tasks` *and*
     `/api/meets`).
  2. **Query params placed in a `body`/`params` field on a GET** — the
     `app_request` tool only sends `:path` (+ `:body` for POST/PUT), so GET
     params there are silently dropped and the limit/filter vanish, snapping
     back to the capped default. The skill rule: **encode all GET query
     params in the path string** (`/api/tasks?category=…&due-date=…&limit=100`).
- **Hedging on reads**: it would ask "shall I list them?" instead of just
  answering — the skill now says act on read-only questions.

Diminishing-returns residue (LLM judgment, not structural): exact counts can
drift when combining filters, and meets aren't server-filtered by category so
a day query lists the day's other meetings (it caveats this).

After any skill edit, **restart plurama** so the new guidance is loaded. To
reproduce the cap-driven failures, point the agent's `tracker` credential at a
**machine user** and seed >10 items.

## Verifying writes

Writes go through `app_request` POST/PUT. In a **regular**-user dev context
they land directly; for a **machine-user** caller they pass through tracker's
recording-mode gate (see the `tracker-api` skill). Confirm a write by
re-reading via the tracker API (e.g. task count before/after) rather than
trusting the bot's "done!".
