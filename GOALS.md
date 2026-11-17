# Durable goals — unreleased 0.3 development

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

This interface is under qualification. Public v0.2.1 does not include it.
See [the release plan (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/NEXT_RELEASE_PLAN.md) for remaining gates and the
[configuration reference](CONFIGURATION.md) for all defaults and examples.

A goal records its objective and acceptance requirements **before any model
work**, plus user corrections, retained reports and an optional lifetime budget.
No overall turn, period or elapsed-calendar-time cap is imposed by default.
Each work period uses the ordinary recursive execution core. The default path
replans from retained public state. The opt-in native consumer profile retains
its exact safely closed recursive state across periods. Uncertain interrupted
work is never automatically replayed.
Ordinary `spine run` incurs no goal-store or mandatory planner calls.

The model finishes a period with typed progress: `continue`, `needs_input`,
`wait` or `complete`. The host checks field combinations and preserves remaining
obligations. A completion declaration creates a candidate; default acceptance
requires configured checks or an explicit user decision. Invalid progress receives
repair feedback within the period's existing limits, without an extra allowance.

```mermaid
flowchart LR
    G[Objective, requirements and retained progress] --> P[Bounded recursive period]
    P -->|More work| G
    P --> W[Question or event wait: no model calls]
    W -->|Answer or observed event| G
    P --> D[Completion candidate and evidence]
    D -->|Repair required| G
    D -->|Configured checks or explicit acceptance| A[Accepted within recorded scope]
    P --> F[Uncertain effects: retain ownership and await reconciliation]
```

## Start and control a goal

With a development build and configured provider, create a specification outside
the model workspace:

```json
{
  "objective": "Prepare the supplier comparison and ask me for missing criteria.",
  "acceptance": [
    "Cite supplied evidence for each price and service claim.",
    "List unresolved questions before recommending a supplier."
  ]
}
```

```sh
spine goal create /absolute/workspace /outside/workspace/goal.json
spine goal run GOAL_ID
spine goal show GOAL_ID
```

Creation returns an ID and revision. `run` supervises successive periods until
accepted or explicitly cancelled. Questions, waits, blockers and attention states
remain pending; it reports the reason and waits without model calls. Answer or
amend the goal to resolve missing information. A recorded timer deadline wakes
automatically; an external event requires explicit input.

Use `SPINE_GOAL_DRIVE=until_wait` to return at a wait/attention boundary for an
external scheduler, or `run GOAL_ID --once` for at most one period. Final JSON
includes the goal and its status. `started` identifies admission of the last
requested period; configuration rejection does not spend the goal allowance.

Control operations require the current revision from `show`; stale updates fail:

```sh
spine goal amend GOAL_ID REVISION 'Prioritize total annual cost.'
spine goal answer GOAL_ID REVISION QUESTION_ID 'The budget is 25000 EUR.'
spine goal wake GOAL_ID REVISION EVENT_ID 'The supplier response is available.'
spine goal accept GOAL_ID REVISION CANDIDATE_ID
spine goal cancel GOAL_ID REVISION 'The request has been withdrawn.'
```

Question, event and acceptance-candidate IDs are distinct. `amend` records a
correction, including during active execution. The host queues it for a safe
boundary; a late correction remains available to the next period. Results based
on an earlier revision cannot complete a revised goal. An explicit amendment
reopens an accepted/model-completed goal under its existing limits.

New answer records retain the exact question ID and text with the unchanged
answer, including after history compaction. This keeps short replies such as
“Option B” interpretable through `goal_history`. Older records without question
context remain readable; missing text is not reconstructed or invented.

In CLI supervision, stdin text answers the current pending question, or records
a correction if none is pending. `/accept CANDIDATE_ID` explicitly accepts a
candidate; ordinary text such as “yes” is an answer, not acceptance. Text at a
terminal state is rejected: reopening requires the explicit amendment command.

Storage/control commands make no provider calls. Keep the supervising process
running, or have an application restart it for the stored goal. Spine does not
install an OS daemon. A configuration flag cannot guarantee arbitrary task
success, machine uptime or provider availability; unavailable dependencies remain
visible as unfinished work. Calendar waiting does not spend active-work time.

## Limits and accounting

### Consumer verification (0.3 development)

With a development build, enable parent assessment and retained same-child repair:

```sh
SPINE_NATIVE_TOOLS=1 SPINE_RETURN_VERIFICATION=consumer spine goal run GOAL_ID
```

This opt-in profile requires built-in native tools, no custom native server or
external/client tool providers, and the `require_acceptance` completion policy.
Include `goal_history` if the goal declares an explicit tool scope. Configuration
and source-profile changes are checked before a period is reserved. Keep the
original model, endpoint, effort, context and tool configuration when continuing
a retained execution. Questions survive supervisor restart with zero model calls
while waiting. An answer resumes the same child; old evidence becomes historical
and current sources must be reread before relying on them.

The [actual CLI controls (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/proofs/2026-11-17-native-consumer-goals/README.md) cover
restart, correction, inspection and explicit rebase. Parent assessment remains
fallible model judgment. The separate adaptive mode below adds independent review;
neither assessment nor review substitutes for final goal acceptance.

### Adaptive verification (0.3 development)

For a native macOS/Linux development CLI, enable independent review alongside
parent assessment:

```sh
SPINE_NATIVE_TOOLS=1 SPINE_RETURN_VERIFICATION=adaptive \
  SPINE_REVIEW_MAX_OUTPUT_TOKENS=1024 spine goal run GOAL_ID
```

This is opt-in and unreleased. It has the same built-in-only,
`require_acceptance` and `goal_history` restrictions described above. Keep the
recorded model and tool profile when resuming. See [configuration and review costs](CONFIGURATION.md#native-adaptive-verification-03-development).

A parent may escalate a pending child to independent review, inspect the cited
artifacts and repair that same child before consuming its result. Complete goal
candidates require a separate judgment. Valid unfinished period yields bypass
whole-goal review; they remain unfinished work. Reviews consume the existing
allowance, and unchanged attempted judgments are not automatically retried.

An unresolved review question uses the ordinary durable question/answer path.
While waiting, the supervisor spends no model calls; an exact accepted answer
resumes work and requires the current scope and evidence to be checked again.
A positive model judgment still leads to the goal’s configured acceptance checks
or explicit `goal accept` decision. It cannot establish every natural-language
requirement by itself. The default remains `off` pending efficacy evaluation.

The [integrated native adaptive controls (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/proofs/2026-11-17-native-adaptive-goals/README.md)
pass 1,062 default / 1,591 all-feature test invocations, strict Clippy and formatting.
An actual CLI control uses 13 scripted requests and three file reads to exercise
independent child review, same-child repair, root uncertainty, restart and short-answer
resumption. This establishes lifecycle behavior, not live model repair efficacy.

### Period and lifetime settings

The optional `mode` is `auto` (default), `direct` or `recursive`. `allowed_tools`
restricts exact tool names and is inherited by descendants. Model/provider
configuration follows ordinary runs; the stored goal controls its own limits.

The default lifetime is `null`: **no overall maximum turn/period count**. Bounded
periods limit each execution slice, not the total number of slices. The default
period is:

```json
{
  "requests": 16,
  "max_request_bytes": 1048576,
  "total_request_bytes": 8388608,
  "output_tokens": 65536,
  "steps": 32,
  "tasks": 8,
  "tools": 32,
  "depth": 4,
  "active_seconds": 300
}
```

Supply a complete `period` object to change it. DIRECT fixes one task/depth zero.
A finite overall cap is optional; this example deliberately enables one:

```json
{
  "objective": "Reconcile the weekly operating reports.",
  "lifetime": {
    "requests": 320,
    "request_bytes": 167772160,
    "output_tokens": 1310720,
    "steps": 640,
    "tasks": 160,
    "tools": 640,
    "active_seconds": 6000,
    "periods": 20
  }
}
```

Omit `lifetime` to leave it unlimited. Zero is not an unlimited marker. Explicit
limits are retained and cannot reset on restart, reconnect or amendment. Reaching
an explicit lifetime cap keeps the goal unfinished and waiting for direction.

Before dispatch, the host reserves a period within any remaining finite allowance.
It settles consumed counters only against an owned closed report and durable
request journal. Unused capacity is released; spent requests, rejected decisions
and uncertain effects are not refunded. Each started period charges its full
active-time slice conservatively. This is an accounting policy, not CPU or model
elapsed time. Output reservations are not actual token counts or currency costs.

The older `SPINE_VERIFICATION_POLICY` and `SPINE_PUBLIC_CHECK_SET` Task policies
are rejected before goal admission or prompt correction: they lack a nonfinal
pause contract. Goal completion predicates below use a separate goal contract;
no verification policy is silently bypassed.

## Completion acceptance

New goals default to `{"mode":"require_acceptance","checks":[]}`. A valid
completion without checks creates a `needs_input` candidate. Review the retained
report and use `goal accept` with its exact ID/current revision. Confirmation
rechecks the report, contract and listed artifact snapshots. It does not verify
unlisted workspace files independently.

To accept a machine-checkable result automatically, include a policy such as:

```json
{
  "objective": "Count the supplied records and write result.json.",
  "completion": {
    "mode": "require_acceptance",
    "checks": [{
      "id": "expected-count",
      "path": "result.json",
      "expected": {"kind": "json_equals", "value": {"count": 3}}
    }]
  }
}
```

`sha256` is also supported, using a lowercase 64-digit hex value. These are exact
file predicates, not semantic judges. Expected values stay outside model context;
failed checks return bounded repair feedback. Limits are 64 checks, 2 MiB per
file and 32 MiB total artifact bytes. Paths must be regular workspace files,
without traversal, symlinks or hardlinks. Keep specifications containing private
expectations outside the model's workspace.

Corrections, answers and human wake messages can change requirements. They prevent
old predicates from automatically accepting revised work; passing checks then
require explicit confirmation. Mechanical scheduled wakes do not change this
scope. The initial ACP prompt for a ready attached goal is also a user correction;
it therefore requires confirmation after passing checks. CLI supervision does
not insert an initial correction. Immutable acceptance receipts retain the candidate identity. Stale
confirmations and changed reports/artifacts are rejected.

Amendments do not rewrite configured predicates or budgets. If changed requirements
conflict with an old exact predicate, explicit acceptance cannot override that
failure. Create a goal with the revised contract and explicitly cancel the old
one; Spine does not infer a new machine-checkable predicate from free text.

Explicit `{"mode":"model_declared"}` preserves the legacy declaration-only
behavior, terminating at `model_completed`. Legacy records keep their policy and
finite limits. Model evidence references, summaries and diagnoses remain labeled
declarations, not independent proof of every natural-language requirement.

## ACP integration

Initialization advertises `com.spine.goals`. `_spine/goal` is a Spine extension
to ACP v1, not a standard ACP goal protocol. Requests use `sessionId` and a strict
`operation` object:

```json
{
  "sessionId": "SESSION_ID",
  "operation": {
    "op": "create",
    "goal": {
      "cwd": "/absolute/workspace",
      "objective": "Prepare the supplier comparison."
    }
  }
}
```

The returned goal matches CLI `show`. Attach with
`{"op":"attach","goalId":"GOAL_ID"}`. A normal session prompt then supervises
successive periods and waits, keeping its request pending. A prompt for a ready
goal is retained as a correction; for a waiting goal it starts supervision without
inventing an answer. Typed operations can resolve the dependency while that prompt
is pending. Load/attach start no work. `SPINE_GOAL_DRIVE=until_wait` enables the
external-scheduler behavior.

| Operation | Fields |
| --- | --- |
| `show`, `attach` | `goalId` |
| `detach` | None; idle session only |
| `amend` | `goalId`, `expectedRevision`, `message` |
| `answer` | `goalId`, `expectedRevision`, `questionId`, `answer` |
| `accept` | `goalId`, `expectedRevision`, `candidateId` |
| `wake` | `goalId`, `expectedRevision`, `eventId`, `message` |
| `cancel` | `goalId`, `expectedRevision`, `reason` |

An explicit matching event wakes a wait. `eventId: null` requires a recorded
scheduled time that has arrived according to the host clock. Client permissions,
tools, session cancellation and `_spine/steer` remain in use. Attached-goal
steering is persisted before acknowledgment. CLI and ACP share storage, revisions
and accounting; an OS lock prevents concurrent supervisors for one goal.

`session/cancel` ends supervision or the active period without implicitly
cancelling the stored goal. Use goal `cancel` for that. An idle goal can be watched
by a later prompt, with no model call until its dependency resolves. Work periods
and goal-input updates have separate bounded journals, so a long prompt does not
accumulate an unlimited in-memory transcript or inherit an ordinary turn's total
steering-message cap. The per-message input limit remains.

Generic editor clients need UI support for these extensions; use the CLI for
goal control until then. See [editors](EDITORS.md) and [ACP](ACP.md).

## Recovery and retained context

Records live outside the workspace under `$XDG_STATE_HOME/spine/goals`, normally
`~/.local/state/spine/goals`. Reports retain paths, hashes and accounting. Exact
older periods and user input remain in immutable hash-bound archives; only recent
records and bounded indexes remain in the active view. The hot input window holds
at most eight entries and 128 KiB serialized; unusually escaped input can use
fewer entries. Current work receives the
original requirements, recent input, history locators and latest progress with
remaining obligations. An archive locator is not a semantic summary of old input.

The scoped `goal_history` tool retrieves exact settled progress, user input and
safe work-slice checkpoints in UTF-8 pages:

```json
{"index": 0, "record": "progress", "max_bytes": 4096}
```

```json
{"index": 0, "record": "user_input", "input_kind": "correction", "max_bytes": 4096}
```

```json
{"index": 0, "record": "execution", "max_bytes": 4096}
```

`progress` is the default. For user input, `index` is the zero-based global
input index, or the ordinal within the optional `input_kind`. Execution records
contain observed public work and explicitly unexecuted pending actions; a
`prior_continuation` locator preserves the chain to earlier slices. Follow
`next_offset` to read later pages. The page request defaults to 4,096 bytes and
permits at most 8,192, within the 16 KiB encoded output bound.

It costs one ordinary tool unit, obeys ancestor restrictions and must appear in
an explicit `allowed_tools` list. Reads verify report identity, hashes and settled
accounting. Pages are capped at 16 KiB including JSON escaping. Arbitrary paths,
other goals and private reports are inaccessible. External MCP names are
namespaced and cannot impersonate the internal tool.

New acceptance-based goals may continue after a typed limit reached between
completed steps, or an accounted pre-dispatch request-limit refusal that can fit
a fresh period. The host first verifies closed resources, exact checkpoint and
accounting, then replans from the retained observations under the same goal
account. It never resumes a failed task stack with reset limits. Required history
retrieval must remain permitted and affordable. Repeated identical public work
asks for direction instead of spinning.

Generic provider errors, malformed returns and unmarked tool/task/depth failures
are not silently classified as safe work slices. They remain explicit blockers;
in-flight uncertain effects retain their ownership fence. Explicit legacy
`model_declared` execution preserves its original limit behavior.

A missing report, uncertain action, damaged accounting or failed cleanup keeps
the active period and reservation fenced. Restart or elapsed time does not grant
retry permission. There is no recovery command that simply clears that fence;
reconciliation requires evidence of what happened. The supervisor reports the
attention state and awaits resolution instead of marking success.

### Explicitly supersede a retained execution (0.3 development)

An unfinished recursive execution can be archived explicitly when its retained
tree needs replacement. This admits an already-settled source or an active
period with verified closed resources and unchanged original ownership. The
native consumer profile supports this path; live or uncertain periods reject.

```sh
# Prepare exact source hashes, size, current input head and read allowance.
spine goal rebase-plan GOAL_ID > /outside/workspace/rebase.json
# Review that payload; use the current goal revision.
spine goal rebase GOAL_ID REVISION /outside/workspace/rebase.json
spine goal run GOAL_ID
```

`max_state_bytes` is an explicit one-time read allowance in that request, not a
new default state limit or a lifetime budget. The objective, acceptance rules,
accepted input and spent allowance remain unchanged. The old tree, candidate,
question and observed effects are archived as `superseded_unfinished`; none is
accepted or automatically replayed. The replacement root consumes ordinary
remaining task allowance. A repeated identical committed request is idempotent.

For a closed active source, recovery settles its previously uncommitted observed
consumption exactly once. Its closure receipt must bind the original Unix lock
and directory identities; copied/imported directories or legacy receipts cannot
authorize this path. The ordinary state reader stays limited to 32 MiB, while
the explicit recovery may read the exact larger state approved in the request.
Reports and journals keep their existing bounds. Missing state, uncertain effects
or incomplete cleanup remain fenced. See the [closed-active recovery controls (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/proofs/2026-11-17-closed-active-recovery/README.md).

The captured `goal_history` schema then additionally offers:

```json
{"record":"execution_archive","index":0,"view":"obligations","page":0,"max_bytes":4096}
```

Follow its exact frame/section locators for candidate output or individual
observations, `next_offset` within a page and `next_page` between archive pages.
`view=full` retains the complete public projection. Retrieval verifies the
captured hash roots and uses bounded index/page reads; it does not make old
checks fresh. These fields are absent from ordinary goals without an archive.
See the [scoped qualification (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/proofs/2026-11-17-execution-supersession/README.md).

After three settled periods with identical declared progress, no tool/child work
and unchanged input, the host asks what should change. It records `blocked` while
supervision remains pending; an explicit amendment can continue under the same
limits. This detects exact repetition without observed action. Changed wording
or tool activity does not itself prove progress. Repeated rejected completion
without action is also subject to this safeguard.

For optional graph/timeline diagnostics, use `SPINE_TRACE=1 spine goal run ID`
and `spine trace REPORT.trace.jsonl --html review.html`. Each period gets its own
trace. Details and coverage limits are in [tracing](TRACING.md). Scripted lifecycle
controls do not prove week-scale model competence or superiority over other agents.

One [real Kimi goal qualification (private source)](https://github.com/noxstellar/spine/blob/20b4fc38c71ef78ad087e34c37c86d0545dbada8/rust/proofs/2026-11-16-kimi-goal-live/README.md)
passes three explicitly instructed work periods, a question wait with zero model
calls, automatic resumption after the answer and independently accepted artifacts.
It used 10 requests and 57.485 seconds. This small lifecycle observation does not
establish long-term reliability or comparison with another harness.
