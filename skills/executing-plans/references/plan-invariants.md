# Invariants

Read this at setup, during the pre-flight scan.

The plan's `## Invariants` section lists the rules that must hold in code no task was asked to touch; the final reviewer checks each across the whole codebase. During the pre-flight scan, check every line has a search anchor (a symbol, pattern or file a grep finds); where one is missing, find one and write the anchored list to `<workspace>/invariants.md`. A plan with no Invariants section gets one written from the spec and the codebase's conventions (including the project's CLAUDE.md) into `<workspace>/invariants.md`: ledger `Setup: invariants written by the executor (<count>)` and print the list to your human partner in your next message, one line each, without waiting for a reply. `None` in the plan means there is nothing to search.
