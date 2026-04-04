# tests/test_structured_io.mojo — Tests for structured I/O and remote transport
#
# Run with:  mojo test fireclaw/tests/test_structured_io.mojo

from std.testing import assert_equal, assert_true
from std.collections import List

from claw_runtime.structured_io import (
    StructuredMessage,
    StructuredIOHandler,
    MessageBuffer,
    encode_message,
    decode_message,
    is_valid_message_type,
    new_structured_handler,
    MSG_USER,
    MSG_ASSISTANT,
    MSG_TOOL_USE,
    MSG_TOOL_RESULT,
    MSG_SYSTEM,
    MSG_ERROR,
    MSG_HEARTBEAT,
)


def test_encode_decode_message():
    """Encode a message to JSON, decode it back, and verify all fields match."""
    var original = StructuredMessage(
        id=42,
        type=MSG_ASSISTANT,
        content="Hello, world!",
        metadata='{"model":"opus"}',
        timestamp="2026-04-04T00:00:00Z",
    )

    var json_line = encode_message(original)

    # The JSON must contain key fragments
    assert_true('"id":42' in json_line, "JSON should contain id")
    assert_true('"type":"assistant_message"' in json_line, "JSON should contain type")

    # Decode round-trip
    var decoded = decode_message(json_line)
    assert_equal(decoded.id, 42)
    assert_equal(decoded.type, MSG_ASSISTANT)
    assert_equal(decoded.content, "Hello, world!")
    assert_equal(decoded.metadata, '{"model":"opus"}')
    assert_equal(decoded.timestamp, "2026-04-04T00:00:00Z")


def test_encode_decode_special_characters():
    """Verify that quotes and newlines survive the encode/decode round-trip."""
    var original = StructuredMessage(
        id=1,
        type=MSG_USER,
        content='He said "hi"\nNew line',
        metadata="{}",
        timestamp="0",
    )
    var json_line = encode_message(original)
    var decoded = decode_message(json_line)
    assert_equal(decoded.content, 'He said "hi"\nNew line')


def test_message_buffer():
    """Add messages to a buffer, verify count, drain, and verify empty."""
    var buf = MessageBuffer()
    assert_equal(buf.count(), 0)

    var m1 = StructuredMessage(
        id=1, type=MSG_USER, content="a", metadata="{}", timestamp="0"
    )
    var m2 = StructuredMessage(
        id=2, type=MSG_ASSISTANT, content="b", metadata="{}", timestamp="0"
    )
    var m3 = StructuredMessage(
        id=3, type=MSG_TOOL_USE, content="c", metadata="{}", timestamp="0"
    )

    buf.add(m1)
    buf.add(m2)
    buf.add(m3)
    assert_equal(buf.count(), 3)

    # Drain returns all messages and empties the buffer
    var drained = buf.drain()
    assert_equal(len(drained), 3)
    assert_equal(buf.count(), 0)


def test_sequence_numbers():
    """Handler should assign incrementing sequence IDs starting at 1."""
    var handler = new_structured_handler()
    assert_equal(handler.next_id(), 1)

    _ = handler.encode(MSG_USER, "first")
    assert_equal(handler.next_id(), 2)

    _ = handler.encode(MSG_ASSISTANT, "second")
    assert_equal(handler.next_id(), 3)

    _ = handler.encode(MSG_SYSTEM, "third")
    assert_equal(handler.next_id(), 4)

    # Outgoing buffer should have 3 messages
    assert_equal(handler.outgoing_count(), 3)


def test_filter_by_type():
    """Buffer with mixed types — filter should return only the requested type."""
    var buf = MessageBuffer()

    buf.add(StructuredMessage(
        id=1, type=MSG_USER, content="u1", metadata="{}", timestamp="0"
    ))
    buf.add(StructuredMessage(
        id=2, type=MSG_TOOL_USE, content="t1", metadata="{}", timestamp="0"
    ))
    buf.add(StructuredMessage(
        id=3, type=MSG_ASSISTANT, content="a1", metadata="{}", timestamp="0"
    ))
    buf.add(StructuredMessage(
        id=4, type=MSG_TOOL_USE, content="t2", metadata="{}", timestamp="0"
    ))
    buf.add(StructuredMessage(
        id=5, type=MSG_ERROR, content="e1", metadata="{}", timestamp="0"
    ))

    var tool_msgs = buf.filter_by_type(MSG_TOOL_USE)
    assert_equal(len(tool_msgs), 2)
    assert_equal(tool_msgs[0].content, "t1")
    assert_equal(tool_msgs[1].content, "t2")

    # Filter should not drain the buffer
    assert_equal(buf.count(), 5)

    # Filter for a type not present should return empty
    var heartbeats = buf.filter_by_type(MSG_HEARTBEAT)
    assert_equal(len(heartbeats), 0)


def test_heartbeat_message():
    """Encode a heartbeat and verify its type field."""
    var handler = new_structured_handler()
    var line = handler.encode(MSG_HEARTBEAT, "ping")

    assert_true('"type":"heartbeat"' in line, "JSON should contain heartbeat type")

    var decoded = decode_message(line)
    assert_equal(decoded.type, MSG_HEARTBEAT)
    assert_equal(decoded.content, "ping")
    assert_equal(decoded.id, 1)


def test_valid_message_types():
    """Verify the type-validation helper."""
    assert_true(is_valid_message_type(MSG_USER), "user_message should be valid")
    assert_true(is_valid_message_type(MSG_ASSISTANT), "assistant_message should be valid")
    assert_true(is_valid_message_type(MSG_TOOL_USE), "tool_use should be valid")
    assert_true(is_valid_message_type(MSG_TOOL_RESULT), "tool_result should be valid")
    assert_true(is_valid_message_type(MSG_SYSTEM), "system should be valid")
    assert_true(is_valid_message_type(MSG_ERROR), "error should be valid")
    assert_true(is_valid_message_type(MSG_HEARTBEAT), "heartbeat should be valid")

    assert_true(
        not is_valid_message_type("unknown"),
        "unknown should not be valid",
    )


def test_handler_decode_tracks_incoming():
    """Handler.decode should add messages to the incoming buffer."""
    var handler = new_structured_handler()

    # Encode a message to get a valid JSON-line
    var line = handler.encode(MSG_SYSTEM, "status ok")
    assert_equal(handler.incoming_count(), 0)

    # Decode it — should land in incoming buffer
    _ = handler.decode(line)
    assert_equal(handler.incoming_count(), 1)

    # Decode another
    var line2 = handler.encode(MSG_ERROR, "oops")
    _ = handler.decode(line2)
    assert_equal(handler.incoming_count(), 2)

    # Filter incoming
    var errors = handler.filter_incoming_by_type(MSG_ERROR)
    assert_equal(len(errors), 1)
    assert_equal(errors[0].content, "oops")
