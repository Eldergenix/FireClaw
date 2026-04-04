# bridge/websocket.mojo — WebSocket client via Python websockets
#
# Used for MCP HTTP transport and streaming connections.
#
# Python dependency: websockets >= 12.0

from python import Python


struct WebSocketClient:
    """WebSocket client wrapping Python websockets library."""
    var _ws: PythonObject
    var _connected: Bool

    def __init__(out self):
        self._ws = PythonObject()
        self._connected = False

    def connect(mut self, url: String) raises:
        """Connect to a WebSocket server."""
        var websockets = Python.import_module("websockets.sync.client")
        self._ws = websockets.connect(str(url))
        self._connected = True

    def send(self, message: String) raises:
        """Send a message over the WebSocket."""
        if not self._connected:
            raise Error("WebSocket not connected")
        self._ws.send(str(message))

    def recv(self) raises -> String:
        """Receive a message from the WebSocket."""
        if not self._connected:
            raise Error("WebSocket not connected")
        var msg = self._ws.recv()
        return String(str(msg))

    def close(mut self) raises:
        """Close the WebSocket connection."""
        if self._connected:
            self._ws.close()
            self._connected = False
