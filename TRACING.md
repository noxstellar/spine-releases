# Optional execution traces — unreleased 0.3

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

Use a compact trace to review how a run decomposed its task, which tools it
called, what returned, and where it stopped. This is implemented in development
source; the published v0.2.1 package does not include it.

Tracing is **off by default**. It adds no model calls, dependencies, background
service or network exporter. The viewer works offline without a configured
provider, API key or worker.

## Record and review

With a development build and configured provider:

```sh
SPINE_TRACE=1 spine run /path/to/workspace 'Review the supplied research sources'
```

The launcher prints `Run reports: /path/to/run-directory`. Use that path:

```sh
spine trace /path/to/run-directory/report.json.trace.jsonl
spine trace /path/to/run-directory/report.json.trace.jsonl --html review.html
```

The terminal view contains a task tree and ordered timeline. The standalone HTML
contains a task tree and expandable event details, elapsed times, cumulative
work/request usage and the final status. Open `review.html` in a browser; it uses
no JavaScript, external assets or network requests. Output files are private and
are never overwritten: choose a fresh filename for each export.

For bounded previews of the public task and tool content:

```sh
SPINE_TRACE=details spine run /path/to/workspace 'Review the supplied research sources'
```

| Setting | Recorded content |
| --- | --- |
| Unset, `0` or `off` | No optional trace file or trace projection. |
| `1` or `summary` | Task IDs and parent relationships, delegation, candidate IDs and consumer dispositions, charged tool names, observed result/error flags, steering revisions, public-message lengths, work counters, step durations, request usage and stop status. No prompt, tool argument/result, message or error-text content. |
| `details` | Summary plus bounded previews of goals, requirements, tool arguments/results, public messages, decision errors and child/root returns. |

An invalid setting rejects execution before dispatch. The raw CLI writes
`REPORT_FILE.trace.jsonl` alongside its report, outside the model workspace.
The existing recovery checkpoints, full state `.steps.jsonl` files and request
journals remain unchanged; turning this diagnostic off does not disable them.

## ACP sessions and durable goals

Set `SPINE_TRACE=1` or `details` in the environment of `spine acp` to record each
execution beside its private run report. This produces local files and does not
add unsolicited messages to ACP stdout. The same setting works with
`spine goal run GOAL_ID`; each work period has its own trace. Use the period's
`report_path` from `spine goal show GOAL_ID` and append `.trace.jsonl`.

A trace covers **one invocation or goal work period**, not the entire session
or lifetime of a durable goal. Resume records label pre-existing observations
as historical; their elapsed times describe this recorder, not the old run.

## Read the evidence correctly

The graph shows runtime parent/child relationships. `tool_called` is a charged
ToolPort invocation; permission checks can still deny the operation. A
`tool_result` records an observed return and its error flag. It does not establish
that an inner shell command, external effect or overall task succeeded.

Task `returned` and `model_completed` statuses are model declarations. Use the
task's acceptance checks and retained artifacts to judge correctness. Cleanup
failures, incomplete coverage and model-reported goal outcomes are displayed
separately. Timing is measured at step boundaries, not inferred as individual
model/tool latency. Missing provider token usage is not zero cost.

With experimental consumer assessment enabled, the graph distinguishes
`awaiting review`, `awaiting input`, `repair requested`, `steering invalidated review` and
`reviewed input`. These labels come from typed runtime transitions, not text
parsed from a model's answer. `reviewed input` means the parent accepted that
candidate for its own work; it is not independent task acceptance. Candidate IDs
identify returns within one run. Detailed mode can show the accompanying bounded
public feedback; neither mode records private reasoning.

Pending artifact inspection appears as an ordinary charged tool operation while
the child stays `awaiting review`. The tool result does not change that label or
create a verified-completion receipt. Only a later typed assessment settles the
candidate; inspection, repair and acceptance remain distinct steps.

The recorder emits `step_started` before entering a runtime step; this is not
proof that a provider request or tool action has already been dispatched. Other
records are appended at observed step boundaries. A live read shows the complete
rows available so far. A missing footer, unfinished final row, projection
omission or cap is explicitly marked incomplete. A crash can leave work
unrecorded; the trace is not a recovery journal or an exactly-once effect ledger.
The footer describes execution and cleanup before the final report is published.
Its `report_publication: not_confirmed` field is intentional: inspect the report
and CLI result to confirm publication and the full invocation outcome.

## Small, bounded and private

Each trace is capped at 8 MiB and 10,000 ordinary records, with room reserved for
a truncation marker and final summary. Rows are limited to 16 KiB. Detail previews
are limited to 2,048 UTF-8 bytes with explicit truncation markers. State projection
is capped at 32 MiB. Once the trace cap is reached, execution continues and the
final counters/status are retained when writing remains possible.

Files use private permissions (`0600` on Unix) and exclusive creation. A trace
creation/write failure never cancels or retries task work. The execution report's
`optional_trace` field records the path, bounds outcome and any logging impairment;
`finalized` distinguishes a written footer from `complete` diagnostic coverage.
The viewer rejects malformed complete rows and unsafe input files. It escapes
terminal controls and HTML content. JSONL rows use format version `1`, a sequential
`seq`, `elapsed_ms`, `kind`, optional `task_id`/`parent_id`, and structured `data`.

Summary mode omits content. Details mode redacts sensitive structured field names
such as authorization, credentials and private reasoning fields, but **cannot
detect arbitrary secrets embedded in prose or source**. Treat detailed traces
like task data. The recorder never reads raw provider bodies, headers or private
reasoning. No tracing mode exposes these files as model tools.

See [the local verification record (private source)](https://github.com/noxstellar/spine/blob/98957d414fcb6c6060bcfe3045b5c364d4b39983/rust/proofs/2026-11-16-execution-tracing/README.md)
for checks and scope. These diagnostics help investigate behavior; they do not
by themselves establish improved model quality or peer parity.
