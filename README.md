# Spine

A Rust coding agent that reads, edits and tests your project in an isolated Docker worker.
The compiled core is distributed here; its source repository stays private.

## Install

**Apple Silicon macOS.** Install and start [Docker](https://docs.docker.com/desktop/setup/install/mac-install/), then:

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

Choose a provider and model. Setup downloads the pinned Rust/Python worker once
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

## Versions

Official releases use `vX.Y.Z` tags. The installer selects the latest official
release by default. To pin a version:

```sh
curl -fsSL https://raw.githubusercontent.com/noxstellar/spine-releases/main/install.sh | sh -s -- 0.1.1
```

Every push or merge to the private source repository's `main` branch runs the
checks and publishes a nightly prerelease after they pass. Nightlies are opt-in:
replace `0.1.1` above with a complete version from the
[release list](https://github.com/noxstellar/spine-releases/releases), such as
`0.1.1-nightly.20261115.42.1`. Versions and download assets are never overwritten.
Nightly checks establish build and test results, not new model benchmark results.

Public builds target macOS ARM64/Docker. The historical scoped Rust 0.1.0
same-model comparison covered all 67 comparator-passed checks; automated builds
do not establish new model benchmark results or broad parity.
Public packages include setup scripts, runtime helpers and third-party notices;
they do not contain the Rust source checkout or internal benchmark evidence.

## License

Spine is proprietary software. The [binary-use license](LICENSE) permits free
personal and internal business use of official builds. Bundled dependencies
retain their own licenses in `THIRD_PARTY_NOTICES` and the worker image.
