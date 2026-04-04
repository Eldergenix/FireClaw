# main.mojo — Main entrypoint for Claw Code (Mojo port)
#
# Usage:
#   mojo run main.mojo [options] [prompt]
#   mojo run main.mojo <subcommand> [args]
#   ./build/claw [options] [prompt]
#
# Build:
#   mojo build main.mojo -I packages -o build/claw

from std.sys import argv
from std.collections import List
from claw_runtime.config import load_config, RuntimeConfig
from claw_runtime.prompt import discover_claw_files, assemble_system_prompt
from claw_runtime.session import create_session, Session, save_session
from claw_runtime.port_manifest import build_port_manifest
from claw_runtime.parity_audit import run_parity_audit
from claw_runtime.bootstrap_graph import build_bootstrap_graph
from claw_runtime.command_graph import build_command_graph
from claw_runtime.tool_pool import assemble_tool_pool
from claw_runtime.command_registry import (
    get_commands,
    get_command,
    command_names,
    render_command_index,
    execute_command,
)
from claw_runtime.tool_registry import (
    get_tools,
    get_tool,
    tool_names,
    render_tool_index,
    execute_tool,
)
from claw_runtime.port_runtime import PortRuntime
from claw_runtime.query_engine import (
    from_workspace,
    render_summary,
    flush_transcript,
)
from claw_runtime.setup import (
    start_mdm_raw_read,
    start_keychain_prefetch,
    start_project_scan,
)
from claw_runtime.transcript import new_transcript
from claw_runtime.direct_modes import run_direct_connect, run_deep_link
from claw_runtime.remote_runtime import (
    run_remote_mode,
    run_ssh_mode,
    run_teleport_mode,
)
from claw_runtime.misc import build_repl_banner
from tools import mvp_tool_specs
from commands import CommandRegistry
from api.types import ToolSpec


# ---------------------------------------------------------------------------
# Subcommand dispatch table
# ---------------------------------------------------------------------------

def _is_known_subcommand(name: String) -> Bool:
    """Return True if *name* matches a known subcommand."""
    if name == "summary":            return True
    if name == "manifest":           return True
    if name == "parity-audit":       return True
    if name == "setup-report":       return True
    if name == "command-graph":      return True
    if name == "tool-pool":          return True
    if name == "bootstrap-graph":    return True
    if name == "subsystems":         return True
    if name == "commands":           return True
    if name == "tools":              return True
    if name == "route":              return True
    if name == "bootstrap":          return True
    if name == "turn-loop":          return True
    if name == "flush-transcript":   return True
    if name == "load-session":       return True
    if name == "remote-mode":        return True
    if name == "ssh-mode":           return True
    if name == "teleport-mode":      return True
    if name == "direct-connect-mode": return True
    if name == "deep-link-mode":     return True
    if name == "show-command":       return True
    if name == "show-tool":          return True
    if name == "exec-command":       return True
    if name == "exec-tool":          return True
    return False


