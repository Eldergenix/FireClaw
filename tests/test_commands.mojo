# tests/test_commands.mojo — Tests for the full command surface
#
# Validates all 30+ slash commands dispatch correctly and return
# meaningful output.

from std.testing import assert_equal, assert_true
from packages.commands import CommandRegistry, CommandResult


def test_help_command():
    """Dispatch /help, verify output contains 'Available commands'."""
    var reg = CommandRegistry()
    var result = reg.dispatch("help")
    assert_true("Available commands" in result.output, "help output missing header")
    assert_equal(result.should_exit, False)
    assert_equal(result.error, "")


def test_version_command():
    """Dispatch /version, verify output contains 'Claw Code'."""
    var reg = CommandRegistry()
    var result = reg.dispatch("version")
    assert_true("Claw Code" in result.output, "version output missing product name")
    assert_true("Mojo" in result.output, "version output missing runtime info")
    assert_equal(result.error, "")


def test_status_command():
    """Dispatch /status, verify output contains 'Session'."""
    var reg = CommandRegistry()
    var result = reg.dispatch("status")
    assert_true("Session" in result.output, "status output missing session info")
    assert_true("model" in result.output.lower(), "status output missing model info")
    assert_equal(result.error, "")


def test_unknown_command():
    """Dispatch unknown command, verify error message."""
    var reg = CommandRegistry()
    var result = reg.dispatch("nonexistent_command_xyz")
    assert_true(len(result.error) > 0, "unknown command should produce error")
    assert_true("Unknown command" in result.error, "error should say unknown command")


def test_config_no_args():
    """Dispatch /config with no args, verify lists config."""
    var reg = CommandRegistry()
    var result = reg.dispatch("config", "")
    assert_true("configuration" in result.output.lower(), "config output missing header")
    assert_true("model" in result.output, "config should list model key")
    assert_equal(result.error, "")


def test_config_get_key():
    """Dispatch /config with one arg, verify shows value."""
    var reg = CommandRegistry()
    var result = reg.dispatch("config", "theme")
    assert_true("dark" in result.output, "config get should show theme=dark")
    assert_equal(result.error, "")


def test_config_set_key():
    """Dispatch /config with two args, verify sets value."""
    var reg = CommandRegistry()
    var result = reg.dispatch("config", "theme light")
    assert_true("Set" in result.output, "config set should confirm")
    assert_true("light" in result.output, "config set should show new value")
    assert_equal(result.error, "")


def test_config_unknown_key():
    """Dispatch /config with unknown key, verify error."""
    var reg = CommandRegistry()
    var result = reg.dispatch("config", "nonexistent_key_xyz")
    assert_true(len(result.error) > 0, "unknown config key should produce error")


def test_clear_command():
    """Dispatch /clear, verify 'cleared' in output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("clear")
    assert_true("cleared" in result.output.lower(), "clear output should mention cleared")
    assert_equal(result.error, "")


def test_cost_command():
    """Dispatch /cost, verify cost info returned."""
    var reg = CommandRegistry()
    var result = reg.dispatch("cost")
    assert_true("Cost" in result.output, "cost output missing header")
    assert_true("token" in result.output.lower(), "cost output should mention tokens")
    assert_equal(result.error, "")


def test_compact_command():
    """Dispatch /compact, verify compaction message."""
    var reg = CommandRegistry()
    var result = reg.dispatch("compact")
    assert_true("compact" in result.output.lower(), "compact output should describe action")
    assert_equal(result.error, "")


def test_model_no_args():
    """Dispatch /model with no args, verify shows current model."""
    var reg = CommandRegistry()
    var result = reg.dispatch("model", "")
    assert_true("Current model" in result.output, "model output should show current")
    assert_true("claude" in result.output.lower(), "model output should list models")
    assert_equal(result.error, "")


def test_model_switch():
    """Dispatch /model with valid name, verify switch."""
    var reg = CommandRegistry()
    var result = reg.dispatch("model", "claude-sonnet-4")
    assert_true("Switched" in result.output, "model switch should confirm")
    assert_equal(result.error, "")


def test_model_invalid():
    """Dispatch /model with invalid name, verify error."""
    var reg = CommandRegistry()
    var result = reg.dispatch("model", "gpt-99")
    assert_true(len(result.error) > 0, "invalid model should produce error")


def test_session_list():
    """Dispatch /session list, verify output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("session", "list")
    assert_true("Sessions" in result.output, "session list should show sessions")
    assert_equal(result.error, "")


