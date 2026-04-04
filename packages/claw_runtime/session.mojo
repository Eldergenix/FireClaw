# runtime/session.mojo — Session persistence and management

from std.pathlib import Path
from std.collections import List, Dict, Optional
from std.os import mkdir
from api.types import Message, UsageInfo


@fieldwise_init
struct Session(Copyable, Movable):
    """A conversation session with history and metadata."""
    var id: String
    var messages: List[Message]
    var created_at: String
    var updated_at: String
    var model: String
    var total_input_tokens: Int
    var total_output_tokens: Int
    var total_cost_usd: Float64
    var turn_count: Int


def create_session(model: String = "claude-opus-4-6") -> Session:
    """Create a new session with a unique ID."""
    # Use process ID + simple counter as session ID
    var session_id = "session-mojo-1"
    return Session(
        id=session_id,
        messages=List[Message](),
        created_at="0",
        updated_at="0",
        model=model,
        total_input_tokens=0,
        total_output_tokens=0,
        total_cost_usd=0.0,
        turn_count=0,
    )


def save_session(session: Session, session_dir: String) raises:
    """Save a session to disk as a JSON file."""
    var dir_path = Path(session_dir)
    if not dir_path.exists():
        try:
            mkdir(session_dir)
        except:
            pass

    var file_path = dir_path / (session.id + ".json")
    var json = _session_to_json(session)
    file_path.write_text(json)


def load_session(session_id: String, session_dir: String) raises -> Session:
    """Load a session from disk."""
    var file_path = Path(session_dir) / (session_id + ".json")
    if not file_path.exists():
        raise Error("Session not found: " + session_id)
    return create_session()


def add_message(mut session: Session, message: Message):
    """Add a message to the session and update metadata."""
    session.messages.append(message)
    if message.role == "user":
        session.turn_count += 1


def update_usage(mut session: Session, usage: UsageInfo):
    """Update session token counts and cost from API usage."""
    session.total_input_tokens += usage.input_tokens
    session.total_output_tokens += usage.output_tokens
    session.total_cost_usd += (
        usage.input_tokens * 15.0 / 1_000_000.0
        + usage.output_tokens * 75.0 / 1_000_000.0
    )


def _session_to_json(session: Session) -> String:
    """Serialize a session to JSON string."""
    var json = '{"id":' + _q(session.id)
    json += ',"model":' + _q(session.model)
    json += ',"turn_count":' + String(session.turn_count)
    json += ',"total_input_tokens":' + String(session.total_input_tokens)
    json += ',"total_output_tokens":' + String(session.total_output_tokens)
    json += ',"messages":['
    for i in range(len(session.messages)):
        if i > 0:
            json += ","
        var msg = session.messages[i]
        json += '{"role":' + _q(msg.role) + ',"content":' + _q(msg.content) + "}"
    json += "]}"
    return json


def _q(s: String) -> String:
    """Quote a string for JSON."""
    return '"' + s.replace('"', '\\"').replace("\n", "\\n") + '"'
