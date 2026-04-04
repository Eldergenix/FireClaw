# runtime/setup.mojo — Workspace setup, prefetch, deferred init, and system init
#
# Combined port of: src/prefetch.py, src/deferred_init.py, src/setup.py, src/system_init.py

from std.collections import List
from std.os import getenv
from std.pathlib import Path


# ---------------------------------------------------------------------------
# Prefetch (from src/prefetch.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct PrefetchResult(Copyable, Movable):
    """Result of a prefetch operation."""
    var name: String
    var started: Bool
    var detail: String


def start_mdm_raw_read() -> PrefetchResult:
    """Simulate MDM raw-read prefetch for workspace bootstrap."""
    return PrefetchResult(
        name="mdm_raw_read",
        started=True,
        detail="Simulated MDM raw-read prefetch for workspace bootstrap",
    )


def start_keychain_prefetch() -> PrefetchResult:
    """Simulate keychain prefetch for trusted startup path."""
    return PrefetchResult(
        name="keychain_prefetch",
        started=True,
        detail="Simulated keychain prefetch for trusted startup path",
    )


def start_project_scan(root: String) -> PrefetchResult:
    """Scan project root directory."""
    return PrefetchResult(
        name="project_scan",
        started=True,
        detail="Scanned project root " + root,
    )


# ---------------------------------------------------------------------------
# Deferred Init (from src/deferred_init.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct DeferredInitResult(Copyable, Movable):
    """Result of trust-gated deferred initialisation."""
    var trusted: Bool
    var plugin_init: Bool
    var skill_init: Bool
    var mcp_prefetch: Bool
    var session_hooks: Bool

    def as_lines(self) -> List[String]:
        """Return human-readable status lines."""
        var lines = List[String]()
        lines.append("- plugin_init=" + String(self.plugin_init))
        lines.append("- skill_init=" + String(self.skill_init))
        lines.append("- mcp_prefetch=" + String(self.mcp_prefetch))
        lines.append("- session_hooks=" + String(self.session_hooks))
        return lines


def run_deferred_init(trusted: Bool) -> DeferredInitResult:
    """Run deferred initialisation gated on trust status."""
    var enabled = trusted
    return DeferredInitResult(
        trusted=trusted,
        plugin_init=enabled,
        skill_init=enabled,
        mcp_prefetch=enabled,
        session_hooks=enabled,
    )


# ---------------------------------------------------------------------------
# Workspace Setup (from src/setup.py)
# ---------------------------------------------------------------------------

@fieldwise_init
struct WorkspaceSetup(Copyable, Movable):
    """Describes the runtime environment for the workspace."""
    var mojo_version: String
    var implementation: String
    var platform_name: String
    var test_command: String

    def startup_steps(self) -> List[String]:
        """Return the ordered list of startup steps."""
        var steps = List[String]()
        steps.append("start top-level prefetch side effects")
        steps.append("build workspace context")
        steps.append("load mirrored command snapshot")
        steps.append("load mirrored tool snapshot")
        steps.append("prepare parity audit hooks")
        steps.append("apply trust-gated deferred init")
        return steps


@fieldwise_init
struct SetupReport(Copyable, Movable):
    """Full setup report including prefetches and deferred init."""
    var setup: WorkspaceSetup
    var prefetches: List[PrefetchResult]
    var deferred_init: DeferredInitResult
    var trusted: Bool
    var cwd: String

    def as_markdown(self) -> String:
        """Render the report as a Markdown string."""
        var lines = List[String]()
        lines.append("# Setup Report")
        lines.append("")
        lines.append("- Mojo: " + self.setup.mojo_version + " (" + self.setup.implementation + ")")
        lines.append("- Platform: " + self.setup.platform_name)
        lines.append("- Trusted mode: " + String(self.trusted))
        lines.append("- CWD: " + self.cwd)
        lines.append("")
        lines.append("Prefetches:")
        for i in range(len(self.prefetches)):
            var p = self.prefetches[i]
            lines.append("- " + p.name + ": " + p.detail)
        lines.append("")
        lines.append("Deferred init:")
        var init_lines = self.deferred_init.as_lines()
        for i in range(len(init_lines)):
            lines.append(init_lines[i])

        var result = String("")
        for i in range(len(lines)):
            if i > 0:
                result = result + "\n"
            result = result + lines[i]
        return result


def build_workspace_setup() -> WorkspaceSetup:
    """Build a WorkspaceSetup describing the current Mojo runtime."""
    var platform_name = getenv("OSTYPE", "darwin")
    return WorkspaceSetup(
        mojo_version="0.26.2",
        implementation="Mojo",
        platform_name=platform_name,
        test_command="mojo test -v",
    )


def run_setup(cwd: String = "", trusted: Bool = True) raises -> SetupReport:
    """Run full workspace setup and return a report."""
    var root: String
    if cwd != "":
        root = cwd
    else:
        root = String(Path())

    var prefetches = List[PrefetchResult]()
    prefetches.append(start_mdm_raw_read())
    prefetches.append(start_keychain_prefetch())
    prefetches.append(start_project_scan(root))

    return SetupReport(
        setup=build_workspace_setup(),
        prefetches=prefetches,
        deferred_init=run_deferred_init(trusted=trusted),
        trusted=trusted,
        cwd=root,
    )


# ---------------------------------------------------------------------------
# System Init (from src/system_init.py)
# ---------------------------------------------------------------------------

def build_system_init_message(trusted: Bool = True) raises -> String:
    """Build the system init message shown at startup.

    References command/tool registries from sibling modules. Uses placeholder
    counts when the registries are not yet wired up.
    """
    var report = run_setup(trusted=trusted)

    # Placeholder counts for command and tool registries.
    # In the full runtime these come from command_registry and port_runtime.
    var builtin_command_count: Int = 14
    var loaded_command_count: Int = 14
    var loaded_tool_count: Int = 12

    var steps = report.setup.startup_steps()

    var lines = List[String]()
    lines.append("# System Init")
    lines.append("")
    lines.append("Trusted: " + String(report.trusted))
    lines.append("Built-in command names: " + String(builtin_command_count))
    lines.append("Loaded command entries: " + String(loaded_command_count))
    lines.append("Loaded tool entries: " + String(loaded_tool_count))
    lines.append("")
    lines.append("Startup steps:")
    for i in range(len(steps)):
        lines.append("- " + steps[i])

    var result = String("")
    for i in range(len(lines)):
        if i > 0:
            result = result + "\n"
        result = result + lines[i]
    return result
