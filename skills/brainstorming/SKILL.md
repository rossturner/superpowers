---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new, in software or out of it (a talk, a business, a renovation)."
---

# Brainstorming

You are very good at building. You build what you believe your human partner wants, and that belief is usually thinner than it feels. This skill is for finding out what they actually want, and why, before anything gets built.

People often haven't finished working out what they want. Good questions help them think it through. When you understand the why, you make the hundred decisions they never mention the way they would have made them.

## First: What Do You Actually Know?

Before you reply, ask yourself: what do I know about what they want, and why?

- **Everything that matters is in the request** ("make the icon cornflower blue"). This is a quick, clear task. Do it, and say what you did.
- **Something non-trivial is missing.** Start the conversation.

Before you start implementing, you must, in order:

1. Lay out the approaches in a message of their own, and have your human partner pick one (see Lay out the approaches).
2. Play the design back and get their approval of it (see Play It Back).
3. Size the work (see Size the Work). For a project, write the design document and run the spec panel.
4. For a project in software, invoke the superpowers-ross:writing-plans skill.

If nothing is open when you write your first message and there's one sensible way, steps 1 and 2 happen in that message (see Your First Message).

Two things aren't implementing: a spike they said yes to (see Spike to feel things out), and doing what they asked once they've opted out of the questions.

## Look Before You Ask

In an existing project, or when they've given you context (a spec, a plan, a handoff, files they pointed at, earlier conversation), dig in before your first message. Read what they referred to and the code or material it connects to, and keep reading until you can explain how the relevant parts work today and what this change would touch. Never ask what the project or their context already answers, or reopen what they've already decided.

## Your First Message

Move the work forward, with one of these:

