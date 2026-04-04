# tools/config.mojo — Configuration management tool
#
# Allows the agent to read and modify runtime configuration.

from std.pathlib import Path
from claw_runtime.config import RuntimeConfig


struct ConfigTool:
    """Read and modify configuration settings."""

    def execute_get(self, key: String, config: RuntimeConfig) -> String:
        """Get a config value by key."""
        if key == "model":
            return config.model
        elif key == "max_tokens":
            return String(config.max_tokens)
        elif key == "tools_profile":
            return config.tools_profile
        elif key == "base_url":
            return config.base_url
        elif key == "thinking_level":
            return config.thinking_level
        elif key == "context_1m":
            return String(config.context_1m)
        elif key == "cwd":
            return config.cwd
        elif key == "session_dir":
            return config.session_dir
        else:
            return "Unknown config key: " + key

    def execute_set(
        self, key: String, value: String, mut config: RuntimeConfig
    ) -> String:
        """Set a config value by key."""
        if key == "model":
            config.model = value
            return "Set model = " + value
        elif key == "max_tokens":
            try:
                config.max_tokens = int(value)
                return "Set max_tokens = " + value
            except:
                return "Invalid integer: " + value
        elif key == "tools_profile":
            config.tools_profile = value
            return "Set tools_profile = " + value
        elif key == "thinking_level":
            config.thinking_level = value
            return "Set thinking_level = " + value
        else:
            return "Unknown or read-only config key: " + key
