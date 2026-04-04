# tools/file_write.mojo — File writing tool

from std.pathlib import Path
from std.os import makedirs


struct FileWriteTool:
    """Write content to files on the filesystem."""

    def execute(self, file_path: String, content: String) raises:
        """Write content to a file, creating parent directories if needed.

        Args:
            file_path: Absolute path to the file.
            content: Content to write.
        """
        var path = Path(file_path)

        # Ensure parent directory exists
        var parent = path.parent()
        if not parent.exists():
            makedirs(String(parent))

        path.write_text(content)


struct FileEditTool:
    """Perform exact string replacement in files."""

    def execute(
        self,
        file_path: String,
        old_string: String,
        new_string: String,
        replace_all: Bool = False,
    ) raises:
        """Replace old_string with new_string in the file.

        Args:
            file_path: Absolute path to the file.
            old_string: Text to find and replace.
            new_string: Replacement text.
            replace_all: If True, replace all occurrences.
        """
        var path = Path(file_path)
        if not path.exists():
            raise Error("File not found: " + file_path)

        var content = path.read_text()

        if old_string not in content:
            raise Error("old_string not found in file: " + file_path)

        var new_content: String
        if replace_all:
            new_content = content.replace(old_string, new_string)
        else:
            # Replace first occurrence only
            var pos = content.find(old_string)
            new_content = (
                content[:pos] + new_string + content[pos + len(old_string) :]
            )

        # Check uniqueness for single replacement
        if not replace_all:
            var second = content.find(old_string, pos + 1)
            if second >= 0:
                raise Error(
                    "old_string is not unique in file. Use replace_all=True"
                    " or provide more context."
                )

        path.write_text(new_content)
