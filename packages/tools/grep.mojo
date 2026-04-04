# tools/grep.mojo — Content search tool using native string matching
#
# For regex patterns, delegates to bridge/regex.mojo (Python re module).
# This implementation handles literal string search natively.

from std.pathlib import Path
from std.collections import List
from std.os import listdir


@fieldwise_init
struct GrepMatch(Copyable, Movable, Writable):
    """A single grep match with file, line number, and content."""
    var file_path: String
    var line_number: Int
    var line_content: String

    def __str__(self) -> String:
        return self.file_path + ":" + String(self.line_number) + ":" + self.line_content


struct GrepTool:
    """Search file contents for patterns."""

    def execute(
        self,
        pattern: String,
        path: String = "",
        file_glob: String = "",
        output_mode: String = "files_with_matches",
        max_results: Int = 250,
    ) raises -> String:
        """Search for a pattern in files.

        Args:
            pattern: String pattern to search for (literal match).
            path: File or directory to search in.
            file_glob: Glob pattern to filter files (e.g. "*.mojo").
            output_mode: "content", "files_with_matches", or "count".
            max_results: Maximum number of results to return.

        Returns:
            Formatted search results.
        """
        var search_path = Path(path) if path != "" else Path()
        var matches = List[GrepMatch]()

        if search_path.is_file():
            self._search_file(search_path, pattern, matches)
        elif search_path.is_dir():
            self._search_dir(search_path, pattern, file_glob, matches, max_results)
        else:
            raise Error("Path not found: " + String(search_path))

        return self._format_results(matches, output_mode, max_results)

    def _search_file(
        self, file_path: Path, pattern: String, mut matches: List[GrepMatch]
    ) raises:
        """Search a single file for the pattern."""
        var content = file_path.read_text()
        var lines = content.split("\n")
        for i in range(len(lines)):
            if pattern in lines[i]:
                matches.append(GrepMatch(
                    file_path=String(file_path),
                    line_number=i + 1,
                    line_content=lines[i],
                ))

    def _search_dir(
        self,
        dir_path: Path,
        pattern: String,
        file_glob: String,
        mut matches: List[GrepMatch],
        max_results: Int,
    ) raises:
        """Recursively search a directory."""
        if len(matches) >= max_results:
            return

        var entries = listdir(dir_path)
        for entry in entries:
            if entry[].startswith("."):
                continue  # Skip hidden files/dirs
            var child = dir_path / entry[]
            if child.is_dir():
                self._search_dir(child, pattern, file_glob, matches, max_results)
            elif child.is_file():
                if file_glob != "" and not _simple_glob(entry[], file_glob):
                    continue
                try:
                    self._search_file(child, pattern, matches)
                except:
                    pass  # Skip binary/unreadable files

    def _format_results(
        self, matches: List[GrepMatch], mode: String, limit: Int
    ) -> String:
        """Format grep results according to output mode."""
        var result = String("")
        var count = 0

        if mode == "files_with_matches":
            var seen = List[String]()
            for match in matches:
                if count >= limit:
                    break
                var fp = match[].file_path
                var found = False
                for s in seen:
                    if s[] == fp:
                        found = True
                        break
                if not found:
                    seen.append(fp)
                    result += fp + "\n"
                    count += 1
        elif mode == "count":
            result = String(len(matches))
        else:  # "content"
            for match in matches:
                if count >= limit:
                    break
                result += String(match[]) + "\n"
                count += 1

        return result


def _simple_glob(name: String, pattern: String) -> Bool:
    """Match filename against simple glob (e.g. *.mojo, *.py)."""
    if pattern.startswith("*"):
        var suffix = pattern[1:]
        return name.endswith(suffix)
    return name == pattern
