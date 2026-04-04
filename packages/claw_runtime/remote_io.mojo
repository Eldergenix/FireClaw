# runtime/remote_io.mojo — Remote I/O transport adapters
#
# Mirrors TypeScript's remoteIO.ts — transport layer for structured I/O over
# different channels (stdio, file/named-pipe).
#
# Transports are implemented as concrete structs with a common method surface
# (Mojo does not yet have dynamic dispatch traits, so we use struct-based
# dispatch via the TransportKind enum).

from std.collections import List
from .structured_io import (
    StructuredMessage,
    StructuredIOHandler,
    encode_message,
    decode_message,
    new_structured_handler,
    MSG_HEARTBEAT,
)


# ---------------------------------------------------------------------------
# Transport kind tag
# ---------------------------------------------------------------------------

alias TRANSPORT_STDIO = "stdio"
alias TRANSPORT_FILE = "file"


@fieldwise_init
struct TransportConfig(Copyable, Movable):
    """Configuration for a transport adapter.

    Fields:
        kind      — "stdio" or "file"
        read_path — for file transport, the path to read from (named pipe / file)
        write_path — for file transport, the path to write to
    """
    var kind: String
    var read_path: String
    var write_path: String


# ---------------------------------------------------------------------------
# StdioTransport — JSON-lines over stdin / stdout
# ---------------------------------------------------------------------------

struct StdioTransport:
    """Transport that reads/writes JSON-lines over standard I/O streams.

    In a real implementation this would perform blocking or async reads on
    stdin and writes on stdout.  For the port we keep the serialization logic
    and buffer management; actual I/O will be wired through the bridge layer.
    """
    var _handler: StructuredIOHandler
    var _write_buffer: List[String]

    def __init__(out self):
        self._handler = new_structured_handler()
        self._write_buffer = List[String]()

    def __copyinit__(out self, *, copy: Self):
        self._handler = copy._handler
        self._write_buffer = copy._write_buffer

    def __moveinit__(out self, *, deinit take: Self):
        self._handler = take._handler^
        self._write_buffer = take._write_buffer^

    def send(mut self, msg_type: String, content: String, metadata: String = "{}") -> String:
        """Encode a message and queue its JSON-line for writing to stdout."""
        var line = self._handler.encode(msg_type, content, metadata)
        self._write_buffer.append(line)
        return line

    def receive(mut self, json_line: String) raises -> StructuredMessage:
        """Decode an incoming JSON-line (as if read from stdin)."""
        return self._handler.decode(json_line)

    def flush(mut self) -> List[String]:
        """Return and clear the pending write buffer."""
        var out = self._write_buffer
        self._write_buffer = List[String]()
        return out

    def pending_count(self) -> Int:
        """Number of lines waiting to be flushed."""
        return len(self._write_buffer)


# ---------------------------------------------------------------------------
# FileTransport — JSON-lines over named-pipe / file paths
# ---------------------------------------------------------------------------

struct FileTransport:
    """Transport that reads/writes JSON-lines to file paths (e.g. named pipes).

    Actual file I/O is deferred to the bridge layer; this struct manages the
    serialization, buffering, and path configuration.
    """
    var _handler: StructuredIOHandler
    var _write_buffer: List[String]
    var read_path: String
    var write_path: String

    def __init__(out self, read_path: String, write_path: String):
        self._handler = new_structured_handler()
        self._write_buffer = List[String]()
        self.read_path = read_path
        self.write_path = write_path

    def __copyinit__(out self, *, copy: Self):
        self._handler = copy._handler
        self._write_buffer = copy._write_buffer
        self.read_path = copy.read_path
        self.write_path = copy.write_path

    def __moveinit__(out self, *, deinit take: Self):
        self._handler = take._handler^
        self._write_buffer = take._write_buffer^
        self.read_path = take.read_path
        self.write_path = take.write_path

    def send(mut self, msg_type: String, content: String, metadata: String = "{}") -> String:
        """Encode a message and queue its JSON-line for writing to the write path."""
        var line = self._handler.encode(msg_type, content, metadata)
        self._write_buffer.append(line)
        return line

    def receive(mut self, json_line: String) raises -> StructuredMessage:
        """Decode an incoming JSON-line (as if read from the read path)."""
        return self._handler.decode(json_line)

    def flush(mut self) -> List[String]:
        """Return and clear the pending write buffer."""
        var out = self._write_buffer
        self._write_buffer = List[String]()
        return out

    def pending_count(self) -> Int:
        """Number of lines waiting to be flushed."""
        return len(self._write_buffer)


