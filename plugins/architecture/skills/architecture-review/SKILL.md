---
name: architecture-review
description: Architecture review guidance. Use when reviewing architectural changes, assessing system design, or evaluating code structure.
---

# Architecture Review

## Module responsibilities

Does each namespace or function has a clear responsibility? And is it one, and a clearly nameable one?
Or are there multiple things being done at once? In that case, why not break it down into modules which do just **one** thing?

## Side effects to the outside, functional core

Example, when we access an environment variable in a namespace, we can ask if we can access the variable one namespace \"higher\",
at the current function's call-site, and pass it simply in as a paramter. The more functions are kept pure, the easier it is for us to test.

## Full Stack Application Review - Keep the frontend small and focused on UI

When we have an application like here which is part single page application (SPA) for the frontend and a backend (via REST, or GraphQL),
we want to consider some things.

While the frontend is responsible for keeping a specific user's state, it should stay **as dumb as possible**. For example, instead of sorting
something in the frontend, we always would chose sorting on the backend and hand over a list (which is sorted by definition) to the frontend.
