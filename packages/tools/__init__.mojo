# tools/ — Built-in tool registry and execution
#
# Each tool is a struct conforming to the Tool trait.
# The registry returns ToolSpec definitions for API requests
# and dispatches execution by tool name.

from std.collections import List, Dict
from api.types import ToolSpec


def mvp_tool_specs() -> List[ToolSpec]:
    """Return the MVP set of tool specifications for API requests."""
    var specs = List[ToolSpec]()

    specs.append(ToolSpec(
        name="Bash",
        description="Execute a bash command and return its output.",
        input_schema='{"type":"object","properties":{"command":{"type":"string","description":"The bash command to execute"},"timeout":{"type":"integer","description":"Timeout in milliseconds (max 600000)"}},"required":["command"]}',
    ))

    specs.append(ToolSpec(
        name="Read",
        description="Read a file from the filesystem.",
        input_schema='{"type":"object","properties":{"file_path":{"type":"string","description":"Absolute path to the file"},"offset":{"type":"integer","description":"Line number to start from"},"limit":{"type":"integer","description":"Number of lines to read"}},"required":["file_path"]}',
    ))

    specs.append(ToolSpec(
        name="Write",
        description="Write content to a file, creating it if needed.",
        input_schema='{"type":"object","properties":{"file_path":{"type":"string","description":"Absolute path to the file"},"content":{"type":"string","description":"Content to write"}},"required":["file_path","content"]}',
    ))

    specs.append(ToolSpec(
        name="Edit",
        description="Perform exact string replacement in a file.",
        input_schema='{"type":"object","properties":{"file_path":{"type":"string","description":"Absolute path to the file"},"old_string":{"type":"string","description":"Text to replace"},"new_string":{"type":"string","description":"Replacement text"},"replace_all":{"type":"boolean","description":"Replace all occurrences"}},"required":["file_path","old_string","new_string"]}',
    ))

    specs.append(ToolSpec(
        name="Glob",
        description="Find files matching a glob pattern.",
        input_schema='{"type":"object","properties":{"pattern":{"type":"string","description":"Glob pattern (e.g. **/*.mojo)"},"path":{"type":"string","description":"Directory to search in"}},"required":["pattern"]}',
    ))

    specs.append(ToolSpec(
        name="Grep",
        description="Search file contents using regex patterns.",
        input_schema='{"type":"object","properties":{"pattern":{"type":"string","description":"Regex pattern to search for"},"path":{"type":"string","description":"File or directory to search"},"glob":{"type":"string","description":"Glob to filter files"},"output_mode":{"type":"string","enum":["content","files_with_matches","count"]}},"required":["pattern"]}',
    ))

    specs.append(ToolSpec(
        name="TodoWrite",
        description="Create and manage a task list for tracking progress.",
        input_schema='{"type":"object","properties":{"todos":{"type":"array","items":{"type":"object","properties":{"content":{"type":"string"},"status":{"type":"string","enum":["pending","in_progress","completed"]},"activeForm":{"type":"string"}},"required":["content","status","activeForm"]}}},"required":["todos"]}',
    ))

    return specs^
