---
name: tracker-rest-api
description: Tracker's local REST API — authenticate as a specific user, read tasks (including the Today board), and create/toggle tasks via curl
triggers:
  - tracker api
  - tracker today
  - tracker tasks
  - today board
  - add to tracker
---

# Tracker REST API

Tracker exposes a local REST API at `http://127.0.0.1:<port>/rest/`. Dev port is
`3027`. Request/response bodies are JSON. Use `curl` directly.

Tracker must be running locally (`make start` in `tracker/`) for any of this to
work. Logs at `tracker/logs/tracker.log`.

## Authentication

Tracker is multi-user. The auth rules differ between dev and production:

### Dev mode (local, default for `make start`)

**No credentials required for reads.** The server is bound to `127.0.0.1`, so
access already assumes local shell access. Pick the user by setting an
`X-User-Id` header, or omit it to target the first user (admin-ish).

```bash
# Any user can be addressed in dev — same API as tracker's main /api/ endpoints
curl -sf -H "X-User-Id: 3" http://127.0.0.1:3027/rest/tasks/today

# No header at all → defaults to the first user in the DB
curl -sf http://127.0.0.1:3027/rest/tasks/today
```

Writes are **still** gated by recording mode even in dev — see below.

### Production mode (`DEV` unset, `ADMIN_PASSWORD` set, or on Fly)

Every `/rest/*` endpoint except `/rest/auth/login` requires a Bearer JWT.
**You need the specific user's username + password** to read or write that
user's data. Another user's token cannot see yours.

```bash
# 1) Log in — get a token
TOKEN=$(curl -sf -X POST http://tracker.example.com/rest/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"s3cret"}' | jq -r .token)

# 2) Use it on every subsequent request
curl -sf -H "Authorization: Bearer $TOKEN" http://tracker.example.com/rest/tasks/today
```

Admin uses `"username":"admin"` + the server's `ADMIN_PASSWORD` env var.

## Endpoint catalogue — ask the server

`GET /rest/describe` returns a self-description of every handler (name,
arglists, docstring). **That endpoint is the authoritative reference** — this
skill focuses on *how* to use the API.

```bash
# dev — no auth
curl -sf http://127.0.0.1:3027/rest/describe | jq

# prod — token required
curl -sf -H "Authorization: Bearer $TOKEN" http://tracker.example.com/rest/describe | jq
```

Examples below use the **dev-mode** form (localhost, no token). In prod, add
`-H "Authorization: Bearer $TOKEN"` to every request and replace the host.

## Reading

### Today board

This is the canonical answer to *"what's on my today board right now?"*.
It returns tasks that are **not done** AND match at least one of: has a due
date, urgency is `urgent`/`superurgent`, `today` flag set, `lined_up_for`
set, or `reminder` is `active`.

```bash
curl -sf http://127.0.0.1:3027/rest/tasks/today | jq
```

### All tasks (with sort modes)

```bash
# most recently modified (default)
curl -sf "http://127.0.0.1:3027/rest/tasks?sort=recent"

# by due date
curl -sf "http://127.0.0.1:3027/rest/tasks?sort=due-date"

# done tasks
curl -sf "http://127.0.0.1:3027/rest/tasks?sort=done"

# full-text search on title/tags
curl -sf "http://127.0.0.1:3027/rest/tasks?q=deploy"
```

Sort modes: `recent` (default), `today`, `due-date`, `done`, `manual`,
`reminder`.

### Single task

```bash
curl -sf http://127.0.0.1:3027/rest/tasks/42
```

## Writing — gated by recording mode

**Write endpoints (`POST /rest/tasks`, `PUT /rest/tasks/:id/done`,
`PUT /rest/tasks/:id/today`) first log the intended action, then execute
only when recording mode is ON**. When off, they return a `{"dropped":true}`
or `{"created":true}` stub without touching the database.

To enable recording: inside the running Tracker app press **Alt+Shift+W**. A
red ⚠ REC badge appears in the top-left corner while active. Toggle off with
the same shortcut. **The toggle is deliberately not exposed on `/rest/*`** —
an external REST caller cannot flip its own gate.

Every attempted write is logged to `tracker/logs/tracker.log` regardless of
whether it was executed or dropped.

### Create a task

```bash
curl -sf -X POST -H "Content-Type: application/json" \
  -d '{"title":"Ship the demo","scope":"work"}' \
  http://127.0.0.1:3027/rest/tasks
```

`scope` is optional, one of `private` | `both` (default) | `work`.

### Mark done / un-done

```bash
curl -sf -X PUT -H "Content-Type: application/json" \
  -d '{"done":true}' \
  http://127.0.0.1:3027/rest/tasks/42/done
```

### Put a task on / off the Today board

```bash
curl -sf -X PUT -H "Content-Type: application/json" \
  -d '{"today":true}' \
  http://127.0.0.1:3027/rest/tasks/42/today
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

1. `GET /rest/tasks/today` (dev: no auth needed; prod: attach Bearer token).
2. Summarise `title` per entry, optionally grouping by `urgency`, presence of
   `due_date`, or `today == 1` vs `lined_up_for` vs `reminder == "active"`.