def _dispatch_subcommand(args: List[String]) raises:
    """Dispatch to the appropriate subcommand handler."""
    var subcmd = args[1]

    # --- summary ---
    if subcmd == "summary":
        var port = from_workspace()
        print(render_summary(port))
        return

    # --- manifest ---
    if subcmd == "manifest":
        var manifest = build_port_manifest()
        print(manifest.to_markdown())
        return

    # --- parity-audit ---
    if subcmd == "parity-audit":
        var audit = run_parity_audit()
        print(audit.to_markdown())
        return

    # --- setup-report ---
    if subcmd == "setup-report":
        var prefetch_mdm = start_mdm_raw_read()
        var prefetch_key = start_keychain_prefetch()
        var prefetch_scan = start_project_scan(".")
        print("# Setup Report")
        print("")
        print("Prefetch results:")
        print("- " + prefetch_mdm.name + ": started=" + str(prefetch_mdm.started) + " — " + prefetch_mdm.detail)
        print("- " + prefetch_key.name + ": started=" + str(prefetch_key.started) + " — " + prefetch_key.detail)
        print("- " + prefetch_scan.name + ": started=" + str(prefetch_scan.started) + " — " + prefetch_scan.detail)
        return

    # --- command-graph ---
    if subcmd == "command-graph":
        var graph = build_command_graph()
        print(graph.as_markdown())
        return

    # --- tool-pool ---
    if subcmd == "tool-pool":
        var pool = assemble_tool_pool()
        print(pool.as_markdown())
        return

    # --- bootstrap-graph ---
    if subcmd == "bootstrap-graph":
        var graph = build_bootstrap_graph()
        print(graph.as_markdown())
        return

    # --- subsystems ---
    if subcmd == "subsystems":
        var manifest = build_port_manifest()
        print("Subsystems (" + String(len(manifest.top_level_modules)) + "):")
        for i in range(len(manifest.top_level_modules)):
            var m = manifest.top_level_modules[i]
            print("- " + m.name + " (" + String(m.file_count) + " files) — " + m.notes)
        return

    # --- commands ---
    if subcmd == "commands":
        print(render_command_index())
        return

    # --- tools ---
    if subcmd == "tools":
        print(render_tool_index())
        return

    # --- route ---
    if subcmd == "route":
        var prompt = _rest_of_args(args, 2)
        if prompt == "":
            print("Usage: claw route <prompt>")
            return
        var runtime = PortRuntime()
        var matches = runtime.route_prompt(prompt)
        print("Routed matches for: " + prompt)
        for i in range(len(matches)):
            var m = matches[i]
            print(
                "- [" + m.kind + "] " + m.name
                + " (score=" + str(m.score) + ") — " + m.source_hint
            )
        return

    # --- bootstrap ---
    if subcmd == "bootstrap":
        var prompt = _rest_of_args(args, 2)
        if prompt == "":
            prompt = "default bootstrap prompt"
        var runtime = PortRuntime()
        var session = runtime.bootstrap_session(prompt)
        print(session.as_markdown())
        return

    # --- turn-loop ---
    if subcmd == "turn-loop":
        var prompt = _rest_of_args(args, 2)
        if prompt == "":
            prompt = "default turn-loop prompt"
        var runtime = PortRuntime()
        var results = runtime.run_turn_loop(prompt)
        print("Turn loop results (" + String(len(results)) + " turns):")
        for i in range(len(results)):
            print("")
            print("--- Turn " + String(i + 1) + " ---")
            print(results[i].output)
        return

    # --- flush-transcript ---
    if subcmd == "flush-transcript":
        var port = from_workspace()
        flush_transcript(port)
        print("Transcript flushed.")
        return

    # --- load-session ---
    if subcmd == "load-session":
        var session_id = _rest_of_args(args, 2)
        if session_id == "":
            print("Usage: claw load-session <session-id>")
            return
        print("Loading session: " + session_id)
        print("[Session load placeholder — not yet connected to session store]")
        return

    # --- remote-mode ---
    if subcmd == "remote-mode":
        var target = _rest_of_args(args, 2)
        if target == "":
            target = "localhost"
        var report = run_remote_mode(target)
        print(report.as_text())
        return

    # --- ssh-mode ---
    if subcmd == "ssh-mode":
        var target = _rest_of_args(args, 2)
        if target == "":
            target = "localhost"
        var report = run_ssh_mode(target)
        print(report.as_text())
        return

    # --- teleport-mode ---
    if subcmd == "teleport-mode":
        var target = _rest_of_args(args, 2)
        if target == "":
            target = "localhost"
        var report = run_teleport_mode(target)
        print(report.as_text())
        return

    # --- direct-connect-mode ---
    if subcmd == "direct-connect-mode":
        var target = _rest_of_args(args, 2)
        if target == "":
            target = "localhost"
        var report = run_direct_connect(target)
        print(report.as_text())
        return

    # --- deep-link-mode ---
    if subcmd == "deep-link-mode":
        var target = _rest_of_args(args, 2)
        if target == "":
            target = "localhost"
        var report = run_deep_link(target)
        print(report.as_text())
        return

    # --- show-command ---
    if subcmd == "show-command":
        var name = _rest_of_args(args, 2)
        if name == "":
            print("Usage: claw show-command <name>")
            return
        try:
            var cmd = get_command(name)
            print("Command: " + cmd.name)
            print("Responsibility: " + cmd.responsibility)
            print("Source: " + cmd.source_hint)
            print("Status: " + cmd.status)
        except e:
            print("Error: " + String(e))
        return

    # --- show-tool ---
    if subcmd == "show-tool":
        var name = _rest_of_args(args, 2)
        if name == "":
            print("Usage: claw show-tool <name>")
            return
        try:
            var tool = get_tool(name)
            print("Tool: " + tool.name)
            print("Responsibility: " + tool.responsibility)
            print("Source: " + tool.source_hint)
            print("Status: " + tool.status)
        except e:
            print("Error: " + String(e))
        return

    # --- exec-command ---
    if subcmd == "exec-command":
        var name = String("")
        if len(args) > 2:
            name = args[2]
        var prompt = _rest_of_args(args, 3)
        if name == "":
            print("Usage: claw exec-command <name> [prompt]")
            return
        var result = execute_command(name, prompt)
        if result.handled:
            print(result.message)
        else:
            print("Error: " + result.message)
        return

    # --- exec-tool ---
    if subcmd == "exec-tool":
        var name = String("")
        if len(args) > 2:
            name = args[2]
        var payload = _rest_of_args(args, 3)
        if name == "":
            print("Usage: claw exec-tool <name> [payload]")
            return
        var result = execute_tool(name, payload)
        if result.handled:
            print(result.message)
        else:
            print("Error: " + result.message)
        return

    print("Unknown subcommand: " + subcmd)