# ---------------------------------------------------------------------------
# RemoteSession — manages a remote connection
# ---------------------------------------------------------------------------

struct RemoteSession:
    """A remote session wrapping a transport.

    Manages session identity, connected state, heartbeat tracking, and
    delegates actual send/receive to a StdioTransport or FileTransport
    (selected at construction time via *transport_kind*).
    """
    var session_id: String
    var transport_kind: String
    var connected: Bool
    var _heartbeat_sent: Int
    var _heartbeat_received: Int
    var _message_count: Int

    # Internal transports — only one is active based on transport_kind
    var _stdio: StdioTransport
    var _file: FileTransport

    def __init__(
        out self,
        session_id: String,
        transport_kind: String,
        read_path: String = "",
        write_path: String = "",
    ):
        self.session_id = session_id
        self.transport_kind = transport_kind
        self.connected = True
        self._heartbeat_sent = 0
        self._heartbeat_received = 0
        self._message_count = 0
        self._stdio = StdioTransport()
        self._file = FileTransport(read_path=read_path, write_path=write_path)

    def __copyinit__(out self, *, copy: Self):
        self.session_id = copy.session_id
        self.transport_kind = copy.transport_kind
        self.connected = copy.connected
        self._heartbeat_sent = copy._heartbeat_sent
        self._heartbeat_received = copy._heartbeat_received
        self._message_count = copy._message_count
        self._stdio = copy._stdio
        self._file = copy._file

    def __moveinit__(out self, *, deinit take: Self):
        self.session_id = take.session_id
        self.transport_kind = take.transport_kind
        self.connected = take.connected
        self._heartbeat_sent = take._heartbeat_sent
        self._heartbeat_received = take._heartbeat_received
        self._message_count = take._message_count
        self._stdio = take._stdio^
        self._file = take._file^

    def send_message(
        mut self,
        msg_type: String,
        content: String,
        metadata: String = "{}",
    ) -> String:
        """Send a message through the active transport.

        Returns the encoded JSON-line.
        """
        self._message_count += 1
        if self.transport_kind == TRANSPORT_FILE:
            return self._file.send(msg_type, content, metadata)
        # Default to stdio
        return self._stdio.send(msg_type, content, metadata)

    def receive_message(mut self, json_line: String) raises -> StructuredMessage:
        """Receive and decode a JSON-line through the active transport."""
        var msg: StructuredMessage
        if self.transport_kind == TRANSPORT_FILE:
            msg = self._file.receive(json_line)
        else:
            msg = self._stdio.receive(json_line)

        # Track heartbeats
        if msg.type == MSG_HEARTBEAT:
            self._heartbeat_received += 1
        self._message_count += 1
        return msg

    def send_heartbeat(mut self) -> String:
        """Send a heartbeat message and track it."""
        self._heartbeat_sent += 1
        return self.send_message(MSG_HEARTBEAT, "ping")

    def heartbeats_sent(self) -> Int:
        """Number of heartbeats sent."""
        return self._heartbeat_sent

    def heartbeats_received(self) -> Int:
        """Number of heartbeats received."""
        return self._heartbeat_received

    def message_count(self) -> Int:
        """Total messages sent + received."""
        return self._message_count

    def disconnect(mut self):
        """Mark the session as disconnected."""
        self.connected = False

    def flush(mut self) -> List[String]:
        """Flush the active transport's write buffer."""
        if self.transport_kind == TRANSPORT_FILE:
            return self._file.flush()
        return self._stdio.flush()


# ---------------------------------------------------------------------------
# Factory helpers
# ---------------------------------------------------------------------------

def create_stdio_transport() -> StdioTransport:
    """Create a new StdioTransport."""
    return StdioTransport()


def create_file_transport(read_path: String, write_path: String) -> FileTransport:
    """Create a new FileTransport with the given paths."""
    return FileTransport(read_path=read_path, write_path=write_path)


def new_remote_session(
    session_id: String,
    transport_kind: String = TRANSPORT_STDIO,
    read_path: String = "",
    write_path: String = "",
) -> RemoteSession:
    """Create a new RemoteSession with the specified transport."""
    return RemoteSession(
        session_id=session_id,
        transport_kind=transport_kind,
        read_path=read_path,
        write_path=write_path,
    )
