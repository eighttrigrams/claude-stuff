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