- **They've already said what they want** (a spec, a plan, a detailed request): aim for about 200 words for the whole message. Echo their request back in your own words, so they can see whether you've got its shape: what they want, who it's for, and why, as far as they've said. Add what you found that bears on it: how the relevant parts work today and what the change would touch. If you found something they may not have considered that would change what they're asking for or how it has to be built, like a constraint, a conflict, or a cheaper path, say so plainly. How to build it comes later, once you understand what they want (see Lay out the approaches). End with one line inviting corrections. Then, if they haven't told you why they want it, even if you can guess, ask about that: one open question in their own terms, with nothing to pick from. If they have told you, and their request and the project leave open something whose answer would change what gets built, ask about the one that would change it most; when its choices can be named, sketch each concretely, with what it trades off and which you'd pick. If nothing like that is open, there's one sensible way: end with the short design itself (the approach, a line on why the others don't fit, and the design in a few lines) and ask them to approve it. Their approval covers the approach and the design: go on to Size the Work. Specs are often incomplete, so confirm before you build on one.
- **They haven't:** one open question, in their own terms, about the biggest thing their request leaves unsettled. Say why you're asking: what the answer would change about what you build. For "a website for my bakery": "If it's mostly for people deciding whether to stop by, I'd lead with hours and what's in the case today; taking orders is a different site. What do you want someone to do when they land on it?"

How the message ends depends on whether their message asked for brainstorming:

- **They asked for it** (by name, by invoking it, or by asking for a design discussion): end there. They want this conversation.
- **They didn't:** they may not want a conversation at all. End with a light, one-line offer to just get going instead, like "Or if you'd rather I just dive in, say so." If they take you up on it, this skill is done: state any significant how-it-gets-made choice (platform, language, medium) in one plain line, then do what they asked through the normal workflow.

That's the whole message.

## The Conversation

Ask a question only when the answer would change what gets built and neither the request nor the project answers it. Otherwise, state your call and your reason as a proposal they can correct, and move the work forward. Process steps are always your calls: writing things up, where files go, looking further, how to show something. Do them and say so. Ask one at a time. Use plain language, pitched just a little above where your human partner is. Match their vocabulary; never use process jargon. You never need to quote this skill to your human partner.

Be clear and concise. Lead with what matters. Avoid jargon. When you report what you found, give them the most important findings and offer the rest.

**Get them describing.** Until you know why they want it, ask open questions, with no example answers attached. Their own words carry intent that your options can't. Once you know why, when a decision has choices you can name, sketch each concretely, with what it trades off and which you'd pick. When they say "just guess" or "what do you think?", propose something concrete.

**How it gets made.** Every project rests on choices about medium, tools, materials, and resources: the platform, programming language, and libraries for an app; the medium for a piece of art. Read from how they talk which of those choices they want to make. Someone who raises the how or asks about trade-offs wants the options with your pick. Someone who talks about outcomes is handing you the how: make those calls and state each in a line. When there's existing work, build on what it already uses. Any choice you make goes in the design as your call, never as something they agreed to.

**Ground to cover.** This is territory, not a script. Never read these out as questions:

- what kind of thing this is, and what makes it special
- why now, and what success looks like to them
- goals, non-goals, and anti-goals (what would make this a failure even if it technically works)
- prior art: what they've seen elsewhere, loved or hated
- current state: what exists now, what they've tried
- the details they care about

**Make every question specific** to their project and what they've told you. Ask Socratically, the way a sharp colleague would: build each question on their last answer or on something you found, so it helps them think through a consequence or a case they may have missed ("Voting closes before the meeting, and two members joined this month. Does someone who joins mid-round get a vote?"). When the reason isn't already plain, say what you're hoping to learn or what the answer would change. A proposal they can correct, plus your reason for it, often beats a question.

**Do recon.** Once you have a bit of grounding and looking further would help, go look without asking first: deeper into their codebase or project, their own files and data, or the web. Read files outside the project only where they've pointed you to them. Then say briefly what you looked for and what you found.

**Lay out the approaches.** Once you understand what they want, and before you write anything up, put the ways of building it in a message of its own. Come up with several real alternatives and drop the weak ones, including any that work against why they want it and any the existing work rules out. Sketch the two or three that remain concretely enough to picture, grounded in what the project actually does, with what each trades off. Recommend one and say why, then ask which way they want to go; if they've handed you the how, say you'll go with your pick instead. When there's genuinely one sensible way, say so in that message and explain why the others don't fit; the design comes in the next one. This is for how it gets built; for what they want, get them describing first.

**Show, don't tell.** Whenever seeing would help more than reading, sketch it in text: a few lines of what they'd see. Offer the visual companion (below) when the look itself is theirs to decide:

- something they'll look at: a screen, a page, a printout, a sign
- a layout or arrangement: of a screen, a room, a schedule
- a flow or a sequence of steps
- options that would look different from each other
- a structure that's easier to see than read: a diagram, a timeline, a map

Once they've accepted, use it for mockups to react to, side-by-side options, and throwaway prototypes they can click.

**Spike to feel things out.** Agentic work is waterfall, but very, very fast. A quick throwaway build is often the cheapest way to learn what they want or whether something works. Offer one when it would help. When they just want to spike, get out of the way. Spikes get no tests or minimal ones, aren't bulletproof, and skip the plan, implementation, and review process. Bring what the spike taught you back into the conversation.

## Play It Back

Play back as you go. As soon as you understand one part well enough to describe it (what it's for and who it serves, say, or how one piece behaves), describe that part back in about 200-300 words, then return to questions about the next part. Playback and questions alternate through the whole conversation; the last chunk covers whatever is left.

Only what they said goes in as theirs. Anything you filled in goes in as your proposal, with your reason. End each chunk by asking what's wrong or missing. Once every part has been played back and corrected, their yes approves the design.

Before you send a chunk, check it: does it describe something they'll look at, like a page, a screen, a schedule, or a printout? If so, put a text sketch next to the description. If the look itself is theirs to decide and they haven't seen the visual companion offer yet, send the offer instead (its own message, below) and hold the chunk for the next message. Once they've accepted, put a mockup next to the description.

## Size the Work

Once you understand what they want and they've picked an approach, pick a size and say it in plain words. They can override it.

| Size | The full description | Then |
|------|----------------------|------|
| A quick, clear task | the request itself | do it |
| A small change | in chat | build it through the normal workflow |
| A project with a written design | played back in chat, recorded in a written design document | a full plan (for software: superpowers-ross:writing-plans) |

The written design has an **Approaches** part: the two or three ways you considered building it, what each trades off, which one they picked, and why. They pick in the conversation, before you write the document.

If it grows mid-task, stop, say so, and step up a size.

If this is really several independent projects, say so, agree on an order, and brainstorm them one at a time.

## The Written Design

For a project, once they've approved the design, write a plain document a talented builder in the domain could plan from without going back to your human partner. It records what they approved; it isn't a second thing to approve. Cover:

- intent and the why
- goals, non-goals, anti-goals
- constraints
- approaches (above)
- the parts of the how they decided, as they decided them
- what's left to the builder

**Where it goes:** in a software repo, `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. Otherwise, where they say. Your human partner's preferences override both. Commit it as soon as it's written; don't review it yourself first, the panel is the review.

The document is a working document. Nothing outside `docs/superpowers/` links to it, and no later work updates it.

**Spec panel:** dispatch reviewer subagents in parallel with `spec-panel-prompt.md` in this directory, one per lens, all in one message. Don't set a model; they run at this session's tier. The builder lens is always on the panel: a talented builder in the domain who has to plan from the document and can't ask. Add one to three more lenses chosen to fit this design. When you tell your human partner you're writing it up, say a few reviewers will read it first and you may come back once with a few questions.

Without a subagent tool, read the document through each lens yourself, one lens at a time. That's the panel run by hand, not a self-review.

Merge what the lenses report, then fix clear errors and contradictions directly, and sort the questions into three piles:

- **Answered already** by the conversation or the project: put the answer in the document.
- **Minor:** a sensible builder could settle it without changing what gets built. Settle it yourself and mark it in the document as your call.
- **Theirs:** only your human partner can answer it, and the answer changes what gets built.

Bring the "theirs" pile in one AskUserQuestion round, most important first, at most four questions. Settle anything past four yourself and mark it in the document as your call. That's the only round of questions the panel produces. Update the document with their answers and commit the revisions as a second commit, not an amend.

Then report the short list of calls you made, so they can check them, and move straight on: for software, invoke superpowers-ross:writing-plans. Don't ask them to review the document; they approved the design when you played it back. Outside software there's no writing-plans hand-off; the plan comes next, with them.

<HARD-GATE>
Nothing gets built until your human partner approves the full description as you played it back in conversation: the chat description for a small change, the playback for a project. The written document records what they approved; there's no separate approval of it. Building includes writing product code, scaffolding, installing dependencies, creating projects, and invoking an implementation skill. Reading and exploring are fine.

Two exceptions. If they opted out of the questions, the skill is done and the gate goes with it. A spike they said yes to may be built; it stays labeled throwaway, and keeping what it produced is a new request that comes back through this gate.

After a project's design is approved, write the document and run the panel; the next step is the plan. For software, invoke superpowers-ross:writing-plans and no other skill.
</HARD-GATE>

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll offer a menu of what they might want" | Options steer. Ask them to describe it first. |
| "I'll fill in sensible defaults" | Good. Say them out loud. A default they never heard is one they couldn't reject. |
| "I've answered their questions, so I'll play the design back" | Lay out the approaches first, in a message of their own (or, when nothing was open from the start, in your first message's short design). |
| "I should explain the process first" | Ask your question. The process shows itself. |
| "They said 'sounds good' to the idea" | Approval covers what you showed them. A part you haven't played back isn't approved. |
| "I'll ask them to look over the document" | They approved the design when you played it back. Report your calls and move on. |
| "The design is clear, the builder lens is enough" | The builder lens is the floor. Add the lenses this design needs. |
| "The spike works, I'll keep building on it" | Keeping it is a new request. Back through the gate. |

## Visual Companion

A browser tab for showing mockups, diagrams, and prototypes. It's a tool, not a mode: accepting it doesn't send every question to the browser.

**Offer it just-in-time.** Offer it the first time one of the moments above comes up, never upfront. The offer is its own message with nothing else in it:

> "This might be easier if I show you. Want me to open a browser tab with some mockups?"

If they decline, stay in text and don't offer again unless they raise it.

**Per question, ask: would they understand this better by seeing it?** Mockups, layouts, diagrams, and side-by-side designs go in the browser. Requirements, scope, tradeoffs, and conceptual choices stay in text. A question about a UI topic isn't automatically a visual question.

If they accept, read `visual-companion.md` in this directory before starting the server.
