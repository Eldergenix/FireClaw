# runtime/mcp.mojo — MCP (Model Context Protocol) client
#
# Supports two transports:
#   1. stdio — spawn MCP server as subprocess, communicate via JSON-RPC over stdin/stdout
#   2. HTTP — WebSocket connection via bridge/websocket.mojo
#
# Config is read from .claw/settings.json under "mcpServers".

from std.collections import List, Dict
from std.pathlib import Path
from std.subprocess import run as subprocess_run


@fieldwise_init
struct McpServerConfig(Copyable, Movable):
    """Configuration for an MCP server."""
    var name: String
    var command: String  # For stdio transport
    var args: List[String]  # Command arguments
    var env: Dict[String, String]  # Environment variables
    var transport: String  # "stdio" | "http"
    var url: String  # For HTTP transport


@fieldwise_init
struct McpTool(Copyable, Movable):
    """A tool exposed by an MCP server."""
    var name: String
    var description: String
    var input_schema: String  # JSON schema
    var server_name: String  # Which MCP server provides this tool


@fieldwise_init
struct McpResource(Copyable, Movable):
    """A resource exposed by an MCP server."""
    var uri: String
    var name: String
    var description: String
    var mime_type: String


struct McpClient:
    """Client for MCP stdio servers using JSON-RPC protocol."""
    var servers: Dict[String, McpServerConfig]
    var tools: List[McpTool]
    var resources: List[McpResource]

    def __init__(out self):
        self.servers = Dict[String, McpServerConfig]()
        self.tools = List[McpTool]()
        self.resources = List[McpResource]()

    def load_config(mut self, settings_path: String) raises:
        """Load MCP server configs from settings file."""
        var path = Path(settings_path)
        if not path.exists():
            return
        var content = path.read_text()
        self._parse_mcp_config(content)

    def initialize_server(mut self, name: String) raises:
        """Initialize an MCP server and discover its tools/resources.

        For stdio transport: spawns the server process and sends
        the initialize JSON-RPC request.
        """
        if name not in self.servers:
            raise Error("MCP server not configured: " + name)

        var config = self.servers[name]

        if config.transport == "stdio":
            self._init_stdio_server(name, config)
        elif config.transport == "http":
            self._init_http_server(name, config)
        else:
            raise Error("Unknown MCP transport: " + config.transport)

    def call_tool(
        self, server_name: String, tool_name: String, arguments: String
    ) raises -> String:
        """Call a tool on an MCP server.

        Args:
            server_name: Name of the MCP server.
            tool_name: Name of the tool to call.
            arguments: JSON string of tool arguments.

        Returns:
            Tool result as a string.
        """
        # Build JSON-RPC request
        var request = (
            '{"jsonrpc":"2.0","id":1,"method":"tools/call",'
            '"params":{"name":"'
            + tool_name
            + '","arguments":'
            + arguments
            + "}}"
        )

        # TODO: Send via stdio pipe or WebSocket to the running server
        raise Error("MCP tool execution not yet implemented — requires process management")

    def _init_stdio_server(mut self, name: String, config: McpServerConfig) raises:
        """Initialize a stdio MCP server."""
        # TODO: Spawn subprocess, send initialize request, parse capabilities
        pass

    def _init_http_server(mut self, name: String, config: McpServerConfig) raises:
        """Initialize an HTTP MCP server via WebSocket."""
        # TODO: Connect via bridge/websocket, send initialize, parse capabilities
        pass

    def _parse_mcp_config(mut self, json_content: String):
        """Parse MCP server configurations from JSON."""
        # Simplified extraction — full parsing via EmberJson or bridge/json_compat
        pass
