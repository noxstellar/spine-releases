# Spine in VS Code and IntelliJ

> **Version scope:** This public copy preserves the guide’s release and development labels. Features marked unreleased are not available in an older installed binary. Private-source links require repository access.

Spine can run as the agent behind an editor's **ACP client**. The Rust process
owns the task and model connection; the editor supplies chat, file and terminal
tools, permission prompts and session UI. Use the same provider setup as the CLI.
Spine does not currently publish its own VSIX or JetBrains Marketplace plugin.

Public v0.2.1 includes ACP v1, session persistence, modes and client tools.
The configurations below follow the clients' published documentation, checked
on 16 November 2026. Spine's protocol has automated integration coverage; these
specific editor GUIs have not yet been qualified end to end. Published binaries
currently target Apple Silicon macOS.

## Configure Spine once

```sh
# No Docker is needed when the editor provides files/terminals or MCP tools.
spine setup --provider ollama --model qwen3:8b --tools external

# Alternative: setup asks privately for the API key.
spine setup --provider openai --model gpt-6.1-sol --tools external
command -v spine
```

Use the absolute path printed by `command -v spine` below. GUI applications may
not inherit your shell's PATH. Start the installed **launcher**, which loads the
saved profile, rather than its internal `spine-core` executable. Keep credentials
in the launcher profile; the examples need no API key in editor settings. See
[configuration](CONFIGURATION.md) for profiles, endpoints and effort.

## IntelliJ IDEA and other JetBrains IDEs

Install/enable JetBrains AI Assistant. In AI Chat, choose **Add Custom Agent** and
add this entry to `~/.jetbrains/acp.json`, preserving any existing entries:

```json
{
  "agent_servers": {
    "Spine": {
      "command": "/absolute/path/to/spine",
      "args": ["acp"],
      "env": { "SPINE_NATIVE_TOOLS": "0" }
    }
  }
}
```

Select Spine in AI Chat. If needed, enable **Pass custom MCP servers** or
**Pass IntelliJ MCP server** under Settings → Tools → AI Assistant → Agents.
This exposes editor tools to Spine alongside the standard ACP client tools.
JetBrains documents custom ACP agents as usable without a JetBrains AI service
subscription; your configured model provider still controls its own access and
charges. See [JetBrains' ACP instructions](https://www.jetbrains.com/help/ai-assistant/acp.html).

## Visual Studio Code

The [ACP Client extension](https://github.com/formulahendry/vscode-acp) supports
custom agent commands. Install it, open its ACP panel and add Spine, or merge
this into your **user** `settings.json`:

```json
{
  "acp.agents": {
    "Spine": {
      "command": "/absolute/path/to/spine",
      "args": ["acp"],
      "env": { "SPINE_NATIVE_TOOLS": "0" }
    }
  },
  "acp.autoApprovePermissions": "ask"
}
```

Open your project and connect to Spine. Use a new conversation for a new task;
restoring a saved session reuses its retained conversation. Permission decisions
remain in the client. Other ACP clients are listed in the
[protocol's client directory](https://agentclientprotocol.com/get-started/clients).

This uses Spine's own execution runtime and provider configuration. Adding a
Copilot custom-agent instruction file alone does not run Spine's Rust runtime.

## What the editor integration exposes

| Capability | Spine behavior |
| --- | --- |
| Coding tools | Editor file reads/writes and terminals, plus configured MCP tools; optional native Docker tools remain separately configurable. |
| Modes | `auto`, `direct` and `recursive`; mode changes require an idle session. |
| Model and effort | Configure the launcher/environment before startup. Spine does not yet expose an ACP model/effort picker. |
| Permissions | ACP client prompts for tool actions. Editor permission settings are separate from model settings. |
| Sessions | Load stored conversation and its tool results. An interrupted uncertain action is not silently retried. |
| Steering | Spine supports `_spine/steer`; a client's mid-run input UI must use that extension to steer a pending turn. Standard support alone does not establish this UI behavior. |
| Long-running goals | Unreleased 0.3 adds `_spine/goal`. Generic editor clients need explicit support to display its acceptance, questions and event controls; use the goal CLI until then. |
| Autocomplete | ACP task assistance does not provide inline next-token code completion. That would require separate editor integration. |

For a dedicated Spine plugin, keep it a thin ACP client: launch the installed
binary, use the editor's permission and diff interfaces, and add durable goal,
question/answer and trace views. The runtime, credentials and recursive execution
remain shared with the CLI. Marketplace publication and GUI qualification are
separate work from the currently supported protocol. The full wire contract is
documented in [ACP integration](ACP.md).
