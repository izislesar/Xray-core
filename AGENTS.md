# Agent instructions

## Task tracking

Beads is the source of truth for task state in this repository. Do not create parallel task trackers in Markdown.

Before starting work:
- Run `bd ready` to find unblocked work.
- Run `bd show <id>` for the issue being worked on.
- Inspect dependencies before changing implementation.

While working:
- Keep Beads status, dependencies, and notes synchronized with actual progress.
- Close issues only after the implementation and required verification are complete.
- Use Markdown documentation for durable technical knowledge, decisions, and interfaces only; do not use it as a second task database.

Before handing off:
- Run the relevant tests and verification commands.
- Update Beads with the resulting state.
- Leave the working tree and task graph understandable to the next agent.

## Current engineering constraint

The kernel TCP connect observer work must not claim a `flow_id <-> socket_cookie` mapping. That mapping is a later M4 gate and requires an explicit zero-ambiguity result.
