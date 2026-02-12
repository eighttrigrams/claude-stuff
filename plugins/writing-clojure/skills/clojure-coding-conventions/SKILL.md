---
name: clojure-coding-conventions
description: When in need to not only read and understand, but to actually write Clojure code.
---

Whenever we start editing Clojure Code, start by saying "Hammock Time!"

# Conventions

- Atoms start with `*`, i.e. `*my-atom`, to be deref'ed as `@*my-atom`.

Prefer to write conditionals as compactly as possible.

Bad:

```clojure
(if condition
  (do-something a)
  (do-something b))
```

Good

```clojure
(do-something 
  (if condition a b))
```

With let bindings, default to returning results unnamed

Bad:

```clojure
(let [a 1
      result (do-stuff a)]
  result)
```

Good:

```clojure
(let [a 1]
  (do-stuff a))
```
