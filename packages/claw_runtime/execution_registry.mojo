# runtime/execution_registry.mojo — Unified execution registry (ported from src/execution_registry.py)

from std.collections import List
from .command_registry import PORTED_COMMANDS, execute_command
from .tool_registry import PORTED_TOOLS, execute_tool


@fieldwise_init
struct MirroredCommand(Copyable, Movable):
    """A command entry that delegates to the command registry."""
    var name: String
    var source_hint: String

    def execute(self, prompt: String) -> String:
        """Execute the mirrored command and return its result message."""
        return execute_command(self.name, prompt).message


@fieldwise_init
struct MirroredTool(Copyable, Movable):
    """A tool entry that delegates to the tool registry."""
    var name: String
    var source_hint: String

    def execute(self, payload: String) -> String:
        """Execute the mirrored tool and return its result message."""
        return execute_tool(self.name, payload).message


@fieldwise_init
struct ExecutionRegistry(Copyable, Movable):
    """Combined registry of mirrored commands and tools."""
    var commands: List[MirroredCommand]
    var tools: List[MirroredTool]

    def command(self, name: String) raises -> MirroredCommand:
        """Look up a command by name (case-insensitive).

        Raises if no matching command is found.
        """
        var lowered: String = name.lower()
        for i in range(len(self.commands)):
            if self.commands[i].name.lower() == lowered:
                return self.commands[i]
        raise Error("Unknown command in execution registry: " + name)

    def tool(self, name: String) raises -> MirroredTool:
        """Look up a tool by name (case-insensitive).

        Raises if no matching tool is found.
        """
        var lowered: String = name.lower()
        for i in range(len(self.tools)):
            if self.tools[i].name.lower() == lowered:
                return self.tools[i]
        raise Error("Unknown tool in execution registry: " + name)


def build_execution_registry() -> ExecutionRegistry:
    """Build an ExecutionRegistry from the ported command and tool snapshots."""
    var commands = List[MirroredCommand]()
    for i in range(len(PORTED_COMMANDS)):
        commands.append(MirroredCommand(
            name=PORTED_COMMANDS[i].name,
            source_hint=PORTED_COMMANDS[i].source_hint,
        ))

    var tools = List[MirroredTool]()
    for i in range(len(PORTED_TOOLS)):
        tools.append(MirroredTool(
            name=PORTED_TOOLS[i].name,
            source_hint=PORTED_TOOLS[i].source_hint,
        ))

    return ExecutionRegistry(commands=commands, tools=tools)
