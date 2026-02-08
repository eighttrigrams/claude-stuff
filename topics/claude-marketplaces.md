# How to use and make your own claude plugin marketplaces

See also
- Anthropic "Discover and install prebuilt plugins through marketplaces" article [here](https://code.claude.com/docs/en/discover-plugins)
- [plugins](./claude-plugins.md)

It seems like in order to 'host' plugins, like we do here, we cannot simply host a single plugin,
but must do this using the marketplaces construct.

---

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