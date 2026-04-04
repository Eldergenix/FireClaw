# runtime/conversation.mojo — Core conversation loop with tool calling
#
# Implements the agent loop:
#   1. Assemble system prompt + messages
#   2. Call Anthropic API (via bridge)
#   3. Parse response for tool calls
#   4. Execute tools
#   5. Loop until end_turn or max iterations

from std.collections import List
from api.types import Message, ToolSpec, ApiResponse, ToolUseBlock, UsageInfo
from .config import RuntimeConfig
from .session import Session, add_message, update_usage


@fieldwise_init
struct TurnResult(Copyable, Movable):
    """Result of a single conversation turn."""
    var assistant_text: String
    var tool_calls_made: Int
    var stop_reason: String
    var usage: UsageInfo


struct ConversationLoop:
    """The core agentic conversation loop.

    Manages the cycle of:
      user input → API call → tool execution → API call → ... → final response
    """
    var config: RuntimeConfig
    var tools: List[ToolSpec]
    var system_prompt: String
    var max_iterations: Int

    def __init__(
        out self,
        config: RuntimeConfig,
        tools: List[ToolSpec],
        system_prompt: String,
        max_iterations: Int = 200,
    ):
        self.config = config
        self.tools = tools
        self.system_prompt = system_prompt
        self.max_iterations = max_iterations

    def run_turn(
        mut self,
        mut session: Session,
        user_input: String,
    ) raises -> TurnResult:
        """Execute a full conversation turn with tool calling loop.

        This is the heart of the agentic loop:
          1. Add user message to session
          2. Call API with full context
          3. If response contains tool_use, execute tools and continue
          4. If response is end_turn, return final text
        """
        # Add user message
        var user_msg = Message(
            role="user",
            content=user_input,
            tool_use_blocks=List[ToolUseBlock](),
        )
        add_message(session, user_msg)

        var total_tool_calls = 0
        var iterations = 0
        var final_text = String("")
        var final_stop = String("end_turn")
        var total_usage = UsageInfo(
            input_tokens=0,
            output_tokens=0,
            cache_creation_input_tokens=0,
            cache_read_input_tokens=0,
        )

        while iterations < self.max_iterations:
            iterations += 1

            # Call API (this will delegate to bridge for HTTP)
            var response = self._call_api(session)

            # Accumulate usage
            total_usage.input_tokens += response.usage.input_tokens
            total_usage.output_tokens += response.usage.output_tokens

            # Add assistant message to session
            var assistant_msg = Message(
                role="assistant",
                content=response.content,
                tool_use_blocks=response.tool_use_blocks,
            )
            add_message(session, assistant_msg)

            if response.stop_reason == "end_turn" or len(response.tool_use_blocks) == 0:
                final_text = response.content
                final_stop = response.stop_reason
                break

            # Execute tool calls and add results
            for tool_call in response.tool_use_blocks:
                total_tool_calls += 1
                var result = self._execute_tool(tool_call[])
                var tool_result_msg = Message(
                    role="user",
                    content='{"type":"tool_result","tool_use_id":"'
                    + tool_call[].id
                    + '","content":'
                    + _quote(result)
                    + "}",
                    tool_use_blocks=List[ToolUseBlock](),
                )
                add_message(session, tool_result_msg)

        update_usage(session, total_usage)

        return TurnResult(
            assistant_text=final_text,
            tool_calls_made=total_tool_calls,
            stop_reason=final_stop,
            usage=total_usage,
        )

    def _call_api(self, session: Session) raises -> ApiResponse:
        """Call the Anthropic API with current session context.

        TODO: This is a placeholder — actual HTTP call goes through bridge/http.mojo.
        """
        raise Error(
            "API call not yet connected — requires bridge/http.mojo integration"
        )

    def _execute_tool(self, tool_call: ToolUseBlock) raises -> String:
        """Execute a tool call and return the result string.

        TODO: Wire up to tools/ package registry.
        """
        raise Error("Tool execution not yet connected — requires tools/ integration")


def _quote(s: String) -> String:
    """JSON-escape and quote a string."""
    var result = String('"')
    for i in range(len(s)):
        var c = s[i]
        if c == '"':
            result += '\\"'
        elif c == "\\":
            result += "\\\\"
        elif c == "\n":
            result += "\\n"
        else:
            result += c
    result += '"'
    return result
