---
name: rhizome-development
description: Describes the current local development setup, for when we want to perform development tasks on the actual Rhizome app
---

The preferred setup is a CMUX workspace, where we, in the left pane of two panes, coordinate from a `claude` session (the *coordinator*), in the upper pane of a vertical split, in its terminal surface, another agent, which sits in the lower pane in its
vertical split, in its own terminal surface.

That agent is the *doer*. We want the doing be happening in a sandbox.
Normally in one where the internet is cut off (`make yolo`), and when the feature(s) we are working on demand, 
one which has vector db support. For reference, see `rhizome/README.md`.

Interaction happens between the human and the coordinator, and then, autonomously, between the coordinator and the doer.
I want full visibility, that's why I want handoffs to happen in the cmux surfaces (use `cmux` CLI).
