# runtime/tool_registry.mojo — Tool surface registry (ported from src/tools.py)

from std.collections import List
from .models import PortingModule, PortingBacklog
from .permissions import ToolPermissionContext


@fieldwise_init
struct ToolExecution(Copyable, Movable):
    """Result of attempting to execute a mirrored tool."""
    var name: String
    var source_hint: String
    var payload: String
    var handled: Bool
    var message: String


def load_tool_snapshot() -> List[PortingModule]:
    """Return a list of representative tool entries.

    # TODO: Load from reference_data/tools_snapshot.json when the data file
    # is available.  For now, return hardcoded placeholder entries so the rest
    # of the registry can function without dynamic JSON loading at module init.
    """
    var entries = List[PortingModule]()
    entries.append(PortingModule(
        name="BashTool", responsibility="Execute shell commands in a sandbox",
        source_hint="src/tools/bash.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="FileReadTool", responsibility="Read file contents from disk",
        source_hint="src/tools/file_read.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="FileEditTool", responsibility="Apply edits to existing files",
        source_hint="src/tools/file_edit.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="FileWriteTool", responsibility="Write new files to disk",
        source_hint="src/tools/file_write.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="GlobTool", responsibility="Search for files by glob pattern",
        source_hint="src/tools/glob.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="GrepTool", responsibility="Search file contents with regex",
        source_hint="src/tools/grep.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="McpTool", responsibility="Invoke MCP server tools",
        source_hint="src/tools/mcp/mcp_tool.ts", status="mirrored",
    ))
    entries.append(PortingModule(
        name="WebFetchTool", responsibility="Fetch content from URLs",
        source_hint="src/tools/web_fetch.ts", status="mirrored",
    ))
    return entries


# Module-level snapshot (replaces @lru_cache singleton).
var PORTED_TOOLS: List[PortingModule] = load_tool_snapshot()


def build_tool_backlog() -> PortingBacklog:
    """Build a PortingBacklog covering the full tool surface."""
    var modules = List[PortingModule]()
    for i in range(len(PORTED_TOOLS)):
        modules.append(PORTED_TOOLS[i])
    return PortingBacklog(title="Tool surface", modules=modules)


def tool_names() -> List[String]:
    """Return a list of tool names."""
    var names = List[String]()
    for i in range(len(PORTED_TOOLS)):
        names.append(PORTED_TOOLS[i].name)
    return names


def get_tool(name: String) raises -> PortingModule:
    """Look up a tool by name (case-insensitive).

    Raises if no matching tool is found.
    """
    var needle: String = name.lower()
    for i in range(len(PORTED_TOOLS)):
        if PORTED_TOOLS[i].name.lower() == needle:
            return PORTED_TOOLS[i]
    raise Error("Unknown mirrored tool: " + name)


def filter_tools_by_permission_context(
    tools: List[PortingModule],
    permission_context: ToolPermissionContext,
    use_context: Bool = False,
) -> List[PortingModule]:
    """Filter out tools blocked by the permission context.

    When *use_context* is False the tools are returned unchanged (equivalent
    to the Python version receiving ``permission_context=None``).
    """
    if not use_context:
        return tools
    var filtered = List[PortingModule]()
    for i in range(len(tools)):
        if not permission_context.blocks(tools[i].name):
            filtered.append(tools[i])
    return filtered


def get_tools(
    simple_mode: Bool = False,
    include_mcp: Bool = True,
    permission_context: ToolPermissionContext = ToolPermissionContext(
        deny_names=List[String](), deny_prefixes=List[String]()
    ),
    use_permission_context: Bool = False,
) -> List[PortingModule]:
    """Return tools, optionally filtering by mode and permission context.

    Pass ``use_permission_context=True`` to honour the *permission_context*
    argument (mirrors the Python ``permission_context is not None`` branch).
    """
    var tools = List[PortingModule]()
    for i in range(len(PORTED_TOOLS)):
        var m = PORTED_TOOLS[i]
        if simple_mode:
            if m.name != "BashTool" and m.name != "FileReadTool" and m.name != "FileEditTool":
                continue
        if not include_mcp:
            if String("mcp") in m.name.lower() or String("mcp") in m.source_hint.lower():
                continue
        tools.append(m)
    return filter_tools_by_permission_context(tools, permission_context, use_permission_context)


def find_tools(query: String, limit: Int = 20) -> List[PortingModule]:
    """Find tools whose name or source_hint contains *query* (case-insensitive)."""
    var needle: String = query.lower()
    var results = List[PortingModule]()
    for i in range(len(PORTED_TOOLS)):
        if len(results) >= limit:
            break
        var m = PORTED_TOOLS[i]
        if needle in m.name.lower() or needle in m.source_hint.lower():
            results.append(m)
    return results


def execute_tool(name: String, payload: String = "") -> ToolExecution:
    """Execute (mirror) a tool by name. Returns a ToolExecution result."""
    try:
        var module = get_tool(name)
        var action: String = (
            "Mirrored tool '"
            + module.name
            + "' from "
            + module.source_hint
            + " would handle payload '"
            + payload
            + "'."
        )
        return ToolExecution(
            name=module.name,
            source_hint=module.source_hint,
            payload=payload,
            handled=True,
            message=action,
        )
    except:
        return ToolExecution(
            name=name,
            source_hint="",
            payload=payload,
            handled=False,
            message="Unknown mirrored tool: " + name,
        )


def render_tool_index(limit: Int = 20, query: String = "") -> String:
    """Render a human-readable index of tool entries."""
    var modules: List[PortingModule]
    if len(query) > 0:
        modules = find_tools(query, limit)
    else:
        modules = List[PortingModule]()
        var cap: Int = limit
        if cap > len(PORTED_TOOLS):
            cap = len(PORTED_TOOLS)
        for i in range(cap):
            modules.append(PORTED_TOOLS[i])

    var lines = List[String]()
    lines.append("Tool entries: " + String(len(PORTED_TOOLS)))
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
