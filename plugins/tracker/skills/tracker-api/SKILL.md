---
name: tracker-api
description: Tracker's HTTP API — authenticate as a machine user, read tasks/meets/journals/today-board, ingest mail messages, write through the recording-mode gate via curl
triggers:
  - tracker api
  - tracker today
  - tracker tasks
  - tracker meets
  - tracker journal
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
  user* checkbox + a target user. They authenticate exactly like a regular
  user, but their JWT carries `is-machine-user: true` and a `for-user-id`
  claim. The server resolves all data access against `for-user-id` (so the
  machine acts on the bound user's tasks, meets, journals, mail, ...), and
  most write requests are gated by recording mode (see below). At most one
  machine user per regular user.

Read access for machine users is unrestricted.

## Authentication

### Dev mode (local)

Bound to `127.0.0.1`. No credentials required. Pick the user with
`X-User-Id`, or omit to target the first user.

```bash
curl -sf -H "X-User-Id: 3" http://127.0.0.1:3027/api/tasks?sort=today
```

In dev mode the recording-mode gate fires only when you send a real
machine-user JWT. The `X-User-Id` path bypasses it.

### Production mode

Every mutating `/api/*` request requires a Bearer JWT.

```bash
TOKEN=$(curl -sf -X POST http://tracker.example.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"my-machine","password":"s3cret"}' | jq -r .token)

curl -sf -H "Authorization: Bearer $TOKEN" \
  http://tracker.example.com/api/today-board
```

Admin: `"username":"admin"` + the server's `ADMIN_PASSWORD`.

## The recording-mode gate

For machine-user callers, mutating requests (`POST`/`PUT`/`DELETE`) are
intercepted before reaching the handler:

- The intent is logged to `tracker/logs/tracker.log` regardless of outcome.
- If recording mode is **ON**, the handler runs.
- If recording mode is **OFF**, the request returns `{"dropped":true}`
  (HTTP 200) and nothing hits the database.

Regular UI users are never gated.

Toggle from inside the UI with **Alt+Shift+W** (or `POST
/api/recording-mode/toggle`). A red REC badge appears in the top bar. The
toggle is **human-only** — agents must not flip it.

### Gate exemptions

These endpoints are exempt from the gate even for machine users — they
always go through:

- `POST /api/messages` — mail inbox ingestion. Mail is always inbox-only
  noise until the human triages it in the UI, so the gate would only get
  in the way of automation.

Everything else gated for machine users (tasks, meets, journals, etc.).

## Endpoint overview

```
POST   /api/auth/login                      → {token, user}
GET    /api/auth/required                   → {required: bool}
GET    /api/auth/available-users            → list (dev mode only)

GET    /api/today-board                     → {tasks, meets, journal-entries}
GET    /api/translations                    → i18n strings
GET    /api/export                          → user data export (zip)
GET    /api/reports                         → reporting handler
POST   /api/recording-mode/toggle           → {recording: bool}

# Tasks (see /tasks below)
# Meets / meeting series / recurring tasks
# Messages (mail inbox)
# Resources
# Journals / journal entries
# Categories: people / places / projects / goals
# Relations
# Users (admin only)
```

## Tasks

```bash
# List with sort modes: recent (default), today, due-date, done, manual, reminder
curl -sf "http://127.0.0.1:3027/api/tasks?sort=today"

# Free-text search on title/tags
curl -sf "http://127.0.0.1:3027/api/tasks?q=deploy"

# Filter by importance, scope, categories
curl -sf "http://127.0.0.1:3027/api/tasks?importance=important&context=work&strict=true"
curl -sf "http://127.0.0.1:3027/api/tasks?projects=12,13&excluded-places=4"

# Single task
curl -sf http://127.0.0.1:3027/api/tasks/42
```

Mutations:

```bash
# Create
POST /api/tasks                {"title":"Ship demo","scope":"work"}
# Update title/description/tags
PUT  /api/tasks/:id            {"title":"...","description":"...","tags":"..."}
# Delete
DELETE /api/tasks/:id
# Toggle done / today flag
PUT  /api/tasks/:id/done       {"done": true|false}
PUT  /api/tasks/:id/today      {"today": true|false}
# Schedule
PUT  /api/tasks/:id/due-date   {"due-date":"2026-05-01"}     # null clears
PUT  /api/tasks/:id/due-time   {"due-time":"14:00"}          # null clears
# Priorities
PUT  /api/tasks/:id/scope      {"scope":"private|both|work"}
PUT  /api/tasks/:id/importance {"importance":"normal|important|critical"}
PUT  /api/tasks/:id/urgency    {"urgency":"default|urgent|superurgent"}
# Lined-up-for / reminders
PUT  /api/tasks/:id/lined-up-for {"lined-up-for":"YYYY-MM-DD"}
PUT  /api/tasks/:id/reminder     {"reminder":"YYYY-MM-DD HH:MM"}
PUT  /api/tasks/:id/acknowledge-reminder
# Manual reorder
POST /api/tasks/:id/reorder    {"target-task-id":99,"position":"before|after"}
# Categorize
POST   /api/tasks/:id/categorize   {"category-type":"person|place|project|goal","category-id":12}
DELETE /api/tasks/:id/categorize   {"category-type":"...","category-id":12}
```

Task response shape:

```json
{
  "id": 42, "title": "...", "description": "", "tags": "",
  "done": 0, "today": 1,
  "urgency": "default", "importance": "normal", "scope": "both",
  "due_date": null, "due_time": null,
  "lined_up_for": null, "reminder": null, "reminder_date": null,
  "created_at": "...", "modified_at": "...", "done_at": null,
  "sort_order": -3.0, "recurring_task_id": null,
  "people": [], "places": [], "projects": [], "goals": [],
  "relations": []
}
```

`done` and `today` are integers (0/1), not booleans.

## Meets

A *meet* is a one-off meeting with a date/time. Recurring meetings live as
*meeting series* that materialize meets.

```bash
# List — sort: upcoming (default, future + non-archived), past, summary
curl -sf "http://127.0.0.1:3027/api/meets?sort=upcoming"
curl -sf "http://127.0.0.1:3027/api/meets?series-id=7"

# Single
curl -sf http://127.0.0.1:3027/api/meets/15
```

Mutations mirror tasks:

```
POST   /api/meets                 {"title":"Sync with Sara","scope":"work"}
PUT    /api/meets/:id             {"title":"...","description":"...","tags":"..."}
DELETE /api/meets/:id
PUT    /api/meets/:id/start-date  {"start-date":"2026-05-03"}    # null clears
PUT    /api/meets/:id/start-time  {"start-time":"10:30"}         # null clears
PUT    /api/meets/:id/scope       {"scope":"private|both|work"}
PUT    /api/meets/:id/importance  {"importance":"normal|important|critical"}
PUT    /api/meets/:id/archive     {"archived": true|false}
POST   /api/meets/:id/categorize     {"category-type":"...","category-id":...}
DELETE /api/meets/:id/categorize     {"category-type":"...","category-id":...}
```

### Meeting series (recurring meetings)

```
GET    /api/meeting-series
GET    /api/meeting-series/:id
GET    /api/meeting-series/:id/taken-dates       # dates already materialized
POST   /api/meeting-series                       {"title":"..."}
PUT    /api/meeting-series/:id                   {"title":"...","description":"..."}
DELETE /api/meeting-series/:id
PUT    /api/meeting-series/:id/scope             {"scope":"..."}
PUT    /api/meeting-series/:id/schedule          {"mode":"weekly|biweekly|monthly", ...}
POST   /api/meeting-series/:id/create-meeting    # materialize the next meet
```

## Recurring tasks

Same shape as meeting series; materialize tasks instead of meets.

```
GET    /api/recurring-tasks
GET    /api/recurring-tasks/:id
GET    /api/recurring-tasks/:id/taken-dates
POST   /api/recurring-tasks
PUT    /api/recurring-tasks/:id
DELETE /api/recurring-tasks/:id
PUT    /api/recurring-tasks/:id/scope
PUT    /api/recurring-tasks/:id/schedule
POST   /api/recurring-tasks/:id/create-task
```

## Messages (mail inbox)

`POST /api/messages` is the **gate-exempt** ingestion endpoint — used by the
automator to drop mail/RSS/Telegram items into the inbox. The target user
must have `has_mail = 1`; for a machine user, this resolves to the bound
target user's flag.

```bash
curl -sf -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"sender":"GitHub","title":"PR #123 ready",
       "description":"...","type":"text",
       "scope":"work","importance":"normal","urgency":"default"}' \
  http://127.0.0.1:3027/api/messages
```

Required: `sender`, `title`. Optional: `description`, `type`
(`text|markdown|html`), `scope` (`private|work`), `importance`, `urgency`.

Other message endpoints (gated as usual):

```
GET    /api/messages?sort=...&q=...&importance=...&context=...&urgency=...
DELETE /api/messages/archived         # purge all archived
PUT    /api/messages/:id/done         {"done": bool}
PUT    /api/messages/:id/annotation   {"annotation":"..."}
PUT    /api/messages/:id/scope|importance|urgency
POST   /api/messages/:id/convert-to-resource
POST   /api/messages/:id/convert-to-task
POST   /api/messages/:id/merge        {"into-id":99}
DELETE /api/messages/:id
```

## Resources

A resource is a saved link or sheet (text snippet).

```
GET    /api/resources?sort=...&q=...&context=...&...
GET    /api/resources/:id
POST   /api/resources                 {"link":"https://...","title":"..."}   # link or title-only sheet
PUT    /api/resources/:id             {"title":"...","description":"...","tags":"..."}
DELETE /api/resources/:id
POST   /api/resources/:id/categorize     {"category-type":"...","category-id":...}
DELETE /api/resources/:id/categorize     ...
POST   /api/resources/:id/reorder        {"target-resource-id":...,"position":"before|after"}
PUT    /api/resources/:id/scope          {"scope":"..."}
PUT    /api/resources/:id/importance     {"importance":"..."}
```

YouTube / Substack URLs auto-fetch their title.

## Journals & journal entries

A *journal* is a daily/themed notebook; *entries* are dated items inside it.

```
# Journals
GET    /api/journals
GET    /api/journals/:id
POST   /api/journals               {"title":"..."}
PUT    /api/journals/:id           {"title":"...","description":"...","tags":"..."}
DELETE /api/journals/:id
PUT    /api/journals/:id/scope     {"scope":"..."}
POST   /api/journals/:id/create-entry          # add a new entry under this journal

# Entries
GET    /api/journal-entries
GET    /api/journal-entries/today
GET    /api/journal-entries/:id
POST   /api/journal-entries        {"journal-id":7,"title":"...","description":"..."}
PUT    /api/journal-entries/:id    {"title":"...","description":"...","tags":"..."}
DELETE /api/journal-entries/:id
PUT    /api/journal-entries/:id/scope|importance
POST   /api/journal-entries/:id/reorder
POST   /api/journal-entries/:id/categorize
DELETE /api/journal-entries/:id/categorize
```

## Categories: people / places / projects / goals

Same shape across all four types. Substitute `<cat>` with `people`,
`places`, `projects`, or `goals`.

```
GET    /api/<cat>
POST   /api/<cat>                   {"name":"...","description":"...","tags":"..."}
PUT    /api/<cat>/:id               {"name":"...","description":"...","tags":"..."}
POST   /api/<cat>/:id/reorder       {"target-id":...,"position":"before|after"}
DELETE /api/<cat>/:id               # generic across all types
```

## Relations

Generic many-to-many between entities.

```
POST   /api/relations            {"from-type":"task","from-id":1,"to-type":"meet","to-id":2}
DELETE /api/relations            {"from-type":"...","from-id":...,"to-type":"...","to-id":...}
GET    /api/relations/:type/:id  # all relations involving (type, id)
```

`type`s: `task`, `meet`, `resource`, `journal-entry`, `message`.

## Today-board (machine-friendly aggregate)

```bash
curl -sf http://127.0.0.1:3027/api/today-board | jq
# → { "tasks": [...], "meets": [...], "journal-entries": [...] }
```

Tasks use the same `:today` filter as the UI's Today list (incomplete +
due-date OR urgent/superurgent OR `today=1` OR `lined_up_for` set OR active
reminder). Meets are those with `start_date = today` and not archived.
Journal entries are today's entries.

