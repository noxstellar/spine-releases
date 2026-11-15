# Spine

**Spine 0.2.1** adds AUTO execution, ACP clients, persistent sessions, external
MCP tools and local project memory.

Spine is a general-purpose AI agent harness written in Rust. Give it a goal and
access to the tools and information the work needs. It can work directly or
break a complex goal into smaller tasks, combine their results and continue.
Research synthesis, data analysis, operational workflows and coding use the
same execution core. The compiled core is distributed publicly; its source
repository stays private.

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

[Codex has subagent workflows](https://learn.chatgpt.com/docs/agent-configuration/subagents),
and [Claude Code has nested subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents).
Spine emphasizes a Rust runtime that can be embedded through ACP/MCP, explicit
return/resume behavior and shared execution limits. Those design choices do not
establish superiority; measured task results are scoped below.

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

One attempt per row used GPT-6.1 Sol/high, the published v0.2.1 binary and a common
bounded tool bridge. The research task used a frozen real-source packet; operations
used synthetic records. This was not live-web research. The study allowed 8,192
output tokens per call (the CLI default is 4,096). DIRECT disabled peer delegation;
the two AUTO rows are separate within-Spine observations, not matched peer AUTO
parity or a general quality, speed or cost advantage.
<!-- GENERAL_TASK_RESULTS_END -->

Public packages include setup scripts, runtime helpers and third-party notices;
they do not contain the Rust source checkout or internal benchmark evidence.

## License

Spine is proprietary software. The [binary-use license](LICENSE) permits free
personal and internal business use of official builds. Bundled dependencies
retain their own licenses in `THIRD_PARTY_NOTICES` and the worker image.
