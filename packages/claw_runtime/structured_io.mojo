# runtime/structured_io.mojo — Structured I/O protocol for machine-readable communication
#
# Mirrors TypeScript's structuredIO.ts — a JSON-lines based structured message
# protocol for remote control of the CLI agent.
#
# Message types:
#   "user_message"      — user input
#   "assistant_message"  — assistant text output
#   "tool_use"           — tool invocation request
#   "tool_result"        — tool execution result
#   "system"             — system/status messages
#   "error"              — error messages
#   "heartbeat"          — keepalive

from std.collections import List


# --- Valid message type constants ---

alias MSG_USER = "user_message"
alias MSG_ASSISTANT = "assistant_message"
alias MSG_TOOL_USE = "tool_use"
alias MSG_TOOL_RESULT = "tool_result"
alias MSG_SYSTEM = "system"
alias MSG_ERROR = "error"
alias MSG_HEARTBEAT = "heartbeat"


@fieldwise_init
struct StructuredMessage(Copyable, Movable):
    """A single structured message flowing through the I/O protocol.

    Each message has a unique id (sequence number), a type tag, content payload,
    optional metadata (serialized JSON string), and an ISO-ish timestamp string.
    """
    var id: Int
    var type: String
    var content: String
    var metadata: String
    var timestamp: String


def is_valid_message_type(msg_type: String) -> Bool:
    """Check whether a message type string is one of the known types."""
    return (
        msg_type == MSG_USER
        or msg_type == MSG_ASSISTANT
        or msg_type == MSG_TOOL_USE
        or msg_type == MSG_TOOL_RESULT
        or msg_type == MSG_SYSTEM
        or msg_type == MSG_ERROR
        or msg_type == MSG_HEARTBEAT
    )


# ---------------------------------------------------------------------------
# JSON encoding / decoding helpers
# ---------------------------------------------------------------------------

def _escape_json_string(s: String) -> String:
    """Escape special characters for JSON string values."""
    var result = String("")
    for i in range(len(s)):
        var c = s[i]
        if c == '"':
            result += '\\"'
        elif c == '\\':
            result += '\\\\'
        elif c == '\n':
            result += '\\n'
        elif c == '\r':
            result += '\\r'
        elif c == '\t':
            result += '\\t'
        else:
            result += c
    return result


def encode_message(msg: StructuredMessage) -> String:
    """Serialize a StructuredMessage to a single JSON line.

    Format:
      {"id":<int>,"type":"...","content":"...","metadata":"...","timestamp":"..."}
    """
    var s = String('{"id":')
    s += String(msg.id)
    s += ',"type":"' + _escape_json_string(msg.type) + '"'
    s += ',"content":"' + _escape_json_string(msg.content) + '"'
    s += ',"metadata":"' + _escape_json_string(msg.metadata) + '"'
    s += ',"timestamp":"' + _escape_json_string(msg.timestamp) + '"'
    s += "}"
    return s


def _extract_json_string_value(json: String, key: String) raises -> String:
    """Extract a string value for *key* from a flat JSON object.

    Looks for `"key":"value"` and returns the (un-escaped) value.
    """
    var needle = '"' + key + '":"'
    var start = -1
    # Manual search for needle position
    for i in range(len(json)):
        var match = True
        if i + len(needle) > len(json):
            match = False
        else:
            for j in range(len(needle)):
                if json[i + j] != needle[j]:
                    match = False
                    break
        if match:
            start = i + len(needle)
            break
    if start == -1:
        raise Error("Key not found in JSON: " + key)

    # Walk forward until un-escaped closing quote
    var result = String("")
    var idx = start
    while idx < len(json):
        var c = json[idx]
        if c == '\\' and idx + 1 < len(json):
            var nc = json[idx + 1]
            if nc == '"':
                result += '"'
            elif nc == '\\':
                result += '\\'
            elif nc == 'n':
                result += '\n'
            elif nc == 'r':
                result += '\r'
            elif nc == 't':
                result += '\t'
            else:
                result += nc
            idx += 2
            continue
        if c == '"':
            break
        result += c
        idx += 1
    return result


def _extract_json_int_value(json: String, key: String) raises -> Int:
    """Extract an integer value for *key* from a flat JSON object.

    Looks for `"key":123` and returns the integer.
    """
    var needle = '"' + key + '":'
    var start = -1
    for i in range(len(json)):
        var match = True
        if i + len(needle) > len(json):
            match = False
        else:
            for j in range(len(needle)):
                if json[i + j] != needle[j]:
                    match = False
                    break
        if match:
            start = i + len(needle)
            break
    if start == -1:
        raise Error("Key not found in JSON: " + key)

    # Collect digits (and optional leading minus)
    var num_str = String("")
    var idx = start
    while idx < len(json):
        var c = json[idx]
        if c == '-' or (c >= '0' and c <= '9'):
            num_str += c
            idx += 1
        else:
            break
    return Int(num_str)


