# Claude Plugins

See also
- Anthropic "Create Plugins" article [here](https://code.claude.com/docs/en/plugins)
- Marketplaces [here](./claude-marketplaces.md)
- There is a `plugin-dev` plugin for Claude which is a "Toolkit for creating your own plugins" [source](https://code.claude.com/docs/en/discover-plugins#development-workflows)

Claude Plugins are collections of
- agents definitions
- skill definitions
- command definition
- hooks definitions (fire in parallel to project level hooks already defined, when matcher matches; TODO may be cool to define some here for uniform logging)
- mcps (? not sure how that works)

A plugin can be as simple as a local folder containing such files and directories as
- `<your-local-plugin-folder>/agents`
- `<your-local-plugin-folder>/skills`
- `<your-local-plugin-folder>/plugin.json`

the last of which looks something like this

```json
{
  "name": "<your-plugin-name>",
  "description": "<your-plugin-description>",
  "version": "1.0.0"
}
```

When provided as local folder, by calling `claude` with
the `--plugin-dir` parameter, which takes a path, and which can be specified multiple times
on a CLI call, to specify several of them.

Plugins can also be distributed using Claude [marketplaces](./claude-marketplaces.md).
Note that I noticed in this case the `plugin.json` is under a `.claude-plugin` folder,
not sure for what that discrepancy is relevant.
