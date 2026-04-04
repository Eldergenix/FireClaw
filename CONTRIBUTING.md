# Contributing to Claw Code

Thank you for your interest in contributing to Claw Code! This guide will help you get set up and productive quickly.

## Getting Started

### Prerequisites

- [Max toolchain 25.3+](https://www.modular.com/max) (includes Mojo compiler)
- [Pixi package manager](https://pixi.sh/) (installed with Max)
- Python 3.14+ (managed by Pixi)
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/instructkr/claw-code.git
cd claw-code

# Install all dependencies (Mojo toolchain + Python packages)
pixi install

# Build the binary
pixi run build

# Verify the build
./build/claw --version

# Run all tests
pixi run test
pixi run test-bridge
```

## Project Structure

```
main.mojo              # CLI entry point
packages/
  api/                 # Anthropic API client + SSE streaming
  claw_runtime/        # Core runtime (config, session, conversation, hooks)
  tools/               # Built-in tool implementations
  commands/            # Slash command registry
  bridge/              # Python interop layer (HTTP, OAuth, WebSocket, TLS)
  claw_cli/            # CLI utilities
  compat/              # Cross-implementation testing harness
```

See [Architecture](README.md#architecture) in the README for detailed descriptions of each package.

## Development Workflow

### Build Commands

```bash
pixi run build         # Compile to native binary at build/claw
pixi run test          # Run Mojo test suite
pixi run test-bridge   # Run Python interop tests (pytest)
pixi run format        # Format all .mojo files
pixi run clean         # Remove build artifacts
```

### Making Changes

1. **Create a branch** from `main` with a descriptive name
2. **Make your changes** following the conventions below
3. **Test your changes**: `pixi run test && pixi run test-bridge`
4. **Format your code**: `pixi run format`
5. **Build and verify**: `pixi run build && ./build/claw --version`
6. **Open a pull request** with a clear description of what and why

## Mojo Coding Conventions

### File & Naming

- File extension: `.mojo` (never `.🔥`)
- Module names: `snake_case` (e.g., `file_read.mojo`)
- Type names: `PascalCase` (e.g., `RuntimeConfig`)
- Function names: `snake_case` (e.g., `load_config`)
- Constants: `UPPER_SNAKE_CASE`

### Language Patterns

```mojo
# Use def, not fn (fn is deprecated as of Mojo v26.2)
def load_config() raises -> RuntimeConfig:
    ...

# Structs with explicit typing — no classes
@fieldwise_init
struct ToolResult(Copyable, Movable):
    var output: String
    var error: String
    var is_error: Bool

# Traits for polymorphism
trait Tool:
    def execute(self, input: ToolInput) raises -> ToolResult:
        ...

# Mutation requires mut self
def add_message(mut self, role: String, content: String):
    self.messages.append(Message(role, content))
```

### Key Rules

- All function arguments and return types must have explicit type annotations
- Error-raising functions must be annotated with `raises`
- Every package directory needs an `__init__.mojo`
- Types are not copyable/movable by default — opt in via traits
- Compile-time parameters use `[square_brackets]`; runtime args use `(parentheses)`

### Python Interop

If your feature needs Python libraries:

1. **Isolate it in `packages/bridge/`** — never call `from python import Python` outside the bridge
2. **Expose a pure-Mojo interface** — Mojo types in, Mojo types out
3. **Document the dependency** in `pixi.toml`
4. **Add a test** in `tests/` via `pixi run test-bridge`

```mojo
# Good — isolated in bridge/
# packages/bridge/http.mojo
def post_json(url: String, body: String, api_key: String) raises -> String:
    var Python = Python.import_module("builtins")
    var httpx = Python.import_module("httpx")
    # ... Python calls isolated here
    return String(response_text)

# Bad — Python in non-bridge code
# packages/tools/grep.mojo
def search(pattern: String) raises -> String:
    var re = Python.import_module("re")  # DON'T do this
```

## Priority Contribution Areas

### High Impact

- **API integration** — connecting `bridge/http.mojo` to the conversation loop in `claw_runtime/conversation.mojo`
- **Additional tools** — implementing more of the 184 tool specifications as native Mojo structs
- **Test coverage** — unit tests for existing tools and runtime modules

### Medium Impact

- **MCP transports** — native Mojo implementations to replace bridge WebSocket
- **Session management** — conversation compaction and history search
- **Error handling** — improving error messages and recovery paths

### Good First Issues

- Adding a new slash command to `packages/commands/__init__.mojo`
- Implementing a simple tool (e.g., a file diff tool) in `packages/tools/`
- Adding test cases for existing tool implementations
- Improving inline documentation in existing modules

## Pull Request Guidelines

- Keep PRs focused on a single change
- Include a clear description of what changed and why
- Ensure all tests pass: `pixi run test && pixi run test-bridge`
- Format your code: `pixi run format`
- Reference any related issues

## Code of Conduct

Be respectful and constructive. We're building something together.

## Questions?

- Open a GitHub issue for bugs or feature requests
- Join the [instructkr Discord](https://instruct.kr/) for discussion
