---
name: rhizome-rest-api
description: Rhizome's local REST API — search, read, and create contexts/items via curl
---

Note that when the user mentions books that you also load rhizome-books.

# Rhizome REST API

Rhizome exposes a local REST API at `http://127.0.0.1:<port>/rest/`. Dev port is
`3006`. Request/response bodies are JSON.

Rhizome must be running locally (`./dev.sh` in `rhizome/`) for any of this to work.

Script: ${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh

Thin wrapper around `curl` against `127.0.0.1`. The port is required. Pass the
path after `/rest`, **including the leading `/`** (the script does not duplicate
the API surface; you must know the endpoints).

Usage
```
rhizome-cli.sh <port> <path>                        # GET
rhizome-cli.sh <port> <method> <path> [json-body]   # any method, optional JSON body
```

## Endpoint catalogue — ask the server

`GET /rest/describe` returns a self-description of every handler (name, arglists,
docstring with method, path, params, and status codes). **That endpoint is the
authoritative reference** — this skill focuses on *how* to use the API, not on
duplicating the catalogue.

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 /describe | jq
```

## Model

Everything is an **item**. Items flagged `is_context: true` are **contexts** —
they act as categories/topics/collections and group other items. A "search" in
Rhizome typically means: find the relevant context(s), then list items related
to them — ideally using *intersection* search across multiple contexts.

### Topic vs. kind-of-item contexts

Two distinct flavours of context coexist and are routinely intersected:

- **Topic contexts** — what an item is *about* or where it belongs (e.g. a
  book, a chapter, "Second World War", "Preface").
- **Kind-of-item contexts** — what an item *is* (e.g. `Page`, `📚❝❞` Quote,
  `People`). An item being a member of a kind-context is how its type is
  expressed in the data model.

When the user names both a kind ("pages", "quotes", "people") **and** a topic
or scope ("of the preface", "about Wittgenstein"), this is a type filter —
intersect topic ∩ kind. See the recipe below.

## Search recipes

### Find the right context first, then drill down

```bash
# 1) search contexts
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/contexts?q=Books"

# 2) search items within a context (selected = narrowest context)
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/10935/related"
```

### Intersection search (preferred strategy)

The selected context defines the working set; each id in `secondary_ids`
further constrains it (logical AND). Put the **narrowest / most specific**
context as the selected id, the additional constraints as `secondary_ids`.
With secondary ids present the limit rises from 10 to 100.

```bash
# Quotes that also belong to "Second World War"
# (Second World War is narrower → selected; Quotes is the kind filter → secondary)
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3006 "/items/10935/related?secondary_ids=11041"
```

**Kind filter recipe.** When the user asks for "<kind> of/in/about <topic>"
(e.g. "pages of the preface", "quotes about virtue", "people in this book"):

1. Resolve the topic context → selected id.
2. Resolve the kind context (Page, Quote, People, …) → `secondary_ids`.
3. Issue intersection. Without it, the result mixes kinds (e.g. pages **and**
   their quotes appear together under the same topic context).

```bash
# "pages of the Preface" → Preface (topic) ∩ Page (kind)
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/49041/related?secondary_ids=48601&search_mode=2"
```

**Prefer the minimal intersection that captures the user's intent.** Adding
ancestor topics on top of a working kind filter (e.g. also intersecting with
the enclosing book) does not broaden the result — it narrows it, and risks
excluding items whose context membership isn't fully populated. Only add a
secondary id if the user's query actually constrains on it.

### Search modes

`search_mode` tweaks the ordering of related-items results:

- `0` (default) — most recently touched first
- `2` — ordered by `sort_idx` (e.g. page numbers for book quotes); raises the
  result limit to 5000
- `5` — most recently added first

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/10935/related?secondary_ids=11041&search_mode=2"
```

### Get an item with its description and neighbourhood

Only for *non-context* items (leaf notes with longer titles).

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/34696/with-related"
```

### Free-text item search (use sparingly)

Prefer the context/intersection approach above. Fall back to `q` on `/rest/items`
only when you can't narrow by context.

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items?q=Wittgenstein"
```

### Finding people

People are items under a dedicated "People" context. Once you have that
context's id, use `/related`:

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/<people-ctx-id>/related?q=Daniel"
```

### Semantic / vector search

`/items/:id/related` takes `vector=true` to switch from SQL LIKE to cosine
similarity. The query `q` is embedded by local Ollama (`nomic-embed-text`,
768-dim) and matched against `items.embedding` via pgvector.

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 "/items/9659/related?vector=true&q=history%20of%20oil"
```

Important: **only items with a non-empty description get embedded** — both
on ingestion (POST /rest/items, PUT /rest/items/:id) and via the backfill
endpoint below. Title-only items are intentionally skipped and will never
appear in vector results.

### Embedding backfill

`POST /rest/backfill/embeddings` embeds every item that has a description
and a NULL embedding. Idempotent and resumable — safe to re-run (or
interrupt and re-run). Gated by recording mode. The request blocks until
completion and returns `{"embedded": N}` (or `{"embedded": 0, "dry-run":
true}` when recording is off).

```bash
${CLAUDE_SKILL_DIR}/scripts/rhizome-cli.sh 3140 POST "/backfill/embeddings"
```

Run this after bulk-ingest scripts (the rhizome-ingest scripts already call
it at the end), or periodically if items were created via the UI (the UI
path bypasses the per-item embed hook).

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

URLs (YouTube, GitHub, Substack, …) passed as `title` on `POST /rest/items` are
auto-detected and enriched by the insertion pipeline.

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
