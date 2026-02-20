# MCPs

With the help of MCPs Claude can connect to other programs.

Which MCPs are available to Claude Code depends on the project
directory we are starting `claude` in. Remember Claude Code
stores project information by default centrally in `~/.claude.json`.
It manages this file by itself, but remembers some things
about the project when we issue certain commands; one of which
is the command to add an MCP.

```bash
$ cd my-project
my-project$ claude mcp add <mcp-name>
```

A concrete example

```bash
$ npx playwright install
$ claude mcp add playwright -- npx -y @playwright/mcp
```

When I open `claude` next time in that directory, it has that MCP
available; when I open `claude` in another directory, this does not apply.

Certain things are stored in the project dir itself in the `.claude` folder,
instead of that central place, and as such we can see them easily and feel
invited to edit those. They are closer at hand.

We also can store MCP configuration for our project *explicitly* in a similar
manner, only that we do that not in that `.claude` folder, but at the top
level of our project dir, under `.mcp.json`.

An example:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest", 
        "--headless", 
        "--viewport-size=1400x900",
        "--output-dir=.playwright-mcp",
        "--allowed-origins=http://localhost:3027"]
    }
  }
} 
```

One advantage is that we can easily hand edit such a file and we can see
how this is useful for setting specific call parameters, as shown above.

The corresponding remove command is

```bash
$ claude mcp remove <mcp-name>
```

For our example


```bash
$ claude mcp remove playwright
```

Should I have defined playwright in both places, it asks me whether to
remove it from the local or the project scope. TIL that local scope 
refers to `~/.claude.json` and project scope to `<my-project>/.mcp.json`.

TODO
- plugins
- claude.ai
- write mcps
- mcps as part of plugins
- i actually *needed* to use .mcp.json in one instances, because mcp add adds on a per git repo basis; not a per folder basis, and i switched that setup