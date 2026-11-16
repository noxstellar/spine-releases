# ACP integration

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

Spine v0.2.1 implements stable **Agent Client Protocol (ACP) v1** over
stdin/stdout. It uses the official Rust SDK pinned to `5.3.0` and the same
execution core, provider budgets, task policies and MCP adapters as the CLI.
The published package includes ACP and embedded project memory. Protocol and
lifecycle controls, together with the separate two-task AUTO qualification, are
recorded in [the integration release proof (private source)](https://github.com/noxstellar/spine/blob/9fd6ead1d43e4dde18927fc4592eccf3eda6e1c7/rust/proofs/2026-11-15-v0.2-integration/README.md).
Those two AUTO coding passes do not establish matched AUTO parity or broad reliability.
The separately frozen [general-purpose study (private source)](https://github.com/noxstellar/spine/blob/9fd6ead1d43e4dde18927fc4592eccf3eda6e1c7/rust/proofs/2026-11-15-general-tasks/README.md)
adds research/operations CLI evidence with explicit benchmark limits; it is not a
paid ACP trial.

Development toward 0.3 is tracked in [the next release plan (private source)](https://github.com/noxstellar/spine/blob/9fd6ead1d43e4dde18927fc4592eccf3eda6e1c7/rust/NEXT_RELEASE_PLAN.md).
The unreleased source now preserves a genuine model-declared root blocker as
`root_blocker: {task_id, reason}` in the private execution report and as bounded
text in the ACP final answer. That answer survives session reload and appears in
later-turn history. It is explicitly model-authored and does not grant permission
to resume. Cancellation/quota stop reasons and uncertain-effect fences retain
precedence. That blocker alone is not a typed question/answer API. The separate
unreleased [durable goal extension](GOALS.md#acp-integration) adds explicit
questions, event waits, optional shared lifetime limits, explicit completion
acceptance and continuous session supervision; it is
under qualification. The published v0.2.1 binary retains its earlier generic
safe-failure message and does not advertise the goal extension.

The unreleased host also accepts `SPINE_TRACE=1` or `details` in its environment
for [optional local execution traces](TRACING.md). Each invocation writes beside
its private report; `spine trace` reviews the graph and timeline offline without
adding protocol messages to stdout.

## Start the agent

Configure the installed launcher once, then let the editor or application spawn
`spine acp`. Provider keys use hidden terminal input or an already provisioned
`SPINE_API_KEY`; keep them out of arguments and workspace files.

```sh
# Native coding tools: requires Docker and prepares the pinned worker.
spine setup --provider ollama --model qwen3:8b
spine acp

# An integration that supplies tools through ACP/MCP can skip Docker entirely.
spine setup --provider openai --model gpt-6.1-sol --tools external
spine acp
```

Use a model actually available from your provider. Ollama Cloud models use the
signed-in Ollama gateway; the local model route requires a locally pulled model.
`--tools external` saves the integration's tool choice. `SPINE_NATIVE_TOOLS=0`
or `1` overrides that choice for a process. Setup makes no model calls. The
launcher also supports OpenRouter and custom OpenAI-compatible endpoints; the
native Anthropic API is not implemented.

For a source build, enable `acp` and optionally `embedded-rag`:

```sh
cd rust
cargo build --release --features acp,embedded-rag --bin spine
# Configure SPINE_MODEL, SPINE_MODEL_ENDPOINT and SPINE_MODEL_API, and the key
# in the process environment. The direct binary does not read launcher profiles.
SPINE_NATIVE_TOOLS=0 target/release/spine acp
```

`SPINE_MODEL_ENDPOINT` is the complete Responses or Chat Completions URL;
`SPINE_MODEL_API` is `responses` or `chat_completions`. Native Docker execution
additionally needs the configured worker image and Docker context. Prefer the
installed setup flow for that configuration. Logs use stderr; stdout contains
only newline-delimited JSON-RPC. ACP does not implement a separate login or
credential-entry protocol: configure the provider before starting the process.

## Connection and session flow

Initialize once with protocol version `1` and the client's actual file-system
and terminal capabilities. Then use the following methods. Wire message shapes
follow the [official initialization specification](https://agentclientprotocol.com/protocol/v1/initialization)
and [session specification](https://agentclientprotocol.com/protocol/v1/session-setup).

| Method | Spine behavior |
| --- | --- |
| `initialize` | Negotiates v1; advertises session loading/closing, embedded context and HTTP MCP. Images, audio and SSE are unsupported. |
| `session/new` | Creates a private session for an existing absolute `cwd`; defaults to `auto`. Accepts client MCP descriptors. |
| `session/load` | Acquires the saved session, validates the same canonical workspace, replays public history before responding, and accepts fresh MCP descriptors. |
| `session/prompt` | Runs one bounded ordinary turn and returns its actual stop reason after cleanup and final updates. Unreleased attached goals supervise successive periods and waits until accepted/cancelled. |
| `session/cancel` | Cancels the active turn without replaying or refunding charged work. |
| `session/set_mode` | Selects `auto`, `direct` or `recursive` while idle. Cancel an active turn before changing mode. |
| `session/close` | Cancels active work, waits for bounded cleanup and releases session ownership. |
| `session/update` | Agent notifications carry public assistant text and tool states/results. Tool IDs remain unique across turns. |

A session already loaded by this connection must be closed before loading it
again. Another process cannot load it while its ownership lock is held.
Additional workspace roots and system-prompt overrides are rejected. There is
no session listing, fork, ACP resource server, rich plan stream, image/audio
input, private-reasoning stream or ACP v2 implementation. Text, resource links
and embedded text resources are accepted. Binary embedded resources are
rejected before execution. Links and resource metadata are provided as data,
with no automatic URI fetch.
MCP tool results can supply RAG data; Spine does not itself subscribe to MCP
resource changes or expose MCP resources/prompts as additional agent tools.

`auto` lets the model work directly or delegate bounded subtasks. It does not
require a separate classifier model. `direct` disables delegation;
`recursive` starts with coordination. Children share the turn's step, tool,
depth, task, time and provider-request limits. Each new prompt is a new turn;
loading a session does not silently resume a failed execution checkpoint.

## Steering an active turn

The `initialize` response advertises the `_spine/steer` extension in
`agentCapabilities._meta["com.spine.steering"]`. Send it as a JSON-RPC request:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "_spine/steer",
  "params": {
    "sessionId": "SESSION_ID_FROM_NEW_OR_LOAD",
    "message": "Preserve the public interface and add a regression check."
  }
}
```

The response is `{"accepted":true}` when queued. The existing runtime applies
updates at safe decision boundaries and reports applied revisions as public
progress. The exact accepted text is durably stored as public user content
before it is queued, so load replay and later turns retain the correction even
if the current turn finishes before applying it. Acceptance does not mean an in-progress external effect can be
undone. A turn accepts at most 64 messages and 64 KiB of steering text, with
16 KiB per message. Empty messages, inactive sessions and full queues are
rejected. A concurrent ordinary `session/prompt` is rejected as busy; clients
must use this advertised extension for in-flight steering or cancel and submit
a new prompt. These semantics complement the standard
[prompt/cancellation lifecycle](https://agentclientprotocol.com/protocol/v1/prompt-turn).

## Client MCP and RAG tools

Supply MCP servers in `session/new` and supply them again in `session/load`.
Descriptors are process memory only: commands, environment credentials and HTTP
headers are not stored in session transcripts. For example, the relevant
`session/new` parameters can be:

```json
{
  "cwd": "/absolute/project",
  "mcpServers": [
    {
      "name": "project_rag",
      "command": "/absolute/path/to/rag-mcp-server",
      "args": ["--stdio"],
      "env": [{"name": "RAG_TOKEN", "value": "REPLACE_IN_CLIENT_SECRET_STORE"}]
    },
    {
      "type": "http",
      "name": "knowledge",
      "url": "https://mcp.example.invalid/mcp",
      "headers": [{"name": "Authorization", "value": "Bearer REPLACE_IN_CLIENT_SECRET_STORE"}]
    }
  ]
}
```

The placeholders above are not usable credentials. Have the embedding client
resolve its own secrets when constructing the request. For a deliberately
local HTTP server, use an explicit loopback URL such as
`http://127.0.0.1:4312/mcp`; other remote endpoints require HTTPS. Streamable HTTP
supports the existing transport's session lifecycle and bounded shutdown. SSE
transport is unsupported. Connection errors omit supplied headers and URLs.

At most 16 client servers and 128 KiB of serialized MCP configuration are
accepted. Names must be unique, 1–64 ASCII letters, digits, `_` or `-`.
`workspace`, `client` and `session` are reserved. Tool names are routed as
`SERVER_NAME.TOOL_NAME`, so several servers may expose the same raw tool name.
Stdio commands must be absolute and run directly, without an added shell, in
the session workspace. They receive the supplied environment plus a small
process-runtime allowlist; they do not inherit Spine's provider keys.

MCP server startup is client configuration, not a model-selected command.
Client-supplied stdio servers execute under the host account. Their own tools
may reach systems outside the workspace. The native Docker worker's sandbox
does not cover those servers or remote services.

## Permissions, client files and terminals

Spine emits pending tool updates, requests approval for external/client and
effectful native operations, then emits progress and observed results. Only
the exact `allow-once` choice grants approval; a cancelled, denied or unknown
choice does not dispatch the operation. Known native read-only tools and the
session-history reader omit a permission prompt. An external MCP server cannot
make itself privileged by claiming a read-only annotation.

When advertised by the client, `client.read`, `client.write` and `client.run`
use ACP file/terminal callbacks. File reads can therefore see the editor's
unsaved buffer. Paths are scoped to the session workspace and rechecked at
dispatch after permission. Terminal arguments remain literal; the integration
owns terminal execution and its security boundary. Created terminals are
released after completion, or killed and released during cancellation; release
is still attempted when kill times out. See the official
[permission/tool-call rules](https://agentclientprotocol.com/protocol/v1/tool-calls),
[file callbacks](https://agentclientprotocol.com/protocol/v1/file-system) and
[terminal lifecycle](https://agentclientprotocol.com/protocol/v1/terminals).

Provider/tool cancellation returns through the execution state machine; it
does not abort and discard the running core step. A known result is retained
even if cancellation arrives at the same time. Safe cancellation and a lost
client connection can be followed by loading the session and starting a new
turn. An unknown tool outcome, incomplete cleanup or failed durable storage
keeps the old turn fenced: further prompts are refused, retained artifacts
remain available for inspection, and the operation is never retried
automatically. Cancellation still returns `cancelled`; it is not a success
claim. Session close and disconnect cleanup share a 90-second outer deadline for
all four concurrent turns; this does not extend their execution or provider
budgets. A dispatched native container create gets up to 30 seconds to settle
before cancellation cleanup. Owned cleanup has one 10-second deadline, with a
five-second emergency fallback. Recovery removes only a full container ID bound
to the attempt's ownership label. Unconfirmed creation or removal retains the
private ownership descriptor and session fence; the deadline does not establish
that an uncertain Docker operation left no resource behind. These rules implement
the [ACP cancellation contract](https://agentclientprotocol.com/protocol/v1/cancellation)
while preserving Spine's stronger execution-accounting requirements.

## Persistence, memory and limits

Public sessions live under `$XDG_STATE_HOME/spine/sessions`, or
`~/.local/state/spine/sessions`. Directories are `0700`; records, ownership locks
and public update journals are `0600`. Session IDs are generated UUIDs. Storage
rejects unsafe permissions, symlinks, hard-linked artifacts and workspaces that
overlap private session or Spine credential directories. A turn's pending
marker is persisted before execution begins. Progress is journaled before it
is sent to the client, enabling replay after a disconnect without duplicating
the final answer. Provider credentials and client MCP descriptors are excluded;
user messages and returned tool content remain the user's public conversation
data and should be treated accordingly.

The next turn gets bounded recent user/final messages and observed tool/progress
updates. Older public entries remain available through the model's paged
`session.history` tool, scoped to this session's prior turns. It accepts
`kind` (`message` or `update`), `index`, a UTF-8 byte `offset` and `max_bytes`
(1–16,384; default 8,192). It cannot read another session, arbitrary files,
credentials or private model reasoning.

Project memory is separate: `spine memory init PROJECT` creates Markdown memory
under `.spine/memory/`. `spine memory refresh PROJECT` rebuilds its disposable
SQLite FTS index in `.spine/cache/`; `spine memory search PROJECT QUERY` searches
without a provider. With the `embedded-rag` feature and an initialized memory
directory, the host can retrieve that memory into workspace context. Session
transcripts are not automatically copied into project memory. RAG supplied by
an external system can instead stay entirely behind that system's MCP tools.

| Bound | Limit |
| --- | --- |
| Loaded sessions per process | 32 |
| Concurrent prompt turns per process | 4 |
| Stored sessions | At most 1,024 entries; creation is serialized across processes |
| Public session record | 8 MiB and 256 user/final messages |
| Prompt/final message | 256 KiB, 1–64 content blocks |
| Public updates per turn | 2 MiB and 1,024 updates, reserving capacity for final output |
| Incoming JSON-RPC frame | 1 MiB, newline-delimited UTF-8 |

Input/output queues are bounded. A client that stops reading stdout is
disconnected after a five-second frame-delivery deadline; the pipe writer
cannot hold Tokio's blocking pool open during shutdown.

Limits reject additional work before starting it where possible; they do not
silently forget earlier turns or reset spent budgets. Start a new session when
its history is full. Execution/provider caps remain separately configurable
through the existing `SPINE_MAX_*`, timeout and request-limit settings.

The pinned SDK is documented at
[agent-client-protocol 5.3.0](https://docs.rs/agent-client-protocol/5.3.0/agent_client_protocol/),
with source in the [official Rust SDK repository](https://github.com/agentclientprotocol/rust-sdk).
The frontend follows the official [stdio transport](https://agentclientprotocol.com/protocol/v1/transports)
and [content formats](https://agentclientprotocol.com/protocol/v1/content).
