# runtime/command_registry.mojo — Command surface registry (ported from src/commands.py)

from std.collections import List
from .models import PortingModule, PortingBacklog


@fieldwise_init
struct CommandExecution(Copyable, Movable):
    """Result of attempting to execute a mirrored command."""
    var name: String
    var source_hint: String
    var prompt: String
    var handled: Bool
    var message: String


def load_command_snapshot() -> List[PortingModule]:
    """Return a list of representative command entries.

    # TODO: Load from reference_data/commands_snapshot.json when the data file
    # is available.  For now, return hardcoded placeholder entries so the rest
    # of the registry can function without dynamic JSON loading at module init.
    """
    var entries = List[PortingModule]()
    entries.append(PortingModule(
        name="init", responsibility="Initialise a new project",
        source_hint="src/commands/init.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="doctor", responsibility="Run diagnostics on the environment",
        source_hint="src/commands/doctor.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="config", responsibility="Read or write configuration values",
        source_hint="src/commands/config.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="review", responsibility="Review pending changes or diffs",
        source_hint="src/commands/review.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="login", responsibility="Authenticate with the remote service",
        source_hint="src/commands/login.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="logout", responsibility="Revoke current authentication session",
        source_hint="src/commands/logout.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="resume", responsibility="Resume a previously interrupted session",
        source_hint="src/commands/resume.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="mcp", responsibility="Manage MCP plugin connections",
        source_hint="src/commands/plugins/mcp.ts", status="mirrored",
    ))
    return entries


# Module-level snapshot (replaces @lru_cache singleton).
var PORTED_COMMANDS: List[PortingModule] = load_command_snapshot()


def built_in_command_names() -> List[String]:
    """Return a list of all built-in command names."""
    var names = List[String]()
    for i in range(len(PORTED_COMMANDS)):
        names.append(PORTED_COMMANDS[i].name)
    return names


def build_command_backlog() -> PortingBacklog:
    """Build a PortingBacklog covering the full command surface."""
    var modules = List[PortingModule]()
    for i in range(len(PORTED_COMMANDS)):
        modules.append(PORTED_COMMANDS[i])
    return PortingBacklog(title="Command surface", modules=modules)


def command_names() -> List[String]:
    """Return a list of command names."""
    var names = List[String]()
    for i in range(len(PORTED_COMMANDS)):
        names.append(PORTED_COMMANDS[i].name)
    return names


def get_command(name: String) raises -> PortingModule:
    """Look up a command by name (case-insensitive).

    Raises if no matching command is found.
    """
    var needle: String = name.lower()
    for i in range(len(PORTED_COMMANDS)):
        if PORTED_COMMANDS[i].name.lower() == needle:
            return PORTED_COMMANDS[i]
    raise Error("Unknown mirrored command: " + name)


def get_commands(
    include_plugin_commands: Bool = True,
    include_skill_commands: Bool = True,
) -> List[PortingModule]:
    """Return commands, optionally excluding plugin or skill commands."""
    var commands = List[PortingModule]()
    for i in range(len(PORTED_COMMANDS)):
        var m = PORTED_COMMANDS[i]
        if not include_plugin_commands:
            if String("plugin") in m.source_hint.lower():
                continue
        if not include_skill_commands:
            if String("skills") in m.source_hint.lower():
                continue
        commands.append(m)
    return commands


def find_commands(query: String, limit: Int = 20) -> List[PortingModule]:
    """Find commands whose name or source_hint contains *query* (case-insensitive)."""
    var needle: String = query.lower()
    var results = List[PortingModule]()
    for i in range(len(PORTED_COMMANDS)):
        if len(results) >= limit:
            break
        var m = PORTED_COMMANDS[i]
        if needle in m.name.lower() or needle in m.source_hint.lower():
            results.append(m)
    return results


def execute_command(name: String, prompt: String = "") -> CommandExecution:
    """Execute (mirror) a command by name. Returns a CommandExecution result."""
    try:
        var module = get_command(name)
        var action: String = (
            "Mirrored command '"
            + module.name
            + "' from "
            + module.source_hint
            + " would handle prompt '"
            + prompt
            + "'."
        )
        return CommandExecution(
            name=module.name,
            source_hint=module.source_hint,
            prompt=prompt,
            handled=True,
            message=action,
        )
    except:
        return CommandExecution(
            name=name,
            source_hint="",
            prompt=prompt,
            handled=False,
            message="Unknown mirrored command: " + name,
        )


def render_command_index(limit: Int = 20, query: String = "") -> String:
    """Render a human-readable index of command entries."""
    var modules: List[PortingModule]
    if len(query) > 0:
        modules = find_commands(query, limit)
    else:
        modules = List[PortingModule]()
        var cap: Int = limit
        if cap > len(PORTED_COMMANDS):
            cap = len(PORTED_COMMANDS)
        for i in range(cap):
            modules.append(PORTED_COMMANDS[i])

    var lines = List[String]()
    lines.append("Command entries: " + String(len(PORTED_COMMANDS)))
    lines.append("")
    if len(query) > 0:
        lines.append("Filtered by: " + query)
        lines.append("")
    for i in range(len(modules)):
        lines.append("- " + modules[i].name + " — " + modules[i].source_hint)

    var result: String = ""
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result
