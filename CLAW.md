# CLAW.md

This file provides guidance to Claw Code when working with code in this repository.

## Detected stack
- Languages: Mojo (primary), Python (interop bridge via `packages/bridge/`).
- Frameworks: EmberJson (community JSON library), Lightbug HTTP (community).
- Build tooling: Pixi package manager, `mojo` CLI (Max toolchain 25.3+).

## Verification
- Build: `pixi run build` or `mojo build main.mojo -I packages -o build/claw`
- Test: `pixi run test` (Mojo tests), `pixi run test-bridge` (Python interop tests via pytest)
- Format: `pixi run format` (applies `mojo format .`)
- Quick check: `./build/claw --version`

## Repository shape
- `main.mojo` — CLI entrypoint with REPL loop, argument parsing, and session management.
- `packages/` — Mojo packages organized by subsystem:
  - `packages/api/` — Anthropic API client, SSE streaming parser, message/tool types.
  - `packages/claw_runtime/` — conversation loop, config loading, session persistence, prompt assembly, hooks, plugins, MCP, usage tracking.
  - `packages/tools/` — built-in tool registry and 12 native tool implementations (bash, file_read, file_write, glob, grep, todo, agent, skill, config, web_fetch, web_search).
  - `packages/commands/` — slash command registry with 207 commands.
  - `packages/claw_cli/` — CLI utilities package.
  - `packages/bridge/` — Python interop wrappers for HTTP (httpx), OAuth (PKCE), WebSocket, TLS, regex, async I/O. Unique to the Mojo implementation.
  - `packages/compat/` — compatibility harness for TypeScript feature surface testing.
- `build/` — compiled binary output directory.
- `tests/` — test suite for Mojo and Python bridge tests.

## Mojo-specific conventions
- File extension: `.mojo` (not `.🔥` — emoji extensions are deprecated).
- Package directories require `__init__.mojo` files.
- Module names use `snake_case`; type names use `PascalCase`.
- All function arguments and return types require explicit type annotations.
- Use `def` for all functions (`fn` is deprecated as of Mojo v26.2).
- Structs are the primary type mechanism — no classes, no inheritance.
- Use traits for polymorphism and interface contracts.
- Methods that mutate state require `mut self`.
- Types are not copyable/movable by default — opt in via `Copyable`, `Movable` traits.
- Use `@fieldwise_init` decorator for auto-generated constructors.
- Error-raising functions must be annotated with `raises`.
- Compile-time parameters use `[square_brackets]`; runtime arguments use `(parentheses)`.

## Python interop strategy
- Networking (HTTP, TLS, WebSocket) is delegated to Python via `from python import Python`.
- OAuth flows use Python's `httpx` library through the interop bridge.
- SSE/streaming uses Python's async libraries wrapped in Mojo's bridge layer.
- Performance-critical paths (tool execution, prompt assembly, config parsing, session management) are native Mojo.
- All Python-calling functions must be marked `raises`.
- The `packages/bridge/` package encapsulates all Python interop to keep the rest of the codebase pure Mojo.

## Architecture decisions
- Follow modular package decomposition: api, claw_runtime, tools, commands, claw_cli, bridge, compat.
- The `bridge/` package has no equivalent in other implementations — it is unique to the Mojo port.
- Use community libraries where mature enough: EmberJson for JSON serialization.
- Session persistence uses native Mojo file I/O (available in stdlib).
- CLAW.md discovery and prompt assembly are fully native Mojo.
- Config parsing uses native string operations with JSON fallback via bridge.

## Working agreement
- Prefer small, reviewable changes.
- Keep shared defaults in `.claw.json`; reserve `.claw/settings.local.json` for machine-local overrides.
- Do not overwrite existing `CLAW.md` content automatically.
- When a feature requires Python interop, isolate the Python dependency in `bridge/` and provide a pure-Mojo interface.
- Document all Python library dependencies in `pixi.toml` under `[dependencies]`.
- Track Mojo language evolution — revisit bridge patterns when native alternatives become available.
