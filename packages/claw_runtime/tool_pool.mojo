# runtime/tool_pool.mojo — Tool pool assembly
#
# Ported from src/tool_pool.py.
# Assembles the active tool pool with filtering by mode and MCP inclusion.

from std.collections import List
from .models import PortingModule
from .permissions import ToolPermissionContext
from .tool_registry import get_tools


@fieldwise_init
struct ToolPool(Copyable, Movable):
    """Frozen pool of active tools with configuration metadata."""
    var tools: List[PortingModule]
    var simple_mode: Bool
    var include_mcp: Bool

    def as_markdown(self) -> String:
        """Render the tool pool as Markdown text."""
        var lines = List[String]()
        lines.append("# Tool Pool")
        lines.append("")
        lines.append("Simple mode: " + String(self.simple_mode))
        lines.append("Include MCP: " + String(self.include_mcp))
        lines.append("Tool count: " + String(len(self.tools)))
        var cap = len(self.tools)
        if cap > 15:
            cap = 15
        for i in range(cap):
            lines.append(
                "- " + self.tools[i].name + " — " + self.tools[i].source_hint
            )
        var result = String("")
        for i in range(len(lines)):
            if i > 0:
                result += "\n"
            result += lines[i]
        return result


def assemble_tool_pool(
    simple_mode: Bool = False,
    include_mcp: Bool = True,
    use_permission_context: Bool = False,
    permission_context: ToolPermissionContext = ToolPermissionContext(
        deny_names=List[String](), deny_prefixes=List[String]()
    ),
) -> ToolPool:
    """Assemble the tool pool with the given configuration."""
    return ToolPool(
        tools=get_tools(
            simple_mode=simple_mode,
            include_mcp=include_mcp,
            permission_context=permission_context,
            use_permission_context=use_permission_context,
        ),
        simple_mode=simple_mode,
        include_mcp=include_mcp,
    )
