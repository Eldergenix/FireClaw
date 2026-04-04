# tools/file_read.mojo — File reading tool

from std.pathlib import Path
from std.collections import Optional


struct FileReadTool:
    """Read files from the filesystem with optional offset and limit."""

    def execute(
        self,
        file_path: String,
        offset: Int = 0,
        limit: Int = 2000,
    ) raises -> String:
        """Read a file and return its contents with line numbers.

        Args:
            file_path: Absolute path to the file.
            offset: Line number to start reading from (0-based).
            limit: Maximum number of lines to read.

        Returns:
            File contents with line numbers (cat -n format).
        """
        var path = Path(file_path)
        if not path.exists():
            raise Error("File not found: " + file_path)

        var content = path.read_text()
        var lines = content.split("\n")

        var result = String("")
        var start = offset
        var end = min(start + limit, len(lines))

        for i in range(start, end):
            var line_num = i + 1
            result += String(line_num) + "\t" + lines[i] + "\n"

        return result


def min(a: Int, b: Int) -> Int:
    return a if a < b else b
