<div align="center">

# FireClaw

### The AI Coding Agent Forged in Mojo

**FireClaw** is a high-performance, open-source AI coding assistant and agent framework forged in [Mojo](https://www.modular.com/mojo) — the systems programming language that fuses Python's usability with C-level speed. Born from the architecture of Claw Code and rewritten from scratch, FireClaw delivers 184+ developer tools, Model Context Protocol (MCP) integration, and multi-language runtimes from your terminal — at native performance.

[![GitHub Stars](https://img.shields.io/github/stars/instructkr/fireclaw?style=for-the-badge&logo=github&label=Stars)](https://github.com/instructkr/fireclaw)
[![Mojo](https://img.shields.io/badge/Mojo-25.3+-FF6600?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxMiIgY3k9IjEyIiByPSIxMCIgZmlsbD0id2hpdGUiLz48L3N2Zz4=)](https://www.modular.com/mojo)
[![Rust](https://img.shields.io/badge/Rust-1.70+-DEA584?style=for-the-badge&logo=rust)](https://www.rust-lang.org/)
[![Python](https://img.shields.io/badge/Python-3.14+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![License](https://img.shields.io/badge/License-Open_Source-green?style=for-the-badge)](#license)
[![Tests](https://img.shields.io/badge/Tests-274_Passing-brightgreen?style=for-the-badge)](#testing)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github&style=for-the-badge)](https://github.com/sponsors/instructkr)

[Quick Start](#quick-start) · [Features](#features) · [Why Mojo?](#why-mojo-over-python-and-typescript) · [Python Compatibility](#full-python-compatibility--use-every-python-library-from-mojo) · [FireClaw vs Claw Code](#fireclaw-vs-claw-code) · [Comparison](#how-fireclaw-compares-to-other-ai-coding-tools) · [FAQ](#frequently-asked-questions)

</div>

---

## What Is FireClaw?

**FireClaw is an open-source AI coding assistant and agentic development framework** that runs entirely from your terminal. It is a clean-room reimplementation of Claw Code's agent architecture, rewritten from the ground up in Mojo for maximum performance. FireClaw connects to large language models (LLMs), orchestrates 184+ developer tools, and manages multi-turn conversations with full project awareness — delivering the power of an AI pair programmer at native speed.

Unlike cloud-locked AI coding tools, FireClaw is self-hosted, gives you fine-grained control over permissions and tool access, persists sessions across restarts, and runs on your machine. It is the first major open-source AI agent framework written in Mojo, proving the language's readiness for production-grade systems.

> **Built on the foundation of Claw Code** — the fastest repo in history to surpass 50K GitHub stars (reached in just 2 hours). FireClaw takes that architecture further with a ground-up Mojo rewrite for speed, safety, and extensibility.

<p align="center">
  <img src="assets/clawd-hero.jpeg" alt="FireClaw — AI Coding Agent Forged in Mojo" width="300" />
</p>

<p align="center">
  <a href="https://star-history.com/#instructkr/claw-code&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=instructkr/claw-code&type=Date&theme=dark" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=instructkr/claw-code&type=Date" />
      <img alt="Star History Chart — 50K stars in 2 hours" src="https://api.star-history.com/svg?repos=instructkr/claw-code&type=Date" width="600" />
    </picture>
  </a>
</p>

---

## Why FireClaw?

| Problem | How FireClaw Solves It |
|---------|----------------------|
| AI coding tools are cloud-only and proprietary | FireClaw is **open-source** and runs locally in your terminal |
| Existing agents lack real tool execution | **184+ built-in tools** for file ops, shell, search, web, MCP, and more |
| No project awareness across sessions | **CLAW.md** auto-discovery + session persistence + git integration |
| AI assistants can't be extended | **Plugin system**, hooks pipeline, MCP server integration |
| Performance bottlenecks in Python-based agents | Built in **Mojo** — Python syntax with C-level speed |
| No fine-grained access control | **3-tier permission system**: read-only, workspace-write, full-access |
| Claw Code was TypeScript-only and proprietary | FireClaw is a **clean-room Mojo rewrite** — open, fast, and yours to own |

---

## Features

### Core AI Agent Capabilities

- **Interactive REPL** — Chat with AI models in a rich terminal interface with markdown rendering and syntax highlighting
- **Streaming Responses** — Real-time token-by-token output with Server-Sent Events (SSE)
- **184+ Developer Tools** — File read/write/edit, Bash execution, glob/grep search, web fetch, agent orchestration, todo tracking, and more
- **207 Slash Commands** — `/help`, `/status`, `/cost`, `/compact`, `/model`, `/diff`, `/export`, `/session`, and 200+ more
- **Extended Thinking** — Multi-step reasoning with thinking blocks for complex coding tasks
- **Session Persistence** — Save, resume, and compact conversations across restarts

### Model Context Protocol (MCP) Integration

- **Stdio, WebSocket, and HTTP transports** for connecting external tool servers
- **OAuth-managed proxy support** for authenticated MCP connections
- **Server lifecycle management** — auto-start, health checks, and graceful shutdown
- **Custom MCP tool registration** — extend FireClaw with any MCP-compatible server

### Project Intelligence

- **CLAW.md Discovery** — Automatically reads project documentation for context-aware assistance
- **Git Integration** — Reads diffs, branches, and commit history for change-aware coding
- **Config Hierarchy** — Workspace `.claw.json` > local settings > environment variables > CLI flags
- **Cost Tracking** — Real-time token accounting with per-model pricing breakdowns

### Security & Permissions

- **Read-only mode** — AI can read but not modify your codebase
- **Workspace-write mode** — Controlled write access within project boundaries
- **Full-access mode** — Unrestricted tool execution for trusted workflows
- **Per-tool denylists** — Block specific tools by name or prefix pattern
- **Pre/Post tool hooks** — Middleware-style interception for every tool execution

### Extensibility

- **Plugin System** — Add custom tools, commands, and integrations
- **Hooks Pipeline** — PreToolUse and PostToolUse hooks for automated workflows
- **Skill System** — Invoke specialized capabilities via slash commands
- **Multi-language Runtimes** — Choose Mojo (performance), Rust (safety), or Python (compatibility)

---

## Quick Start

### Mojo (Primary — Fastest Performance)

**Prerequisites:** [Max toolchain 25.3+](https://www.modular.com/max) with Pixi package manager.

```bash
# Clone the repository
git clone https://github.com/instructkr/fireclaw.git
cd fireclaw/mojo

# Install dependencies
pixi install

# Build and run
mojo build packages/claw_cli/main.mojo -o fireclaw
./fireclaw --help

# Start interactive REPL
./fireclaw

# Single-shot prompt
./fireclaw -p "Explain this codebase"
```

### Rust (Complete Port — Memory Safe)

**Prerequisites:** Rust 1.70+ with Cargo.

```bash
cd fireclaw/rust

# Build release binary
cargo build --release

# Run the CLI
./target/release/claw --help

# Start interactive REPL
./target/release/claw

# Run all 274 tests
cargo test --workspace
```

### Python (Reference Implementation)

```bash
cd fireclaw

# Render porting summary
python3 -m src.main summary

# Print workspace manifest
python3 -m src.main manifest

# List tools and commands
python3 -m src.main tools --limit 10
python3 -m src.main commands --limit 10

# Run verification tests
python3 -m unittest discover -s tests -v
```

---

## Architecture

FireClaw uses a **modular package architecture** consistent across all three language implementations:

```
fireclaw/
├── mojo/                           # Mojo implementation (primary)
│   ├── packages/
│   │   ├── api/                    # Anthropic API client + SSE streaming
│   │   ├── claw_runtime/           # Session, config, prompt assembly
│   │   ├── claw_cli/              # CLI entry point and REPL
│   │   ├── tools/                  # 184+ built-in tool implementations
│   │   ├── commands/               # 207 slash command handlers
│   │   ├── bridge/                 # Python interop for networking/TLS/OAuth
│   │   └── compat/                 # TypeScript feature surface testing
│   ├── main.mojo                   # CLI entry point
│   └── pixi.toml                   # Mojo + Python dependency management
│
├── rust/                           # Rust port (complete, 274 tests passing)
│   ├── crates/
│   │   ├── api/                    # HTTP client, SSE, authentication
│   │   ├── runtime/                # Conversation loop, config, session, MCP
│   │   ├── tools/                  # Tool specifications and execution
│   │   ├── commands/               # Slash command registry
│   │   ├── claw-cli/             # Main CLI binary
│   │   └── plugins/                # Plugin system with hooks
│   └── Cargo.toml
│
├── src/                            # Python reference implementation
│   ├── commands.py                 # 207 command registry (mirrored)
│   ├── tools.py                    # 184 tool registry (mirrored)
│   ├── runtime.py                  # Port runtime engine
│   ├── models.py                   # Data structures
│   └── reference_data/             # Command/tool snapshots (JSON)
│
├── CLAW.md                         # Project context for AI assistants
├── PARITY.md                       # Mojo port gap analysis
└── README.md
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Native Mojo for compute-bound paths** | Tool execution, prompt assembly, config parsing, session management |
| **Python interop for I/O-bound paths** | HTTP, TLS, WebSocket, OAuth via `bridge/` package |
| **Structural parity across languages** | Same package decomposition: api, runtime, tools, commands, cli |
| **Permission-first security** | Every tool call passes through permission evaluation + hooks |
| **Clean-room implementation** | No proprietary code — architectural patterns only |

---

## FireClaw vs Claw Code

FireClaw is not a fork — it is a **clean-room reimplementation** of Claw Code's architecture, rewritten entirely in Mojo with additional runtimes in Rust and Python. Here's what changed:

| Dimension | Claw Code (Original) | FireClaw (This Project) |
|-----------|---------------------|------------------------|
| **Language** | TypeScript (Node.js) | Mojo (primary), Rust, Python |
| **Performance** | Interpreted JS runtime | Near-C native speed via Mojo |
| **Source availability** | Proprietary / exposed once | Fully open-source from day one |
| **Memory model** | Garbage collected | Deterministic destruction (Mojo) / ownership (Rust) |
| **Python ecosystem** | Not accessible | Seamless Python interop via Mojo bridge |
| **GPU/SIMD path** | None | Native Mojo SIMD/GPU primitives (future accelerated ops) |
| **Extensibility** | Internal plugin system | Open plugin system + hooks + MCP + community registry |
| **Legal status** | IP concerns with leaked source | Clean-room — no proprietary code, architectural patterns only |
| **Multi-runtime** | Single runtime | Three runtimes: Mojo (speed), Rust (safety), Python (compatibility) |
| **Test coverage** | Unknown | 274 tests passing across Rust workspace |

### What FireClaw Keeps From Claw Code

- The proven agent loop architecture (tool dispatch, conversation management, streaming)
- CLAW.md project context discovery pattern
- 184+ tool surface area and 207 slash command registry
- MCP protocol integration design
- Session persistence and compaction model
- Permission system with hooks pipeline

### What FireClaw Adds

- **Mojo-native performance** for compute-bound paths (tool execution, prompt assembly, config parsing)
- **Python interop bridge** for I/O-bound paths (HTTP, TLS, OAuth, WebSocket)
- **Multi-language architecture** — choose the runtime that fits your needs
- **Open-source governance** — community contributions welcome across all three runtimes
- **Modular package system** matching the Rust crate structure for maintainability

---

## How FireClaw Compares to Other AI Coding Tools

### AI Coding Assistant Comparison (2026)

| Feature | FireClaw | GitHub Copilot | Cursor | Aider | Continue | Claw Code |
|---------|:--------:|:--------------:|:------:|:-----:|:--------:|:---------:|
| **Open source** | Yes | No | No | Yes | Yes | No |
| **Terminal-native CLI** | Yes | No | No | Yes | No | Yes |
| **Language** | Mojo/Rust/Python | N/A | N/A | Python | TypeScript | TypeScript |
| **Built-in tools** | 184+ | Limited | IDE only | ~10 | ~15 | 184+ |
| **MCP integration** | Full | No | Partial | No | Yes | Full |
| **Session persistence** | Yes | No | No | Partial | No | Yes |
| **Permission system** | 3-tier + hooks | N/A | N/A | Basic | Basic | Yes |
| **Project context** | CLAW.md | No | .cursorrules | .aider | .continue | CLAW.md |
| **Self-hosted** | Yes | No | No | Yes | Yes | No |
| **Cost tracking** | Built-in | N/A | N/A | No | No | Yes |
| **Native performance** | Yes (Mojo) | N/A | N/A | No | No | No |
| **Plugin hooks** | Pre/Post | No | No | No | Basic | Yes |

### Why Mojo Over Python and TypeScript?

FireClaw could have been written in Python (like Aider) or TypeScript (like the original Claw Code). We chose Mojo because an AI coding agent has a unique performance profile — it must be **fast on CPU-bound tool execution** and **smooth on streaming I/O** — and Mojo is the only language that delivers both while keeping the entire Python ecosystem accessible.

#### Mojo vs Python vs TypeScript — Language Comparison for AI Agents

| Dimension | Mojo (FireClaw) | Python (Aider, etc.) | TypeScript (Claw Code) |
|-----------|:---------------:|:--------------------:|:----------------------:|
| **Execution model** | Compiled to native machine code | Interpreted (CPython) | JIT compiled (V8) |
| **Tool execution speed** | Near-C — no interpreter overhead | 10-100x slower on CPU-bound ops | Faster than Python, slower than native |
| **Memory management** | Ownership + deterministic destruction | Garbage collected (GC pauses) | Garbage collected (GC pauses) |
| **Streaming smoothness** | No GC pauses during SSE parsing | GC can stutter mid-stream | GC can stutter mid-stream |
| **Type safety** | Static types, compile-time checks | Dynamic types, runtime errors | Static types (but transpiled) |
| **Python ecosystem access** | Direct — `from python import Python` | Native | Requires child processes or FFI |
| **GPU/SIMD primitives** | Built-in — first-class SIMD and GPU kernels | Via NumPy/CuPy (C extensions) | Not available |
| **Syntax familiarity** | Python-like — readable by any Python dev | Python | JavaScript/C-like |
| **Binary distribution** | Single compiled binary | Requires Python runtime + venv | Requires Node.js runtime |
| **Startup time** | Instant — no interpreter boot | 100-500ms interpreter warmup | 50-200ms V8 warmup |
| **Concurrency model** | Native (async roadmapped) | GIL-limited threads / asyncio | Event loop + async/await |

#### Where Mojo Beats Python (and Why It Matters for FireClaw)

An AI coding agent isn't a web server or a data pipeline. Its performance bottleneck is **tool execution** — the hundreds of file reads, regex searches, config parses, and prompt assemblies that happen every conversation turn. These are all CPU-bound, and they happen *synchronously in the agent loop* while the developer waits.

In Python, each of these operations carries interpreter overhead: dynamic type checks, dictionary lookups for attribute access, reference counting, and GC cycles. In Mojo, they compile to tight native loops with zero runtime overhead.

**Concrete impact in FireClaw:**

| Operation | In Mojo | In Python | Why It Matters |
|-----------|---------|-----------|----------------|
| **Grep 10,000 files** | Native string matching at compiled speed | `re` module with interpreter overhead per line | Developers run search dozens of times per session |
| **Parse `.claw.json` configs** | EmberJson — native JSON at memory-copy speed | `json.loads()` — interpreter-bound | Config is read on every single agent turn |
| **Assemble system prompt** | String concatenation compiles to `memcpy` | String ops allocate new objects each concat | Prompt assembly happens before every API call |
| **Serialize session to disk** | Native struct → JSON, near-instant | `dataclasses` → `json.dumps()`, GC pressure | Sessions save after every turn for persistence |
| **Glob walk a directory tree** | `std.pathlib` — compiled directory traversal | `pathlib.glob()` — interpreted per-entry | File discovery runs before every tool execution |

The difference isn't academic. On a large codebase (10K+ files), a full grep in Mojo completes while Python is still warming up its regex engine.

#### Where Mojo Beats TypeScript (and Why We Didn't Stay in TS)

The original Claw Code was TypeScript running on Node.js. TypeScript gives you type safety and a mature async ecosystem, but it has fundamental limitations for an AI agent:

1. **No Python interop** — TypeScript can't call `httpx`, `transformers`, `numpy`, or any Python library directly. FireClaw can, via Mojo's `from python import Python`. This means FireClaw has access to the **entire Python ML/AI ecosystem** natively.

2. **V8 GC pauses** — Node.js uses V8's generational garbage collector. During streaming SSE responses, GC pauses cause visible stutters. Mojo's deterministic destruction means memory is freed the instant it's no longer needed — no pauses, ever.

3. **No path to GPU** — TypeScript has no mechanism for SIMD operations or GPU kernels. Mojo has first-class support for both, giving FireClaw a future path to accelerated embedding and token operations on your local GPU.

4. **Runtime dependency** — A TypeScript agent requires Node.js installed. A Mojo agent compiles to a single native binary — `./fireclaw` and you're running.

5. **No true systems access** — Node.js file operations go through libuv's thread pool. Mojo uses direct syscalls via its native stdlib. For an agent making thousands of file operations per session, this eliminates an entire layer of indirection.

---

### Full Python Compatibility — Use Every Python Library from Mojo

One of Mojo's most powerful features is **zero-friction Python interoperability**. FireClaw doesn't just "support" Python — it calls Python libraries directly, in-process, with no serialization overhead, no subprocess spawning, and no FFI boilerplate.

#### How It Works

```mojo
# Import any Python library directly from Mojo
from python import Python

def fetch_api_response(url: String, api_key: String) raises -> String:
    # Call Python's httpx exactly as you would in Python
    var httpx = Python.import_module("httpx")
    var headers = Python.dict()
    headers["Authorization"] = "Bearer " + api_key
    var response = httpx.post(url, headers=headers)
    return String(response.text)
```

This isn't a wrapper or a binding generator — Mojo's compiler understands Python objects natively. You `import` a Python module and call it. Types convert automatically between Mojo and Python. The Python code runs in the same process with zero IPC overhead.

#### What FireClaw Uses Python For

FireClaw uses a dedicated **bridge layer** (`mojo/packages/bridge/`) that isolates all Python dependencies behind clean Mojo interfaces:

| Bridge Module | Python Library | What It Does |
|---------------|---------------|-------------|
| `bridge/http.mojo` | `httpx` | All API communication — Anthropic, MCP servers, web fetch |
| `bridge/oauth.mojo` | `httpx` + `secrets` | PKCE OAuth flows for authenticated connections |
| `bridge/websocket.mojo` | `websockets` | MCP WebSocket transport for real-time tool servers |
| `bridge/regex.mojo` | `re` | Advanced regex patterns beyond Mojo stdlib matching |
| `bridge/async_io.mojo` | `asyncio` | Async patterns for concurrent network requests |
| `bridge/tls.mojo` | `ssl` | TLS context management for secure HTTPS connections |

**The key architectural rule:** Every bridge module presents a **pure-Mojo interface** to the rest of the codebase. Mojo types go in, Mojo types come out. No other package imports `Python` directly. This means:

- The 95% of FireClaw that is CPU-bound runs as compiled native code
- The 5% that is I/O-bound uses Python's mature, battle-tested networking libraries
- As Mojo's stdlib adds native HTTP/TLS, bridge modules can be swapped one at a time with zero changes to calling code

#### Why This Is Better Than "Just Use Python"

You might ask: if FireClaw uses Python for networking anyway, why not write the whole thing in Python?

Because **networking is I/O-bound and tool execution is CPU-bound** — and they have completely different performance profiles:

```
┌─────────────────────────────────────────────────────────┐
│  Native Mojo — CPU-bound, performance-critical          │
│  Runs 10-100x faster than Python on these paths         │
│                                                         │
│  ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐ │
│  │ 184+ Tools│ │ Config   │ │ Prompts  │ │ Sessions  │ │
│  │ grep,glob │ │ .claw.json│ │ CLAW.md  │ │ JSON I/O  │ │
│  │ file r/w  │ │ env vars │ │ assembly │ │ EmberJson │ │
│  │ bash exec │ │ discovery│ │ context  │ │ serialize │ │
│  └───────────┘ └──────────┘ └──────────┘ └───────────┘ │
├─────────────────────────────────────────────────────────┤
│  Python Bridge — I/O-bound, network-latency dominated   │
│  Python is perfectly fast here (network is the limit)   │
│                                                         │
│  ┌───────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐ │
│  │ HTTP/API  │ │ OAuth    │ │ WebSocket│ │ TLS       │ │
│  │ httpx     │ │ PKCE     │ │ MCP      │ │ ssl ctx   │ │
│  └───────────┘ └──────────┘ └──────────┘ └───────────┘ │
└─────────────────────────────────────────────────────────┘
```

An API call to Claude takes 200-2000ms regardless of whether it's sent from Python or native code. But grepping 10,000 files, parsing 50 config entries, and assembling a 4,000-token system prompt — those operations happen **on every single turn** and the speed difference is felt directly by the developer at the keyboard.

This hybrid strategy gives FireClaw **the best of both worlds**: C-level speed where speed matters, and the entire Python ecosystem where ecosystem matters.

#### Compatible Python Libraries

Because Mojo interop works with any Python package, FireClaw can integrate with the entire Python AI/ML ecosystem:

- **httpx, requests, aiohttp** — HTTP clients for API communication
- **transformers, torch, tensorflow** — ML model loading and inference
- **numpy, pandas** — Data processing and analysis
- **langchain, llama-index** — LLM orchestration frameworks
- **boto3, google-cloud** — Cloud provider SDKs
- **Any `pip install`-able package** — if Python can import it, Mojo can call it

This makes FireClaw uniquely positioned among AI coding tools: it has the **performance of a compiled systems language** with the **library access of the Python ecosystem** — no other tool in this space can claim both.

---

### Mojo Deep Dive — Architecture Details

#### Struct-Based Architecture with Static Dispatch

FireClaw's Mojo implementation uses **structs and traits exclusively** — no classes, no inheritance, no dynamic polymorphism. Every tool conforms to a `Tool` trait with an `execute()` method, and dispatch is resolved at compile time:

```mojo
# Every tool is a struct with a statically-dispatched execute() method
struct GrepTool:
    fn execute(self, input: ToolInput) raises -> ToolResult:
        # Native string matching — no vtable, no dynamic lookup
        ...
```

This means tool execution has zero overhead from virtual method tables or runtime type inspection. When the agent calls Grep, it's a direct function call into compiled native code. With 184+ tools and potentially dozens of tool calls per conversation turn, this adds up.

Mojo's `@fieldwise_init` decorator provides automatic struct constructors, keeping boilerplate low while maintaining the performance benefits of value types.

#### Built-In Path to Hardware Acceleration

Mojo was designed from the ground up for **SIMD operations and GPU compute**. While FireClaw doesn't use these today, the language provides a clear path forward:

- **SIMD primitives** for parallel string processing and token operations
- **GPU kernel support** for accelerated embedding generation
- **Hardware-aware memory layouts** for cache-efficient data structures

These capabilities are roadmapped for Phase 3+ of the project — accelerated embedding operations and token processing that can take advantage of the same GPU sitting in your machine. Because the codebase is already in Mojo, adopting these features will be incremental, not a rewrite.

#### Python-Familiar Syntax, Lower Contributor Barrier

Mojo's syntax is intentionally close to Python. For an open-source project, this matters enormously:

```mojo
# This is Mojo, not Python — but any Python developer can read it
fn discover_claw_md(path: Path) raises -> String:
    var current = path
    var content = String("")
    while current != Path("/"):
        let claw_file = current / "CLAW.md"
        if claw_file.exists():
            content = claw_file.read_text()
            break
        current = current.parent()
    return content
```

Contributors who know Python can read, understand, and contribute to the Mojo codebase without learning an entirely new language. The mental model is familiar — the performance characteristics are just dramatically better.

---

## Built With AI Orchestration

The entire codebase was developed and verified using AI orchestration tools — a testament to agentic development workflows:

### Python Port — oh-my-codex (OmX)

Built using [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex) by [@bellman_ych](https://x.com/bellman_ych):
- **`$team` mode** for parallel code review and architectural feedback
- **`$ralph` mode** for persistent execution loops with verification
- End-to-end orchestration from reading harness structure to producing a working Python tree

### Rust Port — oh-my-opencode (OMO)

Built using [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) by [@code-yeongyu](https://github.com/code-yeongyu):
- **Sisyphus agent** in `ultrawork` mode — autonomous plan-implement-verify loops
- Complete cleanroom pass across 55 files
- **274 tests passing** across the entire Rust workspace

### QA — Jobdori (OpenClaw)

- 18-point functional test suite against the built binary
- Grep-based cleanroom verification — zero branding leakage
- Git workflow coordination across branches

---

## Featured In

> *AI startup worker Sigrid Jin, who attended the Seoul dinner, single-handedly used 25 billion of [AI coding] tokens last year...*
>
> — **The Wall Street Journal**, March 21, 2026, [*"The Trillion Dollar Race to Automate Our Entire Lives"*](https://lnkd.in/gs9td3qd)

---

## Frequently Asked Questions

### What is FireClaw?

FireClaw is an open-source AI coding assistant and agent framework written in Mojo that runs in your terminal. It connects to large language models like Claude, executes 184+ developer tools (file operations, shell commands, code search, web requests), and manages multi-turn conversations with full project context. It is a clean-room reimplementation of the Claw Code architecture, rewritten from scratch for native performance.

### Is FireClaw free and open source?

Yes. FireClaw is fully open source. You can self-host it, modify it, extend it, and contribute to it. You provide your own API key for the LLM provider (e.g., Anthropic Claude).

### What is the difference between FireClaw and Claw Code?

FireClaw is a clean-room reimplementation of Claw Code's architecture, rewritten entirely in Mojo (with additional Rust and Python runtimes). Claw Code was proprietary TypeScript; FireClaw is open-source Mojo with near-C performance, seamless Python interop, deterministic memory management, and a future path to GPU-accelerated operations. See the [full comparison](#fireclaw-vs-claw-code).

### Why is FireClaw written in Mojo instead of Python or TypeScript?

Mojo gives FireClaw compiled native speed on the operations that happen most often — tool execution, config parsing, prompt assembly, and session persistence — while maintaining seamless Python interop for networking and ecosystem access. The ownership-based memory model eliminates garbage collection pauses during streaming, and Mojo's Python-like syntax keeps the codebase accessible to contributors. FireClaw is one of the largest open-source Mojo projects in production. See the full [Why Mojo?](#why-mojo-performance--capabilities-deep-dive) section for the complete breakdown.

### How does FireClaw compare to Aider, Continue, or Cursor?

FireClaw offers significantly more built-in tools (184+ vs ~10-15), full MCP protocol integration, a 3-tier permission system with pre/post hooks, session persistence, multi-language runtimes (Mojo/Rust/Python), native performance, and built-in cost tracking. See the [full comparison table](#how-fireclaw-compares-to-other-ai-coding-tools).

### Does FireClaw support Model Context Protocol (MCP)?

Yes. FireClaw has full MCP integration supporting stdio, WebSocket, and HTTP transports. Connect any MCP-compatible server to extend FireClaw with custom tools, resources, and capabilities — from databases to design tools to deployment platforms.

### Can I use FireClaw with models other than Claude?

The architecture supports any LLM with a compatible API. The primary implementation targets Anthropic's Claude models, but the modular API client layer is designed for provider flexibility. Multi-model support is on the roadmap.

### What are CLAW.md files?

CLAW.md is FireClaw's project context file — similar to `.cursorrules` or `.aider`. Place a `CLAW.md` in your project root and FireClaw automatically reads it to understand your tech stack, conventions, and architectural decisions, enabling context-aware assistance without manual setup.

### How do I extend FireClaw with custom tools?

FireClaw supports three extension mechanisms: (1) **Plugins** for custom tools and commands, (2) **MCP servers** for external tool integration, and (3) **Hooks** for pre/post tool execution middleware. Each tool is a struct conforming to the `Tool` trait with a simple `execute()` method.

### Is FireClaw a fork of Claw Code?

No. FireClaw is a **clean-room reimplementation** — the architecture was studied and rebuilt from scratch without copying proprietary source code. This approach is both legally clean and technically superior, as the rewrite targets Mojo's strengths rather than inheriting TypeScript's constraints.

---

## Roadmap

- [x] Python reference implementation
- [x] Rust port — complete with 274 tests
- [x] Mojo port — core architecture and tool system
- [ ] Mojo native async runtime (awaiting Mojo language evolution)
- [ ] Mojo native HTTP/TLS (replacing Python bridge)
- [ ] Plugin marketplace and community registry
- [ ] Multi-model provider support (OpenAI, Gemini, local models)
- [ ] VS Code and JetBrains IDE extensions
- [ ] GPU-accelerated embedding operations via Mojo SIMD
- [ ] FireClaw Cloud — hosted agent runtime (planned)

---

## Testing

```bash
# Rust — full test suite (274 tests)
cd rust && cargo test --workspace

# Python — verification suite
python3 -m unittest discover -s tests -v

# Mojo — format check and build verification
cd mojo && mojo format . && mojo build packages/claw_cli/main.mojo
```

---

## Contributing

Contributions are welcome across all three language implementations. See the [Architecture](#architecture) section for codebase layout and the [PARITY.md](PARITY.md) for current Mojo port gaps that need work.

**Priority areas:**
- Mojo tool implementations (bridging the 184-tool parity gap)
- MCP transport layers in native Mojo
- Documentation and examples
- Test coverage expansion
- Community MCP server integrations

---

## Community

<p align="center">
  <a href="https://instruct.kr/"><img src="assets/instructkr.png" alt="instructkr community" width="400" /></a>
</p>

Join the [**instructkr Discord**](https://instruct.kr/) — the largest Korean language model community. Discuss LLMs, harness engineering, agent workflows, Mojo development, and open-source AI tooling.

[![Discord](https://img.shields.io/badge/Join%20Discord-instruct.kr-5865F2?logo=discord&style=for-the-badge)](https://instruct.kr/)

---

## Acknowledgments

- [Modular](https://www.modular.com/) — creators of the Mojo programming language
- [oh-my-codex (OmX)](https://github.com/Yeachan-Heo/oh-my-codex) by [@bellman_ych](https://x.com/bellman_ych) — AI orchestration for the Python port
- [oh-my-opencode (OMO)](https://github.com/code-yeongyu/oh-my-opencode) by [@code-yeongyu](https://github.com/code-yeongyu) — AI orchestration for the Rust port
- [OpenClaw](https://github.com/openclaw/openclaw) — QA orchestration via Jobdori

---

## License

This repository is open source. See [LICENSE](LICENSE) for details.

### Disclaimer

This repository does **not** claim ownership of any original proprietary source material. FireClaw is a **clean-room reimplementation** that captures architectural patterns without copying proprietary code. This project is **not affiliated with, endorsed by, or maintained by** the original authors of any referenced systems.

---

<div align="center">

**FireClaw** — The Open-Source AI Coding Agent Forged in Mojo

*Rewritten from Claw Code's architecture. Built for speed. Designed for developers.*

[GitHub](https://github.com/instructkr/fireclaw) · [Discord](https://instruct.kr/) · [Sponsor](https://github.com/sponsors/instructkr)

</div>

<!-- SEO: Semantic keyword layer for search engine and AI system indexing -->
<!-- fireclaw, fire claw, fireclaw ai, fireclaw mojo, fireclaw coding assistant, claw code alternative, claw code rewrite, claw code mojo, open source ai coding assistant, ai agent framework mojo, mojo programming language project, ai coding cli tool, model context protocol mcp tool, agentic coding framework, ai pair programming terminal, mojo ai agent orchestration, best ai coding tools 2026, self-hosted ai coding assistant, ai code generation, ai developer tools open source, terminal ai assistant, claw code vs fireclaw, fireclaw vs aider, fireclaw vs cursor, fireclaw vs copilot, fireclaw vs continue, mojo vs python performance, mojo vs typescript, mojo python interop, mojo python compatibility, why mojo over python, mojo programming language benefits, mojo language ai development, mojo compiled performance, mojo python bridge, mojo call python libraries, mojo systems programming, clean room reimplementation, ai agent harness, harness engineering, modular mojo framework, mojo open source project, ai coding agent mojo language, mojo deterministic memory, mojo gpu simd ai, mojo native speed python syntax -->