def _rest_of_args(args: List[String], start: Int) -> String:
    """Join args[start:] with spaces."""
    var result = String("")
    for i in range(start, len(args)):
        if i > start:
            result += " "
        result += args[i]
    return result


# ---------------------------------------------------------------------------
# Main entrypoint
# ---------------------------------------------------------------------------


def main() raises:
    """Claw Code CLI entrypoint."""
    var args = argv()

    # Handle --version
    for i in range(len(args)):
        if args[i] == "--version":
            print("Claw Code (Mojo port) v0.1.0")
            print("Runtime: Mojo 0.26.2")
            return

    # Handle --help
    for i in range(len(args)):
        if args[i] == "--help" or args[i] == "-h":
            _print_help()
            return

    # Check for subcommand dispatch (argv[1] is a known subcommand)
    if len(args) > 1 and _is_known_subcommand(args[1]):
        _dispatch_subcommand(args)
        return

    # Load configuration
    var config: RuntimeConfig
    try:
        config = load_config()
    except e:
        print("Error loading config: " + String(e))
        print("Set ANTHROPIC_API_KEY or create .claw.json")
        return

    # Override model from args
    for i in range(len(args)):
        if args[i] == "--model" and i + 1 < len(args):
            config.model = args[i + 1]

    # Discover CLAW.md files and assemble system prompt
    var claw_files = discover_claw_files()
    var system_prompt = assemble_system_prompt(
        claw_files,
        tools_profile=config.tools_profile,
        model=config.model,
    )

    # Get tool specs
    var tools = mvp_tool_specs()

    # Create session
    var session = create_session(config.model)

    # Check for -p (non-interactive single prompt)
    var single_prompt = String("")
    for i in range(len(args)):
        if args[i] == "-p" and i + 1 < len(args):
            single_prompt = args[i + 1]

    if single_prompt != "":
        _run_single(config, session, system_prompt, tools, single_prompt)
        return

    # Interactive REPL
    _run_repl(config, session, system_prompt, tools)


