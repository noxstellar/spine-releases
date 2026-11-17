# Spine configuration reference

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

This reference covers the installed launcher and Rust host as inspected on
16 November 2026. **The published release is v0.2.1.** Sections marked **0.3
development** describe unreleased work under qualification, not capabilities
already delivered by the public installer. Check your binary with `spine --version`.

The usual starting point is `spine setup`, followed by
`spine run /absolute/workspace 'your task'`. Advanced settings are process
environment variables. AUTO chooses direct work or recursive delegation;
there is no mandatory difficulty classifier or automatic selection of the
highest reasoning effort.

- [Provider setup and saved settings](#provider-setup-and-saved-settings)
- [Effort, context and execution limits](#effort-context-and-execution-limits)
- [All runtime environment settings](#all-runtime-environment-settings)
- [Durable goals: optional overall limits](#durable-goals-optional-overall-limits-03-development)
- [ACP, MCP, sessions and memory](#acp-mcp-sessions-and-memory)
- [Installer settings and storage](#installer-settings-and-storage)
- [Examples](#examples)
- [Scope and source audit](#scope-and-source-audit)

## Provider setup and saved settings

```sh
# Local Ollama: choose a tool-capable model already present in ollama list.
spine setup --provider ollama --model qwen3:8b

# Ollama Cloud through your signed-in local Ollama gateway.
spine setup --provider ollama --model kimi-k3.1-pro:cloud

# OpenAI Responses; enter the API key at the hidden prompt.
spine setup --provider openai --model gpt-6.1-sol

# Claude through an OpenAI-compatible provider, using that provider's key.
spine setup --provider openrouter --model anthropic/claude-sonnet-4

# A custom Chat Completions endpoint. Substitute your provider's actual values.
spine setup --provider custom --model MODEL_ID \
  --endpoint https://provider.example/v1/chat/completions --api chat_completions
```

Model IDs above are configuration examples, not a discovery list or a promise
that an account has access. Setup does not query the model catalog or make a
generation request. Local Ollama must be running; Ollama Cloud uses Ollama's
existing sign-in. Spine does not forward another provider's key to that gateway.
**Native Anthropic Messages is not implemented**: a Claude model must be exposed
through a compatible endpoint. A Codex/ChatGPT login is not an OpenAI API key.

| Setup flag | Accepted value / default | Effect |
| --- | --- | --- |
| `--provider` | `ollama`, `openai`, `openrouter`, `custom`; prompted when omitted | Selects endpoint/API defaults. |
| `--model` | Exact provider model ID; prompted when omitted | Saved primary model. There is no hardcoded default model. |
| `--endpoint` | Complete HTTPS URL; loopback HTTP is allowed | Overrides the endpoint selected by the provider. Include `/responses` or `/chat/completions`, not just `/v1`. |
| `--api` | `responses` or `chat_completions` | Overrides the provider's wire format. |
| `--tools` | `docker` by default; `external` skips worker setup | Saves native tools on/off. External tools must be supplied by the integration. |
| `--docker-context` | Current Docker context on fresh Docker setup | Selects the daemon; an existing saved context is retained unless replaced. |
| `--worker-image` | Bundled pinned image by default; otherwise `sha256:` plus 64 lowercase hex digits | A custom image must already be loaded in the chosen daemon. |

| Provider preset | Endpoint | API | Credentials |
| --- | --- | --- | --- |
| `ollama` | `http://127.0.0.1:11434/v1/chat/completions` | `chat_completions` | No Spine API key; local gateway owns cloud sign-in. |
| `openai` | `https://api.openai.com/v1/responses` | `responses` | OpenAI API key. |
| `openrouter` | `https://openrouter.ai/api/v1/chat/completions` | `chat_completions` | OpenRouter API key. |
| `custom` | Supplied by you | `chat_completions` unless overridden | Key entered during setup. |

Settings live in `$XDG_CONFIG_HOME/spine/config`, normally
`~/.config/spine/config`. This is a private line-oriented data file, **not a shell
script or `.env` file**. Its recognized keys are `provider`, `model`, `endpoint`,
`api`, `api_key`, `docker_context`, `worker_image` and `native_tools`.
The directory must be owned by you with mode `0700`; the file must be `0600`.
Use setup to change these settings. Unknown keys and duplicate keys are rejected.
Other advanced settings below are not written by setup.

Keys are entered through hidden terminal input or an already provisioned
`SPINE_API_KEY` environment variable. Never put a key in a task, command argument,
checked-in configuration or example. The launcher does not automatically use
`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` or another provider-specific variable.

### Precedence

1. `spine run --mode ...` wins over `SPINE_EXECUTION_MODE`; the default is `auto`.
2. Runtime environment overrides saved provider/model/API/tool settings where
   listed below. Changing an endpoint with a saved key requires an explicit
   `SPINE_API_KEY` for that endpoint, or a new setup, to avoid forwarding a saved
   credential to a different service. An Ollama preset always removes that key.
3. Launcher defaults apply next. In particular, it selects snapshot history.
4. The raw Rust binary does not read the launcher's saved profile. It requires
   model/endpoint environment settings and defaults to replay history.
5. **0.3 development:** a durable goal's stored `mode`, `period` and `lifetime`
   govern its work periods. Ordinary run-limit environment settings do not
   replace those stored limits; model/provider settings still come from the host.

Export advanced nonsecret settings in the environment that starts Spine, or use
a per-command assignment. Editors launched from a GUI may not inherit your shell
profile: configure their child-process environment explicitly. Spine does not
automatically load a project `.env` file.

## Effort, context and execution limits

| Control | What it changes | What it does not change |
| --- | --- | --- |
| Reasoning effort | A provider's reasoning setting for one response | Model context capacity, recursion depth or the number of allowed calls. |
| Output tokens | The maximum requested response size | A model's input context window or the whole task's budget. |
| Request bytes | Serialized HTTP request payload allowance | Exact input-token count; JSON/tool schemas also occupy bytes. |
| Context retrieval | Which workspace/memory evidence enters a decision | The provider's model architecture or maximum context window. |
| Steps / requests | Decision-loop and provider-call limits | A guaranteed amount of useful work or task success. |
| Tasks / depth | Total admitted task frames and nesting | Reasoning effort inside a frame. The root is depth zero. |
| Goal lifetime | Optional total allowance across durable work periods | The individual period's limits or permission to replay an uncertain effect. |

### Reasoning effort, including `ultra`

`SPINE_REASONING_EFFORT` is **unset by default**. Spine then omits the field;
the provider chooses its default. It does not silently select `high`, `max` or
`ultra`. When set, the string is passed unchanged as `reasoning_effort` for Chat
Completions or `reasoning.effort` for Responses.

There is no universal effort enum across providers. Values such as `low`,
`medium`, `high`, `xhigh`, `max` and `ultra` are usable only if the selected
endpoint/model accepts them. Spine currently does not negotiate supported levels,
translate an editor's effort label, or substitute another value after rejection.
Thus `SPINE_REASONING_EFFORT=ultra` can be forwarded, but **universal ultra support
is not established**. An unknown value can cause a provider error. Check the
selected provider/model's contract; naming a level does not prove the provider
honored it.

```sh
# For a model whose endpoint supports high:
SPINE_REASONING_EFFORT=high spine run /absolute/workspace 'Audit this proposal'

# Return to provider default; an empty string is still an explicit string.
unset SPINE_REASONING_EFFORT
```

Effort can affect response time and output-token use. Output reservations and
all run/period limits still apply. Sampling controls are independent: unset
temperature/top-p omits those fields, which may differ from defaults saved in a
local model alias. Some models reject explicit sampling or effort parameters.
Spine does not infer their compatibility from the model's name.

### Context size

There is **no `SPINE_CONTEXT_LENGTH`, `SPINE_CONTEXT_TOKENS` or `num_ctx` setting**
in the host. The provider determines the model's token window. Configure a local
model's server-side context through that provider's supported mechanisms.

Spine's workspace retriever uses a bounded evidence packet: at most **8 items and
16,384 serialized bytes**. The host uses graph depth 2, seed limit 8, candidate
limit 32 and graph-entity limit 64; text chunks target 2,048 bytes / 48 lines.
These are retrieval settings compiled into the host, not environment knobs. The
SDK exposes `RetrievalConfig` for embedding applications. Embedded project memory
contributes at most 3 notes / 4,096 bytes within the same total packet cap.

The complete model request also includes task instructions, tool schemas and
public history, so it can be much larger than the retrieved packet. Request-byte
limits refuse oversized dispatches; they do not enlarge the provider context.
Snapshot windowing can omit older observations from model input, while retained
state/reports remain intact. That tradeoff is explicit and can lose useful model
context; it is not a guarantee of better answers.

### Ordinary runs and ACP turns

These v0.2.1 defaults apply to an installed `spine run`, a four-argument standalone
invocation and an ordinary ACP prompt turn:

| Allowance | Default | Scope |
| --- | --- | --- |
| Model decisions (`SPINE_MAX_STEPS`) | 64 | Whole run, including descendants. |
| Tool units (`SPINE_MAX_TOOLS`) | 48 | Whole run; aggregate tools may cost more than one unit. |
| Tasks (`SPINE_MAX_TASKS`) | 16 in AUTO/recursive; fixed 1 in DIRECT | Includes the root. |
| Depth (`SPINE_MAX_DEPTH`) | 4 in AUTO/recursive; fixed 0 in DIRECT | Maximum nesting below the root. |
| Active run timeout (`SPINE_RUN_TIMEOUT_SECS`) | 600 seconds | Whole run, not a new timeout per child. |
| Provider requests | 32 | Shared request account. |
| One request payload | 1,048,576 bytes | Final serialized request. |
| All request payloads | 8,388,608 bytes | Cumulative submitted bytes. |
| Reserved output tokens | 131,072 | Sum of requested maxima across requests. |
| Requested output per response | 4,096 tokens | `SPINE_MAX_OUTPUT_TOKENS`. |
| Provider request timeout | 120 seconds | `SPINE_REQUEST_TIMEOUT_SECS`, also bounded by remaining execution time. |
| Provider response body | 1,048,576 bytes | `SPINE_MAX_RESPONSE_BYTES`. |

There is no `SPINE_MAX_TURNS` setting. `SPINE_MAX_STEPS` means model decisions,
not user messages or weeks of supervision. Ordinary runs are bounded; use durable
goals in the **0.3 development build** for continuation across settled periods.
Separate ordinary ACP prompts have separate per-turn accounts, not a shared
session-wide spending ceiling. A durable goal adds that shared lifetime account.

Reservations occur before dispatch and are not refunded when the provider uses
fewer tokens or returns an error. They bound submitted work, not currency. The
reference `live` example and SDK do not automatically get every standalone CLI
default; configure their request account explicitly. Zero does not mean unlimited
for these positive run/request settings.

## All runtime environment settings

The tables below inventory the runtime's recognized `SPINE_*` configuration,
including role names generated by the host. Defaults refer to the installed
standalone host unless stated otherwise. Optional historical policies are
documented for reproducibility; their presence is not a recommendation to enable
them, nor qualification of every combination.

### Provider and response settings

| Variable | Default / accepted values | Effect |
| --- | --- | --- |
| `SPINE_MODEL` | Saved setup model; required for raw binary | Primary provider model ID. |
| `SPINE_MODEL_ENDPOINT` | Saved setup endpoint; required for raw binary | Full endpoint URL. Launcher permits HTTPS or loopback HTTP. |
| `SPINE_MODEL_API` | Saved setup API; raw binary `chat_completions` | `chat_completions` or `responses`. Responses requires native decisions, snapshot history and state transport. |
| `SPINE_API_KEY` | Saved key; omitted for Ollama | Host-only bearer credential. |
| `SPINE_REASONING_EFFORT` | Unset | Provider-specific effort string; see above. |
| `SPINE_TEMPERATURE` | Unset | Finite nonnegative number; provider may impose narrower bounds. |
| `SPINE_TOP_P` | Unset | Finite number from 0 to 1 inclusive. |
| `SPINE_MAX_OUTPUT_TOKENS` | `4096` | Positive integer per-response maximum; remains subject to account capacity. |
| `SPINE_REQUEST_TIMEOUT_SECS` | `120` | Positive provider request timeout in seconds. |
| `SPINE_MAX_RESPONSE_BYTES` | `1048576` | Positive maximum response-body size. |
| `SPINE_DECISION_FORMAT` | `native` | `native` function calls or `structured` JSON decisions. Structured requires provider JSON-schema support and is incompatible with Responses. |

### Mode, budgets and recovery

| Variable | Default / accepted values | Effect |
| --- | --- | --- |
| `SPINE_EXECUTION_MODE` | `auto` in launcher | `auto`, `direct`, `recursive`; `run --mode` overrides. ACP uses its session mode; goal mode is stored separately. |
| `SPINE_MAX_STEPS` | `64` | Positive shared decision count. |
| `SPINE_MAX_TASKS` | `16` | Positive shared task count, at most 1,024; ignored by DIRECT, which fixes 1. |
| `SPINE_MAX_TOOLS` | `48` | Positive shared tool-unit count. |
| `SPINE_MAX_DEPTH` | `4` | Positive nesting bound, at most 64; ignored by DIRECT, which fixes 0. |
| `SPINE_RUN_TIMEOUT_SECS` | `600` | Positive cumulative active-run timeout. |
| `SPINE_REQUEST_LIMITS` | Standalone defaults in previous table | JSON object with all four positive integer fields shown below. |
| `SPINE_STEERING` | `1` | `0` disables CLI stdin steering for batch runs; `1` enables safe-boundary updates. Ordinary runs allow 64 prompts / 65,536 bytes total, 16,384 bytes per prompt. ACP uses its explicit steering extension. |
| `SPINE_RESUME_FAILURE_REPORT` | Unset | Path to an eligible closed error report. Requires matching executable/task/profile and original limits/account; never replay an unknown effect. Unsupported for ACP and durable goals. |
| `SPINE_REQUEST_JOURNAL` | Retained journal path on eligible resume | Alternate location of the same verified journal; not a new allowance. New runs create `REPORT_FILE.requests.jsonl` regardless of this override. |
| `SPINE_GOAL_DRIVE` | **0.3 development:** `continuous` | `continuous` watches pending goals and resumes on answers/events; `until_wait` yields control at a wait/attention boundary. No model polling during waits. |
| `SPINE_TRACE` | **0.3 development:** unset/off | `0` or `off`; `1` or `summary`; `details`. Writes a bounded public execution trace beside each report; details may include workspace/tool previews. No private reasoning. |

An explicit request account replaces the default object in full:

```sh
export SPINE_REQUEST_LIMITS='{"max_requests":32,"max_request_bytes":1048576,"max_total_request_bytes":8388608,"max_total_output_tokens":131072}'
```

### Role models

All role settings default to unset. Without an override, the role uses the primary
configuration. Roles are selected from current execution state, not a separate
difficulty classifier. Endpoint, key, sampling, timeout and output limit are
inherited; all actors share the same account.

| Model variable | Effort variable | When selected |
| --- | --- | --- |
| `SPINE_COORDINATOR_MODEL` | `SPINE_COORDINATOR_REASONING_EFFORT` | Initial coordination under a coordinating policy. |
| `SPINE_WORKER_MODEL` | `SPINE_WORKER_REASONING_EFFORT` | Descendant work without coordinator/returning-caller priority. |
| `SPINE_CALLER_MODEL` | `SPINE_CALLER_REASONING_EFFORT` | A task integrating recorded child or blocked-child results. |
| `SPINE_WORKER_ERROR_FALLBACK_MODEL` | `SPINE_WORKER_ERROR_FALLBACK_REASONING_EFFORT` | Optional worker escalation after supported repeated tool/decision errors. Unset disables it. It is not a generic network-provider fallback. |

An effort-only override keeps the primary model. **A model-only override omits
effort for that role**, rather than inheriting the primary effort. Set both when
you want a specific pair. Different roles cannot select different endpoints or
credentials through these variables. A local-Qwen/cloud-Kimi combination requires
a compatible gateway exposing both model IDs, or an embedding application's
model adapter; simply naming models from two unrelated providers is insufficient.

### Context and history

| Variable | Default / accepted values | Effect |
| --- | --- | --- |
| `SPINE_CONTEXT` | `embedded` when feature + `.spine/memory` exist, otherwise `workspace` | `workspace`, `embedded`, `empty`. Embedded requires the `embedded-rag` build feature. Empty disables automatic retrieval, not explicit tools or task/history input. |
| `SPINE_MODEL_HISTORY` | Launcher `snapshot`; raw host `replay` | Snapshot sends public state; replay reconstructs public action/tool turns. Provider-private reasoning is not retained. |
| `SPINE_SNAPSHOT_TRANSPORT` | `state` | `state` or `tool_turns`. Tool turns requires native + snapshot; incompatible with Responses. |
| `SPINE_COMPACT_ASSIGNMENTS` | `0` | Experimental `0`/`1`; requires snapshot + state transport. Aliases only exactly equal trusted original request, local goal and current instruction strings, with at least 512 net message bytes saved including protocol overhead. Small/ineligible requests keep their existing rendering. Canonical state, history and request limits stay unchanged; enabled policy is bound to the durable profile. Token/latency savings and equivalent model behavior are not yet live-qualified. |
| `SPINE_SNAPSHOT_RECENT_OBSERVATIONS` | Unset: full snapshot | Positive recent-observation count. Requires snapshot; zero is rejected. Retains specified important child/error records, with specialized historical policies as described in source. |
| `SPINE_BUDGETED_SNAPSHOT_WINDOW` | `0` | `0`/`1`; optional byte-budget packing. Requires snapshot, a recent-observation window and a request account. Omitted history stays identified; this does not reset state. |
| `SPINE_FAILURE_CONTEXT` | `0` | `0`/`1`; adds bounded evidence from owned failures; requires workspace context. |
| `SPINE_PUBLIC_WORK_RECORD` | `0` | `0`/`1`; optional model-authored public progress metadata; native snapshot only. It is not verified progress. |
| `SPINE_PUBLIC_WORK_RECORD_TRANSPORT` | `envelope` | `envelope` or `assistant_text`. Assistant text requires public records enabled. Tool-turn snapshots with public records require assistant text. |

### Tools and workspace

| Variable | Default / accepted values | Effect |
| --- | --- | --- |
| `SPINE_NATIVE_TOOLS` | Saved `native_tools`; fresh setup `1` | `0`/`1`. External mode removes the native worker; it does not create replacement tools. |
| `SPINE_TOOL_HOST` | `docker` for standalone; `local` for reference example | `docker` or `local`. Local runs trusted tools under the host account and has no Docker sandbox. |
| `SPINE_TOOL_IMAGE` | Saved pinned worker image | Required digest-pinned Docker image; no implicit pull during execution. |
| `SPINE_DOCKER_CONTEXT` | Saved context; raw host uses Docker's default selection | Docker daemon/context to use. |
| `SPINE_TOOL_MEMORY_MIB` | `512` | Positive Docker-worker memory limit in MiB. |
| `SPINE_TOOL_CACHE_VOLUME` | `auto` for standalone; absent for reference example | `auto` derives a UID/image-specific volume; otherwise a valid Docker volume name. An empty string is invalid; there is no documented `off` sentinel. |
| `SPINE_TOOL_SERVER` | Embedded/bundled workspace server | Optional caller-owned server file outside the workspace. Docker must be able to mount it; bytes are fingerprinted. |
| `SPINE_PROTECTED_PATHS` | `[]` | JSON list of relative file paths mounted read-only; native Docker tools required. |
| `SPINE_WORKSPACE_TOOLSET` | `full` | `full` or native-only `core`. Core reduces the workspace interface to list/read/read-many/search/edit/edit-many/write/run, preserving optional configured controls. |
| `SPINE_WORKSPACE_CHANGES` | On for native standalone with nonempty context; otherwise off | `0`/`1`; owned source-change review. Applicable tool/context restrictions are validated. |
| `SPINE_WORKSPACE_MUTATIONS` | On only for `evidenced_test_handoff` / `direct_test_handoff`; otherwise off | `0`/`1`; host mutation receipts for specialized policies; native tools required. |
| `SPINE_STABLE_NATIVE_TOOL_NAMES` | `0` | `0`/`1`; stable native aliases; requires native decision format. |

The worker's CPU/PID/network/root-filesystem restrictions are separate from these
knobs. Default Docker workers have 2 CPUs, 64 PIDs, no network, a read-only root
and a writable scoped workspace. External MCP servers and ACP client terminals
use their own execution boundary; the Docker restrictions do not sandbox them.

### Optional verification and historical workflow policies

Leave these unset unless deliberately selecting the corresponding profile.
Published studies qualify exact configurations, not every policy combination.

| Variable | Default / accepted values | Effect |
| --- | --- | --- |
| `SPINE_AUTO_WORKFLOW` | `agent` | AUTO policy. Other values: `adaptive`, `producer_handoff`, `implementation_review_handoff`, `test_first_handoff`, `staged_handoff`, `implementation_test_handoff`, `obligation_test_handoff`, `evidenced_test_handoff`, `direct_test_handoff`. Other modes keep their own policy. |
| `SPINE_VERIFICATION_POLICY` | Unset | JSON `{ "id": "…", "checks": [{"name":"…","arguments":{}}], "effect_tools": ["…"] }`. Exact caller-owned ToolCalls define observed checks; no semantic correctness oracle. Native tools required. |
| `SPINE_RETURN_VERIFICATION` | `off` | **0.3 development, experimental:** `consumer` holds each nonroot completion for parent assessment. `inspect` can read through an explicitly admitted host capability while the candidate remains pending; acceptance can include one ordinary next action. Repair reuses the child and spent counters; `ask` retains a candidate-bound question without polling. Shares ordinary model/request/tool limits. Model review is fallible and does not establish whole-goal acceptance. Unsupported model profiles and mode changes on resume reject before dispatch. |
| `SPINE_PUBLIC_CHECK_SET` | Unset | JSON with optional `preparation` ToolCalls and `author_preparation` check indices; check calls come from the verification policy. Exposes the configured aggregate action. |
| `SPINE_CALLER_RESERVE` | Applicable default: tools `min(max_tools/3,8)`, decisions `min(max_steps/4,6)` | JSON with exactly integer `tools` and `decisions`; supported by AUTO adaptive/producer/implementation-review policies. Explicit reserve must leave producer capacity and fund checks plus delivery. |
| `SPINE_DIRECT_CALLER_TOOL_RESERVE` | `min(max_tools/3,8)` | Positive explicit tool reserve only for `direct_test_handoff` with a native public check set; must fit its configured checks and leave producer capacity. |
| `SPINE_BUDGET_AWARE_ACTIONS` | `1` standalone; `0` reference example | `0`/`1`; constrains offered actions to remaining shared capacity. Does not replenish limits. |
| `SPINE_VALIDATION_GUIDANCE` | `0` | `0`/`1`; guidance based on observed check state; not another model judge. |
| `SPINE_RATE_LIMIT_RECOVERY` | `0` | `0`/`1`; recoverable HTTP 429 waits use numeric `Retry-After` up to 60 seconds, or 5 seconds if absent. Unsupported/date-form delays remain fatal. The next decision needs a new reservation under unchanged limits. |

Producer, implementation-review, test-first, staged, implementation-test,
obligation-test and evidenced-test handoffs require configured nonempty check
calls. Obligation-test, evidenced-test and direct-test handoffs also require a
native public check set. Invalid combinations fail before model dispatch.
The native aggregate permits 1–16 check calls and at most 4 preparation calls,
within 8,192 serialized bytes. Its calls must be `workspace.run` with explicit
`argv` and `timeout_seconds` from 1 to 120; author-preparation indices must be sorted, unique
and valid, and require host mutation metadata. Evidenced-test/direct-test
policies also require that metadata. These reserves allocate existing capacity;
they do not create extra calls or independent proof of task correctness.
Consumer assessment supports ordinary Agent, Task, Objective and Adaptive model
policies; historical staged policies and the native public-record envelope are
not supported. When public work records are enabled, use their `assistant_text`
transport. Native Chat Completions, structured decisions and Responses retain
their existing provider requirements. This first consumer mode does not add an
independent root reviewer. The [adaptive default (private source)](https://github.com/noxstellar/spine/blob/bb5310820bd657487a27329039a49e592a8acaf7/rust/VERIFICATION_DESIGN.md) still
requires efficacy, overhead and durable-state qualification.

The development SDK separately exposes `RootReviewConfig` and `step_reviewed`
with an explicit trusted evidence policy. Its configured output ceiling is
1–2,048 tokens. It preserves review attempts and typed final audit records; see
the [SDK controls and limits (private source)](https://github.com/noxstellar/spine/blob/bb5310820bd657487a27329039a49e592a8acaf7/rust/proofs/2026-11-17-independent-root-review/README.md).
This interface has no CLI/environment setting and is not yet activated in the
durable host. The proposed `auto` setting below remains a design, not an accepted
configuration value.

The current development profile is `consumer_v3`. It retains the bounded questions
(at most 8,192 UTF-8 bytes) introduced in `consumer_v2`. The runtime exposes a typed suspension and saves the unresolved child;
repeated suspended steps consume no model, context or tool calls and no active
execution time. An accepted answer is trusted steering, not permission to accept
the old result. The [native durable profile (private source)](https://github.com/noxstellar/spine/blob/bb5310820bd657487a27329039a49e592a8acaf7/rust/proofs/2026-11-17-native-consumer-goals/README.md)
now preserves this behavior across work periods and supervisor restarts.
Earlier `consumer_v1` and `consumer_v2` checkpoints retain their original executable/profile;
changing the interface does not authorize resetting their accounting.

For consumer mode with the built-in native workspace tools, the host adds
`workspace.inspect_artifact` with arguments `{"path":"relative/file.txt"}`.
The parent may select it through the assessment's `inspect` disposition before
accepting the child. This consumes one ordinary model decision and one tool call;
it neither releases queued siblings nor grants extra allowance. The reader returns
one complete UTF-8 file of at most 32,768 bytes, its SHA-256 and byte count. It
rejects symlinks, hardlinks, special files, noncanonical paths, protected-file hash
mismatches and changes detected during the read. A captured file revision is
evidence for review, not proof of semantic correctness or future freshness.

The inspector requires `SPINE_NATIVE_TOOLS=1` and no custom `SPINE_TOOL_SERVER`.
It observes the parent's ordinary allowed-tool scope and host permission callbacks.
External MCP names or `readOnlyHint` annotations do not grant this capability.
An embedding host may explicitly implement the default-deny inspection methods
on `Tools`; it owns admission and read-only behavior. `StepRequest` now includes
`return_inspection_tools` in the prospective 0.3 Rust API; empty catalogs are omitted
from serialized ordinary requests. Consumer mode remains off by default pending
adaptive-policy and efficacy/cost qualification.

Owned durable-goal history has a separate typed inspection route. It permits
bounded `goal_history` reads before child acceptance, preserving captured input
and report hashes, parent scope, permissions and normal tool charges. A client
tool with the same name gains no such authority. Native consumer goals validate
the exact model/profile and retained execution before reserving another period.

The matched-evaluation launcher has an additional experimental configuration:
`SPINE_COMMON_READ_INSPECTION` names its private capability descriptor and
`SPINE_COMMON_READ_INSPECTION_SHA256` pins the descriptor bytes. Both are unset
by default and must be supplied together. They require consumer mode, native
tools and the exact configured common-worker bridge. The host validates the
owned files, bridge/frontend/configuration identities and eight-tool catalog;
the supervisor separately binds the worker, transport and complete read result.
This admits the existing `workspace.read` with exactly `{"path":"relative/file"}`
during pending review, without adding a tool or changing its ordinary result.
The launcher owns this setup; these settings are not a generic permission to
trust external MCP read annotations. Actual contained qualification is separate
from the offline configuration controls. Neither setting enables durable goals
or changes the default verification policy.

```sh
# Unreleased experimental consumer assessment, using your configured provider.
SPINE_RETURN_VERIFICATION=consumer spine run /absolute/workspace 'your task'
```

**0.3 development durable consumer goals are opt-in and native-only.** Use
`SPINE_NATIVE_TOOLS=1`, no custom `SPINE_TOOL_SERVER`, no external MCP/client tools,
and the stored `require_acceptance` completion policy. An explicit root tool scope
must include `goal_history`. The same-child state, pending question, original
workspace baseline and spent counters survive safe periods and restarts. Changed
model/endpoint/effort/context/tool/profile settings reject before escrow; do not
silently change a retained execution's profile. `SPINE_VERIFICATION_POLICY` and
`SPINE_PUBLIC_CHECK_SET` remain unsupported for goals. Ordinary runs and existing
external integrations retain their documented modes. See [goal examples](GOALS.md#consumer-verification-03-development).

## Durable goals: optional overall limits (0.3 development)

**Not in v0.2.1.** The new host supervisor is being qualified. It owns the goal
across bounded work periods and keeps pending questions/events durable. An
omitted `lifetime`, or explicit `"lifetime": null`, means **no configured overall
request/token/tool/time/period cap**. It does not mean unknown external effects
can be replayed, that resources are infinite, or that week-scale reliability has
already been proven.

There is no separate fixed maximum-turn setting for a goal. Supply a lifetime
object only when you want an overall allowance. It contains **all eight** fields:
`requests`, `request_bytes`, `output_tokens`, `steps`, `tasks`, `tools`,
`active_seconds`, `periods`. Values are positive integers except `tools`, which
may be zero. Limits and committed/reserved charges survive answers, corrections
and reloads; they are not reset for a new child or period. Active time is charged
conservatively from reserved period time, not advertised as exact elapsed usage.

### Goal specification

`spine goal create WORKSPACE SPEC_FILE` supplies `cwd` from its workspace argument;
do **not** put `cwd` in that CLI JSON file. ACP callers must include `cwd` in the
goal object; Spine checks that it matches the session workspace. A minimal CLI specification is:

```json
{
  "objective": "Reconcile the supplied records and produce the agreed report.",
  "acceptance": ["Cite source records for every material conclusion."],
  "mode": "auto",
  "lifetime": null
}
```

| Specification field | Default | Meaning |
| --- | --- | --- |
| `objective` | Required nonblank text, up to 65,536 bytes | Original goal, retained exactly. |
| `acceptance` | `[]` | Up to 64 textual requirements, each up to 4,096 bytes. Text alone is not a machine check. |
| `mode` | `auto` | `auto`, `direct`, `recursive`. |
| `allowed_tools` | `null` / omitted | Optional explicit allowed tool names; descendants cannot widen scope. An empty list allows no tools. |
| `completion` | `{"mode":"require_acceptance","checks":[]}` | Model completion becomes a candidate; absent checks require explicit operator acceptance. |
| `period` | Complete default object below | Bounds each work period. If supplied, include every field. |
| `lifetime` | `null` / omitted | Optional complete overall budget object. |

Default period limits:

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

Period maxima are 1,024 requests, 16 MiB per request, 1 GiB total request bytes,
16,777,216 reserved output tokens, 4,096 steps, 1,024 tasks, 4,096 tool units,
depth 64 and 3,600 active seconds. Tools/depth may be zero; other values must be
positive. Total request bytes must cover the per-request maximum. DIRECT fixes
one task/depth zero. A finite remaining lifetime can reduce the admitted period.
The model's per-response `SPINE_MAX_OUTPUT_TOKENS` remains separate.

An optional lifetime example, in the same goal specification:

```json
"lifetime": {
  "requests": 160,
  "request_bytes": 83886080,
  "output_tokens": 655360,
  "steps": 320,
  "tasks": 80,
  "tools": 320,
  "active_seconds": 3000,
  "periods": 10
}
```

This is an allowance, not a promise to use all ten periods. The first exhausted
dimension prevents further work. Omit the entire object to leave the overall
cap off. Do not use zero as an unlimited marker.

### Completion, questions and resumption

The default completion policy does not accept a model's assertion by itself.
With no configured checks, inspect the retained candidate and use
`spine goal accept ID REVISION CANDIDATE_ID`. Ordinary text such as “yes” is an
answer/correction, not this acceptance operation. Confirmation binds the goal
contract and report; unlisted workspace files are not independently verified.

Machine-checkable goals can declare bounded file predicates:

```json
"completion": {
  "mode": "require_acceptance",
  "checks": [{
    "id": "expected-record-count",
    "path": "result.json",
    "expected": {"kind": "json_equals", "value": {"count": 3}}
  }]
}
```

The alternative predicate is `{"kind":"sha256","value":"LOWERCASE_64_HEX_DIGEST"}`.
Paths must be safe relative workspace file paths; symlinks, hardlinks and
nonregular files are rejected. At most 64 checks, 2 MiB per observed file and
32 MiB total artifact bytes are supported. Expected values remain host-owned,
outside model context. A passed check establishes only its predicate, not every
natural-language requirement. The explicit legacy policy
`{"mode":"model_declared"}` records `model_completed`, not independent acceptance.
Corrections, answers and human wake messages prevent the old predicates from
automatically accepting revised work. Passing checks then require explicit
confirmation. Mechanical scheduled wakes do not alter that acceptance scope.
The first ACP prompt for a ready attached goal is also a retained user correction,
so it makes configured-check acceptance require confirmation. To preserve an
unchanged predeclared contract, use the CLI goal driver.
Amendments do not edit budgets or configured predicates. An obsolete failing
predicate cannot be bypassed with `accept`; a changed machine contract needs a
new goal specification and explicit cancellation of the previous goal.

```sh
spine goal create /absolute/workspace /outside/workspace/goal.json
spine goal run GOAL_ID

# From another terminal/client, use the current revision and pending ID:
spine goal show GOAL_ID
spine goal answer GOAL_ID REVISION QUESTION_ID 'The agreed cutoff is Friday.'
spine goal wake GOAL_ID REVISION EVENT_ID 'The requested data is available.'
spine goal amend GOAL_ID REVISION 'Include the additional supplied source.'
spine goal cancel GOAL_ID REVISION 'Stop this goal.'

# For an external scheduler:
SPINE_GOAL_DRIVE=until_wait spine goal run GOAL_ID
spine goal run GOAL_ID --once
```

Continuous supervision is the default. While pending, it waits without model
calls; typed answers and explicit wake events let the same supervisor continue.
Recorded future wake times are observed automatically. Cancellation of an ACP
prompt stops that supervisor without silently cancelling its stored goal; a
later prompt can watch the same pending question. An unfinished uncertain work
period stays fenced for inspection. A live process or an external process
supervisor is still needed: a configuration flag cannot keep a machine powered
on or revive a process after the operating system exits it.

Explicit `goal rebase-plan` / `goal rebase` recovery for a settled unfinished
execution or a verifiably closed active period is documented in [goals](GOALS.md#explicitly-supersede-a-retained-execution-03-development).
The generated request binds the source hashes/size, current revision and input
head. Its `max_state_bytes` allowance is explicit and local to that recovery;
it changes no default state or lifetime limit. Closed active recovery additionally
requires the original Unix ownership identities and a valid closure receipt;
live/uncertain work, legacy receipts and inode-changing imports reject. Reports
and journals retain their fixed bounds. Supersession retains obligations,
effects and spending as unfinished history, settles any previously uncommitted
consumption once, and charges a new root normally. The native-only consumer
profile now passes [integrated restart and recovery controls (private source)](https://github.com/noxstellar/spine/blob/bb5310820bd657487a27329039a49e592a8acaf7/rust/proofs/2026-11-17-native-consumer-goals/README.md).

## ACP, MCP, sessions and memory

Use `spine setup ... --tools external` when your application supplies tools, then
start `spine acp` as its stdio child process. Standard output is newline-delimited
ACP JSON-RPC; logs go to stderr. ACP v1 supports new/load/prompt/cancel/close,
`auto`/`direct`/`recursive` modes, client file/terminal tools and multiple MCP
servers. Session mode is selected with ACP, not `SPINE_EXECUTION_MODE`.

MCP descriptors are supplied by the client in `session/new` and again on
`session/load`; the launcher has no global `SPINE_MCP_SERVERS` variable or
automatically loaded project `mcp.json`. A representative parameters fragment:

```json
{
  "cwd": "/absolute/workspace",
  "mcpServers": [
    {"name":"local_rag","command":"/absolute/bin/rag-mcp","args":["--stdio"],"env":[]},
    {"type":"http","name":"office","url":"https://mcp.example/mcp","headers":[]}
  ]
}
```

Stdio and Streamable HTTP are supported; SSE is not. Remote HTTP needs HTTPS;
loopback HTTP is allowed. Up to 16 servers / 128 KiB of serialized descriptor
data are accepted. Server names must be unique, 1–64 ASCII letters/digits/`_`/`-`;
`workspace`, `client`, `session` are reserved. Tools are namespaced as
`SERVER.TOOL`. Stdio commands are absolute, with at most 128 explicitly supplied
environment entries / 64 KiB; they do not inherit the provider key. Resolve any
MCP credentials in the client's own secret store. Connection descriptors are
not persisted in transcripts.

External/client effectful tools require the ACP client's exact allow-once
decision. Native read-only tools and session history can omit that prompt.
Spine's built-in coding tools include read, write, exact edit, search and explicit
command execution. MCP can supply research, RAG and office tools without coding
tools. There is no built-in web-search provider configured by these variables.

| Storage / integration setting | Default / boundary |
| --- | --- |
| ACP sessions | `$XDG_STATE_HOME/spine/sessions`; normally `~/.local/state/spine/sessions`. |
| Loaded sessions / active ordinary prompts | 32 / 4 per process. |
| Stored session limit | 1,024 entries; 8 MiB / 256 user-final messages per session. |
| Incoming ACP frame | 1 MiB newline-delimited UTF-8. |
| Prompt/final content | 256 KiB, 1–64 content blocks. |
| Public turn updates | 2 MiB / 1,024 updates with reserved final-output capacity. |
| In-flight ACP steering | Ordinary turn: `_spine/steer`, up to 64 messages / 64 KiB, 16 KiB per message. **0.3 development goals:** no overall input-message count/byte cap; each message remains bounded and archived. |
| Project memory | `.spine/memory/` Markdown; `.spine/cache/` disposable index. |
| Goal storage (**0.3 development**) | `$XDG_STATE_HOME/spine/goals`; durable accounting separate from session history. |

Use `spine memory init WORKSPACE`, `spine memory refresh WORKSPACE` and
`spine memory search WORKSPACE 'query'`. Memory retrieval requires the
`embedded-rag` feature, included in the released distribution. Session
conversation is not automatically copied into project memory. RAG over MCP is
separate from both. Session history bounds are not an unlimited conversation
promise; loading a session does not replay a failed/uncertain task tree.

## Installer settings and storage

These variables affect `install.sh`, not model reasoning or runtime budgets.

| Variable | Default | Meaning |
| --- | --- | --- |
| `SPINE_VERSION` | `latest` official release | Pin `X.Y.Z` or `X.Y.Z-nightly.YYYYMMDD.RUN.ATTEMPT`; explicit installer argument wins. A leading `v` is accepted for a pinned version. |
| `SPINE_RELEASE_REPOSITORY` | `noxstellar/spine-releases` | GitHub public binary repository in `owner/repo` form. |
| `SPINE_BIN_DIR` | `$HOME/.local/bin` | Absolute destination for the launcher link. |
| `SPINE_DATA_DIR` | `$HOME/.local/share/spine` | Absolute installation/releases directory. |
| `XDG_CONFIG_HOME` | `$HOME/.config` | Absolute configuration base for launcher/host. |
| `XDG_STATE_HOME` | `$HOME/.local/state` | Absolute state/report/session/goal base. |
| `HOME` | Required user home | Supplies the default paths above. |

For a pinned installation, assign the variable to the shell running the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/noxstellar/spine-releases/main/install.sh \
  | SPINE_VERSION=0.2.1 sh
```

The public installer currently targets Apple Silicon macOS. Runtime reports go
under `$XDG_STATE_HOME/spine/runs` for `spine run`; the four-argument interface
takes an explicit report path outside the workspace. Configuration/state
directories cannot be inside the model workspace. Neither the installer nor
Spine setup automatically edits your shell profile.

### Internal worker variables

`SPINE_WORKER_UID`, `SPINE_WORKER_GID`, `SPINE_TOOL_LEASE_SECS`,
`SPINE_WORKSPACE_SERVER_SHA256` and `SPINE_CACHE_ROOT` are set by the native
tool host for its worker supervisor. They are **not user-facing host override
settings**. Test-fixture markers and evaluation-script variables are likewise
not product configuration. SDK applications can configure ports and retrieval
directly through Rust types; no environment variable is implied by every field.

## Examples

### Small local task with explicit spending limits

```sh
spine setup --provider ollama --model qwen3:8b
SPINE_MAX_STEPS=8 SPINE_MAX_TOOLS=6 SPINE_RUN_TIMEOUT_SECS=120 \
SPINE_MAX_OUTPUT_TOKENS=2048 \
SPINE_REQUEST_LIMITS='{"max_requests":8,"max_request_bytes":262144,"max_total_request_bytes":1048576,"max_total_output_tokens":16384}' \
spine run --mode direct /absolute/workspace 'Explain the configuration files'
```

DIRECT has no children. AUTO can also finish a small task directly without a
classification call, while retaining the ability to delegate.

### Complex task using AUTO

```sh
spine setup --provider ollama --model kimi-k3.1-pro:cloud
SPINE_MAX_STEPS=64 SPINE_MAX_TASKS=16 SPINE_MAX_DEPTH=4 \
SPINE_MAX_TOOLS=48 SPINE_RUN_TIMEOUT_SECS=600 \
spine run --mode auto /absolute/workspace \
  'Reconcile the supplied evidence, investigate contradictions, and write a cited report'
```

This uses the gateway's default effort. To choose effort, add a value the gateway
and model actually support. Every child shares this run's existing limits.
Longer goals should use the 0.3 development goal interface after its release
qualification, rather than setting arbitrary enormous per-run limits.

### Explicit OpenAI Responses configuration for a raw binary

With `SPINE_API_KEY` already provisioned in the process environment:

```sh
export SPINE_MODEL_ENDPOINT=https://api.openai.com/v1/responses
export SPINE_MODEL_API=responses SPINE_MODEL=gpt-6.1-sol
export SPINE_DECISION_FORMAT=native SPINE_MODEL_HISTORY=snapshot
export SPINE_SNAPSHOT_TRANSPORT=state SPINE_REASONING_EFFORT=high
# Use an ACP client supplying the tools; this example needs no Docker worker.
SPINE_NATIVE_TOOLS=0 /absolute/path/to/spine acp
```

### Optional trace review (0.3 development)

```sh
SPINE_TRACE=summary spine run /absolute/workspace 'your task'
spine trace /outside/workspace/report.json.trace.jsonl
spine trace /outside/workspace/report.json.trace.jsonl --html /outside/workspace/trace.html
```

Use the report location printed by your invocation. Tracing defaults off.
`details` adds bounded public previews; a graph shows observed execution, not
proof that the task's answer is correct. Trace storage is bounded to 8 MiB /
10,000 records; a row is at most 16 KiB and individual previews at most 2,048
bytes. These are compiled bounds, not additional environment settings.

## Scope and source audit

The inventory was checked against the active launcher, Rust host, role expansion,
request-accounting adapter, goal types/driver, ACP configuration, retriever,
installer and native worker supervisor. Provider defaults come from
`rust/release/spine.sh`; ordinary run settings from `rust/host/mod.rs`; provider
encoding from `rust/src/model.rs` and `rust/src/model/responses.rs`; goal defaults
from `rust/host/goals/types.rs`; context bounds from `rust/src/context.rs` and
`rust/examples/live_support/mod.rs`. These are source locations for maintainers,
not extra configuration files users need to create.

The v0.2.1 tag was inspected to separate the new `SPINE_GOAL_DRIVE` and
`SPINE_TRACE` interfaces from released settings. Existing experimental workflow
settings remain available without retroactively upgrading the old trial results.
No model requests were needed for this documentation audit. Actual effective
settings and counters are retained in execution reports; provider usage can be
missing and model-declared progress remains distinct from accepted task results.
