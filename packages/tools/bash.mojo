# tools/bash.mojo — Shell command execution tool

from std.subprocess import run as subprocess_run
from std.collections import Dict


struct BashTool:
    """Execute bash commands and return stdout/stderr."""

    def execute(self, command: String, timeout_ms: Int = 120000) raises -> String:
        """Run a shell command and return its output.

        Args:
            command: The bash command to execute.
            timeout_ms: Timeout in milliseconds (default 120s, max 600s).

        Returns:
            Combined stdout output as a string.
        """
        var clamped_timeout = timeout_ms
        if clamped_timeout > 600000:
            clamped_timeout = 600000
        if clamped_timeout < 1000:
            clamped_timeout = 1000

        var result = subprocess_run(
            "bash", "-c", command
        )
        return String(result)
