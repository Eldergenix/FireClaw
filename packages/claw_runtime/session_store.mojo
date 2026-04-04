# runtime/session_store.mojo — Lightweight session persistence (JSON files)
#
# Stores and loads frozen session snapshots to disk.
# Ported from src/session_store.py.
#
# Uses manual JSON serialization (no json.dumps in Mojo) and
# bridge/json_compat for parsing.

from std.collections import List
from std.pathlib import Path
from bridge.json_compat import parse_json, get_string, get_int, get_list


@fieldwise_init
struct StoredSession(Copyable, Movable):
    """An immutable snapshot of a session suitable for persistence."""
    var session_id: String
    var messages: List[String]
    var input_tokens: Int
    var output_tokens: Int


var DEFAULT_SESSION_DIR = String(".port_sessions")


def save_session(
    session: StoredSession,
    directory: String = "",
) raises -> Path:
    """Serialize *session* to JSON and write it under *directory*.

    Returns the path to the written file.
    """
    var target_dir: String
    if len(directory) > 0:
        target_dir = directory
    else:
        target_dir = DEFAULT_SESSION_DIR

    var dir_path = Path(target_dir)
    if not dir_path.exists():
        # Create directory - use os.mkdir if available
        try:
            from std.os import mkdir
            mkdir(target_dir)
        except:
            pass  # Directory may already exist or be created by caller

    var file_path = dir_path / (session.session_id + ".json")
    var json = _session_to_json(session)
    file_path.write_text(json)
    return file_path


def load_session(
    session_id: String,
    directory: String = "",
) raises -> StoredSession:
    """Load a stored session from its JSON file."""
    var target_dir: String
    if len(directory) > 0:
        target_dir = directory
    else:
        target_dir = DEFAULT_SESSION_DIR

    var file_path = Path(target_dir) / (session_id + ".json")
    if not file_path.exists():
        raise Error("Session file not found: " + session_id + ".json")

    var text = file_path.read_text()
    var data = parse_json(text)

    var sid = get_string(data, "session_id")
    var input_tok = get_int(data, "input_tokens")
    var output_tok = get_int(data, "output_tokens")

    var msg_list = get_list(data, "messages")
    var messages = List[String]()
    var n = Int(len(msg_list))
    for i in range(n):
        messages.append(String(msg_list[i]))

    return StoredSession(
        session_id=sid,
        messages=messages,
        input_tokens=input_tok,
        output_tokens=output_tok,
    )


# ── private helpers ──────────────────────────────────────────────


def _session_to_json(session: StoredSession) -> String:
    """Manually serialize a StoredSession to a pretty-printed JSON string."""
    var json = String("{\n")
    json += '  "session_id": ' + _q(session.session_id) + ",\n"
    json += '  "messages": ['
    for i in range(len(session.messages)):
        if i > 0:
            json += ", "
        json += _q(session.messages[i])
    json += "],\n"
    json += '  "input_tokens": ' + String(session.input_tokens) + ",\n"
    json += '  "output_tokens": ' + String(session.output_tokens) + "\n"
    json += "}"
    return json


def _q(s: String) -> String:
    """JSON-escape and quote a string value."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
