---
name: using-the-repl-to-eval-clojure-code
description: Evaluate Clojure code via nREPL using clj-nrepl-eval. Use this when you need to test code, check if edited files compile, verify function behavior, or interact with a running REPL session.
---

# Clojure REPL Evaluation

## When to Use This Skill

Use this skill when you need to:
- **Verify that edited Clojure files compile and load correctly**
- Test function behavior interactively
- Check the current state of the REPL
- Debug code by evaluating expressions
- Require or load namespaces for testing
- Validate that code changes work before committing

## How It Works

The `clj-nrepl-eval` command evaluates Clojure code against an nREPL server. 
**Session state persists between evaluations**, so you can require a namespace in one evaluation and use it in subsequent calls. 
Each host:port combination maintains its own session file.

## Instructions

### Discover and select nREPL server

For using the nREPL, we first need to know which port to connect to.
If the port is not clear from context, by the human specifying it, or by an `.nrepl-port` file in the cwd,
you can use `$ clj-nrepl-eval --discover-ports` (will show all nREPL servers (Clojure, Babashka, shadow-cljs, etc.) running in the current project directory).

### Evaluate Clojure Code

Use the `-p` flag to specify the port and pass your Clojure code.

**Recommended: Pass code as a command-line argument:**
```bash
clj-nrepl-eval -p <PORT> "(+ 1 2 3)"
```

**For multiple expressions (single line):**
```bash
clj-nrepl-eval -p <PORT> "(def x 10) (+ x 20)"
```

**Alternative: Using heredoc (may require permission approval for multiline commands):**
```bash
clj-nrepl-eval -p <PORT> <<'EOF'
(def x 10)
(+ x 20)
EOF
```

**Alternative: Via stdin pipe:**
```bash
echo "(+ 1 2 3)" | clj-nrepl-eval -p <PORT>
```

Command-line arguments take precedence over stdin

### Common Patterns

**Require a namespace (always use :reload to pick up changes):**
```bash
clj-nrepl-eval -p <PORT> "(require '[my.namespace :as ns] :reload)"
```

**Test a function after requiring:**
```bash
clj-nrepl-eval -p <PORT> "(ns/my-function arg1 arg2)"
```

**Check if a file compiles:**
```bash
clj-nrepl-eval -p <PORT> "(require 'my.namespace :reload)"
```

**Multiple expressions:**
```bash
clj-nrepl-eval -p <PORT> "(def x 10) (* x 2) (+ x 5)"
```

**Complex multiline code (using heredoc):**
```bash
clj-nrepl-eval -p <PORT> <<'EOF'
(def x 10)
(* x 2)
(+ x 5)
EOF
```
*Note: Heredoc syntax may require permission approval.*

For everything more than evaluating a single expression, using HEREDOC is strongly recommended.

**With custom timeout (in milliseconds):**
```bash
clj-nrepl-eval -p <PORT> --timeout 5000 "(long-running-fn)"
```

**Reset the session (clears all state):**
```bash
clj-nrepl-eval -p <PORT> --reset-session
clj-nrepl-eval -p <PORT> --reset-session "(def x 1)"
```

## Available Options

- `-p, --port PORT` - nREPL port (required)
- `-t, --timeout MILLISECONDS` - Timeout (default: 120000 = 2 minutes)
- `-r, --reset-session` - Reset the persistent nREPL session
- `-h, --help` - Show help message

## Important Notes

- **When using command-line arguments**, pass code as quoted strings: `clj-nrepl-eval -p <PORT> "(+ 1 2 3)"` - works with existing permissions
- **Heredoc for complex code:** Use heredoc (`<<'EOF' ... EOF`) for truly multiline code
- **Sessions persist:** State (vars, namespaces, loaded libraries) persists across invocations until the nREPL server restarts or `--reset-session` is used
- **Always use :reload:** When requiring namespaces, use `:reload` to pick up recent changes

## Typical Workflow

1. Discover nREPL servers
3. Require namespace:
   ```bash
   clj-nrepl-eval -p <PORT> "(require '[my.ns :as ns] :reload)"
   ```
4. Test function:
   ```bash
   clj-nrepl-eval -p <PORT> "(ns/my-fn ...)"
   ```
5. Iterate: Make changes, re-require with `:reload`, test again
