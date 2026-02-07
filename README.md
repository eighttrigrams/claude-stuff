# Claude Stuff

See also 
- [eighttrigrams/preferences](https://github.com/eighttrigrams/claude-stuff)

## Claude Code on Mac

### Installation

Use

```sh
$ npm install -g @anthropic-ai/claude-code
```

as per [docs.anthropic.com/en/docs/claude-code/setup](https://docs.anthropic.com/en/docs/claude-code/setup) and choose your account type (see above).

Or use *Homebrew*.

### Configuration files

The main config file is under `~/.claude.json`. I believe it is not really meant to be edited by hand.
Rather, it keeps tabs about where your claude working directories are on your system and what your preferences are
there, apart from the things you yourself specify in these working dirs.

***Working dirs*** means that when you open `claude` in a dir `/Users/dan/Workspace/a`, its settings get stored independently
from those which get stored for a working dir on the same system, at a different path, say `/Users/dan/Workspace/b`.

TODO talk about
- projects key in that file
- more than one way to store configuration about mcp servers

## "Memory"

A metaphor, which you see from the scare quotes, I don't like, for whichever reason, although I'm generally a fan of metaphors.

There is a configuration folder `~/.claude/`. 
It contains `settings.json` for permissions and `CLAUDE.md` for global preferences.

### VSCode

Surprisingly to me, when I opened up a *Claude Code* console inside **VSCode**, it integrated seemlessly and immediately without
any further setup necessary. For example, it shows diffs then using VSCode editor windows.

## Clojure Skills plugin
TODO move to recipes

Provides SKILLS:
- clojure-coding-conventions
- using-the-repl-to-eval-clojure-code

Can be installed and removed at another location with

```
$ claude
claude> /plugin marketplace add eighttrigrams/claude-stuff
```

It seems to me that the above step can be done from any claude anywhere and the following below then just "imports" this or enables 
this in a specific claude workdir.

And there in the `.claude/settings.json`:

```json
"extraKnownMarketplaces": {
    "claude-stuff": {
      "source": {
        "source": "github",
        "repo": "eighttrigrams/claude-stuff"
      }
    }
  },
  "enabledPlugins": {
    "writing-clojure@claude-stuff": true
  }
```

Test

```
claude> ❯ /skills                                                                                                                                                                                                                      
────────────────────────────
 Skills                                                                                                                                                                                                                        
 <n> skills                                                                                                                                                                                                                    
                                                                                                                                                                                                                             
 Project skills (.claude/skills, .claude/commands)                                                                                                                                                                           
<snip>

 Plugin skills (plugin)
 using-the-repl-to-eval-clojure-code · writing-clojure · ~60 description tokens
 clojure-coding-conventions · writing-clojure · ~31 description tokens
```

To clean up

```bash
claude> /plugin marketplace remove eighttrigrams/claude-stuff
$ rm -rf ~/.claude/plugins/cache
```