## User preferences (regular user only)

```
PUT  /api/user/language    {"language":"en|de|pt"}
PUT  /api/user/vim-keys    {"vim_keys": 0|1}
```

Admin cannot use these. Machine users would have to be acting on behalf of
their target — but in practice the UI handles this.

## Admin: user management

Requires admin auth.

```
GET    /api/users                  # list non-admin users
POST   /api/users                  {"username":"...","password":"...",
                                   "is_machine_user": true,
                                   "for_user_id": 4}     # for machines only
DELETE /api/users/:id              # cascades, also removes bound machine user
```

## Common request patterns

### Answering "what's on my today board?"

`GET /api/today-board` for the full aggregate, or `GET
/api/tasks?sort=today` for tasks only. Group by `urgency`, `due_date`,
`today == 1`, `lined_up_for`, or `reminder == "active"` as needed.

### Adding mail to the inbox from a job

`POST /api/messages` — bypasses the gate, requires `has_mail` on the (target)
user.

### Creating a task that should appear on Today

```bash
curl -sf -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Deploy","scope":"work"}' http://127.0.0.1:3027/api/tasks
# → { "id": 99, ... }
curl -sf -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"today":true}' http://127.0.0.1:3027/api/tasks/99/today
```

(Both writes hit the gate — recording mode must be ON for a machine user
to land them.)
