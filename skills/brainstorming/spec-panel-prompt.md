# Spec Panel Prompt

Dispatch one fresh general-purpose subagent per lens with this prompt
once the written design is committed, all in one message so they run in
parallel. Don't set a model. Fill in the lens, the document path, and
the domain.

The builder lens is always on the panel, and is the default fill:

- **[LENS]:** a talented [DOMAIN, e.g. "software engineer", "event
  planner", "bakery consultant"]
- **[TASK]:** You've been handed a design document and asked to put
  together a plan to build what it describes.
- **[WHAT MATTERS]:** places where you'd have to guess to plan this, and
  a wrong guess would matter

For each further lens, replace those three with who the reader is, what
they've been asked to do with the document, and what they're looking
for. For example: the person who'll run or maintain it, looking for what
breaks in use; someone who doubts the core assumption, looking for where
the design rests on something unproven; the person whose existing work
this touches, looking for what it would break or contradict.

```
You are [LENS]. [TASK] You will not be able to talk to the person who
wrote it.

Read [DOCUMENT_PATH].

Report only what matters from where you stand: [WHAT MATTERS]. Put each
finding in one of two lists, ranked by importance within each:

1. Questions: things you'd still need answered. For each, give the
   question and why the answer changes what gets built.
2. Clear errors: contradictions within the document, or statements that
   are plainly wrong. For each, quote the passage and say what's wrong.

Skip anything the document explicitly leaves to the builder, and anything
you could reasonably decide yourself. Skip nitpicks about wording.

If nothing important is left, say "nothing important left".
```