def _run_repl(
    config: RuntimeConfig,
    mut session: Session,
    system_prompt: String,
    tools: List[ToolSpec],
) raises:
    """Run the interactive REPL loop."""
    var commands = CommandRegistry()

    print("\033[1;36m╭─────────────────────────────────────╮\033[0m")
    print("\033[1;36m│  Claw Code (Mojo) v0.1.0            │\033[0m")
    print("\033[1;36m│  Model: " + config.model + "  │\033[0m")
    print("\033[1;36m│  Type /help for commands, /q to quit │\033[0m")
    print("\033[1;36m╰─────────────────────────────────────╯\033[0m")
    print()

    while True:
        # Read input
        print("\033[1;32m>\033[0m ", end="")
        var input_line: String
        try:
            input_line = input()
        except:
            break  # EOF

        var trimmed = input_line.strip()
        if trimmed == "":
            continue

        # Handle quit
        if trimmed == "/q" or trimmed == "/quit" or trimmed == "/exit":
            print("Goodbye!")
            break

        # Handle slash commands
        if trimmed.startswith("/"):
            var without_slash = String(trimmed.removeprefix("/"))
            var parts = without_slash.split(" ")
            var cmd_name = String(parts[0])
            var cmd_args = String(without_slash.removeprefix(cmd_name).strip()) if len(parts) > 1 else String("")
            var result = commands.dispatch(cmd_name, cmd_args)
            if result.error != "":
                print("\033[31m" + result.error + "\033[0m")
            else:
                print(result.output)
            if result.should_exit:
                break
            continue

        # Regular message — send to conversation loop
        print(
            "\033[33m[API call not yet connected — bridge/http integration pending]\033[0m"
        )
        print(
            "Would send: "
            + String(len(trimmed))
            + " chars to "
            + config.model
            + " with "
            + String(len(tools))
            + " tools"
        )

    # Save session on exit
    try:
        save_session(session, config.session_dir)
        print("Session saved: " + session.id)
    except:
        pass


def _run_single(
    config: RuntimeConfig,
    mut session: Session,
    system_prompt: String,
    tools: List[ToolSpec],
    prompt: String,
) raises:
    """Run a single non-interactive prompt."""
    var display = prompt if len(prompt) <= 80 else prompt
    print("Running: " + display)
    print("[API call not yet connected — bridge/http integration pending]")


def _print_help():
    """Print CLI help message."""
    print("Claw Code (Mojo port) — AI coding assistant")
    print()
    print("Usage:")
    print("  claw [options] [prompt]")
    print("  claw <subcommand> [args]")
    print()
    print("Options:")
    print("  --model <model>   Override model (default: claude-opus-4-6)")
    print("  --version         Show version")
    print("  --help, -h        Show this help")
    print("  -p <prompt>       Run single prompt non-interactively")
    print()
    print("Subcommands:")
    print("  summary           Render workspace summary")
    print("  manifest          Print port manifest")
    print("  parity-audit      Run parity audit")
    print("  setup-report      Render setup report")
    print("  command-graph     Show command graph")
    print("  tool-pool         Show tool pool")
    print("  bootstrap-graph   Show bootstrap graph")
    print("  subsystems        List subsystems")
    print("  commands          List commands")
    print("  tools             List tools")
    print("  route <prompt>    Route a prompt to commands/tools")
    print("  bootstrap [prompt] Bootstrap a session")
    print("  turn-loop [prompt] Run turn loop")
    print("  flush-transcript  Flush transcript")
    print("  load-session <id> Load session")
    print("  remote-mode [target]         Remote mode simulation")
    print("  ssh-mode [target]            SSH mode simulation")
    print("  teleport-mode [target]       Teleport mode simulation")
    print("  direct-connect-mode [target] Direct-connect mode simulation")
    print("  deep-link-mode [target]      Deep-link mode simulation")
    print("  show-command <name>  Show a specific command entry")
    print("  show-tool <name>     Show a specific tool entry")
    print("  exec-command <name> [prompt]  Execute a command")
    print("  exec-tool <name> [payload]    Execute a tool")
    print()
    print("Interactive commands:")
    print("  /help             Show available slash commands")
    print("  /q, /quit         Exit the REPL")
    print("  /status           Show session status")
    print("  /cost             Show token usage and cost")
    print("  /model            Switch model")
    print("  /compact          Compact conversation context")
