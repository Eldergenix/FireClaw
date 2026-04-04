# Claw Code — Mojo Port Parity Tracker

This document tracks the implementation status of the Mojo port against the full feature specification. It serves as a living roadmap for contributors.

## Status Legend

| Symbol | Meaning |
|--------|---------|
| Done | Fully implemented and tested |
| Partial | Core logic exists, needs integration or edge cases |
| Planned | Architecture designed, not yet implemented |
| Blocked | Waiting on Mojo language feature or upstream dependency |

---

## Core Runtime

| Feature | Status | File | Notes |
|---------|--------|------|-------|
| CLI entry point + REPL | Done | `main.mojo` | Arg parsing, interactive loop, colored output |
| Configuration loading | Done | `packages/claw_runtime/config.mojo` | `.claw.json`, env vars, directory walk |
| CLAW.md discovery | Done | `packages/claw_runtime/prompt.mojo` | Recursive upward directory search |
| System prompt assembly | Done | `packages/claw_runtime/prompt.mojo` | Project context + tool specs + model info |
| Session persistence | Done | `packages/claw_runtime/session.mojo` | JSON serialization via EmberJson |
| Conversation loop | Partial | `packages/claw_runtime/conversation.mojo` | Structure exists, needs API integration |
| Hook pipeline | Partial | `packages/claw_runtime/hooks.mojo` | PreToolUse/PostToolUse framework |
| Plugin system | Partial | `packages/claw_runtime/plugins.mojo` | Loading framework, needs runtime binding |
| MCP client | Partial | `packages/claw_runtime/mcp.mojo` | Types defined, needs transport wiring |
| Token/cost tracking | Done | `packages/claw_runtime/usage.mojo` | Per-model pricing, token counting |

## API Layer

| Feature | Status | File | Notes |
|---------|--------|------|-------|
| Message types | Done | `packages/api/types.mojo` | Message, ToolSpec, ApiResponse structs |
| SSE parser | Done | `packages/api/sse.mojo` | Event type + data extraction |
| API client | Partial | `packages/api/client.mojo` | Request building done, needs HTTP wiring |
| Streaming support | Partial | `packages/api/sse.mojo` + `bridge/http.mojo` | Parser ready, needs integration |

## Tools (12 of 184 implemented)

| Tool | Status | File | Notes |
|------|--------|------|-------|
| Bash | Done | `packages/tools/bash.mojo` | Shell command execution |
| FileRead | Done | `packages/tools/file_read.mojo` | Read with line numbers |
| FileWrite | Done | `packages/tools/file_write.mojo` | Create and overwrite files |
| Glob | Done | `packages/tools/glob.mojo` | Pattern matching file discovery |
| Grep | Done | `packages/tools/grep.mojo` | Content search with line matching |
| Todo | Done | `packages/tools/todo.mojo` | Task tracking |
| Agent | Done | `packages/tools/agent.mojo` | Sub-agent spawning |
| Skill | Done | `packages/tools/skill.mojo` | Skill loading and dispatch |
| Config | Done | `packages/tools/config.mojo` | Configuration management |
| WebFetch | Done | `packages/tools/web_fetch.mojo` | HTTP GET via bridge |
| WebSearch | Done | `packages/tools/web_search.mojo` | Web search integration |
| ToolRegistry | Done | `packages/tools/__init__.mojo` | MVP tool spec generation |
| Edit | Planned | — | File editing with string replacement |
| NotebookEdit | Planned | — | Jupyter notebook operations |
| LSP | Planned | — | Language Server Protocol client |

## Bridge Layer (Python Interop)

| Module | Status | File | Notes |
|--------|--------|------|-------|
| HTTP client | Done | `packages/bridge/http.mojo` | httpx wrapper for POST/GET |
| OAuth (PKCE) | Done | `packages/bridge/oauth.mojo` | Full PKCE flow |
| WebSocket | Done | `packages/bridge/websocket.mojo` | Python websockets library |
| TLS | Done | `packages/bridge/tls.mojo` | SSL context management |
| Regex | Done | `packages/bridge/regex.mojo` | Python re module wrapper |
| Async I/O | Done | `packages/bridge/async_io.mojo` | Python asyncio wrapper |
| JSON compat | Done | `packages/bridge/json_compat.mojo` | JSON fallback via Python |

## Commands

| Feature | Status | File | Notes |
|---------|--------|------|-------|
| Command registry | Done | `packages/commands/__init__.mojo` | 207 command definitions |
| Command dispatch | Done | `packages/commands/__init__.mojo` | Name lookup + argument passing |
| Command handlers | Partial | `packages/commands/__init__.mojo` | Core commands work, many are stubs |

## Cross-Implementation Testing

| Feature | Status | File | Notes |
|---------|--------|------|-------|
| Compat harness | Done | `packages/compat/harness.mojo` | TypeScript feature surface validation |

---

## Blocked on Mojo Language Evolution

These features are waiting on capabilities that Mojo has not yet stabilized:

| Feature | Waiting On | Workaround |
|---------|-----------|------------|
| Native async runtime | Mojo async/await | Python asyncio via bridge |
| Native HTTP client | Mojo stdlib networking | Python httpx via bridge |
| Native TLS | Mojo stdlib crypto | Python ssl via bridge |
| Native WebSocket | Mojo stdlib networking | Python websockets via bridge |
| GPU-accelerated ops | Mojo GPU kernel APIs | Not started |

---

## Contributing

Pick any **Planned** item above and open a PR! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions and coding conventions.

**Highest impact contributions right now:**
1. Wire `bridge/http.mojo` into `claw_runtime/conversation.mojo` for live API calls
2. Implement additional tools from the 184-tool specification
3. Add tests for existing tool implementations
