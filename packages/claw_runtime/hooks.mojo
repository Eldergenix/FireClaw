# runtime/hooks.mojo — Hook execution pipeline
#
# Supports PreToolUse, PostToolUse, and Stop hooks configured in
# .claw/settings.json. Hooks execute shell commands and can allow,
# deny, or modify tool invocations.

from std.collections import List, Dict
from std.subprocess import run as subprocess_run
from std.pathlib import Path


@fieldwise_init
struct HookConfig(Copyable, Movable):
    """Configuration for a single hook."""
    var event: String  # "PreToolUse" | "PostToolUse" | "Stop"
    var matcher: String  # Tool name pattern (supports * wildcard)
    var command: String  # Shell command to execute


@fieldwise_init
struct HookResult(Copyable, Movable):
    """Result of executing a hook."""
    var action: String  # "allow" | "deny" | "modify"
    var reason: String  # Reason for deny/modify
    var modified_input: String  # New input if action is "modify"
    var exit_code: Int


struct HookRunner:
    """Executes hooks based on tool events."""
    var hooks: List[HookConfig]

    def __init__(out self):
        self.hooks = List[HookConfig]()

    def load_hooks(mut self, settings_path: String) raises:
        """Load hooks from a settings JSON file.

        Expected format in .claw/settings.json:
        {
          "hooks": {
            "PreToolUse": [
              {"matcher": "Bash", "command": "echo $TOOL_INPUT | validate.sh"}
            ]
          }
        }
        """
        var path = Path(settings_path)
        if not path.exists():
            return

        var content = path.read_text()
        # Parse hooks from JSON — simplified extraction
        # Full parsing delegates to bridge/json_compat or EmberJson
        self._parse_hooks(content)

    def run_pre_tool_hooks(
        mut self, tool_name: String, tool_input: String
    ) raises -> HookResult:
        """Run all PreToolUse hooks matching the tool name."""
        return self._run_hooks("PreToolUse", tool_name, tool_input)

    def run_post_tool_hooks(
        mut self, tool_name: String, tool_output: String
    ) raises -> HookResult:
        """Run all PostToolUse hooks matching the tool name."""
        return self._run_hooks("PostToolUse", tool_name, tool_output)

    def _run_hooks(
        mut self, event: String, tool_name: String, data: String
    ) raises -> HookResult:
        """Run all hooks matching event and tool name."""
        for hook in self.hooks:
            if hook[].event != event:
                continue
            if not _pattern_match(tool_name, hook[].matcher):
                continue

            # Execute hook command with tool context as env vars
            var result = subprocess_run(
                "bash",
                "-c",
                "TOOL_NAME='"
                + tool_name
                + "' TOOL_INPUT='"
                + data[:1000]
                + "' "
                + hook[].command,
            )
            var output = String(result)
            var exit_code = 0  # TODO: extract from result

            if exit_code != 0:
                return HookResult(
                    action="deny",
                    reason=output,
                    modified_input="",
                    exit_code=exit_code,
                )

        return HookResult(
            action="allow", reason="", modified_input="", exit_code=0
        )

    def _parse_hooks(mut self, json_content: String):
        """Parse hook configurations from JSON."""
        # Simplified — extract hook entries from known structure
        # Full implementation would use EmberJson or bridge/json_compat
        pass


def _pattern_match(name: String, pattern: String) -> Bool:
    """Match a tool name against a pattern with * wildcard."""
    if pattern == "*":
        return True
    if "*" not in pattern:
        return name == pattern
    # Simple prefix/suffix matching
    if pattern.startswith("*"):
        return name.endswith(pattern[1:])
    if pattern.endswith("*"):
        return name.startswith(pattern[:-1])
    return name == pattern
