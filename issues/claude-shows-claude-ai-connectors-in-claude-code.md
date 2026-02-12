# Problem: Claude shows Claude.ai connectors in Claude code

Claude Code auto-syncs MCP connectors (Asana, Notion, Slack) from your claude.ai account.
There is no official setting to disable this per-project. Tracked in:

- https://github.com/anthropics/claude-code/issues/20412
- https://github.com/anthropics/claude-code/issues/22301

### Workaround

In `~/.claude.json`, set the feature flag to `false`:

```json
"tengu_claudeai_mcp_connectors": false
```

Located under `cachedGrowthBookFeatures`. Gets overwritten on startup/updates.