def test_resume_no_args():
    """Dispatch /resume with no args, verify usage hint."""
    var reg = CommandRegistry()
    var result = reg.dispatch("resume", "")
    assert_true("Usage" in result.output or "session" in result.output.lower(),
        "resume with no args should show usage")
    assert_equal(result.error, "")


def test_memory_empty():
    """Dispatch /memory with no entries, verify message."""
    var reg = CommandRegistry()
    var result = reg.dispatch("memory", "")
    assert_true("memory" in result.output.lower(), "memory output should mention memory")
    assert_equal(result.error, "")


def test_memory_add():
    """Dispatch /memory add, verify entry added."""
    var reg = CommandRegistry()
    var result = reg.dispatch("memory", "add Test memory entry")
    assert_true("Added" in result.output, "memory add should confirm")
    assert_true("Test memory entry" in result.output, "memory add should echo text")
    assert_equal(result.error, "")


def test_init_command():
    """Dispatch /init, verify CLAW.md template output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("init")
    assert_true("CLAW.md" in result.output, "init should mention CLAW.md")
    assert_equal(result.error, "")


def test_diff_command():
    """Dispatch /diff, verify file change info."""
    var reg = CommandRegistry()
    var result = reg.dispatch("diff")
    assert_true("change" in result.output.lower(), "diff should mention changes")
    assert_equal(result.error, "")


def test_export_command():
    """Dispatch /export, verify export format info."""
    var reg = CommandRegistry()
    var result = reg.dispatch("export", "")
    assert_true("export" in result.output.lower(), "export should describe export")
    assert_true("markdown" in result.output.lower(), "default format should be markdown")
    assert_equal(result.error, "")


def test_export_json():
    """Dispatch /export json, verify JSON format."""
    var reg = CommandRegistry()
    var result = reg.dispatch("export", "json")
    assert_true("json" in result.output.lower(), "export json should mention json")
    assert_equal(result.error, "")


def test_permissions_list():
    """Dispatch /permissions, verify permission listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("permissions", "")
    assert_true("permission" in result.output.lower(), "permissions should list perms")
    assert_equal(result.error, "")


def test_all_commands_registered():
    """Create registry, verify at least 30 commands registered."""
    var reg = CommandRegistry()
    var count = reg.command_count()
    assert_true(count >= 30, "expected at least 30 commands, got " + String(count))


def test_help_lists_all():
    """Dispatch /help, verify output contains agents, hooks, mcp."""
    var reg = CommandRegistry()
    var result = reg.dispatch("help")
    assert_true("agents" in result.output, "help should list agents command")
    assert_true("hooks" in result.output, "help should list hooks command")
    assert_true("mcp" in result.output, "help should list mcp command")


def test_agents_command():
    """Dispatch /agents, verify agent listing output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("agents", "")
    assert_true("agent" in result.output.lower(), "agents should describe agents")
    assert_equal(result.error, "")


def test_hooks_command():
    """Dispatch /hooks, verify hooks listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("hooks", "")
    assert_true("hook" in result.output.lower(), "hooks should describe hooks")
    assert_true("PreToolUse" in result.output, "hooks should list PreToolUse event")
    assert_equal(result.error, "")


def test_mcp_command():
    """Dispatch /mcp, verify MCP server listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("mcp", "")
    assert_true("MCP" in result.output, "mcp should mention MCP")
    assert_equal(result.error, "")


def test_plugin_command():
    """Dispatch /plugin, verify plugin listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("plugin", "")
    assert_true("plugin" in result.output.lower(), "plugin should describe plugins")
    assert_equal(result.error, "")


