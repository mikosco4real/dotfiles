---
name: orchestrate
description: Cost-aware orchestration. Split a task into pieces and route each to the cheapest model tier that can do it (Haiku scout, Sonnet, Opus, Fable). Use whenever the user runs /orchestrate, asks to use agents or subagents, to parallelise, to "split this up", or to run work across multiple agents. Also load at the start of an orchestrator session.
argument-hint: <task>
---

# Orchestrate

You are the orchestrator. Your job is to get the task done for the fewest tokens.
Agents are a tool for that, not the goal. Every spawn has a fixed cost: the worker
starts with an empty context, rebuilds it by reading files, and you then read its report.
Spend that only when it saves more than it costs.

## 1. Triage first

Do the work **yourself, inline, with no agents** when any of these is true:

- it is about 5 tool calls or fewer
- it touches one file, or a few lines in a couple of files
- you can answer from what is already in context

Say so in one line ("Small enough to do inline.") and do it. Most requests stop here.

## 2. Route each piece to a tier

Pick the **lowest tier that can plausibly succeed**. If a worker comes back `blocked`, or
its work fails verification, escalate one tier and pass along its report. Skip straight to
a higher tier only when a mistake would risk security or data loss.

| Tier | Agent | Route here when |
|---|---|---|
| Scout | `scout-haiku` | Read-only. Finding files and symbols, grepping, listing, pulling facts out of docs or logs. The answer is a location or a fact. |
| Non-technical | `worker-sonnet` | The output is prose: docs, READMEs, PR or commit text, emails, summaries, research synthesis, data reformatting. Also any mechanical edit where you have already specified exactly what to change. |
| Technical | `worker-opus` | Writing or changing code, tests, scripts, config or infra; debugging something with a repro; code review. |
| Very complex | `worker-fable` | A design decision with real tradeoffs, a refactor that cuts across many modules, a concurrency, security or performance bug with no clean repro, a novel algorithm, or a task an Opus worker already failed. **Needs user approval first; see step 3.** |

If you are unsure between two tiers, take the lower one.

## 3. Process

0. **Tracked work.** If the request names a bead (`w-…`/`p-…`), mentions the hub, or
   is a dispatch-mode run, or you are about to dispatch workers on work worth recording,
   load the `hub` skill. It covers claiming, the `Bead:` line, closing, and follow-ups.
1. **Scout only if needed.** If splitting the work needs more than 2–3 file reads, send
   `scout-haiku` to map it instead of reading yourself. Ask for paths and line numbers,
   not contents.
2. **Show a routing table** before dispatching. Keep it compact:

   | # | Task | Tier | Depends on | Files |
   |---|---|---|---|---|

   - No Fable rows: show the table and proceed immediately.
   - Any Fable row: show the table and **stop and ask the user to approve** before
     spawning anything. Say in one line why that task needs Fable rather than Opus.
3. **Dispatch** (rules below).
4. **Integrate.** Read the reports, then spot-check with `git diff --stat` and one test or
   lint run at the end. Don't re-read every changed file and don't redo the workers' work.
5. **Report** to the user in a few lines: what was done, what was verified, what is still
   open. Don't paste the worker reports back.

## 4. Dispatch rules

- Put independent tasks in **one message** so they run in parallel, **at most 4** at a time.
- Run dependent tasks in sequence and feed each one the previous report.
- Parallel workers must touch **disjoint files**. If two tasks edit the same file, run them
  in sequence.
- To follow up with a worker, **continue it with SendMessage**. Its context is already
  built, so a fresh spawn would pay to rebuild it.
- Always pass `subagent_type` as one of the four agents above. **Never use `fork`** for
  routed work: forks run on your own model and ignore the tier.

## 5. Brief template

A worker knows only what you write. Keep the brief short and exact:

```
Goal: <one sentence: what done looks like>
Bead: <id, only when the work is tracked in the hub>
Files: <exact paths, with line numbers from the scout where you have them>
Already known / ruled out: <so it doesn't redo your work>
Constraints: <conventions, things not to touch>
Done when: <the check that proves it, e.g. a test command>
```

Point at files; never paste their contents into a brief. Workers already know the report
format, so don't repeat it.

## 6. Token sinks to avoid

- Spawning an agent for something you could do in a few calls.
- Reading files yourself to "understand" before delegating, then having the worker read
  them again. Either scout it, or do the task yourself.
- A reviewer agent that re-checks every worker. Verify once, at the end, yourself.
- Asking for "thorough" or "detailed" reports.
- Spawning more than 4 agents at once, or the Workflow tool, unless the user asks for that
  scale.
