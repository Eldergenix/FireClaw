# runtime/misc.mojo — Small utility types and helpers
# (ported from src/query.py, src/Tool.py, src/task.py, src/tasks.py,
#  src/ink.py, src/dialogLaunchers.py, src/interactiveHelpers.py,
#  src/replLauncher.py, src/projectOnboardingState.py)

from std.collections import List


# ---------------------------------------------------------------------------
# Query (src/query.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct QueryRequest(Copyable, Movable):
    """An incoming query prompt."""
    var prompt: String


@fieldwise_init
struct QueryResponse(Copyable, Movable):
    """The textual response to a query."""
    var text: String


# ---------------------------------------------------------------------------
# Tool definitions (src/Tool.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct ToolDefinition(Copyable, Movable):
    """A lightweight definition of a tool's name and purpose."""
    var name: String
    var purpose: String


def default_tool_definitions() -> List[ToolDefinition]:
    """Return the default set of tool definitions."""
    var tools = List[ToolDefinition]()
    tools.append(ToolDefinition(
        name="port_manifest", purpose="Summarize the active workspace",
    ))
    tools.append(ToolDefinition(
        name="query_engine", purpose="Render a porting summary",
    ))
    return tools


# ---------------------------------------------------------------------------
# Porting tasks (src/task.py + src/tasks.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct PortingTask(Copyable, Movable):
    """A named porting task with a description."""
    var name: String
    var description: String


def default_tasks() -> List[PortingTask]:
    """Return the default list of porting tasks."""
    var tasks = List[PortingTask]()
    tasks.append(PortingTask(
        name="root-module-parity",
        description="Mirror the root module surface",
    ))
    tasks.append(PortingTask(
        name="directory-parity",
        description="Mirror top-level subsystem names",
    ))
    tasks.append(PortingTask(
        name="parity-audit",
        description="Continuously measure parity against archive",
    ))
    return tasks


# ---------------------------------------------------------------------------
# Markdown panel (src/ink.py)
# ---------------------------------------------------------------------------

def render_markdown_panel(text: String) -> String:
    """Render text inside an ASCII border panel."""
    var border: String = "=" * 40
    return border + "\n" + text + "\n" + border


# ---------------------------------------------------------------------------
# Dialog launchers (src/dialogLaunchers.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct DialogLauncher(Copyable, Movable):
    """A named dialog that can be launched from the UI."""
    var name: String
    var description: String


def default_dialog_launchers() -> List[DialogLauncher]:
    """Return the default set of dialog launchers."""
    var dialogs = List[DialogLauncher]()
    dialogs.append(DialogLauncher(
        name="summary", description="Launch the Markdown summary view",
    ))
    dialogs.append(DialogLauncher(
        name="parity_audit", description="Launch the parity audit view",
    ))
    return dialogs


# ---------------------------------------------------------------------------
# Interactive helpers (src/interactiveHelpers.py)
# ---------------------------------------------------------------------------

def bulletize(items: List[String]) -> String:
    """Format a list of strings as a bullet list."""
    var result: String = ""
    for i in range(len(items)):
        if i > 0:
            result += "\n"
        result += "- " + items[i]
    return result


# ---------------------------------------------------------------------------
# REPL launcher (src/replLauncher.py)
# ---------------------------------------------------------------------------

def build_repl_banner() -> String:
    """Return the REPL banner message."""
    return "Mojo porting REPL is not interactive yet; use `mojo run main.mojo summary` instead."


# ---------------------------------------------------------------------------
# Project onboarding state (src/projectOnboardingState.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct ProjectOnboardingState(Copyable, Movable):
    """Tracks basic onboarding flags for a project."""
    var has_readme: Bool
    var has_tests: Bool
    var python_first: Bool


def new_project_onboarding_state(
    has_readme: Bool,
    has_tests: Bool,
    python_first: Bool = True,
) -> ProjectOnboardingState:
    """Create a ProjectOnboardingState with an optional default for python_first."""
    return ProjectOnboardingState(
        has_readme=has_readme,
        has_tests=has_tests,
        python_first=python_first,
    )
