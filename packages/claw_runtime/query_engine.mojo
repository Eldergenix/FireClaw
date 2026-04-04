# runtime/query_engine.mojo — Port orchestration query engine
#
# Ported 1:1 from src/query_engine.py.
# Provides QueryEngineConfig, TurnResult, StreamEvent, and
# QueryEnginePort with submit/stream/persist/render capabilities.

from std.collections import List
from std.pathlib import Path

from .models import (
    PermissionDenial,
    UsageSummary,
    PortingBacklog,
    PortingModule,
    new_usage_summary,
)
from .session_store import StoredSession, load_session, save_session
from .transcript import TranscriptStore, new_transcript
from .port_manifest import PortManifest, build_port_manifest
from .command_registry import build_command_backlog
from .tool_registry import build_tool_backlog


# ── ID generation (no uuid4 in Mojo) ──────────────────────────────

var _id_counter: Int = 0


def _next_session_id() -> String:
    """Generate a simple incrementing session ID."""
    _id_counter += 1
    return "session-mojo-" + String(_id_counter)


# ── String helpers ─────────────────────────────────────────────────


def _join_lines(lines: List[String]) -> String:
    """Join a list of strings with newline separators."""
    var result = String("")
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result


def _join_comma(items: List[String]) -> String:
    """Join a list of strings with ', ' separators."""
    var result = String("")
    for i in range(len(items)):
        if i > 0:
            result += ", "
        result += items[i]
    return result


def _json_list(items: List[String]) -> String:
    """Serialize a List[String] as a JSON array string."""
    var result = String("[")
    for i in range(len(items)):
        if i > 0:
            result += ","
        result += '"' + items[i].replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    result += "]"
    return result


# ── Core data structures ──────────────────────────────────────────


@fieldwise_init
struct QueryEngineConfig(Copyable, Movable):
    """Frozen configuration for the query engine."""
    var max_turns: Int
    var max_budget_tokens: Int
    var compact_after_turns: Int
    var structured_output: Bool
    var structured_retry_limit: Int


def default_query_engine_config() -> QueryEngineConfig:
    """Create a QueryEngineConfig with default values."""
    return QueryEngineConfig(
        max_turns=8,
        max_budget_tokens=2000,
        compact_after_turns=12,
        structured_output=False,
        structured_retry_limit=2,
    )


@fieldwise_init
struct TurnResult(Copyable, Movable):
    """Immutable result of a single conversation turn."""
    var prompt: String
    var output: String
    var matched_commands: List[String]
    var matched_tools: List[String]
    var permission_denials: List[PermissionDenial]
    var usage: UsageSummary
    var stop_reason: String


@fieldwise_init
struct StreamEvent(Copyable, Movable):
    """A single event emitted during stream_submit_message."""
    var type: String
    var data: String


# ── QueryEnginePort ───────────────────────────────────────────────


@fieldwise_init
struct QueryEnginePort(Copyable, Movable):
    """Mutable port-orchestration engine with session management."""
    var manifest: PortManifest
    var config: QueryEngineConfig
    var session_id: String
    var mutable_messages: List[String]
    var permission_denials: List[PermissionDenial]
    var total_usage: UsageSummary
    var transcript_store: TranscriptStore


def from_workspace() -> QueryEnginePort:
    """Construct a QueryEnginePort from the current workspace."""
    return QueryEnginePort(
        manifest=build_port_manifest(),
        config=default_query_engine_config(),
        session_id=_next_session_id(),
        mutable_messages=List[String](),
        permission_denials=List[PermissionDenial](),
        total_usage=new_usage_summary(),
        transcript_store=new_transcript(),
    )


def from_saved_session(session_id: String) raises -> QueryEnginePort:
    """Restore a QueryEnginePort from a previously persisted session."""
    var stored = load_session(session_id)
    var transcript = TranscriptStore(
        entries=stored.messages,
        flushed=True,
    )
    return QueryEnginePort(
        manifest=build_port_manifest(),
        config=default_query_engine_config(),
        session_id=stored.session_id,
        mutable_messages=stored.messages,
        permission_denials=List[PermissionDenial](),
        total_usage=UsageSummary(
            input_tokens=stored.input_tokens,
            output_tokens=stored.output_tokens,
        ),
        transcript_store=transcript,
    )


