# Spine

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

**Spine 0.2.1** adds AUTO execution, ACP clients, persistent sessions, external
MCP tools and local project memory.

Spine is a general-purpose AI agent harness written in Rust. Give it a goal and
access to the tools and information the work needs. It can work directly or
break a complex goal into smaller tasks, combine their results and continue.
Research synthesis, data analysis, operational workflows and coding use the
same execution core. The compiled core is distributed publicly; its source
repository stays private.

[Why Spine?](#why-use-spine) · [Install](#install) · [Setup](#set-up-once) · [Measurements](#qualification)

## Configuration and editors

The [complete configuration reference](CONFIGURATION.md) lists provider setup,
all runtime settings/defaults, reasoning effort, context, recursion and execution
limits, with examples. Effort is optional and provider-specific. The guide
clearly marks durable goals, optional lifetime caps and traces as **unreleased
0.3 development**, separate from the installed v0.2.1 behavior.
New goals default to continuous supervision with no overall cap; individual
work periods remain bounded and unanswered questions stay pending.
A real Kimi goal trial completed three instructed work periods, waited for an
answer without model calls, resumed and passed independent artifact checks:
10 requests in 57.485 seconds. See [the goal guide](GOALS.md) for the evidence
scope; this small result does not establish week-scale reliability or peer parity.
See [editor integration](EDITORS.md) for VS Code and IntelliJ/JetBrains via ACP;
there is no Spine-branded editor extension or completed GUI qualification yet.

Development also includes opt-in consumer assessment: a parent can reject a
child result and resume that child for correction before using its output.
Development also adds [native adaptive goal review](GOALS.md#adaptive-verification-03-development):
optional child escalation and required judgment of complete goal candidates.
Its integrated controls pass child repair, question/restart and short-answer
resumption. It is unreleased, remains off by default and still needs live task
efficacy evaluation; see [the measured scope](GOALS.md#adaptive-verification-03-development).
The experimental assignment encoder targets
repeated prompt text, with live token and speed gains unproven. Both switches and
their defaults are documented in [configuration](CONFIGURATION.md).

A small frozen Kimi reviewer study caught four seeded incorrect candidates and
supported four correct ones, including changed evidence and a misleading source
note. Independent grading confirmed useful correction guidance. It used eight
calls, 13,970 input / 5,952 output tokens and 64.567 seconds summed request time.
This is unreleased factual-review evidence; actual repairs and whole-task
reliability gains still need measurement. Verification remains opt-in.

A subsequent live adaptive task produced correct artifacts but exhausted its
12-request cap before reviewed completion. It exposed an evidence-format/feedback
defect; the corrected source passes 1,069 default / 1,605 all-feature test
invocations and the scripted CLI lifecycle control. The original failure remains
recorded. These checks do not establish whole-task reliability gains or justify
a default change; see [the current goal workflow](GOALS.md#adaptive-verification-03-development).

Development also adds an opt-in [provider-failure setting](GOALS.md#provider-failures-03-development)
that retains unfinished work and spending after a server error. Its actual CLI
control makes zero additional requests while waiting or after restart. Existing
operator recovery is still required; automatic provider resumption and a default
change are not included.

## Why use Spine?

**Choose Spine when you want a recursive agent inside your own application or
workflow, with your choice of supported model and tools.** Its focus is scoped
child tasks, explicit results returned to the parent, and one set of limits for
the whole run. The same machinery handles research, operations and coding.

### The core: recursive call and return

Spine represents a run as an explicit stack of task frames. A parent can hand a
scoped assignment to a child and wait. That child uses tools or delegates again;
when it finishes, the parent resumes with a structured record:
`result`, `artifacts`, `validation` and `unresolved`. The original goal and
constraints stay available throughout the tree.

For long work, this separates **local investigation from overall coordination**.
The child uses its own working history; the parent receives its findings and
artifact references rather than the full investigation transcript. A review of
source claims can stay separate from writing a recommendation, while the parent
remains responsible for integrating the answer. AUTO decides where to split at
run time and can keep a small task direct.

This is most useful when a goal contains parts with clear inputs and checkable
outputs: research synthesis, reconciling several datasets, incident analysis or
changes across code modules. If every part needs the same shared detail, a split
can lose context or repeat work. Task design and the model still matter.

| What you need | What Spine gives you | Evidence today |
| --- | --- | --- |
| Break complex work into focused investigations | A child works with its own context and returns findings, artifacts, validation and unresolved issues; the parent integrates the result. | Earlier v0.2.1 research and operations AUTO both passed with real child work; the newer pilot used a child for operations only. |
| Put an agent into an existing system | ACP sessions plus multiple MCP servers connect your application, company RAG and approved actions. | Installed-binary checks cover client tools, stdio/HTTP MCP and session reload. |
| Keep delegation within a controlled run | Children share request, tool, time and task limits; their tool scopes cannot widen ancestor permissions. | Accounting and scope controls are tested; live AUTO runs retain child usage in their totals. |
| Stay in control during longer work | In-flight steering, persistent ACP sessions and inspectable execution reports; uncertain interrupted effects are not automatically replayed. | Installed-binary steering, cancellation and no-replay checks pass. |

For example, ask for a recommendation from supplied research sources. A child
can audit calculations and source claims, then return its findings to the parent
writing the recommendation. For an incident plan, the parent can draft the plan
and delegate a review against the original records. Both workflows were observed
in the earlier v0.2.1 AUTO runs. Deeper trees are supported, but those runs used one
child each; they do not prove a benefit from deeper recursion.

### Does that make long work more reliable?

Spine's execution controls are tested: descendants keep shared limits, scopes
cannot widen, and uncertain interrupted effects are not automatically replayed.
Those controls make a run bounded and inspectable. **Higher answer reliability
than Codex or Claude Code has not been demonstrated.** A structured review can
still be wrong, and a few selected task instances are not a reliability rate.

Parent resumption after child completion is part of the recursive runtime.
ACP session reload restores retained conversation, not an interrupted task tree;
an uncertain unfinished turn blocks new work. Long work still needs explicit
limits and review of its recorded results.

### How does it compare with Codex and Claude Code?

Both [Codex](https://learn.chatgpt.com/docs/agent-configuration/subagents) and
[Claude Code](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)
also support delegation. Recursion is not exclusive to Spine. Choose Spine for
the combination of configurable providers, ACP/MCP integration, explicit recursive
handoffs and shared execution limits when that fits your system.

**There are measured benefits, with specific limits:**

| Measured comparison | Benefit observed | Tradeoff / scope |
| --- | --- | --- |
| Four-task development pilot, delegation enabled for all three harnesses | Spine AUTO accepted **3/4**, peers **2/4 each**; Spine covered every peer-passed instance. | Only two jointly accepted pairs per peer. AUTO used 9.75% fewer input tokens than Codex but 10.47% more than Claude by geometric mean, missing the fixed 10% improvement threshold; it was slower on both tasks. |
| Two earlier Python coding tasks: Spine DIRECT vs Codex DIRECT | Both tasks accepted; Spine used **29.4% fewer input tokens and 17.9% fewer output tokens**. | Historical Rust 0.1.0 qualification binary, not current AUTO. Claude used fewer input tokens than Spine. The third, harder task failed in all three harnesses. |
| Research: v0.2.1 AUTO vs Spine DIRECT | Both accepted; AUTO used **9.4% fewer input tokens** and 10 rather than 12 tool calls. | Output tokens rose 8.5%; requests stayed at 13 and elapsed time was similar. |
| Operations: v0.2.1 AUTO vs Spine DIRECT | AUTO **performed a real child review and passed**; DIRECT failed for claiming an independent review that had not occurred. | Both produced correct artifacts. AUTO used 16 rather than 10 requests and took 216.7 rather than 150.1 seconds. |

These are separate studies with one attempt per condition, using GPT-6.1 Sol
with high effort requested. Token counts are not monetary costs. The newest
pilot enabled peer delegation; only Spine AUTO's operations run actually used
a child. Its common gateway preserved public history and excluded private
reasoning for every harness, so it does not compare unrestricted vendor defaults.
The earlier v0.2.1 research/operations study disabled peer delegation and retains
its separate citation-check correction. **General superiority or full parity
with Codex/Claude Code is not established.** See the
[measurements and conditions](#qualification).

Current tradeoffs: children run sequentially, public binaries target Apple Silicon
macOS, source is private, and live-web research needs external search tools.
If those constraints conflict with your workflow, the evidence does not justify
switching from a harness that already meets your needs.

## Install

**Apple Silicon macOS.** For the default native tools, install and start
[Docker](https://docs.docker.com/desktop/setup/install/mac-install/). ACP clients
using external tools can skip Docker. Install Spine:

```sh
curl -fsSL https://raw.githubusercontent.com/noxstellar/spine-releases/main/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

No Rust toolchain, GitHub login or administrator access is needed for the CLI.
The installer verifies checksums and installs under `~/.local`. Add that PATH line
to your shell profile to make the command available in future terminals.

## Set up once

```sh
spine setup
```

Choose a provider and model. Default setup downloads the pinned Rust/Python worker once
(542 MB) and asks for an API key with hidden input when needed. Settings and keys
are stored in a private user configuration file, outside your project. Setup
makes no model requests. Run it again to switch providers.

Or select a provider directly:

```sh
# Local Ollama: use a tool-capable model shown by `ollama list`.
spine setup --provider ollama --model qwen3:8b

# OpenAI: enter your API key when prompted.
spine setup --provider openai --model gpt-6.1-sol

# Claude through OpenRouter: enter an OpenRouter key.
spine setup --provider openrouter --model anthropic/claude-sonnet-4
```

[Ollama](https://docs.ollama.com/api/openai-compatibility) runs locally without an
API key; cloud models through its local server require Ollama sign-in.
[OpenAI](https://developers.openai.com/api/docs/quickstart) uses the Responses API.
[OpenRouter](https://openrouter.ai/docs/quickstart) provides Claude through an
OpenAI-compatible endpoint. Direct Anthropic Messages is not supported.
Model access depends on your provider account; examples are not quality guarantees.

## Run

```sh
spine run ./research "Compare the supplied proposals and write a sourced recommendation"
spine run ./incident "Reconcile the metrics and produce a safe recovery plan"
spine run ./my-project "Find and fix the failing tests, then verify the fix"
```

Type a new instruction and press Enter to steer an active run. Reports are saved
outside the workspace. Review the changes before merging. The Docker worker has
no network; install project dependencies in your workspace beforehand when needed.

Use `spine --help` for custom endpoints, Docker contexts and the original task-file
interface. Re-run the installer to update to the latest official release.

## Recursive work and native tools

A child task can delegate again within shared depth, task, time and provider
limits. Each child receives a focused assignment, explicit inputs and the original
goal, then returns its result, artifact references, observed validation and
unresolved issues. Its parent resumes to integrate and check the work. Parent and
sibling transcripts are not inherited wholesale; workspace files remain shared.

For research, a platform comparison might split into search quality, cost and
access-control investigations, with a child examining conflicting source claims.
For operations, children can reconcile metrics and check a recovery schedule.
Coding uses the same mechanism for implementation, inspection and integration.
**v0.2.1 executes children sequentially**; recursion can improve task organization
but is no guarantee of better answers, lower cost or faster completion. AUTO
allows simple tasks to stay direct.

The native Docker tools list, read, search, write and edit files and run commands
as explicit argv arrays. Use Bash explicitly, such as `bash -lc`, when a shell is
needed. These tools calculate from local data and produce reports as well as
build and test code.
The worker has no network. Supply source files, or connect appropriate external
MCP search/RAG tools through ACP for web or company information.

## Execution modes and limits

The run interface is
`spine run [--mode auto|direct|recursive] WORKSPACE 'YOUR GOAL'`:

```sh
spine run ./work "Analyze the supplied records and deliver a checked report"
spine run --mode direct ./work "Summarize this incident timeline"
spine run --mode recursive ./work "Compare the supplied proposals, investigate tradeoffs and recommend a plan"
```

The default is **AUTO**, introduced in v0.2. The ordinary model chooses direct
actions or scoped child tasks, without a mandatory classifier or extra initial
model call. Direct disables delegation; recursive requires initial delegation
when tool work and available task capacity permit it. An explicit `--mode`
overrides `SPINE_EXECUTION_MODE`.

Children share `SPINE_MAX_STEPS` (default 64), `SPINE_MAX_TOOLS` (48), and
`SPINE_RUN_TIMEOUT_SECS` (600). AUTO/recursive also use `SPINE_MAX_TASKS`
(default 16, range 1–1024) and `SPINE_MAX_DEPTH` (4, range 1–64); direct keeps one
task at depth zero. `SPINE_REQUEST_LIMITS` caps shared provider requests, bytes
and reserved output tokens. Delegation and steering do not reset spent budgets.

### ACP, sessions and external tools

Configure an ACP client to launch `spine acp`, using the same private provider
setup as `spine run`. Stdout carries only the protocol. Docker remains the default;
to use tools supplied by the ACP client or external MCP servers without Docker:

```sh
spine setup --tools external
spine acp
```

External setup skips Docker downloads and inspection while retaining the provider,
model and hidden-key prompts. `spine setup --tools docker` prepares the worker.
The saved choice applies to runs and ACP; `SPINE_NATIVE_TOOLS=0|1` overrides it.
Old configurations keep the Docker default. Setup makes no model request.

An ACP session can connect multiple namespaced MCP tool servers over stdio or
Streamable HTTP, including external retrieval/RAG tools. Remote connections
require HTTPS; explicitly supplied loopback HTTP URLs are accepted. Legacy SSE
transport is not supported. The client can also supply file read/write and
terminal capabilities. External MCP calls and client operations request permission
before dispatch. They run under their client's or server's permissions, outside
the native Docker worker, and receive no native workspace verification receipt.

Sessions persist public messages and tool/progress updates, with separate run
reports, under `${XDG_STATE_HOME:-$HOME/.local/state}/spine/sessions` (directories
0700, files 0600). Provider credentials and MCP connection configurations are not
copied into session records; supply MCP configurations again on session load.
Records are bounded to 256 messages and 8 MiB, and public updates to 2 MiB per
turn. Model context includes a bounded snapshot of prior turns, with older records
available through `session.history`; current parent/sibling execution transcripts
are excluded. Uncertain interrupted effects block further execution and are never
automatically replayed on load.

Use your ACP client's session mode, load and cancel controls. Clients supporting
the advertised `_spine/steer` request can update an active turn with these params:

```json
{"sessionId":"YOUR_SESSION_ID","message":"Preserve the existing API"}
```

Steering keeps the same budgets. It accepts at most 64 messages per turn,
16 KiB per message and 64 KiB in total. Ordinary terminal runs still accept
steering lines on stdin.

### Project memory

```sh
spine memory init ./my-project
# Add or edit Markdown notes in ./my-project/.spine/memory/.
spine memory refresh ./my-project
spine memory search ./my-project "build and test commands"
```

Memory commands need neither provider setup nor Docker. Markdown remains the
source of truth; the local search index is disposable. Initialized workspaces
automatically use bounded embedded retrieval, unless
`SPINE_CONTEXT` overrides it. Project memory is separate from ACP conversation
history and does not infer or save new facts automatically.

## Versions

- **[v0.2.1](https://github.com/noxstellar/spine-releases/releases/tag/v0.2.1):**
  AUTO/recursive execution, ACP sessions, MCP and client tools, project memory;
  published with passing release and installed-runtime checks.
- **[v0.1.1](https://github.com/noxstellar/spine-releases/releases/tag/v0.1.1):**
  first automated Rust binary release with installer, provider setup and CI gates.
- **v0.2.0:** source tag retained after a macOS test-fixture startup failure;
  no public binary was published. v0.2.1 contains the fixture repair. Historical
  v0.2.0 candidate task evidence keeps its original identity.

Official releases use `vX.Y.Z` tags. The installer selects the latest official
release by default. To pin a version:

```sh
curl -fsSL https://raw.githubusercontent.com/noxstellar/spine-releases/main/install.sh | sh -s -- 0.2.1
```

The pipeline publishes a nightly prerelease after successful checks on each
private source `main` push. This trigger takes effect when the workflow is merged
into `main`; current official releases use the proven tag path. Nightlies are opt-in:
replace `0.2.1` above with a complete version from the
[release list](https://github.com/noxstellar/spine-releases/releases), such as
`0.2.1-nightly.20261115.42.1`. Versions and download assets are never overwritten.
Nightly checks establish build and test results, not new model benchmark results.

## Qualification

**Closed development pilot, 16 November:** Spine AUTO accepted lookup, research
and operations (**3/4**); Codex and Claude Code each accepted research and
operations (**2/4**). All three failed the workflow's complete delivery contract
within its frozen request cap. Spine DIRECT accepted both complex diagnostics
(2/2), excluded from the primary sample. Only AUTO operations used an actual
child review. All 14 attempts, including five failures, consumed 129 requests,
118 tools, 1,294,333 input / 72,132 output tokens and 1,259.403 summed seconds
including setup and cleanup.

Spine covered the union of peer-passed instances (**2/2**). On the two jointly
accepted pairs per peer, AUTO/peer input geometric means were **0.902463 versus
Codex** and **1.104696 versus Claude**. Neither met the fixed 10% improvement
threshold; AUTO was slower on both tasks than either peer. These four authored
instances do not establish general parity, production readiness or a broad
efficiency advantage.

This study used frozen development runtime `6ff0ba8`, not the v0.2.1 package or
the ongoing verification changes. Every harness used the same Sol model with
high effort requested, common public inputs/tools and bounded accounts. The
gateway sent full public history with `store=false`, omitting private reasoning;
native prompts, tool presentation and internal delegation limits remained
distinct. It was a controlled comparison, not unrestricted vendor defaults.
Original grades, a separately stopped permission-profile study, uniform generic
read-evidence corrections and independent acceptance supplements are retained.
The renewed first nine rows and five never-launched continuation rows form the
14 observations; no completed row was retried or replenished. The immutable
analysis SHA-256 is `5e815bf746d4101f26422231e78cad13ec60d829046d583d00851a6acc21412c`.

Public builds target macOS ARM64, with Docker as the default native tool host.
The published v0.2.1 release passed hosted checks, anonymous installation and
installed ACP/MCP/native-tool controls. The historical scoped Rust 0.1.0 same-model
DIRECT comparison covered all 67 comparator-passed checks. Two separately frozen
v0.2 AUTO coding tasks passed all 59 historical Python target groups with actual
child delegation and independent acceptance. Their original candidate identities
remain unchanged; the published binary has separate installation/runtime evidence.

These results are limited to the recorded tasks and conditions. They do not
establish matched AUTO peer parity, broad harness parity or reliability. Automated
build and protocol checks alone do not prove model task competence.

<!-- GENERAL_TASK_RESULTS_START -->
**AUTO completed both complex tasks with actual delegation:** research synthesis
and operational analysis each used one child at depth one and passed independent
artifact review. The operations parent wrote its outputs, had a child review them
against the original records, received that review, and validated the final files.

| Harness / mode | Research synthesis | Operational analysis |
| --- | --- | --- |
| Codex DIRECT | Pass | Pass |
| Claude Code DIRECT | Pass | Pass after citation-check repair¹ |
| Spine DIRECT | Pass | Fail: unsupported independent-review claim |
| Spine AUTO | Pass; one child | Pass; one child |

¹ The original checker rejected valid grouped citations and real action IDs.
Its failed grade is retained; a separately reviewed offline correction was applied
to all four operations outputs. Original acceptance was 6/8; adjudicated acceptance
is 7/8. Spine DIRECT's real reporting failure remains disqualifying.

Every row used GPT-6.1 Sol/high and a common bounded tool bridge; Spine used the
published v0.2.1 binary. The research task used a frozen real-source packet; operations
used synthetic records. This was not live-web research. The study allowed 8,192
output tokens per call (the CLI default is 4,096). DIRECT disabled peer delegation;
the two AUTO rows are separate within-Spine observations, not matched peer AUTO
parity or a general quality, speed or cost advantage.
<!-- GENERAL_TASK_RESULTS_END -->

<details>
<summary>Measured usage, historical coding comparison and evaluation conditions</summary>

**Research and operations, published v0.2.1 (15 November 2026):**

| Task | Harness / mode | Requests | Tools | Input tokens | Output tokens | Seconds |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Research | Codex DIRECT | 10 | 9 | 196,532 | 14,478 | 238.0 |
| Research | Claude Code DIRECT | 9 | 11 | 151,170 | 13,730 | 253.5 |
| Research | Spine DIRECT | 13 | 12 | 223,923 | 14,384 | 249.2 |
| Research | Spine AUTO | 13 | 10 | 202,955 | 15,607 | 251.6 |
| Operations | Codex DIRECT | 9 | 8 | 154,873 | 10,606 | 152.7 |
| Operations | Claude Code DIRECT | 9 | 9 | 128,592 | 9,102 | 119.7 |
| Operations | Spine DIRECT (failed) | 10 | 9 | 130,468 | 10,994 | 150.1 |
| Operations | Spine AUTO | 16 | 13 | 209,790 | 18,029 | 216.7 |

Spine used the installed v0.2.1 binary; comparator clients were Codex
0.164.0-alpha.11.1 and Claude Code 2.1.319. The common limits were 32 requests,
64 workspace calls, 900 seconds and 8,192 output tokens per call. AUTO shared
these limits across at most 16 tasks/depth four. Each observed AUTO run used
one child at depth one. Provider settings were GPT-6.1 Sol/high; the provider
does not expose an immutable model digest. Client prompts/history formats
remain part of each harness. Peer delegation was disabled in DIRECT.

**Earlier Python coding tasks, historical Rust 0.1.0 qualification binary:**

All three DIRECT harnesses accepted both `dependency_plan` and `layered_config`
tasks and all 59 target groups under matched Sol/high conditions. Totals for
those two tasks:

| Harness, DIRECT | Requests | Tools | Input tokens | Output tokens |
| --- | ---: | ---: | ---: | ---: |
| Codex | 16 | 14 | 150,073 | 12,253 |
| Claude Code | 13 | 11 | 50,759 | 11,177 |
| Spine | 15 | 13 | 106,011 | 10,059 |

Spine used 29.36% fewer input and 17.91% fewer output tokens than Codex.
Against Claude, it used 10.00% fewer output tokens but 108.85% more input tokens.
The third, harder Rust task failed in all three harnesses. These older DIRECT
results do not establish an advantage for current AUTO.

**Evidence scope:** each row is one attempt, with no retries or budget resets.
Project-reported acceptance combines mechanical checks and separate independent
assistant reviews of artifacts and evidence; it is not third-party certification.
Full traces, assessors and reference solutions remain private. Counts are reported
usage, not invoices or reliability estimates. Different release/policy cohorts
are not combined into a single success rate.

</details>

Public packages include setup scripts, runtime helpers and third-party notices;
they do not contain the Rust source checkout or internal benchmark evidence.

## License

Spine is proprietary software. The [binary-use license](LICENSE) permits free
personal and internal business use of official builds. Bundled dependencies
retain their own licenses in `THIRD_PARTY_NOTICES` and the worker image.
