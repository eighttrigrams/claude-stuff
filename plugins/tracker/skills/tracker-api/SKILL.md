---
name: tracker-api
description: Tracker's HTTP API — authenticate as a machine user, read tasks/meets/journals/today-board, ingest mail messages, write through the recording-mode gate via curl
---

# Tracker API

Tracker exposes a single HTTP API at `http://127.0.0.1:<port>/api/`. Dev port
is `3027`. Request/response bodies are JSON. Use `curl` directly.

Tracker must be running locally (`make start` in `tracker/`) for any of this
to work. Logs at `tracker/logs/tracker.log`.

The same `/api/*` endpoints the UI uses are also the machine-callable
endpoints — what changes is *who* is calling and *whether the recording-mode
gate applies*.

## What tracker covers (scope)

Tracker is not only tasks. A single user's tracker holds **tasks, meetings
("meets") and meeting series, recurring tasks, journals and journal entries,
saved resources (links and videos), mottos**, and **"sources"** — the user's
**YouTube channel subscriptions, podcast feeds, and Atom/RSS feeds** plus
their per-source settings. People / places / projects / goals are the
categories that tie items together through relations.

So questions about the user's **YouTube subscriptions, saved YouTube videos,
podcasts, or RSS feeds are in scope** and are answered from tracker — do
**not** treat them as an external account you cannot reach. Subscriptions
are under `/api/sources/youtube/channels`; saved videos/links are
`resources` (`/api/resources`); podcast and feed sources under
`/api/sources/podcast` and `/api/sources/atom`. For broad reads, prefer the
specific resource endpoint (`/api/tasks`, `/api/meets`, `/api/resources`,
`/api/sources/...`) over `/api/today-board`, which only covers *today*. When
unsure of the exact path, consult `/api/describe` (below) — never refuse on
the assumption that tracker does not track something.

## Answering completely: act, filter, and size the read

- **Act on reads.** For a read-only question, fetch the data and answer —
  do **not** ask permission first ("shall I list them?"). Only ask back when
  the request is genuinely ambiguous.
- **Find the filter before saying "no".** List endpoints take query params
  (look them up in `/api/describe`): `resources` filter by
  `domain`/`excluded-domains`, tasks by scope/importance/urgency/category,
  meets by date/category. "My Google Docs" or "links from X" is a `domain`
  filter on `/api/resources` — a domain is **not** a category and **not** a
  missing feature.
- **Put query params in the path, not a body.** For GET reads, encode every
  query parameter directly in the path query string —
  `GET /api/tasks?category=Acme&due-date=2026-06-22&limit=100`. Parameters
  placed in a separate body/`query`/`params` field are dropped on a GET, so
  the filter and limit silently have no effect and you fall back to the
  default capped list (the `?limit=10` cap above). `body` is only for the
  JSON payload of POST/PUT writes.
- **Size the read to the question — limits are not one-size-fits-all.**
  Machine-user list reads on `/api/tasks`, `/api/meets`, `/api/resources`,
  `/api/journals`, `/api/journal-entries`, `/api/recurring-tasks`,
  `/api/meeting-series` default to `?limit=10`, so a bare list silently
  truncates. Reason about the natural size of the answer:
  - **Bounded queries** — the today board, a single day, "this week",
    "meetings at X in the next 3 days" — are small finite sets. Prefer a
    bounded aggregate when one exists (`/api/today-board` is **not** capped
    and returns the whole day), or pass a `?limit` comfortably above the real
    count, and answer in full.
  - **Explicit counts** — "top 5", "next 3 meetings" — pass that as `?limit`.
  - **Open-ended sets** — "all my tasks", "every resource", a multi-month
    report — do not trust the default 10 and do not silently truncate: pass a
    deliberate `?limit` (or paginate) and tell the user the scope/limit you
    applied instead of implying you listed everything.
- **Aggregate across types** when the question spans them ("everything on
  Monday" = tasks **and** meets), and say which sources you checked. Never
  call a single (possibly filtered or capped) list "all" without checking.

## Endpoint catalogue — ask the server

`GET /api/describe` returns a self-description of every public handler
(`{:name :ns :arglists :doc}`); each `:doc` opens with `VERB /api/path — ...`
and lists body fields, query params, views, sort modes, and notable error
cases. **That endpoint is the authoritative reference** — this skill only
covers *how* to use the API (auth, gating, identity, semantics, request
patterns). It does **not** list endpoints, query params, or body fields.
Always consult `/api/describe` for those — never guess from this document
or from memory.

```bash
curl -sf http://127.0.0.1:3027/api/describe | jq '.[] | {ns, name}'

# Filter to one resource:
curl -sf http://127.0.0.1:3027/api/describe \
  | jq '.[] | select(.doc | startswith("POST /api/tasks"))'
```

If a user asks about a "view", "filter", "sort", or "tab" you don't
recognise (e.g. "saved", "archived", "today"), look it up in
`/api/describe` before answering — do not assume it doesn't exist.

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

Some endpoints are exempt from the gate even for machine users — `POST
/api/messages` (mail inbox ingestion) is the canonical example: mail is
inbox-only noise until the human triages it in the UI, so the gate would
only get in the way of automation. Check `/api/describe` for the
authoritative exemption list per endpoint.

## Common request patterns

### Answering "what's on my today board?"

`GET /api/today-board` returns the aggregate `{tasks, meets,
journal-entries}`. Tasks use the same `:today` filter as the UI's Today
list (incomplete + due-date OR urgent/superurgent OR `today=1` OR
`lined_up_for` set OR active reminder). Meets are those with `start_date =
today` and not archived. Journal entries are today's entries.

### Adding mail to the inbox from a job

`POST /api/messages` bypasses the gate; requires `has_mail` on the (target)
user.

### Creating a task that should appear on Today

Two writes — create the task, then flip its `today` flag — and **both** hit
the gate, so recording mode must be ON for a machine user to land them.
Look up the exact endpoints + bodies in `/api/describe`.

## Response-shape notes

A few shape details that aren't obvious from `/api/describe` docstrings:

- Task `done` and `today` are integers (`0`/`1`), not booleans.
- YouTube / Substack URLs posted to `/api/resources` auto-fetch their
  title server-side.
