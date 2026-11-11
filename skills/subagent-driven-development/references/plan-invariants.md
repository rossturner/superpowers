# Invariants

Part of superpowers-ross:subagent-driven-development. Read this at setup, during the pre-flight scan.

### Invariants

An invariant is a rule that must hold in code no task was asked to touch — "a withheld restriction is invisible to its author", "links are built only through `FrontendUrls`". Task briefs list the places the plan's author thought of; invariants are how a reviewer finds the places nobody listed.

- The plan's `## Invariants` section is the list. Each line names the rule, the kinds of code path it governs, and at least one search anchor — a symbol, pattern or file a grep finds. During the pre-flight scan, check every line has an anchor; where one is missing, find one in the codebase, add it to `<workspace>/invariants.md` beside a copy of the list, and use that file from then on.
- A plan with no Invariants section (an older plan): write the list from the spec and the codebase's conventions (including the project's CLAUDE.md) into `<workspace>/invariants.md`, ledger `Setup: invariants written by the controller (<count>)`, and print the list to your human partner in your next message, one line each. Do not wait for a reply. With no reachable spec, write it from the plan alone.
- `None` in the plan means there is nothing to search; the spec reviewer still checks the diff against the spec.
