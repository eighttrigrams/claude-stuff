---
name: clojure-coding-conventions
description: When in need to not only read and understand, but to actually write Clojure code.
---

Whenever we start editing Clojure Code, start by saying "Hammock Time!"

## REPL & nREPL - Running code in the context of a running application.

Running code inside a running app is as simple as.

```bash
Discover available nREPL ports using the helper script:

$ ./nrepl-ports.sh
utwig                          47480
Then connect:

$ clj-nrepl-eval -p 47480 '(+ 1)'
```
