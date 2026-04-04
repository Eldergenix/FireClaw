# api/sse.mojo — Server-Sent Events parser for streaming API responses
#
# Parses the SSE wire format:
#   event: <event_type>\n
#   data: <json_payload>\n
#   \n

from std.collections import List, Optional


@fieldwise_init
struct SSEEvent(Copyable, Movable, Writable):
    """A single parsed SSE event."""
    var event_type: String
    var data: String

    def __str__(self) -> String:
        return "SSEEvent(" + self.event_type + ")"

    def is_done(self) -> Bool:
        return self.event_type == "message_stop"

    def is_content_delta(self) -> Bool:
        return self.event_type == "content_block_delta"

    def is_content_start(self) -> Bool:
        return self.event_type == "content_block_start"


struct SSEParser:
    """Incremental SSE parser that processes raw byte chunks into events."""
    var _buffer: String
    var _events: List[SSEEvent]

    def __init__(out self):
        self._buffer = ""
        self._events = List[SSEEvent]()

    def feed(mut self, chunk: String):
        """Feed raw text chunk into the parser. Call drain() to get events."""
        self._buffer += chunk
        self._parse_buffer()

    def drain(mut self) -> List[SSEEvent]:
        """Return and clear all parsed events."""
        var result = self._events
        self._events = List[SSEEvent]()
        return result

    def _parse_buffer(mut self):
        """Parse complete events from the buffer."""
        while True:
            # Find double-newline boundary (end of event)
            var boundary = self._find_event_boundary()
            if boundary < 0:
                break

            var event_text = self._buffer[:boundary]
            self._buffer = self._buffer[boundary + 2 :]  # skip \n\n

            var event = self._parse_event(event_text)
            if event.event_type != "":
                self._events.append(event)

    def _find_event_boundary(self) -> Int:
        """Find the position of \\n\\n in the buffer. Returns -1 if not found."""
        var i = 0
        while i < len(self._buffer) - 1:
            if self._buffer[i] == "\n" and self._buffer[i + 1] == "\n":
                return i
            i += 1
        return -1

    @staticmethod
    def _parse_event(text: String) -> SSEEvent:
        """Parse a single event block into an SSEEvent."""
        var event_type = String("")
        var data_parts = List[String]()

        var lines = text.split("\n")
        for line in lines:
            var l = line[]
            if l.startswith("event:"):
                event_type = l[6:].strip()
            elif l.startswith("data:"):
                data_parts.append(l[5:].strip())

        var data = String("")
        for i in range(len(data_parts)):
            if i > 0:
                data += "\n"
            data += data_parts[i]

        return SSEEvent(event_type=event_type, data=data)
