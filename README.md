# Clojure Stuff

See also 
- [eighttrigrams/preferences](https://github.com/eighttrigrams/claude-stuff)

## Clojure Skills plugin

Provides SKILLS:
- clojure-coding-conventions
- using-the-repl-to-eval-clojure-code

Can be installed and removed at another location with

```
$ claude
claude> /plugin marketplace add eighttrigrams/claude-stuff
```

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
