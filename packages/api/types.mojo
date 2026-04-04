# api/types.mojo — Core API types for Anthropic Messages API

from std.collections import List, Dict, Optional


@fieldwise_init
struct UsageInfo(Copyable, Movable, Writable):
    """Token usage information from an API response."""
    var input_tokens: Int
    var output_tokens: Int
    var cache_creation_input_tokens: Int
    var cache_read_input_tokens: Int

    def __str__(self) -> String:
        return (
            "UsageInfo(input="
            + String(self.input_tokens)
            + ", output="
            + String(self.output_tokens)
            + ")"
        )


@fieldwise_init
struct ContentBlock(Copyable, Movable):
    """A content block in a message — text or tool_use."""
    var type: String  # "text" | "tool_use" | "tool_result"
    var text: String  # text content (for type="text")
    var tool_use_id: String  # tool call ID (for type="tool_use" or "tool_result")
    var tool_name: String  # tool name (for type="tool_use")
    var tool_input: String  # JSON string of tool input (for type="tool_use")


@fieldwise_init
struct ToolUseBlock(Copyable, Movable, Writable):
    """A parsed tool_use block from the API response."""
    var id: String
    var name: String
    var input_json: String  # Raw JSON string of the tool input

    def __str__(self) -> String:
        return "ToolUse(" + self.name + ", id=" + self.id + ")"


@fieldwise_init
struct Message(Copyable, Movable):
    """A conversation message (user, assistant, or system)."""
    var role: String  # "user" | "assistant" | "system"
    var content: String  # Text content or JSON for tool use/results
    var tool_use_blocks: List[ToolUseBlock]  # Parsed tool calls (assistant msgs)


@fieldwise_init
struct ToolSpec(Copyable, Movable, Writable):
    """Tool specification for the API request."""
    var name: String
    var description: String
    var input_schema: String  # JSON schema string

    def __str__(self) -> String:
        return "ToolSpec(" + self.name + ")"


@fieldwise_init
struct ApiResponse(Copyable, Movable):
    """Response from the Anthropic Messages API."""
    var id: String
    var content: String  # Final text content
    var stop_reason: String  # "end_turn" | "tool_use" | "max_tokens"
    var usage: UsageInfo
    var tool_use_blocks: List[ToolUseBlock]  # Extracted tool calls
    var raw_json: String  # Full response JSON for debugging
