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
- [Adding and Removing MCP Servers](./recipes/adding-and-removing-mcp-servers.md)
- [Docker Claude Container](./recipes/docker-claude-container.md)

## Issues

- [Claude Shows Claude.ai Connectors in Claude Code](./issues/claude-shows-claude-ai-connectors-in-claude-code.md)

## Claude stuff marketplace

The claude-stuff Claude "marketplace" provides 2 plugins, with a couple of SKILLs each
- writing-clojure
  - clojure-coding-conventions
  - using-the-repl-to-eval-clojure-code (note: this is a nREPL [SKILL](https://github.com/bhauman/clojure-mcp-light/blob/main/skills/clojure-eval/SKILL.md) for using `clj-nrepl-eval` which I copied wholesale over; naturally we want to have that installed via `clojure-mcp-light` via `bbin`)
- architecture
  - architecture review
  - writing-tests

See [claude-marketplaces](./topics/claude-marketplaces.md).
