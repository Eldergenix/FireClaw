# runtime/port_runtime.mojo — Ported from src/runtime.py
#
# Prompt routing, session bootstrapping, and turn-loop execution for
# the Claw Code porting runtime.

from std.collections import List
from .models import PermissionDenial, PortingModule, UsageSummary
from .context import PortContext, build_port_context, render_context
from .history import HistoryLog
from .setup import WorkspaceSetup, SetupReport, run_setup, build_system_init_message
from .query_engine import (
    QueryEngineConfig, TurnResult, StreamEvent,
    from_workspace, submit_message, stream_submit_message,
    persist_session, default_query_engine_config,
)
from .execution_registry import ExecutionRegistry, MirroredCommand, MirroredTool, build_execution_registry
from .command_registry import load_command_snapshot as _ported_commands
from .tool_registry import load_tool_snapshot as _ported_tools


# ---------------------------------------------------------------------------
# RoutedMatch
# ---------------------------------------------------------------------------


@fieldwise_init
struct RoutedMatch(Copyable, Movable):
    """A single match produced by prompt routing."""
    var kind: String
    var name: String
    var source_hint: String
    var score: Int


# ---------------------------------------------------------------------------
# RuntimeSession
# ---------------------------------------------------------------------------


@fieldwise_init
struct RuntimeSession(Copyable, Movable):
    var prompt: String
    var context: PortContext
    var setup: WorkspaceSetup
    var setup_report: SetupReport
    var system_init_message: String
    var history: HistoryLog
    var routed_matches: List[RoutedMatch]
    var turn_result: TurnResult
    var command_execution_messages: List[String]
    var tool_execution_messages: List[String]
    var stream_events: List[StreamEvent]
    var persisted_session_path: String

    def as_markdown(self) -> String:
        var lines = List[String]()
        lines.append("# Runtime Session")
        lines.append("")
        lines.append("Prompt: " + self.prompt)
        lines.append("")
        lines.append("## Context")
        lines.append(render_context(self.context))
        lines.append("")
        lines.append("## Setup")
        lines.append(
            "- Python: "
            + self.setup.python_version
            + " ("
            + self.setup.implementation
            + ")"
        )
        lines.append("- Platform: " + self.setup.platform_name)
        lines.append("- Test command: " + self.setup.test_command)
        lines.append("")
        lines.append("## Startup Steps")
        var steps = self.setup.startup_steps()
        for i in range(len(steps)):
            lines.append("- " + steps[i])
        lines.append("")
        lines.append("## System Init")
        lines.append(self.system_init_message)
        lines.append("")
        lines.append("## Routed Matches")
        if len(self.routed_matches) > 0:
            for i in range(len(self.routed_matches)):
                var m = self.routed_matches[i]
                lines.append(
                    "- ["
                    + m.kind
                    + "] "
                    + m.name
                    + " ("
                    + String(m.score)
                    + ") — "
                    + m.source_hint
                )
        else:
            lines.append("- none")
        lines.append("")
        lines.append("## Command Execution")
        if len(self.command_execution_messages) > 0:
            for i in range(len(self.command_execution_messages)):
                lines.append(self.command_execution_messages[i])
        else:
            lines.append("none")
        lines.append("")
        lines.append("## Tool Execution")
        if len(self.tool_execution_messages) > 0:
            for i in range(len(self.tool_execution_messages)):
                lines.append(self.tool_execution_messages[i])
        else:
            lines.append("none")
        lines.append("")
        lines.append("## Stream Events")
        for i in range(len(self.stream_events)):
            var e = self.stream_events[i]
            lines.append("- " + e.type + ": " + e.detail)
        lines.append("")
        lines.append("## Turn Result")
        lines.append(self.turn_result.output)
        lines.append("")
        lines.append("Persisted session path: " + self.persisted_session_path)
        lines.append("")
        lines.append(self.history.as_markdown())

        var result: String = ""
        for i in range(len(lines)):
            if i > 0:
                result += "\n"
            result += lines[i]
        return result


# ---------------------------------------------------------------------------
# PortRuntime
# ---------------------------------------------------------------------------


