# Clojure Claude & MCP Knowledge

See also 
- [bhauman/clojure-mcp](https://github.com/bhauman/clojure-mcp)
- [Vibe Coding With Clojure-MCP: Bruce Hauman/Luke Burton/Gene Kim](https://www.youtube.com/watch?v=plMpFV5s8nY)
- [eighttrigrams/tracker-mcp](https://github.com/eighttrigrams/tracker-mcp)
- [eighttrigrams/clj-minimals](https://github.com/eighttrigrams/cljc-minimals)
- [eighttrigrams/hq-documentation](https://github.com/eighttrigrams/hq-documentation)
- [RokLenarcic/mcp-server](https://github.com/RokLenarcic/mcp-server)
- [Metosin Clojure MCP Demo](https://www.youtube.com/watch?v=F61YWNapxJg)
- [metosin/mcp-toolkit](https://github.com/metosin/mcp-toolkit)

As developers we want to get the most out of our tools,
and for the current generation of LLM-based AI tools like **Claude** 
that means extending them via *MCP*. 

This repository should serve as an intro to Claude and MCP development in Clojure. As per my usual philosophy,
things in the example projects are just laid out in their barest form, without any unnecesary distraction. 
This is to a) get you going, but keeping the cognitive load light to b) make sure you understand and feel in control about these basics.

Things here have been tested only under MacOS (on an M chip).

## Claude Code and Claude Desktop

**Claude Code** is a terminal/command-line based application primarily focused at editing
code or code-like artifacts on your file system and helping you develop running programs.

**Claude Desktop** is a web-app like experience, which allows you do chat about whatever and 
do research, similar to ChatGPT. It runs on your desktop, however, to exploit the full benefits
of having access to your local system (if you allow it).

For *Claude Desktop* you need to signup for a Pro or Max subscription (can be done monthly) to which
various rate limits apply depending on the options you chose. This account is also called the ***Claude Chat Account***. *Claude Code* can share that subscription
with *Desktop* and both together share the assigned usage quotas. However, if you only intend to use *Claude
Code* you might want to simply buy API credits on console.anthropic.com. This account is called the ***Anthropic Console Account***. 
Again, you can choose between those two accounts when using *Claude Code*.

Both *Claude Code* and *Desktop* can run on the same system, but don't share all their configuration files. So don't expect
things you configure in *Code* to be automatically available to *Desktop* for example.

On the other hand, some artifacts like your local `~/.claude.md` are shared and read by both installations.

## Getting started

## Clojure MCP development

MCP allows you to write tools to which your LLM has access to. In this repository, we find two examples, one
using plain Clojure, one using the Java based modelcontextprotocol SDK. These examples are intended to be minimal.
They are designed to help you to get started with writing your own MCPs.

In general, developing an MCP works in a loop with ongoing communication via `stdin` and `stdout`. So make sure that
any logging that would happen anywhere in your MCP server should either go to `stderr` or to a logfile, such that
the **pitfall** of pollution of the output is circumvented.

### MCP in Claude Desktop

Add this configuration to your Claude Desktop MCP settings file.
To find the configuration file use the MacOS operating system's menu  "Claude ->> Settings" then 
navigate inside Claude via "Developer" section to **Edit Config**. 
It will open the containing folder of `claude_desktop_config.json` in Finder. There is also
a **Open Logs Folder** button in which logs are stored (useful for debugging your MCPs under development).

```json
{
  "mcpServers": {
    "weather": {
      "command": "/absolute/path/to/run.sh"
    }
  }
}
```

### MCP in Claude Code

MCPs are named and point to commands:

```sh
$ claude mcp add <your_mcp_name> -- <command to run your mcp>
```

Running clojure MCPs seems to work best by wrapping them in a short `run.sh` script (don't forget to chmod+x it!):

```bash
#!/bin/bash
cd "$(dirname "$0")"
clojure -M:run
```

Corresponding exerpt from a `deps.edn` pointing to a `server` entry namespace with a `-main` function.

```clojure
:aliases {:run {:main-opts ["-m" "server"]}}
```

MCPs can be removed again with:

```sh
$ claude mcp remove <your_mcp_name>
```

MCPs in Claude Code are *scoped*. When adding an MCP in a folder, don't expect the MCP to be automatically 
available when you call Claude Code from another folder higher up next time.

To check whether things work fine, use the `/mcp` command in Claude Code.

```
│ Manage MCP servers  
│ ❯ 1. weather  ✔ connected · Enter to view details
```

If it says anything else, like "connecting", something is definitely wrong.
