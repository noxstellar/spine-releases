# Spine

**Spine 0.2.1** adds AUTO execution, ACP clients, persistent sessions, external
MCP tools and local project memory.

A Rust coding agent that reads, edits and tests your project in an isolated Docker worker.
The compiled core is distributed here; its source repository stays private.

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
spine run ./my-project "Find and fix the failing tests, then verify the fix"
```

Type a new instruction and press Enter to steer an active run. Reports are saved
outside the workspace. Review the changes before merging. The Docker worker has
no network; install project dependencies in your workspace beforehand when needed.

Use `spine --help` for custom endpoints, Docker contexts and the original task-file
interface. Re-run the installer to update to the latest official release.

## Execution modes and limits

The run interface is
`spine run [--mode auto|direct|recursive] WORKSPACE 'YOUR GOAL'`:

```sh
spine run ./my-project "Implement the change and verify the affected behavior"
spine run --mode direct ./my-project "Fix the focused test failure"
spine run --mode recursive ./my-project "Complete the scoped implementation plan"
```

The default is **AUTO**, changed from direct in v0.1.1. The ordinary model chooses direct
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

Public builds target macOS ARM64, with Docker as the default tool host. The
historical scoped Rust 0.1.0 same-model DIRECT comparison covered all 67
comparator-passed checks. Two separately frozen v0.2 AUTO tasks passed all 59
historically successful Python check groups, with actual subagent delegation and
independent acceptance. These are not a matched AUTO parity comparison. Automated
builds do not establish model task competence or broad parity.
Public packages include setup scripts, runtime helpers and third-party notices;
they do not contain the Rust source checkout or internal benchmark evidence.

## License

Spine is proprietary software. The [binary-use license](LICENSE) permits free
personal and internal business use of official builds. Bundled dependencies
retain their own licenses in `THIRD_PARTY_NOTICES` and the worker image.