struct PortRuntime(Copyable, Movable):
    """Main runtime coordinating prompt routing, session bootstrap, and
    turn-loop execution."""

    def __init__(out self):
        pass

    def __copyinit__(out self, *, copy: Self):
        pass

    def __moveinit__(out self, *, deinit take: Self):
        pass

    # -- routing -----------------------------------------------------------

    def route_prompt(self, prompt: String, limit: Int = 5) -> List[RoutedMatch]:
        """Route a prompt to matching commands and tools by keyword scoring."""
        var tokens = _tokenize(prompt)
        var command_matches = self._collect_matches(tokens, _ported_commands(), "command")
        var tool_matches = self._collect_matches(tokens, _ported_tools(), "tool")

        var selected = List[RoutedMatch]()

        # Take top-1 from each kind first.
        if len(command_matches) > 0:
            selected.append(command_matches[0])
        if len(tool_matches) > 0:
            selected.append(tool_matches[0])

        # Merge remaining into leftovers, sort, and fill to limit.
        var leftovers = List[RoutedMatch]()
        for i in range(1, len(command_matches)):
            leftovers.append(command_matches[i])
        for i in range(1, len(tool_matches)):
            leftovers.append(tool_matches[i])
        _sort_routed_matches(leftovers)

        var remaining = limit - len(selected)
        if remaining < 0:
            remaining = 0
        var take = len(leftovers)
        if take > remaining:
            take = remaining
        for i in range(take):
            selected.append(leftovers[i])

        # Trim to limit.
        var result = List[RoutedMatch]()
        var cap = len(selected)
        if cap > limit:
            cap = limit
        for i in range(cap):
            result.append(selected[i])
        return result

    # -- session bootstrap -------------------------------------------------

    def bootstrap_session(self, prompt: String, limit: Int = 5) raises -> RuntimeSession:
        """Build a full RuntimeSession from a user prompt."""
        var context = build_port_context()
        var setup_report = run_setup(trusted=True)
        var setup = setup_report.setup
        var history = HistoryLog()

        history.add(
            "context",
            "python_files="
            + String(context.python_file_count)
            + ", archive_available="
            + String(context.archive_available),
        )
        var cmds = _ported_commands()
        var tools = _ported_tools()
        history.add(
            "registry",
            "commands=" + String(len(cmds)) + ", tools=" + String(len(tools)),
        )

        var matches = self.route_prompt(prompt, limit=limit)
        var registry = build_execution_registry()

        # Execute matched commands.
        var command_execs = List[String]()
        for i in range(len(matches)):
            if matches[i].kind == "command":
                var cmd = registry.command(matches[i].name)
                if len(cmd.name) > 0:
                    command_execs.append(cmd.execute(prompt))

        # Execute matched tools.
        var tool_execs = List[String]()
        for i in range(len(matches)):
            if matches[i].kind == "tool":
                var t = registry.tool(matches[i].name)
                if len(t.name) > 0:
                    tool_execs.append(t.execute(prompt))

        # Infer permission denials.
        var denials = self._infer_permission_denials(matches)

        # Build command/tool name lists for engine calls.
        var matched_command_names = List[String]()
        var matched_tool_names = List[String]()
        for i in range(len(matches)):
            if matches[i].kind == "command":
                matched_command_names.append(matches[i].name)
            elif matches[i].kind == "tool":
                matched_tool_names.append(matches[i].name)

        # Create a query engine from the workspace.
        var engine = from_workspace()

        # Stream events.
        var stream_events = stream_submit_message(
            engine, prompt, matched_command_names, matched_tool_names, denials,
        )

        # Synchronous turn result.
        var turn_result = submit_message(
            engine, prompt, matched_command_names, matched_tool_names, denials,
        )

        var persisted = persist_session(engine)

        history.add("routing", "matches=" + String(len(matches)) + " for prompt='" + prompt + "'")
        history.add(
            "execution",
            "command_execs=" + String(len(command_execs)) + " tool_execs=" + String(len(tool_execs)),
        )
        history.add(
            "turn",
            "commands="
            + String(len(turn_result.matched_commands))
            + " tools="
            + String(len(turn_result.matched_tools))
            + " denials="
            + String(len(turn_result.permission_denials))
            + " stop="
            + turn_result.stop_reason,
        )
        history.add("session_store", persisted)

        return RuntimeSession(
            prompt=prompt,
            context=context,
            setup=setup,
            setup_report=setup_report,
            system_init_message=build_system_init_message(trusted=True),
            history=history,
            routed_matches=matches,
            turn_result=turn_result,
            command_execution_messages=command_execs,
            tool_execution_messages=tool_execs,
            stream_events=stream_events,
            persisted_session_path=persisted,
        )

    # -- turn loop ---------------------------------------------------------

    def run_turn_loop(
        self,
        prompt: String,
        limit: Int = 5,
        max_turns: Int = 3,
        structured_output: Bool = False,
    ) -> List[TurnResult]:
        """Run multiple engine turns, stopping when the result is not 'completed'."""
        var matches = self.route_prompt(prompt, limit=limit)

        var command_names = List[String]()
        var tool_names = List[String]()
        for i in range(len(matches)):
            if matches[i].kind == "command":
                command_names.append(matches[i].name)
            elif matches[i].kind == "tool":
                tool_names.append(matches[i].name)

        var engine = from_workspace()
        var empty_denials = List[PermissionDenial]()
        var results = List[TurnResult]()
        for turn in range(max_turns):
            var turn_prompt: String
            if turn == 0:
                turn_prompt = prompt
            else:
                turn_prompt = prompt + " [turn " + String(turn + 1) + "]"
            var result = submit_message(
                engine, turn_prompt, command_names, tool_names, empty_denials,
            )
            results.append(result)
            if result.stop_reason != "completed":
                break
        return results

    # -- internal helpers --------------------------------------------------

    def _infer_permission_denials(
        self, matches: List[RoutedMatch],
    ) -> List[PermissionDenial]:
        var denials = List[PermissionDenial]()
        for i in range(len(matches)):
            if matches[i].kind == "tool":
                if _contains_lower(matches[i].name, "bash"):
                    denials.append(
                        PermissionDenial(
                            tool_name=matches[i].name,
                            reason="destructive shell execution remains gated",
                        )
                    )
        return denials

    def _collect_matches(
        self,
        tokens: List[String],
        modules: List[PortingModule],
        kind: String,
    ) -> List[RoutedMatch]:
        var matches = List[RoutedMatch]()
        for i in range(len(modules)):
            var score = _score(tokens, modules[i])
            if score > 0:
                matches.append(
                    RoutedMatch(
                        kind=kind,
                        name=modules[i].name,
                        source_hint=modules[i].source_hint,
                        score=score,
                    )
                )
        _sort_routed_matches(matches)
        return matches


