---
name: migrations
description: Use this skill for anything related to database migrations in apps composed under the plurama umbrella JVM — adding, editing, or rolling back ragtime migrations, debugging migration loading or apply errors, deciding where new migration files go, renaming or reorganising the migrations directory, troubleshooting cross-app classpath collisions, and verifying that one composed app's migrations don't accidentally touch another's database.
---

# Migrations live under `resources/migrations/<reverse-ns-path>/`

Plurama is an umbrella JVM that composes multiple ring-handler-exposing apps (e.g. `personalist`, `blog`) into a single Jetty server, pulling each one as a `:local/root` deps.edn dependency. Because every composed app's `resources/` directory ends up on the same classpath at runtime, anything placed at the classpath root will collide between apps.

To keep apps oblivious of each other, the convention is to namespace migration directories by the app's reverse namespace path:

```
resources/migrations/<reverse-ns-path>/NNN-name.edn
```

Examples:

| App         | Namespace          | Migrations directory                      | Loader path                    |
|-------------|--------------------|-------------------------------------------|--------------------------------|
| plurama     | `net.et.plurama`   | `resources/migrations/net/et/plurama/`    | `"migrations/net/et/plurama"`  |
| personalist | `net.et.pe`        | `resources/migrations/net/et/pe/`         | `"migrations/net/et/pe"`       |
| blog        | `net.et.blog`      | `resources/migrations/net/et/blog/`       | `"migrations/net/et/blog"`     |

The migration loader call in each app reads its own subdirectory:

```clojure
(ragtime-jdbc/load-resources "migrations/net/et/pe")
```

## Adding a new migration

1. Drop the file in the app's `resources/migrations/<reverse-ns-path>/` — for example `002-add-tags.edn`.
2. Use the next sequential id (`002-…`, `003-…`).
3. Do **not** put it at the bare `resources/migrations/` root — it would still work for the app standalone but conflict the moment a sibling app is composed under plurama.

Ragtime tracks applied migrations by file id (the filename), not full path, so renaming or moving the directory does not re-trigger already-applied migrations.

## Why not a per-classloader / per-uberjar isolation scheme?

Because it's heavyweight and unnecessary: namespace-prefixed resources is the standard JVM-library convention for avoiding classpath collisions, and each app stays oblivious to plurama by simply following library hygiene.
