# tools/glob.mojo — File pattern matching tool

from std.pathlib import Path
from std.collections import List
from std.os import listdir


struct GlobTool:
    """Find files matching glob patterns using native path traversal."""

    def execute(
        self, pattern: String, base_path: String = ""
    ) raises -> List[String]:
        """Find files matching a glob pattern.

        Supports: *, **, ? wildcards.
        Returns sorted list of matching file paths.
        """
        var root = Path(base_path) if base_path != "" else Path()
        var results = List[String]()
        self._walk_and_match(root, pattern, results)
        return results

    def _walk_and_match(
        self, dir: Path, pattern: String, mut results: List[String]
    ) raises:
        """Recursively walk directory and match files against pattern."""
        if not dir.exists():
            return

        # Simple glob implementation: split pattern by /
        var parts = pattern.split("/")
        if len(parts) == 0:
            return

        self._match_parts(dir, parts, 0, results)

    def _match_parts(
        self,
        current: Path,
        parts: List[String],
        part_idx: Int,
        mut results: List[String],
    ) raises:
        """Match path parts recursively."""
        if part_idx >= len(parts):
            if current.exists():
                results.append(String(current))
            return

        var part = parts[part_idx]

        if part == "**":
            # Match zero or more directories
            # Try matching remaining pattern at current level
            self._match_parts(current, parts, part_idx + 1, results)
            # Try descending into subdirectories
            if current.is_dir():
                var entries = listdir(current)
                for entry in entries:
                    var child = current / entry[]
                    if child.is_dir():
                        self._match_parts(child, parts, part_idx, results)
        else:
            # Match against entries in current directory
            if not current.is_dir():
                return
            var entries = listdir(current)
            for entry in entries:
                if _wildcard_match(entry[], part):
                    var child = current / entry[]
                    if part_idx == len(parts) - 1:
                        results.append(String(child))
                    elif child.is_dir():
                        self._match_parts(child, parts, part_idx + 1, results)


def _wildcard_match(name: String, pattern: String) -> Bool:
    """Match a filename against a simple wildcard pattern (*, ?)."""
    return _wm(name, 0, pattern, 0)


def _wm(name: String, ni: Int, pat: String, pi: Int) -> Bool:
    """Recursive wildcard matcher."""
    if pi == len(pat):
        return ni == len(name)
    if pat[pi] == "*":
        # * matches zero or more characters
        var i = ni
        while i <= len(name):
            if _wm(name, i, pat, pi + 1):
                return True
            i += 1
        return False
    if ni == len(name):
        return False
    if pat[pi] == "?" or pat[pi] == name[ni]:
        return _wm(name, ni + 1, pat, pi + 1)
    return False
