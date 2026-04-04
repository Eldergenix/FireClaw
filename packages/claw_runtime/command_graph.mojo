# runtime/command_graph.mojo — Command graph classification
#
# Ported from src/command_graph.py.
# Classifies commands into builtins, plugin-like, and skill-like categories.

from std.collections import List
from .models import PortingModule
from .command_registry import get_commands


@fieldwise_init
struct CommandGraph(Copyable, Movable):
    """Frozen command graph grouping commands by category."""
    var builtins: List[PortingModule]
    var plugin_like: List[PortingModule]
    var skill_like: List[PortingModule]

    def flattened(self) -> List[PortingModule]:
        """Return all commands in a single flat list."""
        var result = List[PortingModule]()
        for i in range(len(self.builtins)):
            result.append(self.builtins[i])
        for i in range(len(self.plugin_like)):
            result.append(self.plugin_like[i])
        for i in range(len(self.skill_like)):
            result.append(self.skill_like[i])
        return result

    def as_markdown(self) -> String:
        """Render the command graph as Markdown text."""
        var lines = List[String]()
        lines.append("# Command Graph")
        lines.append("")
        lines.append("Builtins: " + String(len(self.builtins)))
        lines.append("Plugin-like: " + String(len(self.plugin_like)))
        lines.append("Skill-like: " + String(len(self.skill_like)))
        var result = String("")
        for i in range(len(lines)):
            if i > 0:
                result += "\n"
            result += lines[i]
        return result


def build_command_graph() -> CommandGraph:
    """Build a CommandGraph by classifying all commands."""
    var commands = get_commands()
    var builtins = List[PortingModule]()
    var plugin_like = List[PortingModule]()
    var skill_like = List[PortingModule]()
    for i in range(len(commands)):
        var m = commands[i]
        var hint_lower = m.source_hint.lower()
        if String("plugin") in hint_lower:
            plugin_like.append(m)
        elif String("skills") in hint_lower:
            skill_like.append(m)
        else:
            builtins.append(m)
    return CommandGraph(
        builtins=builtins,
        plugin_like=plugin_like,
        skill_like=skill_like,
    )
