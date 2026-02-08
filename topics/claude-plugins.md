# Claude Plugins

See also
- Anthropic "Create Plugins" article [here](https://code.claude.com/docs/en/plugins)
- Marketplaces [here](./claude-marketplaces.md)

Claude Plugins are collections of
- agents definitions
- skill definitions
- command definition
- hooks definitions (fire in parallel to project level hooks already defined, when matcher matches; TODO may be cool to define some here for uniform logging)
- mcps (? not sure how that works)

A plugin can be as simple as a local folder containing such files and directories as
- `agents`
- `skills`
- `plugin.json`

the last of which looks something like this

```json
{
  "name": "<your-plugin-name>",
  "description": "<your-plugin-description>",
  "version": "1.0.0"
}
```

Plugins can be distributed using Claude [marketplaces](./claude-marketplaces.md),
but also being used, when provided as local folder, by calling `claude` with
the `--plugin-dir` parameter, which takes a path, and which can be specified multiple times
on a CLI call, to specify several of them.
