# Claude Stuff

Things I know and find important to document about Claude (Code).

Some of it perhaps interesting to a wider audience, some of it clearly
subject to my own preferences (see below).

<details>

- Clojure as a primary language I am focusing on
- VSCode as my primary targeted IDE
- GitHub, Docker on the tooling side
- MacOS as my OS, Linux inside containers and remote

See also 
- [eighttrigrams/preferences](https://github.com/eighttrigrams/preferences)

</details>

## Topics

- [Claude Code Configuration Files](./topics/claude-code-configuration.md)
- [Claude and VSCode](./topics/claude-and-vscode.md)
- [Claude Plugins](./topics/claude-plugins.md)
- [Claude Marketplaces](./topics/claude-marketplaces.md)
- [clojure-claude-and-mcp-knowledge](./clojure-claude-and-mcp-knowledge/README.md).

## Recipes

- [How to Install Claude Code](./recipes/how-to-install-claude-code.md)
- [Working with MCP](./recipes/working-with-mcp.md)
- [Docker Claude Container](./recipes/docker-claude-container.md)

## Issues

- [Claude Shows Claude.ai Connectors in Claude Code](./issues/claude-shows-claude-ai-connectors-in-claude-code.md)

## Claude stuff marketplace

See [claude-marketplaces](./topics/claude-marketplaces.md) for background.

### Plugins

#### writing-clojure

Skills for writing Clojure code with REPL and nREPL support.

- [Clojure coding conventions](plugins/writing-clojure/skills/clojure-coding-conventions/SKILL.md)
- [Using the REPL to eval Clojure code](plugins/writing-clojure/skills/using-the-repl-to-eval-clojure-code/SKILL.md) — nREPL [SKILL](https://github.com/bhauman/clojure-mcp-light/blob/main/skills/clojure-eval/SKILL.md) copied wholesale from [bhauman/clojure-mcp-light](https://github.com/bhauman/clojure-mcp-light); install `clj-nrepl-eval` via `bbin`

#### architecture

Guidelines for structuring code.

- [Architecture review](plugins/architecture/skills/architecture-review/SKILL.md)
- [Writing tests](plugins/architecture/skills/writing-tests/SKILL.md)

#### tools

Reusable tools — currently a `PreToolUse` hook that logs every tool invocation.

#### rhizome

Skills for working with Rhizome — UI navigation and local REST API.

- [Navigate Rhizome user interface](plugins/rhizome/skills/navigate-rhizome-user-interface/SKILL.md)
- [Rhizome REST API](plugins/rhizome/skills/rhizome-rest-api/SKILL.md)
