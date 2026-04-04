# runtime/config.mojo — Configuration loading and management

from std.pathlib import Path
from std.collections import Dict, List, Optional
from std.os import getenv


@fieldwise_init
struct RuntimeConfig(Copyable, Movable):
    """Runtime configuration for the Claw Code agent."""
    var model: String
    var max_tokens: Int
    var api_key: String
    var base_url: String
    var system_prompt_prefix: String
    var cwd: String
    var session_dir: String
    var tools_profile: String
    var max_turns: Int
    var thinking_level: String
    var context_1m: Bool


def default_config() raises -> RuntimeConfig:
    """Return a RuntimeConfig with sensible defaults."""
    var home = getenv("HOME", "/tmp")
    return RuntimeConfig(
        model="claude-opus-4-6",
        max_tokens=32768,
        api_key=getenv("ANTHROPIC_API_KEY", ""),
        base_url="https://api.anthropic.com",
        system_prompt_prefix="",
        cwd=String(Path()),
        session_dir=home + "/.claw/sessions",
        tools_profile="coding",
        max_turns=1000,
        thinking_level="adaptive",
        context_1m=True,
    )


def load_config() raises -> RuntimeConfig:
    """Load configuration from defaults, env vars, and config files."""
    var cfg = default_config()

    # Environment overrides
    var env_key = getenv("ANTHROPIC_API_KEY", "")
    if env_key != "":
        cfg.api_key = env_key

    var env_model = getenv("CLAW_MODEL", "")
    if env_model != "":
        cfg.model = env_model

    var env_base = getenv("ANTHROPIC_BASE_URL", "")
    if env_base != "":
        cfg.base_url = env_base

    # Discover .claw.json by walking up directory tree
    var claw_json_path = _find_config_file(".claw.json")
    if claw_json_path != "":
        var content = Path(claw_json_path).read_text()
        _apply_json_config(cfg, content)

    if cfg.api_key == "":
        raise Error(
            "No API key found. Set ANTHROPIC_API_KEY or configure in .claw.json"
        )

    return cfg^


def _find_config_file(filename: String) raises -> String:
    """Walk up the directory tree from CWD looking for a config file."""
    var current = Path()
    while True:
        var candidate = current / filename
        if candidate.exists():
            return String(candidate)
        var parent = current.parent()
        if String(parent) == String(current):
            break
        current = parent
    return ""


def _apply_json_config(mut cfg: RuntimeConfig, json_content: String):
    """Apply settings from a JSON config string to RuntimeConfig."""
    var model = _extract_json_string(json_content, "model")
    if model != "":
        cfg.model = model

    var profile = _extract_json_string(json_content, "tools_profile")
    if profile != "":
        cfg.tools_profile = profile


def _extract_json_string(json: String, key: String) -> String:
    """Extract a simple string value from JSON by key name."""
    var search = '"' + key + '"'
    var pos = json.find(search)
    if pos < 0:
        return ""
    # Use find() to locate colon after key
    var colon_pos = json.find(":", pos + len(search))
    if colon_pos < 0:
        return ""
    # Find opening quote after colon
    var quote_pos = json.find('"', colon_pos + 1)
    if quote_pos < 0:
        return ""
    # Find closing quote
    var end_quote = json.find('"', quote_pos + 1)
    if end_quote < 0:
        return ""
    # Extract substring between quotes using split trick
    var after_open = json[quote_pos + 1 :]
    var value_end = after_open.find('"')
    if value_end < 0:
        return ""
    return String(after_open[:value_end])