# ---------------------------------------------------------------------------
# Module-level helper functions
# ---------------------------------------------------------------------------


def _tokenize(prompt: String) -> List[String]:
    """Split the prompt into lower-cased tokens, treating '/' and '-' as
    separators.  Duplicates are not removed (no set in Mojo)."""
    var normalized = prompt.replace("/", " ").replace("-", " ")
    var parts = normalized.split()
    var tokens = List[String]()
    for i in range(len(parts)):
        var t = parts[i].lower()
        if len(t) > 0:
            # Deduplicate by linear scan.
            var found = False
            for j in range(len(tokens)):
                if tokens[j] == t:
                    found = True
                    break
            if not found:
                tokens.append(t)
    return tokens


def _score(tokens: List[String], module: PortingModule) -> Int:
    """Score a module against a token list.  +1 for each token found in the
    module's name, source_hint, or responsibility (all lower-cased)."""
    var name_lower = module.name.lower()
    var hint_lower = module.source_hint.lower()
    var resp_lower = module.responsibility.lower()
    var score: Int = 0
    for i in range(len(tokens)):
        var token = tokens[i]
        if token in name_lower or token in hint_lower or token in resp_lower:
            score += 1
    return score


def _contains_lower(haystack: String, needle: String) -> Bool:
    """Case-insensitive substring check."""
    return needle.lower() in haystack.lower()


def _sort_routed_matches(mut matches: List[RoutedMatch]) -> None:
    """In-place bubble sort by (-score, kind, name)."""
    var n = len(matches)
    for i in range(n):
        for j in range(0, n - i - 1):
            if _match_less_than(matches[j + 1], matches[j]):
                var tmp = matches[j]
                matches[j] = matches[j + 1]
                matches[j + 1] = tmp


def _match_less_than(a: RoutedMatch, b: RoutedMatch) -> Bool:
    """Return True if `a` should sort before `b` (higher score first, then
    alphabetical by kind, then by name)."""
    if a.score != b.score:
        return a.score > b.score
    if a.kind != b.kind:
        return a.kind < b.kind
    return a.name < b.name
