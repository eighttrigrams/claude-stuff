---
name: tracker-api
description: Tracker's HTTP API — authenticate as a machine user, read tasks/today-board, and write through the recording-mode gate via curl
triggers:
  - tracker api
  - tracker today
  - tracker tasks
  - today board
  - add to tracker
---

# Tracker API

Tracker exposes a single HTTP API at `http://127.0.0.1:<port>/api/`. Dev port
is `3027`. Request/response bodies are JSON. Use `curl` directly.

Tracker must be running locally (`make start` in `tracker/`) for any of this
to work. Logs at `tracker/logs/tracker.log`.

The same `/api/*` endpoints the UI uses are also the machine-callable
endpoints — what changes is *who* is calling and *whether the recording-mode
gate applies*.

## Caller identity: regular users vs machine users

Tracker has two kinds of authenticated callers:

- **Regular users** — the human accounts that sign in to the web UI. Writes
  go through with no extra gating.
- **Machine users** — accounts created in admin → Users with the *Machine
  user* checkbox + a target user. They have a name and password of their own
  and authenticate exactly like a regular user, but their JWT carries
  `is-machine-user: true` and a `for-user-id` claim. The server resolves all
  data access against `for-user-id` (so the machine acts on the bound user's
  tasks, meets, journals), and **all write requests are gated by recording
  mode** (see below). At most one machine user per regular user.

Read access for machine users is unrestricted — they can fetch the bound
user's tasks/today-board/etc at any time.

## Authentication

### Dev mode (local, default for `make start`)

The server is bound to `127.0.0.1`, so access already assumes local shell
access. Credentials are not required for reads or writes — pick the user by
setting an `X-User-Id` header, or omit it to target the first user.

```bash
# Dev — pick a user explicitly
curl -sf -H "X-User-Id: 3" http://127.0.0.1:3027/api/tasks?sort=today

# No header → first user
curl -sf http://127.0.0.1:3027/api/tasks?sort=today
```

In dev mode, the recording-mode gate does **not** fire unless you send a
real machine-user JWT (see below). The header path bypasses the gate.

### Production mode (`DEV` unset, `ADMIN_PASSWORD` set, or on Fly)

Every mutating `/api/*` request requires a Bearer JWT. Reads also require it
unless you're hitting an unauthenticated public endpoint.

```bash
# 1) Log in as a machine user — get a token
TOKEN=$(curl -sf -X POST http://tracker.example.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"my-machine","password":"s3cret"}' | jq -r .token)

# 2) Use it on every subsequent request
curl -sf -H "Authorization: Bearer $TOKEN" \
  http://tracker.example.com/api/today-board
```

Regular users use the same `/api/auth/login` flow with their own credentials.
Admin uses `"username":"admin"` + the server's `ADMIN_PASSWORD`.

## Reading

### Today board (machine-friendly aggregate)

Returns tasks, meets, and journal entries for today in a single fetch.
Designed for machine consumers that want the complete picture in one call.

```bash
curl -sf http://127.0.0.1:3027/api/today-board | jq
# → { "tasks": [...], "meets": [...], "journal-entries": [...] }
```

### Today's tasks only

Same logic the UI uses for the Today list — incomplete tasks that have a due
date, are `urgent`/`superurgent`, are explicitly flagged `today`, have
`lined_up_for` set, or have an active reminder.

```bash
curl -sf "http://127.0.0.1:3027/api/tasks?sort=today" | jq
```

### All tasks (with sort modes)

```bash
# most recently modified (default)
curl -sf "http://127.0.0.1:3027/api/tasks?sort=recent"

# by due date
curl -sf "http://127.0.0.1:3027/api/tasks?sort=due-date"

# done tasks
curl -sf "http://127.0.0.1:3027/api/tasks?sort=done"

# full-text search on title/tags
curl -sf "http://127.0.0.1:3027/api/tasks?q=deploy"
```

Sort modes: `recent` (default), `today`, `due-date`, `done`, `manual`,
`reminder`.

### Single task

```bash
curl -sf http://127.0.0.1:3027/api/tasks/42
```

## Writing — gated by recording mode (machine users only)

When the caller is a machine user, every mutating request (`POST`/`PUT`/
`DELETE`) is intercepted before reaching the handler:

- The intent is logged to `tracker/logs/tracker.log` regardless of outcome.
- If recording mode is **ON**, the handler runs and the change persists.
- If recording mode is **OFF**, the handler is skipped and the response is
  `{"dropped":true}` (HTTP 200). Nothing hits the database.

Regular UI users are **not** gated — their writes always go through.

To enable recording: inside the running Tracker app press **Alt+Shift+W** (or
`POST /api/recording-mode/toggle`). A red ⚠ REC badge appears in the top
bar while active. Toggle off with the same shortcut. **The toggle must only
be flipped by a human, not from an agent** — there is no policy reason for a
machine to enable its own gate.

### Create a task

```bash
curl -sf -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Ship the demo","scope":"work"}' \
  http://127.0.0.1:3027/api/tasks
```

`scope` is optional, one of `private` | `both` (default) | `work`.

### Mark done / un-done

```bash
curl -sf -X PUT -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"done":true}' \
  http://127.0.0.1:3027/api/tasks/42/done
```

### Put a task on / off the Today board

```bash
curl -sf -X PUT -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"today":true}' \
  http://127.0.0.1:3027/api/tasks/42/today
```

## Task response shape

```json
{
  "id": 42,
  "title": "Ship the demo",
  "description": "...",
  "tags": "",
  "done": 0,
  "today": 1,
  "urgency": "urgent",
  "importance": "normal",
  "scope": "work",
  "due_date": "2026-04-22",
  "due_time": "14:00",
  "lined_up_for": null,
  "reminder": null,
  "reminder_date": null,
  "created_at": "...",
  "modified_at": "...",
  "done_at": null,
  "sort_order": -3.0,
  "recurring_task_id": null,
  "people": [],
  "places": [],
  "projects": [],
  "goals": []
}
```

`done` and `today` are integers (`0`/`1`), not booleans.

## Answering "what's on my today board?"

1. `GET /api/today-board` for the full aggregate (tasks + meets + journal
   entries), or `GET /api/tasks?sort=today` for tasks only.
2. Summarise `title` per entry, optionally grouping by `urgency`, presence
   of `due_date`, or `today == 1` vs `lined_up_for` vs `reminder == "active"`.
