---
name: developing-plugins
description: Findings and notes about developing Claude Code plugins. Use when working on plugin structure, skills, hooks, or marketplace setup in the claude-stuff repo.
---

# Developing Plugins

## Plugin Structure

A plugin lives under `plugins/<plugin-name>/` with:

```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json          # name, description, version, author
  skills/
    <skill-name>/
      SKILL.md           # frontmatter (name, description) + content
      examples.md        # optional, referenced from SKILL.md
  hooks/                 # optional
  agents/                # optional
  commands/              # optional
```

## plugin.json

Minimal:
```json
{
  "name": "my-plugin",
  "description": "What it does",
  "version": "1.0.0",
  "author": { "name": "you" }
}
```

## Skills

- The `name` in SKILL.md frontmatter is how the skill appears in the system prompt
- The `description` controls when Claude triggers the skill -- make it specific about *when* to use it, not just what it is
- Keep skill content focused on one concern per plugin when possible; splitting unrelated skills into separate plugins makes install granularity better

## Installation

Plugins from this repo (a "marketplace") are installed via `/install-plugin` from within a project. They get cached under `~/.claude/plugins/cache/claude-stuff/<plugin-name>/<version>/`. The registry is `~/.claude/plugins/installed_plugins.json`.

After renaming or restructuring a plugin, users need to uninstall the old one and install the new one.

## Checklist

- When adding, removing, or renaming a plugin, update the project's `README.md` to reflect the change

## Findings

- One-skill-per-plugin is cleaner than bundling unrelated skills; it makes each plugin independently installable
- Skill `description` in frontmatter is the primary trigger mechanism -- if the description doesn't match what Claude is doing, the skill won't activate
- The `examples.md` file alongside SKILL.md is useful for keeping the main skill concise while providing detailed usage patterns