def test_skills_command():
    """Dispatch /skills, verify skills listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("skills", "")
    assert_true("skill" in result.output.lower(), "skills should describe skills")
    assert_equal(result.error, "")


def test_plan_command():
    """Dispatch /plan, verify plan listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("plan", "")
    assert_true("plan" in result.output.lower(), "plan should describe plans")
    assert_equal(result.error, "")


def test_review_command():
    """Dispatch /review, verify review output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("review", "")
    assert_true("Review" in result.output, "review should show review info")
    assert_equal(result.error, "")


def test_tasks_command():
    """Dispatch /tasks, verify task listing."""
    var reg = CommandRegistry()
    var result = reg.dispatch("tasks", "")
    assert_true("task" in result.output.lower(), "tasks should describe tasks")
    assert_equal(result.error, "")


def test_login_command():
    """Dispatch /login, verify auth flow description."""
    var reg = CommandRegistry()
    var result = reg.dispatch("login")
    assert_true("auth" in result.output.lower() or "login" in result.output.lower(),
        "login should describe auth flow")
    assert_equal(result.error, "")


def test_logout_command():
    """Dispatch /logout, verify logout message."""
    var reg = CommandRegistry()
    var result = reg.dispatch("logout")
    assert_true("logged out" in result.output.lower() or "token" in result.output.lower(),
        "logout should confirm logout")
    assert_equal(result.error, "")


def test_doctor_command():
    """Dispatch /doctor, verify diagnostic output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("doctor")
    assert_true("Diagnostics" in result.output, "doctor should show diagnostics header")
    assert_true("Mojo" in result.output, "doctor should check Mojo runtime")
    assert_true("[ok]" in result.output, "doctor should show check results")
    assert_equal(result.error, "")


def test_bug_report_command():
    """Dispatch /bug-report, verify report generation."""
    var reg = CommandRegistry()
    var result = reg.dispatch("bug-report")
    assert_true("Bug Report" in result.output, "bug-report should show header")
    assert_true("reproduce" in result.output.lower(), "bug-report should ask for repro steps")
    assert_equal(result.error, "")


def test_profile_command():
    """Dispatch /profile, verify profile output."""
    var reg = CommandRegistry()
    var result = reg.dispatch("profile")
    assert_true("Profile" in result.output, "profile should show header")
    assert_equal(result.error, "")


def test_fast_toggle():
    """Dispatch /fast twice, verify toggle behavior."""
    var reg = CommandRegistry()
    var result1 = reg.dispatch("fast")
    assert_true("enabled" in result1.output, "first /fast should enable")
    var result2 = reg.dispatch("fast")
    assert_true("disabled" in result2.output, "second /fast should disable")


def test_vim_toggle():
    """Dispatch /vim twice, verify toggle behavior."""
    var reg = CommandRegistry()
    var result1 = reg.dispatch("vim")
    assert_true("enabled" in result1.output, "first /vim should enable")
    var result2 = reg.dispatch("vim")
    assert_true("disabled" in result2.output, "second /vim should disable")


def test_is_command_valid():
    """Test is_command with valid command input."""
    var reg = CommandRegistry()
    assert_true(reg.is_command("/help"), "/help should be recognized")
    assert_true(reg.is_command("/agents"), "/agents should be recognized")
    assert_true(reg.is_command("/doctor"), "/doctor should be recognized")


def test_is_command_invalid():
    """Test is_command with invalid input."""
    var reg = CommandRegistry()
    assert_true(not reg.is_command("help"), "no slash = not a command")
    assert_true(not reg.is_command("/nonexistent_xyz"), "unknown = not a command")


def test_no_exit_on_commands():
    """Verify no command sets should_exit to True."""
    var reg = CommandRegistry()
    var commands = List[String]()
    commands.append("help")
    commands.append("version")
    commands.append("status")
    commands.append("clear")
    commands.append("cost")
    commands.append("doctor")
    commands.append("login")
    commands.append("logout")
    commands.append("profile")
    for i in range(len(commands)):
        var result = reg.dispatch(commands[i])
        assert_equal(result.should_exit, False,
            "/" + commands[i] + " should not cause exit")
