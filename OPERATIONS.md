# Headless host operations

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

Spine **0.2.1** is the current public release. Start with the
[installer and provider setup](README.md) and [ACP integration guide](ACP.md).
This advanced reference also describes optional and historical execution profiles;
their availability does not imply new task-competence qualification. Current
results and limits are recorded in [STATUS.md (private source)](https://github.com/noxstellar/spine/blob/c23950e94493efc04894482653add85a66301de1/rust/STATUS.md) and the
[version history (private source)](https://github.com/noxstellar/spine/blob/c23950e94493efc04894482653add85a66301de1/CHANGELOG.md).

## Install and run

The published package includes ACP and project memory. Use `spine setup`, then
`spine run WORKSPACE 'GOAL'`, or configure your client to launch `spine acp`.
AUTO is the default; `--mode direct|auto|recursive` overrides it. For integrations
providing their own ACP/MCP tools, `spine setup --tools external` skips Docker.
`spine memory init WORKSPACE`, `spine memory refresh WORKSPACE` and
`spine memory search WORKSPACE 'QUERY'` need neither a provider nor Docker.

A matching source build uses
`cargo build --locked --release --features acp,embedded-rag --bin spine` with Rust
1.89 or newer. `--features host` builds the smaller host without ACP or embedded
memory. The direct core executable reads environment settings; the installed
launcher additionally loads the private setup profile.

Native tools need Docker and the pinned Rust/Python worker, prepared by setup.
See [worker setup (private source)](https://github.com/noxstellar/spine/blob/c23950e94493efc04894482653add85a66301de1/rust/containers/README.md). Actual native isolation controls cover
macOS ARM with Colima and Linux ARM workers; passing CI on Linux does not publish
a Linux package or qualify every Docker environment. External MCP/client tools
have their own execution boundary. The following examples use the advanced
four-argument core interface and require explicit provider/tool settings.

Give each run a fresh report filename outside its selected workspace:

```sh
export SPINE_MODEL_ENDPOINT=http://127.0.0.1:11434/v1/chat/completions
export SPINE_MODEL=kimi-k3.1-pro:cloud
export SPINE_REASONING_EFFORT=high
export SPINE_MODEL_HISTORY=snapshot
export SPINE_SNAPSHOT_RECENT_OBSERVATIONS=6
export SPINE_STABLE_NATIVE_TOOL_NAMES=1
export SPINE_BUDGETED_SNAPSHOT_WINDOW=1
export SPINE_MAX_STEPS=32
export SPINE_MAX_TOOLS=64
export SPINE_MAX_OUTPUT_TOKENS=8192
export SPINE_REQUEST_LIMITS='{"max_requests":32,"max_request_bytes":400000,"max_total_request_bytes":3000000,"max_total_output_tokens":262144}'
# The signed-in Ollama gateway handles authentication.
export SPINE_DOCKER_CONTEXT=colima-spine-production
export SPINE_TOOL_IMAGE=sha256:YOUR_VERIFIED_LOCAL_IMAGE_ID
export SPINE_TOOL_MEMORY_MIB=2048
env -u SPINE_API_KEY spine /absolute/workspace /path/to/task.txt /path/to/reports/run.json auto
```

A `.json` task file is decoded as the SDK's `Task`; other filenames contain a
plain goal. Modes are `direct`, `auto` and `recursive`. AUTO may choose direct
work; recursive mode starts a coordinator. All model context comes from explicit
task/state/context inputs. Unreleased 0.3 development reuses one HTTP connection
pool across fresh stateless adapters; published v0.2.1 creates a new client each
step. New reports record `fresh_model_client_each_step: false`,
`fresh_model_adapter_each_step: true` and `model_connection_pool: shared_per_invocation`.
No private reasoning is requested as durable state. This basic invocation uses the default
AUTO policy; specialized direct-test workflow and native checks require their
explicit configuration below. A model-declared completion is not independent
acceptance. Review the patch and run your project checks before merging.

### OpenAI Responses configuration

The standalone host also supports the stateless Responses API. With Docker set
up as above and `SPINE_API_KEY` provisioned in the host environment, select the
API format explicitly. Use a fresh report and explicit limits:

```sh
export SPINE_MODEL_API=responses
export SPINE_MODEL_ENDPOINT=https://api.openai.com/v1/responses
export SPINE_MODEL=gpt-6.1-sol
export SPINE_REASONING_EFFORT=high
export SPINE_DECISION_FORMAT=native
export SPINE_MODEL_HISTORY=snapshot
export SPINE_SNAPSHOT_TRANSPORT=state
export SPINE_MAX_STEPS=32
export SPINE_MAX_TOOLS=64
export SPINE_MAX_OUTPUT_TOKENS=8192
export SPINE_RUN_TIMEOUT_SECS=900
export SPINE_REQUEST_LIMITS='{"max_requests":32,"max_request_bytes":400000,"max_total_request_bytes":3000000,"max_total_output_tokens":262144}'
spine /absolute/workspace /path/to/task.txt /path/to/reports/run.json direct
```

Requests use `store=false`; the adapter retains public responses and tool outcomes,
and excludes provider-private reasoning and continuation identifiers. The API
format is part of the saved profile and must remain unchanged on eligible resume.
The matched comparison uses a separate common gateway and isolated tool bridge;
its task results retain that exact profile scope.

`SPINE_MODEL_HISTORY=replay` is the compatibility default. Opt-in `snapshot`
sends one system/user turn with exact public observations and the latest state;
it does not replay prior provider assistant/tool turns. This accommodates
providers whose multi-turn reasoning contract requires private fields that Spine
does not retain. SDK callers select it with `with_public_state_snapshot()`.
With snapshot history, `SPINE_SNAPSHOT_RECENT_OBSERVATIONS` optionally retains
only the latest positive number of complete observations, plus every child
result, blocked-child result and known failed tool outcome. Batches containing
any failed outcome remain complete in other workflows. In opt-in DirectTests, old
large failed arguments/outputs instead use labelled UTF8 excerpts with hashes and
original byte counts; successful sibling outputs are explicitly omitted. Failure
flags, tool names and original indices/member order remain. Recent and child
outcomes remain exact. Other older entries become explicit omission markers
at their original observation indices. The SDK equivalent is
`with_snapshot_observation_window(recent)`. Unset preserves the full snapshot;
zero, invalid integers and use with replay history fail before execution.
This loses historical content in model inputs. It never removes durable state,
changes current receipt validity, or permits replaying an earlier effect. Re-read
current owned artifacts if omitted information is needed. Large retained values
can still exceed request bounds. The setting is recorded in reports and account
identity; changing it is not a budget reset or permission to resume a failed trial.
`SPINE_RATE_LIMIT_RECOVERY=1` optionally turns HTTP 429 into public decision-error
feedback after a cooldown. The SDK equivalent is `with_rate_limit_recovery()`.
It never silently resends HTTP; a subsequent decision consumes another step and
request reservation under the same budgets. Absent Retry-After waits five
seconds; integer delays of 0–60 seconds wait at least one second. Unsupported
dates, malformed or longer delays remain fatal. The active run deadline cancels
the wait. Oversized/malformed bodies and other fatal statuses retain their
behavior. Default `0` keeps fail-fast 429 handling. Neither setting permits a
closed failed run to resume or resets a reservation.

The selected history/recovery modes are bound into request-account identity and terminal reports;
switching it does not authorize resume with a fresh budget. Qualification of a
snapshot profile does not qualify replay or other model/settings combinations.

For structured task input, supply `goal`, optional `query`, and the explicit
`requirements` list. Requirements are public task data retained in current state;
this interface does not infer requirements or verify their semantic fulfillment.
A caller-supplied receipt policy must classify every potentially mutating tool,
including Python executors; unclassified mutations can leave old receipts
apparently current. Evaluation profiles that enable receipt checking bind their
classification, such as `evaluation/workspace_policy.py`, in the frozen plan.
With ACP integration, the host conservatively treats every non-`workspace.*`
operation as an effect except the immutable `session.history` reader. Client or
external MCP calls therefore invalidate older native check passes; completion
that requires a native check must obtain a fresh passing receipt afterward.

`SPINE_VALIDATION_GUIDANCE=1` (SDK `with_validation_guidance()`) adds generic
change-task guidance for specification-derived boundary/interaction regressions
and exact configured check metadata. Default is `0`. This is model guidance,
not a semantic verifier or an additional model judge. The flag is bound into
request-account identity and terminal reports; qualification is profile-specific.

Explicit environment settings override defaults. The core reads environment
settings; the installed launcher also loads its private setup profile. There is
no implicit cloud fallback. Role overrides are opt-in; qualification leaves
them unset. The standalone tool host defaults to Docker. `SPINE_TOOL_HOST=local`
explicitly selects trusted host tools and is outside the unattended isolation
profile. The reference `live` example retains its local default.

## Caller-protected files

`SPINE_TOOL_SERVER` optionally selects a caller-owned, self-contained Python MCP
server outside the model workspace. The host pins its actual bytes, reports the
SHA-256, and binds that identity into metered resume. The file must be regular,
at most 1 MiB, without symlink or hard-link aliases. Changing it cannot silently
resume a run under different tool behavior. Unset uses the built-in pinned server.

Set `SPINE_PROTECTED_PATHS` to a JSON array of existing workspace-relative file
paths when a task must preserve supplied specifications, tests or fixtures.
The Docker host mounts each file read-only and anchors its parent directories
against rename. Protected files remain readable; new sibling files, including
new regression tests, can still be created. These restrictions cover MCP tools
and subprocesses. The operator and Docker service remain trusted.

The policy accepts up to 64 regular files and 8,192 total path bytes, with at most
512 bytes per path and 192 derived mounts. Traversal, symlinks, existing hard-link
aliases and duplicate paths are refused. Local tool mode refuses a nonempty
policy because it cannot provide this OS boundary. Paths and content hashes are
bound into request-account identity and recorded in the tool-host report.
Changing protected content or policy cannot silently resume an old metered run.
Unset preserves ordinary writable-workspace behavior. Callers choose the policy;
the host does not infer it from model prose.

## Native source change review

The standalone host provides two native read-only tools without Git.
`workspace.changes` lists added, modified and deleted UTF-8 source paths and
hashes; its output explicitly contains no patch content. `max_files` and `after`
page that metadata. It returns a suggested `workspace.diff` call for a changed
path. `workspace.diff` requires `path` and returns actual unified diff lines
against the original source; `start_line` and `max_lines` page that content.
Wrong-mode controls fail instead of being silently ignored. Neither listing
metadata nor reading a patch establishes correctness or runs checks.

Continuation requires the returned `revision` as `expected_revision`, so source
changes cannot silently mix pages. Responses are bounded to32KiB serialized
structured data, default16KiB; oversized lines or computation bounds return
explicit errors. Inspect every relevant changed production/test file, following
`truncated`/`next_line` until the requested patch is complete.

The source view reuses the capability-relative reader: 2 MiB per text file,
32 MiB total, 4,096 files and 16,384 visited entries. Generated directories,
symlinks, binary/non-UTF-8 files and `.spine` are outside this view. It reports
content changes, not all filesystem metadata. The tool is read-only and does
not establish correctness or run checks. Tool calls consume ordinary budgets.

Set `SPINE_WORKSPACE_CHANGES=1` to enable explicitly or `0` to disable. The
reference `live` example and empty context default off. One private, checksummed
`REPORT_FILE.workspace-baseline.json` artifact is stored outside the workspace,
atomically with owner-only permissions. Retain it with reports and journals.
Eligible resume reuses that original artifact; it never re-baselines modified
files or copies a baseline on every checkpoint. Missing/corrupt artifacts or
changed review configuration refuse continuation. A custom MCP server must not
advertise either reserved native name while review is enabled. Native tool
protocol2 is recorded in the baseline reference and binds metered identity.
An old/unversioned protocol refuses resume before HTTP; there is no automatic
migration or budget reset. Preserve its original executable/evidence.

Receipt claims and observed validation have separate scopes. A check declared
effectful conservatively makes earlier receipts stale, including within a batch.
Claim current receipts from the advertised evidence view; the evaluation still
independently requires every original public validation after the last noncheck
effect. Native change review is read-only and preserves those validations. It
does not make an older stale receipt current.

## Budget-aware action menus

`SPINE_BUDGET_AWARE_ACTIONS=1` enables menus based on the shared remaining tool,
child and depth capacity. The standalone host enables this by default; the
reference live example and SDK preserve their legacy default. SDK callers opt in
with `with_budget_aware_actions()`.

Exhausted MCP tools and unavailable child controls are omitted. Structured batch
and algorithm schemas expose remaining item limits; native parallel calls are
disabled at one remaining tool. Oversized tool proposals become public decision
errors before dispatch. They consume a model decision and request reservation;
no tools run, no quotas grow, and no reservation is refunded. Numeric runtime
limits and unsettled-action safeguards remain unchanged. At zero tool quota,
owned results can support completion or a specific blocked/incomplete report.

The enabled mode binds metered identity and is reported as
`budget_aware_actions`. Changing it refuses eligible resume before HTTP. Use explicit `0` to retain the legacy interface for a new run or an eligible
resume with that same executable and mode. Executable identity is also pinned;
an older run requires its original binary. There is no silent migration. Closed qualification failures must never be resumed or retried.

## Opt-in producer handoff

Set `SPINE_AUTO_WORKFLOW=producer_handoff` for AUTO production tasks with explicit
public check configuration. Default `agent` retains existing behavior; DIRECT and
recursive modes keep their existing policies. SDK callers use
`with_producer_handoff()` with receipt verification. Missing check configuration
is rejected before request accounting or worker startup.

The initial root delegates production using the existing scoped child/work-record
interface. The returning caller finishes remaining tests/repairs and executes its
own configured public check. Root completion is not offered until a current passed
local tool/batch receipt exists after the latest child outcome. Child prose or
receipts, failed/stale checks and earlier checks cannot satisfy this ownership
requirement. Explicit `caller_validation` metadata reports these mechanical facts.
State and receipt witnesses survive the usual eligible same-executable resume;
there is no hidden model session or automatic retry. Planning policy binds identity.

The workflow has one production child followed by direct caller work; descendants
and the returning caller cannot delegate again. This is an opt-in policy over the
existing runtime, not a global restriction on other Agent policies. The standalone
host reserves min(8, max_tools/3) tools and min(6, max_steps/4) decisions for the
caller. Descendants see only their callable tool allowance; over-budget proposals
are rejected before dispatch. At the decision boundary the child returns blocked
without a model request, preserving unfinished work rather than claiming success.
SDK callers can choose reserves with `with_producer_handoff_reserve(tools, decisions)`;
`with_producer_handoff()` defaults to 8/6. Recreate the same settings on resume.
With metered requests, children also leave a quarter of the original total byte
and output capacity, plus a bounded caller request count, before a send would
consume that share. This is remaining-capacity preservation, not a promise that
arbitrary caller work fits. All existing limits, consumed charges and hard guards
remain in force. `producer_capacity` is a fresh public view; the host report records
the selected reserves. The binary and original run limits already bind resume.

The caller performs actual production work; it is not an additional semantic
judge. A passed receipt still proves only its recorded check outcome. Independent
Task acceptance remains necessary. All actors share the original run/request/tool
limits. Progress logs display newly emitted execution events and cumulative
decision errors, so a rejected decision cannot repeat an old completion event.

## Opt-in test-first handoff

For coding tasks that request regression tests, select
`SPINE_AUTO_WORKFLOW=test_first_handoff`. The caller first inspects the public
specification/interfaces, authors tests and runs configured checks against the
production baseline. Delegation is absent until a current failed caller-owned
configured check is observed. Passing/stale checks, absent verification and prose
cannot enable it. The public `test_preparation` marker explicitly reports that
semantic test quality is unverified: a failed check might be a test-construction,
compilation or environmental error. Repair those rather than treating them as
behavioral evidence. Independent acceptance must inspect actual tests and behavior.

One child then implements and the caller inspects/repairs and performs its own
current public check after that child. The same caller reserves, single-handoff
rule, cumulative accounting and identity-bound resume apply. No extra model judge,
semantic success inference or global budget growth is introduced. Missing checks
fail before accounting/worker startup. SDK builders are `with_test_first_handoff()`
and `with_test_first_handoff_reserve(tools, decisions)`. Other workflows are
unchanged; use the same builder settings when reconstructing an eligible client.

## Native public-check action

Optionally set `SPINE_PUBLIC_CHECK_SET` to a JSON object with a `preparation`
ToolCall array. An empty object enables the existing configured checks without
preparation. For a Rust project, explicit preparation can be:

```json
{"preparation":[{"name":"workspace.run","arguments":{"argv":["cargo","fmt"],"timeout_seconds":120}}]}
```

The checks come from `SPINE_VERIFICATION_POLICY`; the model cannot supply commands
to `workspace.validate`, whose arguments are exactly `{}`. The action runs the
fixed preparation followed by every configured public check. Preparation is
optional caller configuration, may modify files, and is never inferred from a
check's command text. Configuration requires 1–16 checks, at most 4 preparation
calls, at most 8192 serialized bytes, and the native `workspace.run` output contract
with explicit timeouts of 1–120 seconds. Invalid configuration fails before accounting
or worker startup; a custom native-name collision fails before model dispatch.

Every underlying operation consumes a tool budget unit. The runtime checks the
whole action/batch cost before any dispatch, charges the aggregate before its
first operation, and retains uncertain charges without refunds or replay. Ordinary
SDK tools still cost one unit through the default `Tools::budget_cost`; compound ports
must declare stable positive costs and retain the same configuration on resume.
The adapter omits an unaffordable native action and rejects overweight proposals
before effects. The original global quota is not expanded by grouping operations.

Known error outcomes do not skip later configured operations. A transport failure
or remaining-run deadline stops the group conservatively; eligible recovery may
not replay an unsettled group. One aggregate receipt passes only when every
operation reports an observed exit0 without error. It establishes owned outcomes,
not semantic Task correctness. Existing raw checks remain valid; when the native
action is in scope, the adapter advertises that action once to avoid redundant
receipt-refresh loops. A child granted only `workspace.validate` gets the fixed
caller capability, without arbitrary executor arguments.

The report records the complete configuration and charged cost. Same-executable
resume binds it through the metered execution profile. Each member result keeps
its canonical call, exit/error status, bounded UTF-8 diagnostic head/tail and a
hash of the original output. Omission is explicit; it does not establish success.
The aggregate output is bounded to 192 KiB. Independent qualification still runs
original acceptance externally and reconciles actual charged units with the
attested native members. This option is off by default.

## Bounds and results

Default runtime limits are 64 decisions, 48 tools and 600 seconds; direct has one
task/depth zero, other modes default to 16 tasks/depth four. AUTO and recursive
accept `SPINE_MAX_TASKS` from 1–1024 and `SPINE_MAX_DEPTH` from 1–64; direct keeps
its fixed task/depth limits. Set `SPINE_MAX_STEPS`,
`SPINE_MAX_TOOLS` and `SPINE_RUN_TIMEOUT_SECS` explicitly for reproducible runs.
The standalone request account defaults to 32 requests, 1 MiB per serialized
request, 8 MiB cumulative request bytes and 131,072 maximum-output reservations.
`SPINE_REQUEST_LIMITS` must supply all four fields. These are submitted-work
bounds, not exact input-token or currency budgets. Failed/uncertain dispatches
consume reservations. Provider usage is recorded when available.
The standalone default account also applies when explicitly selecting local
tools. Changing `SPINE_TOOL_HOST` does not disable it. At 8,192 maximum output
tokens per request, the default 131,072 reservation allows at most 16 calls;
set all four request limits explicitly when a different bound is intended.

Provider responses are capped at 1 MiB by default (`SPINE_MAX_RESPONSE_BYTES`).
The pinned workspace server caps a complete MCP response at 1 MiB and returns an
explicit error without partial data. The host's MCP transport independently
discards incoming stdio frames exceeding the pinned SDK's 16 MiB limit, including
frames emitted directly by a faulty worker.
Workspace command stdout/stderr share a 64 KiB raw-byte limit; overflow terminates
the command and reports an explicit incomplete prefix. Source loading limits are
2 MiB per text file, 32 MiB total bytes, 4,096 text files and 16,384 entries, with
additional bounded index sizes. Oversized inputs fail explicitly. These bounds
do not promise support for arbitrary repositories or a fixed process RSS.

Reports distinguish model completion, optional receipt consistency and errors.
Receipt checking validates declared observed checks; independently verify the
task's actual contract before treating it as accepted. Process success alone
does not establish task correctness. Inspect shutdown/cleanup errors as failures.

Artifacts alongside `REPORT` include public state traces, atomic checkpoints,
append-only request reservations and a pre-create container ownership descriptor.
Protect them as host state: they can contain source and task observations, even
though the host API key and provider-private reasoning fields are excluded. Do
not expose them to workers. The selected workspace defines provider-visible data;
the host does not detect arbitrary secrets embedded in source or task text.

For unreleased [native adaptive goals](GOALS.md#adaptive-verification-03-development),
the private report includes `adaptive_review_dispatch` and
`adaptive_review_validation`. The first binds review claims to owned period work;
the second aggregates metadata-only reference checks, local content reads, bytes
and time. Reference checks never issue an inspection receipt. Provider usage stays
in the common request account. A claim can precede an account refusal without an
HTTP call; neither a claim nor model support is goal acceptance. Preserve these
records and the original sender/profile when restarting; do not clear history to
retry unchanged work.

The experimental `SPINE_PROVIDER_FAILURE_MODE=suspend` setting adds a typed
`provider_failure` field to an error report for HTTP 500/502/503/504. Its fixed
status identifies a failed service response; it does not diagnose the underlying
provider problem. Requests and any reported usage stay charged, and absent usage
stays unknown. Safely closed consumer/adaptive goals retain their unfinished
state with provider-specific attention. See [provider failures](GOALS.md#provider-failures-03-development)
for the current explicit recovery boundary. Default `repair` behavior is unchanged.

## Stop, recover and upgrade

Unreleased 0.3 adds [optional diagnostic tracing](TRACING.md). Set `SPINE_TRACE=1`
for compact metadata or `details` for bounded public content; review
`REPORT.trace.jsonl` with `spine trace FILE [--html OUTPUT]`. Trace failures do
not cancel work, and missing/truncated coverage is explicit. Existing recovery
artifacts remain authoritative for their original purpose.

Interrupt the host to stop work. Active Docker workers exit on input EOF or lease
expiry and are automatically removed; cleanup also addresses detached processes.
For interruption during container creation, follow the exact-name ownership
recovery procedure in the worker runbook. Never kill unrelated containers or
delete a shared compiler cache while another worker holds it.

`SPINE_RESUME_FAILURE_REPORT` accepts only eligible closed failures from the same
binary, task, workspace, model/tool profile and original runtime/request limits.
Use a new output report path. Omitted request settings inherit the saved account;
they do not create a fresh budget. Corrupt/partial journals, stale usage, unhealthy
accounts and uncertain tool work refuse continuation. Never edit counters,
delete journals to restart an evaluated failure, or replay an uncertain effect.
The host does not promise exactly-once external effects.

Preserve a release's executable, image, hashes and reports together. An upgraded
binary intentionally changes resume identity; no automatic migration of old
metered failures is promised. Retain the prior artifact to inspect its original
evidence. Future releases and expanded task-reliability claims require evidence
for their intended scope; a successful infrastructure smoke is insufficient.

## Opt-in staged productive handoff

`SPINE_AUTO_WORKFLOW=staged_handoff` separates regression authoring and
implementation into two scoped productive children. The caller delegates test
artifacts first, inspects them and runs its own public baseline check. Only a
current failed owned check after the author returns enables implementation.
After that child, the caller directly inspects, repairs and executes its own
current passing check before completion. Descendants cannot delegate. Neither
failed checks nor structural child records establish semantic acceptance.

SDK builders are `with_staged_handoff()` and
`with_staged_handoff_reserve(tools, decisions)`. Existing global limits still
apply. The author also preserves two configured check costs plus three tool units
and four decisions for intervening production work. These are lower-bound
allocations, not extra quota or a promise of completion. Native check operations
retain their full weighted cost. Stage roles are explicit goal prefixes, derived
again from owned state when a client is reconstructed.

A forced producer budget return may carry a bounded historical diagnostic from
the latest owned caller-advertised public check. Arbitrary private tool history
and reasoning are excluded. The capsule identifies omissions and its original
child receipt; it never creates a caller receipt. Full child observations remain
in the durable trace. Returning callers must execute fresh checks themselves.

When staged handoff and the native public-check set are both enabled, a scoped
productive assignment must retain `workspace.validate`. Omission is rejected
before creating a child; scopes are never silently expanded. Returning producer
callers reserve the full native check cost inside their remaining quota. A
noncheck batch must preserve that affordability, or end with the configured check.
Trailing operations after a check must leave capacity for another check. At the
reserve boundary only validation remains callable. A raw partial check cannot
unlock completion in place of the configured aggregate. Failure still requires a
truthful block when no repair/check capacity remains; this is no success oracle.

## Productive tests after implementation

`SPINE_AUTO_WORKFLOW=implementation_test_handoff` delegates implementation first,
then executable regression authoring against actual changed source and public
requirements. The test author writes real artifacts and reports actual failures;
it supplies no semantic acceptance verdict. It must preserve production code and
existing tests. The caller owns repair and a current aggregate check after both
children. This order deliberately has no preimplementation red-baseline gate.

SDK builders are `with_implementation_test_handoff()` and
`with_implementation_test_handoff_reserve(tools, decisions)`. The first child
preserves caller reserves plus one configured native check and four tool units
(discovery, two reads and an artifact write), and four additional decisions.
Without the native check set, the prior three-unit overhead remains. The test
author preserves caller reserves only. All remain
within original run limits. Native capability/scope guards, final affordability,
receipt ownership, private-scope isolation and identity-bound resume still apply.
Previous workflows remain available with their original order and exact evidence.

The implementation-aware test author switches to public artifact handoff when
a successful explicit write/edit artifact exists and its local allowance reaches
one configured check plus one tool unit (or local allowance is zero). Only
`spine_blocked` is callable for that turn: return actual test paths, observed
failures and unresolved caller repairs. This leaves unspent units for the caller;
it adds no quota and declares no semantic outcome. Hard request/decision guards
still apply. A child block is a control-flow return; caller owns completion.

Workspace server version3 keeps successful `read_many` output unchanged. Errors
return valid whole files with `request_index`, indexed bounded errors and
`complete=false`; the overall MCP result stays failed. Files that do not fit the
remaining32768-byte combined content budget are omitted with requested/available
byte counts, while later smaller files may still fit. No individual file is clipped.
Invalid argument lists and more than64paths still return no files.

`workspace.edit_many` accepts one existing UTF-8 file and1..64 ordered exact
replacements. Each entry has nonempty `old_text`, `new_text` and optional boolean
`replace_all`. Validate all entries and matches in a private buffer, then write
once; a later absent/ambiguous/no-op replacement leaves the actual file unchanged.
Sequential entries may match earlier replacements. Combined old/new text is at
most32768bytes; original/final files at most2MiB. Expansion is bounded before
allocation, line endings/other bytes are preserved, and a detected concurrent edit
refuses the write. This is validation atomicity, not an IO/external-change transaction.
Every call consumes one normal tool unit, like an explicit command, with no refunds.
The configured receipt policy classifies it as an effect and artifact/check logic
recognizes it. Only trusted complete unchanged host snapshots allow a rejected edit
to return for repair without an automatic redundant check; completion still needs
its current owned native check. Missing/untrusted/unknown snapshots stay conservative.

For the opt-in implementation/test workflow with a native check set, effective
caller tool reserve is max(configured reserve, 2*check cost+8), within the original
global cap. After both children return, explicit caller write/edit is followed by
an affordable in-scope native check without HTTP. Normal runtime step and full
weighted tool charges apply. Failed checks settle the edit obligation and return
feedback, avoiding automatic replay. Ordered batches and later child handoffs
settle preceding edits. Full public requirements become productive child obligations;
private parent inputs remain isolated. Early test-author return requires a successful
explicit artifact write/edit unless local capacity is exhausted.

The eight caller actions allow five review operations, two repairs and one
diagnostic read alongside the two full check cycles. With durable metering, a
producer that precedes another productive stage preserves one quarter of global
request-byte/output capacity for that stage and one quarter for the caller;
the final producer preserves the caller quarter. Request-count thresholds include
future decision reserves and stay bounded by those shares. These admission rules
do not increase global limits, release reservations or guarantee task success.

Native check excerpts retain up to512bytes of selected source text plus bounded
framing. Recognized assertion/traceback lines contribute shortened prefixes, so
long successful-test preambles cannot hide all failure details. Unknown formats
retain the existing head/tail projection. Status still comes from owned exit/error
outcomes, never parsed text. Forced producer returns and producer caller blocks
include failure-first native member diagnostics with original indices, inside a
bounded public view. A caller block keeps the model explanation, owned public
check status and remaining capacity even when the explanation is terse. Arbitrary
private history is excluded; old/stale data remains explicitly historical, not
proof of semantic correctness or permission to replay an effect.

`SPINE_AUTO_WORKFLOW=obligation_test_handoff` opts into a productive test inventory
on the implementation-first workflow. It requires the native public check set.
SDK builder: `with_test_obligation_handoff_reserve(tools, decisions)` followed by
`with_public_check_set(cost)`. Defaults and prior workflows stay available.
The author uses `spine_test_handoff` with each original public requirement index,
declared test cases or explicit uncovered work, and owned native check references.
The host binds artifacts to successful owned writes/edits and checks to actual
outcomes after the latest edit. Check diagnostics are bounded and unrelated private
history is excluded. No semantic coverage or task-success claim is verified.
Affordable author checks after edits run without HTTP but consume normal runtime
steps and full weighted tools. Failure feedback is not automatically replayed.
The returning caller still owns missing work, repair and current final validation.
The workflow name binds resume; changing it refuses before request/journal changes.

`SPINE_WORKSPACE_MUTATIONS=1` enables host-overwritten protocol1 metadata on settled
tool outcomes, including `workspace.run` edits. Default is0, except the new
`SPINE_AUTO_WORKFLOW=evidenced_test_handoff`, which requires/enables it. Snapshot
scope, exclusions and bounds are in the report/journal-bound profile. Only hashes,
sizes, types and modes are attached. Tool-server fields cannot forge these receipts.
Unknown snapshots mark overall error while preserving original tool error status;
repair commands can still run. Transport failures never replay for bookkeeping.
These are bounded observations around calls, not transactional filesystem guarantees.

SDK `with_host_workspace_mutations()` must only be used with a trusted adapter
that overwrites the reserved outer field. Default SDK outputs remain opaque.
`with_evidenced_test_handoff_reserve(tools, decisions)` adds explicit productive-gap
closure to obligation handoffs. The caller's `spine_complete` includes
`test_dispositions`: each supplied gap ID, owned artifact reference, case names,
concise resolution and current passed native check. Missing inventory becomes
explicit uncovered work. Invalid references return charged decision errors without
effects. Public dispositions are preserved; case existence, assertions, coverage
and semantic resolution remain model declarations. No semantic judging model.

Original caller-configured public check definitions are retained for bounded
forced-handoff/block diagnostics even when completion eligibility is filtered to
the native aggregate. They are still exact allowlisted owned outcomes, not arbitrary
tool history, and cannot substitute for aggregate completion evidence.

`SPINE_AUTO_WORKFLOW=adaptive` allows direct execution from the first AUTO
turn and optional productive delegation, including further scoped children
when shared capacity permits. It preserves caller tool/request capacity and
nested-return decisions. The root reserves a complete configured native check
and must own a current passed aggregate after its latest child and final edits.
It chooses when to execute that check, permitting several repairs before a full
check cycle. Child validation cannot satisfy root completion. Without configured
checks, ordinary check-free SDK completion remains available. Use
`with_adaptive_execution_reserve(tools, decisions)` for the SDK policy. This
workflow is under qualification; deterministic controls establish mechanics,
not autonomous task competence. Existing staged policies remain available.

With adaptive execution and a native public check set, a scoped child may use
`spine_return` to return its assigned work record for integration even after a
local mutation or an out-of-scope public check failure. The output must match the
assigned type and encode within8192UTF8bytes; the whole handoff remains<=16384bytes.
The host attaches bounded owned public outcomes automatically. It carries the
record as public blocked-child data, not a Task success verdict or inherited
caller check receipt. The root still needs its own current full native validation.
Native adaptive children use this productive return in place of ordinary
completion. Elsewhere `spine_complete` preserves formal receipt propagation,
including failed child check ledgers. Default/custom MCP clients keep their legacy behavior;
`spine_return` is reserved only in the active opt-in child control scope.

`SPINE_AUTO_WORKFLOW=direct_test_handoff` opts into direct coding followed by one
productive independent regression author and caller integration. It requires the
native public check set and trusted host mutation receipts (enabled by default
for this policy). SDK: `with_direct_test_handoff_reserve(tools, decisions)`.
Initial direct work reserves author/caller resources within global limits;
author and caller then execute under those same cumulative limits. The delegated
child retains native validation and receives the full original public contract
plus only explicit assigned inputs. It returns via the existing public
`spine_test_handoff` inventory. A productive owned artifact/check report and a
subsequent caller-owned passed native aggregate are required; declared uncovered
work also needs the existing caller gap dispositions. Coverage remains unverified
until independent acceptance. This is a coding workflow, not a semantic judge or
a requirement to create source regressions for research-only work.

In the direct regression workflow, the host binds the child's responsibility to
independent public-contract tests. A proposed delegate goal or local requirement
is framed as a test focus subject to original restrictions, not a new production
assignment. Current-step and system-role instructions agree in both snapshot and
replay history. Explicit assigned inputs and inherited tool restrictions remain.

## Metered request capacity in model inputs

When request accounting is enabled, current_step.request_account shows remaining
requests, request bytes and reserved output-token capacity before reserving the
current request, together with per-request bounds. The current request consumes
capacity too. This is public planning information; the durable account remains
the authority and refuses dispatch over a ceiling. No reservation is refunded.
Large recent observations or child outcomes may still exceed the allowance.

## Stable tool names and budgeted snapshot history

SPINE_STABLE_NATIVE_TOOL_NAMES=1 (SDK with_stable_native_tool_names()) uses
readable native names without catalog ordinals when their sanitized names are
unique. Collisions get a separate unique alias namespace; the current binding
table remains authoritative. Unknown names still fail strict dispatch validation.
This option requires native format; default0 preserves old aliases.

SPINE_BUDGETED_SNAPSHOT_WINDOW=1 (SDK with_budgeted_snapshot_window()) requires
snapshot history, a positive recent window and a metered request account. Docker
supplies a bounded default account when explicit limits are absent. The SDK
builder requires window/account setup first. Packing may shrink the recent window
down to1 to target an equal share of remaining request bytes. It never truncates
the latest observation or child outcomes; oversized mandatory data still refuses
at hard account limits. observation_projection declares the selected window.
Default0 preserves the configured fixed window. Both options are durable-profile
and report fields; changing either on resume refuses before HTTP/journal mutation.
These adapter controls do not establish autonomous task acceptance.

## Direct-test failed-member recovery and paid stage allocation

With direct_test_handoff, budget-aware actions and trusted host mutations enabled,
current_step.native_recovery lists exact failed configured member calls. Repair
and run those exact calls on current source before repeating workspace.validate.
Use supplied native aliases from mcp_bindings, since listed canonical names are
metadata. Mutations/child work/unknown snapshots stale raw passes, even if old bytes
are later restored. Raw passes permit another aggregate and never replace full
native evidence for delegation/completion. Scope/dispatch and weighted native cost
remain unchanged. Other workflows preserve their prior behavior.

Metered DirectTests use direct_stage_capacity=declared_decisions_v1. Requests are
reserved for declared future decisions, bytes proportionally with upward rounding,
and output tokens using the maximum configured role output limit. Infeasible
profiles refuse before HTTP. State shows numerical reserves; old quarter labels
are absent. This changes stage allocation within the same global limits and never
refunds past reservations or authorizes resuming a closed failed benchmark. Runtime
activation/version is reported, durable-profile-bound and checked by evaluation.