def submit_message(
    mut port: QueryEnginePort,
    prompt: String,
    matched_commands: List[String] = List[String](),
    matched_tools: List[String] = List[String](),
    denied_tools: List[PermissionDenial] = List[PermissionDenial](),
) -> TurnResult:
    """Process a single user turn and return the result."""
    if len(port.mutable_messages) >= port.config.max_turns:
        var output = "Max turns reached before processing prompt: " + prompt
        return TurnResult(
            prompt=prompt,
            output=output,
            matched_commands=matched_commands,
            matched_tools=matched_tools,
            permission_denials=denied_tools,
            usage=port.total_usage,
            stop_reason="max_turns_reached",
        )

    var summary_lines = List[String]()
    summary_lines.append("Prompt: " + prompt)
    var cmd_display: String
    if len(matched_commands) > 0:
        cmd_display = _join_comma(matched_commands)
    else:
        cmd_display = "none"
    summary_lines.append("Matched commands: " + cmd_display)
    var tool_display: String
    if len(matched_tools) > 0:
        tool_display = _join_comma(matched_tools)
    else:
        tool_display = "none"
    summary_lines.append("Matched tools: " + tool_display)
    summary_lines.append("Permission denials: " + String(len(denied_tools)))

    var output = _format_output(port, summary_lines)
    var projected_usage = port.total_usage.add_turn(prompt, output)

    var stop_reason = String("completed")
    if projected_usage.input_tokens + projected_usage.output_tokens > port.config.max_budget_tokens:
        stop_reason = "max_budget_reached"

    port.mutable_messages.append(prompt)
    port.transcript_store.append(prompt)

    for i in range(len(denied_tools)):
        port.permission_denials.append(denied_tools[i])

    port.total_usage = projected_usage
    compact_messages_if_needed(port)

    return TurnResult(
        prompt=prompt,
        output=output,
        matched_commands=matched_commands,
        matched_tools=matched_tools,
        permission_denials=denied_tools,
        usage=port.total_usage,
        stop_reason=stop_reason,
    )


def stream_submit_message(
    mut port: QueryEnginePort,
    prompt: String,
    matched_commands: List[String] = List[String](),
    matched_tools: List[String] = List[String](),
    denied_tools: List[PermissionDenial] = List[PermissionDenial](),
) -> List[StreamEvent]:
    """Process a user turn and return a list of stream events.

    Mojo has no generators/yield, so this returns all events as a List
    instead of yielding them one at a time.
    """
    var events = List[StreamEvent]()

    events.append(StreamEvent(type="start", data=prompt))

    var result = submit_message(
        port,
        prompt,
        matched_commands=matched_commands,
        matched_tools=matched_tools,
        denied_tools=denied_tools,
    )

    events.append(StreamEvent(type="output", data=result.output))
    events.append(StreamEvent(type="usage", data="in=" + String(result.usage.input_tokens) + " out=" + String(result.usage.output_tokens)))
    events.append(StreamEvent(type="stop", data=result.stop_reason))

    return events


def compact_messages_if_needed(mut port: QueryEnginePort):
    """Trim the message list and transcript if they exceed the compaction threshold."""
    if len(port.mutable_messages) > port.config.compact_after_turns:
        var trimmed = List[String]()
        var start = len(port.mutable_messages) - port.config.compact_after_turns
        for i in range(start, len(port.mutable_messages)):
            trimmed.append(port.mutable_messages[i])
        port.mutable_messages = trimmed
    port.transcript_store.compact(port.config.compact_after_turns)


def replay_user_messages(port: QueryEnginePort) -> List[String]:
    """Return a copy of all transcript entries."""
    return port.transcript_store.replay()


def flush_transcript(mut port: QueryEnginePort):
    """Mark the transcript as flushed."""
    port.transcript_store.flush()


def persist_session(mut port: QueryEnginePort) raises -> String:
    """Flush the transcript and write the session to disk.

    Returns the path to the saved file.
    """
    flush_transcript(port)
    var path = save_session(
        StoredSession(
            session_id=port.session_id,
            messages=port.mutable_messages,
            input_tokens=port.total_usage.input_tokens,
            output_tokens=port.total_usage.output_tokens,
        )
    )
    return String(path)


def _format_output(port: QueryEnginePort, summary_lines: List[String]) -> String:
    """Format output as structured JSON or plain text."""
    if port.config.structured_output:
        var payload = '{"summary":' + _json_list(summary_lines) + ',"session_id":"' + port.session_id + '"}'
        return payload
    return _join_lines(summary_lines)


def render_summary(port: QueryEnginePort) -> String:
    """Produce a human-readable markdown summary of the porting workspace."""
    var command_backlog = build_command_backlog()
    var tool_backlog = build_tool_backlog()

    var sections = List[String]()
    sections.append("# Python Porting Workspace Summary")
    sections.append("")
    sections.append(port.manifest.to_markdown())
    sections.append("")
    sections.append("Command surface: " + String(len(command_backlog.modules)) + " mirrored entries")

    var cmd_lines = command_backlog.summary_lines()
    var cmd_limit = len(cmd_lines)
    if cmd_limit > 10:
        cmd_limit = 10
    for i in range(cmd_limit):
        sections.append(cmd_lines[i])

    sections.append("")
    sections.append("Tool surface: " + String(len(tool_backlog.modules)) + " mirrored entries")

    var tool_lines = tool_backlog.summary_lines()
    var tool_limit = len(tool_lines)
    if tool_limit > 10:
        tool_limit = 10
    for i in range(tool_limit):
        sections.append(tool_lines[i])

    sections.append("")
    sections.append("Session id: " + port.session_id)
    sections.append("Conversation turns stored: " + String(len(port.mutable_messages)))
    sections.append("Permission denials tracked: " + String(len(port.permission_denials)))
    sections.append(
        "Usage totals: in="
        + String(port.total_usage.input_tokens)
        + " out="
        + String(port.total_usage.output_tokens)
    )
    sections.append("Max turns: " + String(port.config.max_turns))
    sections.append("Max budget tokens: " + String(port.config.max_budget_tokens))
    sections.append("Transcript flushed: " + String(port.transcript_store.flushed))

    return _join_lines(sections)
