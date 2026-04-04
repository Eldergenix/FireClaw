from std.pathlib import Path
from std.collections import List


def _count_files_with_extension(root: Path, extension: String) raises -> Int:
    """Count files with a given extension under root (non-recursive placeholder).

    Mojo's pathlib does not yet expose rglob, so this walks one level using
    listdir.  Replace with a recursive walk when the standard library supports
    it.
    """
    var count: Int = 0
    if not root.exists():
        return 0
    var entries: List[Path] = root.listdir()
    for i in range(len(entries)):
        var entry: Path = root / String(entries[i])
        if String(entry).endswith(extension) and entry.is_file():
            count += 1
    return count


def _count_all_files(root: Path) raises -> Int:
    """Count all files under root (single-level placeholder)."""
    var count: Int = 0
    if not root.exists():
        return 0
    var entries: List[Path] = root.listdir()
    for i in range(len(entries)):
        var entry: Path = root / String(entries[i])
        if entry.is_file():
            count += 1
    return count


@fieldwise_init
struct PortContext(Copyable, Movable):
    var source_root: Path
    var tests_root: Path
    var assets_root: Path
    var archive_root: Path
    var python_file_count: Int
    var test_file_count: Int
    var asset_file_count: Int
    var archive_available: Bool


def build_port_context(base: Path = Path()) raises -> PortContext:
    var root: Path
    if String(base) == ".":
        root = Path(".")
    else:
        root = base

    var source_root: Path = root / "src"
    var tests_root: Path = root / "tests"
    var assets_root: Path = root / "assets"
    var archive_root: Path = root / "archive" / "claw_code_ts_snapshot" / "src"

    return PortContext(
        source_root=source_root,
        tests_root=tests_root,
        assets_root=assets_root,
        archive_root=archive_root,
        python_file_count=_count_files_with_extension(source_root, ".py"),
        test_file_count=_count_files_with_extension(tests_root, ".py"),
        asset_file_count=_count_all_files(assets_root),
        archive_available=archive_root.exists(),
    )


def render_context(context: PortContext) -> String:
    var lines = List[String]()
    lines.append("Source root: " + String(context.source_root))
    lines.append("Test root: " + String(context.tests_root))
    lines.append("Assets root: " + String(context.assets_root))
    lines.append("Archive root: " + String(context.archive_root))
    lines.append("Python files: " + String(context.python_file_count))
    lines.append("Test files: " + String(context.test_file_count))
    lines.append("Assets: " + String(context.asset_file_count))
    lines.append("Archive available: " + String(context.archive_available))

    var result: String = ""
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result
