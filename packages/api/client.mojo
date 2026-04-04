# api/client.mojo — Anthropic Messages API client
#
# HTTP transport is delegated to bridge/http.mojo.
# This module handles request construction, response parsing, and SSE stream management.

from std.collections import List, Dict, Optional
from .types import Message, ToolSpec, ApiResponse, UsageInfo, ToolUseBlock


struct AnthropicClient:
    """Client for the Anthropic Messages API."""
    var api_key: String
    var base_url: String
    var model: String
    var max_tokens: Int
    var api_version: String

    def __init__(
        out self,
        api_key: String,
        model: String = "claude-opus-4-6",
        base_url: String = "https://api.anthropic.com",
        max_tokens: Int = 32768,
    ):
        self.api_key = api_key
        self.base_url = base_url
        self.model = model
        self.max_tokens = max_tokens
        self.api_version = "2023-06-01"

    def build_headers(self) -> Dict[String, String]:
        """Build HTTP headers for API requests."""
        var headers = Dict[String, String]()
        headers["x-api-key"] = self.api_key
        headers["anthropic-version"] = self.api_version
        headers["content-type"] = "application/json"
        headers["anthropic-beta"] = "interleaved-thinking-2025-05-14"
        return headers

    def build_request_body(
        self,
        messages: List[Message],
        tools: List[ToolSpec],
        system_prompt: String = "",
        stream: Bool = True,
    ) -> String:
        """Build JSON request body for Messages API.

        Returns a JSON string ready to POST to /v1/messages.
        """
        var body = '{"model":"' + self.model + '"'
        body += ',"max_tokens":' + String(self.max_tokens)

        if system_prompt != "":
            body += ',"system":' + _json_escape(system_prompt)

        # Messages array
        body += ',"messages":['
        for i in range(len(messages)):
            if i > 0:
                body += ","
            var msg = messages[i]
            body += '{"role":' + _json_escape(msg.role)
            body += ',"content":' + _json_escape(msg.content) + "}"
        body += "]"

        # Tools array
        if len(tools) > 0:
            body += ',"tools":['
            for i in range(len(tools)):
                if i > 0:
                    body += ","
                var tool = tools[i]
                body += '{"name":' + _json_escape(tool.name)
                body += ',"description":' + _json_escape(tool.description)
                body += ',"input_schema":' + tool.input_schema + "}"
            body += "]"

        if stream:
            body += ',"stream":true'

        body += "}"
        return body

    def messages_endpoint(self) -> String:
        """Return the full URL for the messages endpoint."""
        return self.base_url + "/v1/messages"


def _json_escape(s: String) -> String:
    """Escape a string for JSON output, wrapping in double quotes."""
    var result = String('"')
    for i in range(len(s)):
        var c = s[i]
        if c == '"':
            result += '\\"'
        elif c == "\\":
            result += "\\\\"
        elif c == "\n":
            result += "\\n"
        elif c == "\r":
            result += "\\r"
        elif c == "\t":
            result += "\\t"
        else:
            result += c
    result += '"'
    return result
