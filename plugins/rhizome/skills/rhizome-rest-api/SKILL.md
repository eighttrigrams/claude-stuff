---
name: rhizome-rest-api
description: Rhizome's local REST API — search, read, and create contexts/items via curl
triggers:
  - rhizome api
  - search rhizome
  - rhizome context
  - rhizome item
  - rhizome related
  - add to rhizome
---

# Rhizome REST API

Rhizome exposes a local REST API at `http://127.0.0.1:<port>/rest/`. Dev port is
`3006`. Request/response bodies are JSON. Use `curl` directly — there is no
wrapper script needed.

Rhizome must be running locally (`./dev.sh` in `rhizome/`) for any of this to work.

## Model

Everything is an **item**. Items flagged `is_context: true` are **contexts** —
they act as categories/topics/collections and group other items. A "search" in
Rhizome typically means: find the relevant context(s), then list items related
to them — ideally using *intersection* search across multiple contexts.

## Endpoints

### Contexts

| Method | Path                          | Query/body                         | Purpose |
|--------|-------------------------------|------------------------------------|---------|
| GET    | `/rest/contexts`              | `?q=<query>` (optional)            | List or search contexts |
| POST   | `/rest/contexts`              | `{"title": "..."}`                 | Create a context |

### Items

| Method | Path                                 | Query/body                                             | Purpose |
|--------|--------------------------------------|--------------------------------------------------------|---------|
| GET    | `/rest/items?q=<query>`              | `q` required                                           | Search across all items (context + non-context) |
| GET    | `/rest/items/:id`                    |                                                        | Get a single item (includes description) |
| GET    | `/rest/items/:id/related`            | `q`, `secondary_ids=<csv>`, `search_mode=<n>` (all optional) | List items related to the context item `:id` |
| GET    | `/rest/items/:id/with-related`       | `search_mode=<n>` (optional)                           | Non-context item plus its description plus its related items |
| GET    | `/rest/items/by-sort-idx`            | `sort_idx`, `context_ids=<csv>`                        | Find an item with the given `sort_idx` inside all listed contexts |
| POST   | `/rest/items`                        | `{"title": "...", "context-ids": [id,...], "description": "...", "sort-idx": n}` | Create an item linked to contexts |
| PUT    | `/rest/items/:id`                    | `{"description": "..."}`                               | Replace an item's description |

## Search recipes

### Find the right context first, then drill down

```bash
# 1) search contexts
curl -sf "http://127.0.0.1:3006/rest/contexts?q=Books"

# 2) search items within a context (selected = narrowest context)
curl -sf "http://127.0.0.1:3006/rest/items/10935/related"
```

### Intersection search (preferred strategy)

Put the **narrowest** context as the selected id, **broader** contexts as
`secondary_ids`. With secondary ids present the limit rises from 10 to 100.

```bash
# Quotes (broader) that also belong to "Second World War" (narrower)
curl -sf "http://127.0.0.1:3006/rest/items/10935/related?secondary_ids=11041"
```

### Search modes

`search_mode` tweaks the ordering of related-items results:

- `0` (default) — most recently touched first
- `2` — ordered by `sort_idx` (e.g. page numbers for book quotes); raises the
  result limit to 5000
- `5` — most recently added first

```bash
curl -sf "http://127.0.0.1:3006/rest/items/10935/related?secondary_ids=11041&search_mode=2"
```

### Get an item with its description and neighbourhood

Only for *non-context* items (leaf notes with longer titles).

```bash
curl -sf "http://127.0.0.1:3006/rest/items/34696/with-related"
```

### Free-text item search (use sparingly)

Prefer the context/intersection approach above. Fall back to `q` on `/rest/items`
only when you can't narrow by context.

```bash
curl -sf "http://127.0.0.1:3006/rest/items?q=Wittgenstein"
```

### Finding people

People are items under a dedicated "People" context. Once you have that
context's id, use `/related`:

```bash
curl -sf "http://127.0.0.1:3006/rest/items/<people-ctx-id>/related?q=Daniel"
```

## Writing

**Write endpoints are gated by "recording mode".** `POST /rest/contexts`,
`POST /rest/items`, and `PUT /rest/items/:id` all first log the intended
action, then either execute (when recording is on) or drop the request with
`403 {"dropped":true,"recording":false,"intent":"..."}`.

To enable recording: inside the running Rhizome app, press **Option+Shift+W**.
A red ⚠ REC badge appears in the top-left corner while the mode is active.
Toggle it off with the same shortcut.

Either way, every attempted write is logged to `rhizome/rhizome.log` regardless
of whether it was executed or dropped.

### Create a context

```bash
curl -sf -X POST "http://127.0.0.1:3006/rest/contexts" \
  -H "Content-Type: application/json" \
  -d '{"title": "My New Context"}'
```

### Create an item (at least one context required)

URLs (YouTube, GitHub, Substack, …) passed as `title` are auto-detected and
enriched by the insertion pipeline.

```bash
curl -sf -X POST "http://127.0.0.1:3006/rest/items" \
  -H "Content-Type: application/json" \
  -d '{"title": "Some article or URL", "context-ids": [42, 17]}'
```

Optional fields: `"description"` (body text), `"sort-idx"` (integer, e.g. page
number when ingesting book pages).

### Update a description

```bash
curl -sf -X PUT "http://127.0.0.1:3006/rest/items/123" \
  -H "Content-Type: application/json" \
  -d '{"description": "New body text"}'
```

## Response shape

List endpoints return JSON arrays of item objects. A single item looks like:

```json
{
  "id": 34696,
  "title": "...",
  "short-title": "...",
  "is-context": false,
  "description": "...",
  "inserted-at": "...",
  "updated-at": "...",
  "contexts": { "10935": "Second World War", "11041": "Quotes" }
}
```

`with-related` returns `{"item": {...}, "related": [{...}, ...]}`.

## Search strategy — when using this API for research

1. Break queries into likely categories. Prefer two short searches on separate
   terms over one long multi-word query.
2. `GET /rest/contexts?q=…` first, to find the relevant context ids.
3. `GET /rest/items/:id/related?secondary_ids=…` for intersection search —
   much better than free-text `q` on `/rest/items`.
4. Only use free-text `q` when you cannot narrow by context.
5. Result lists are "most recently touched first" by default — top results
   are literally "top of mind" and should be weighted higher.
