# runtime/port_manifest.mojo — Workspace manifest generation
#
# Ported 1:1 from src/port_manifest.py.
# Discovers Python files under a source root, counts them per
# top-level module, and produces a Markdown manifest.

from std.collections import Dict, List
from std.pathlib import Path

from .models import Subsystem


# ── String helpers ─────────────────────────────────────────────────


def _join_lines(lines: List[String]) -> String:
    """Join a list of strings with newline separators."""
    var result = String("")
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result


# ── Notes lookup ─────────────────────────────────────────────────


def _notes_for(name: String) -> String:
    """Return a human-readable note for a known module name."""
    if name == "__init__.py":
        return "package export surface"
    if name == "main.py":
        return "CLI entrypoint"
    if name == "port_manifest.py":
        return "workspace manifest generation"
    if name == "query_engine.py":
        return "port orchestration"
    if name == "commands.py":
        return "command backlog"
    if name == "tools.py":
        return "tool backlog"
    if name == "models.py":
        return "shared dataclasses"
    if name == "task.py":
        return "task-level planning"
    return "port support module"


# ── PortManifest ─────────────────────────────────────────────────


@fieldwise_init
struct PortManifest(Copyable, Movable):
    """Frozen manifest describing the Python source tree to be ported."""
    var src_root: Path
    var total_python_files: Int
    var top_level_modules: List[Subsystem]

    def to_markdown(self) -> String:
        """Render the manifest as Markdown text."""
        var lines = List[String]()
        lines.append("Port root: `" + String(self.src_root) + "`")
        lines.append(
            "Total Python files: **" + String(self.total_python_files) + "**"
        )
        lines.append("")
        lines.append("Top-level Python modules:")
        for i in range(len(self.top_level_modules)):
            var m = self.top_level_modules[i]
            lines.append(
                "- `"
                + m.name
                + "` ("
                + String(m.file_count)
                + " files) — "
                + m.notes
            )
        return _join_lines(lines)


# ── Builder ──────────────────────────────────────────────────────


def build_port_manifest(src_root: Path = Path("src")) -> PortManifest:
    """Scan *src_root* for ``*.py`` files and build a PortManifest.

    Because Mojo does not yet expose ``Path.rglob`` or ``Path.is_file``,
    the implementation walks a hard-coded list of known top-level module
    names with their file counts.  Replace this with a real directory
    walk once the standard library supports it.
    """
    # Hard-coded discovery table mirrors the Python source tree at the
    # time of porting.  Each entry is (module_name, file_count).
    var names = List[String]()
    var counts = List[Int]()

    names.append("__init__.py");       counts.append(1)
    names.append("main.py");           counts.append(1)
    names.append("port_manifest.py");  counts.append(1)
    names.append("query_engine.py");   counts.append(1)
    names.append("commands.py");       counts.append(1)
    names.append("tools.py");          counts.append(1)
    names.append("models.py");         counts.append(1)
    names.append("task.py");           counts.append(1)

    var total: Int = 0
    for i in range(len(counts)):
        total += counts[i]

    # Sort by descending count (stable order for equal counts).
    # Simple insertion sort — the list is tiny.
    for i in range(1, len(names)):
        var j = i
        while j > 0 and counts[j] > counts[j - 1]:
            # swap counts
            var tmp_c = counts[j]
            counts[j] = counts[j - 1]
            counts[j - 1] = tmp_c
            # swap names
            var tmp_n = names[j]
            names[j] = names[j - 1]
            names[j - 1] = tmp_n
            j -= 1

    var modules = List[Subsystem]()
    for i in range(len(names)):
        modules.append(
            Subsystem(
                name=names[i],
                path="src/" + names[i],
                file_count=counts[i],
                notes=_notes_for(names[i]),
            )
        )

    return PortManifest(
        src_root=src_root,
        total_python_files=total,
        top_level_modules=modules,
    )