def decode_message(json_line: String) raises -> StructuredMessage:
    """Deserialize a JSON line back into a StructuredMessage.

    Raises on malformed input.
    """
    var id_val = _extract_json_int_value(json_line, "id")
    var type_val = _extract_json_string_value(json_line, "type")
    var content_val = _extract_json_string_value(json_line, "content")
    var metadata_val = _extract_json_string_value(json_line, "metadata")
    var timestamp_val = _extract_json_string_value(json_line, "timestamp")

    return StructuredMessage(
        id=id_val,
        type=type_val,
        content=content_val,
        metadata=metadata_val,
        timestamp=timestamp_val,
    )


# ---------------------------------------------------------------------------
# MessageBuffer — queue of pending messages
# ---------------------------------------------------------------------------

struct MessageBuffer:
    """A FIFO buffer for structured messages.

    Supports adding messages, draining (clearing), counting, and filtering by
    message type.
    """
    var _messages: List[StructuredMessage]

    def __init__(out self):
        self._messages = List[StructuredMessage]()

    def __copyinit__(out self, *, copy: Self):
        self._messages = copy._messages

    def __moveinit__(out self, *, deinit take: Self):
        self._messages = take._messages^

    def add(mut self, msg: StructuredMessage):
        """Append a message to the buffer."""
        self._messages.append(msg)

    def count(self) -> Int:
        """Return the number of buffered messages."""
        return len(self._messages)

    def get(self, index: Int) raises -> StructuredMessage:
        """Return the message at *index*."""
        if index < 0 or index >= len(self._messages):
            raise Error("MessageBuffer index out of range")
        return self._messages[index]

    def drain(mut self) -> List[StructuredMessage]:
        """Remove and return all messages, leaving the buffer empty."""
        var out = self._messages
        self._messages = List[StructuredMessage]()
        return out

    def filter_by_type(self, msg_type: String) -> List[StructuredMessage]:
        """Return only messages whose type matches *msg_type*.

        Does not modify the buffer.
        """
        var result = List[StructuredMessage]()
        for i in range(len(self._messages)):
            if self._messages[i].type == msg_type:
                result.append(self._messages[i])
        return result


# ---------------------------------------------------------------------------
# StructuredIOHandler — encode/decode with auto-incrementing sequence
# ---------------------------------------------------------------------------

struct StructuredIOHandler:
    """Manages structured I/O, assigning auto-incrementing sequence IDs.

    Typical usage:
        var handler = new_structured_handler()
        var line = handler.encode("assistant_message", "Hello!", "{}", "ts")
        var msg  = handler.decode(line)
    """
    var _next_id: Int
    var _outgoing: MessageBuffer
    var _incoming: MessageBuffer

    def __init__(out self):
        self._next_id = 1
        self._outgoing = MessageBuffer()
        self._incoming = MessageBuffer()

    def __copyinit__(out self, *, copy: Self):
        self._next_id = copy._next_id
        self._outgoing = copy._outgoing
        self._incoming = copy._incoming

    def __moveinit__(out self, *, deinit take: Self):
        self._next_id = take._next_id
        self._outgoing = take._outgoing^
        self._incoming = take._incoming^

    def next_id(self) -> Int:
        """Return the next sequence ID that will be assigned."""
        return self._next_id

    def encode(
        mut self,
        msg_type: String,
        content: String,
        metadata: String = "{}",
        timestamp: String = "0",
    ) -> String:
        """Create a StructuredMessage, assign a sequence ID, buffer it, and
        return its JSON-line representation."""
        var msg = StructuredMessage(
            id=self._next_id,
            type=msg_type,
            content=content,
            metadata=metadata,
            timestamp=timestamp,
        )
        self._next_id += 1
        self._outgoing.add(msg)
        return encode_message(msg)

    def decode(mut self, json_line: String) raises -> StructuredMessage:
        """Decode a JSON line and add the resulting message to the incoming
        buffer."""
        var msg = decode_message(json_line)
        self._incoming.add(msg)
        return msg

    def outgoing_count(self) -> Int:
        """Number of messages encoded so far."""
        return self._outgoing.count()

    def incoming_count(self) -> Int:
        """Number of messages decoded so far."""
        return self._incoming.count()

    def drain_outgoing(mut self) -> List[StructuredMessage]:
        """Drain and return all outgoing messages."""
        return self._outgoing.drain()

    def drain_incoming(mut self) -> List[StructuredMessage]:
        """Drain and return all incoming messages."""
        return self._incoming.drain()

    def filter_incoming_by_type(self, msg_type: String) -> List[StructuredMessage]:
        """Return incoming messages of a given type without draining."""
        return self._incoming.filter_by_type(msg_type)


# ---------------------------------------------------------------------------
# Convenience constructor
# ---------------------------------------------------------------------------

def new_structured_handler() -> StructuredIOHandler:
    """Create a fresh StructuredIOHandler starting at sequence 1."""
    return StructuredIOHandler()
