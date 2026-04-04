# runtime/analytics.mojo — Native analytics engine with local event buffering
#
# Provides event tracking, usage analytics, and error reporting.
# Events are buffered locally and batch-sent via the bridge HTTP layer.

from std.collections import List


@fieldwise_init
struct AnalyticsEvent(Copyable, Movable):
    """A single analytics event."""
    var event_type: String       # "tool_use" | "command" | "api_call" | "error" | "session_start" | "session_end" | "turn_complete"
    var event_name: String       # Specific event name
    var properties: String       # JSON string of event properties
    var timestamp: String        # ISO-ish timestamp string
    var session_id: String
    var sequence_num: Int


@fieldwise_init
struct AnalyticsConfig(Copyable, Movable):
    """Configuration for analytics collection and dispatch."""
    var enabled: Bool
    var endpoint: String         # Remote analytics endpoint URL
    var batch_size: Int          # Events to buffer before sending (default 10)
    var flush_interval_hint: Int # Seconds between auto-flush (advisory)
    var anonymize: Bool          # Strip PII from events


struct AnalyticsClient:
    """Buffered analytics client that tracks events and flushes in batches."""
    var config: AnalyticsConfig
    var buffer: List[AnalyticsEvent]
    var session_id: String
    var _sequence: Int
    var _total_events: Int
    var _total_errors: Int

    def __init__(out self, config: AnalyticsConfig, session_id: String):
        self.config = config
        self.buffer = List[AnalyticsEvent]()
        self.session_id = session_id
        self._sequence = 0
        self._total_events = 0
        self._total_errors = 0

    def track(mut self, event_type: String, event_name: String, properties: String = "{}"):
        """Track a generic analytics event.

        If analytics is disabled, this is a no-op.
        """
        if not self.config.enabled:
            return

        self._sequence += 1
        var evt = AnalyticsEvent(
            event_type=event_type,
            event_name=event_name,
            properties=properties,
            timestamp=_current_timestamp(),
            session_id=self.session_id,
            sequence_num=self._sequence,
        )
        self.buffer.append(evt)
        self._total_events += 1

    def track_tool_use(mut self, tool_name: String, duration_ms: Int, success: Bool):
        """Track a tool invocation event."""
        var success_str: String
        if success:
            success_str = "true"
        else:
            success_str = "false"
        var props = (
            '{"tool":"' + tool_name
            + '","duration_ms":' + String(duration_ms)
            + ',"success":' + success_str + "}"
        )
        self.track("tool_use", "tool_invocation", props)

    def track_api_call(
        mut self,
        model: String,
        input_tokens: Int,
        output_tokens: Int,
        latency_ms: Int,
    ):
        """Track an API call event with token and latency metrics."""
        var props = (
            '{"model":"' + model
            + '","input_tokens":' + String(input_tokens)
            + ',"output_tokens":' + String(output_tokens)
            + ',"latency_ms":' + String(latency_ms) + "}"
        )
        self.track("api_call", "api_request", props)

    def track_error(mut self, error_type: String, message: String):
        """Track an error event and increment the error counter."""
        var props = '{"error_type":"' + error_type + '","message":"' + message + '"}'
        self.track("error", "error_occurred", props)
        self._total_errors += 1

    def track_session_start(mut self):
        """Track session start event."""
        self.track("session_start", "session_started")

    def track_session_end(mut self, total_turns: Int, total_cost_usd: Float64):
        """Track session end event with summary metrics."""
        var props = (
            '{"total_turns":' + String(total_turns)
            + ',"total_cost_usd":' + String(total_cost_usd) + "}"
        )
        self.track("session_end", "session_ended", props)

    def flush(mut self) raises -> Int:
        """Send all buffered events and clear the buffer.

        Returns the number of events that were flushed.
        In this local-only implementation the events are cleared from the
        buffer without actually dispatching over HTTP (use the bridge
        analytics sender for real dispatch).
        """
        var count = len(self.buffer)
        if count == 0:
            return 0

        # Serialize before clearing — callers that need the payload
        # should call _serialize_batch() first.
        self.buffer = List[AnalyticsEvent]()
        return count

    def pending_count(self) -> Int:
        """Return the number of events waiting to be flushed."""
        return len(self.buffer)

    def total_tracked(self) -> Int:
        """Return the total number of events tracked since creation."""
        return self._total_events

    def summary(self) -> String:
        """Human-readable analytics summary."""
        return (
            "Analytics: "
            + String(self._total_events) + " events tracked, "
            + String(len(self.buffer)) + " pending, "
            + String(self._total_errors) + " errors"
        )

    def _should_flush(self) -> Bool:
        """Check whether the buffer has reached the batch size threshold."""
        return len(self.buffer) >= self.config.batch_size

    def _serialize_batch(self) -> String:
        """Serialize buffered events as a JSON array string."""
        if len(self.buffer) == 0:
            return "[]"

        var parts = List[String]()
        for i in range(len(self.buffer)):
            var evt = self.buffer[i]
            var entry = (
                '{"event_type":"' + evt.event_type
                + '","event_name":"' + evt.event_name
                + '","properties":' + evt.properties
                + ',"timestamp":"' + evt.timestamp
                + '","session_id":"' + evt.session_id
                + '","sequence_num":' + String(evt.sequence_num) + "}"
            )
            parts.append(entry)

        var result = String("[")
        for i in range(len(parts)):
            if i > 0:
                result += ","
            result += parts[i]
        result += "]"
        return result


# ---------------------------------------------------------------------------
# Free functions
# ---------------------------------------------------------------------------

def default_analytics_config() -> AnalyticsConfig:
    """Return a sensible default analytics configuration (enabled)."""
    return AnalyticsConfig(
        enabled=True,
        endpoint="https://analytics.claw.dev/v1/events",
        batch_size=10,
        flush_interval_hint=60,
        anonymize=False,
    )


def disabled_analytics_config() -> AnalyticsConfig:
    """Return an analytics configuration with tracking disabled."""
    return AnalyticsConfig(
        enabled=False,
        endpoint="",
        batch_size=10,
        flush_interval_hint=60,
        anonymize=False,
    )


def new_analytics_client(session_id: String, enabled: Bool = True) -> AnalyticsClient:
    """Create a new AnalyticsClient with default config.

    Args:
        session_id: Unique session identifier.
        enabled: Whether analytics tracking is active.

    Returns:
        A freshly initialised AnalyticsClient.
    """
    var config: AnalyticsConfig
    if enabled:
        config = default_analytics_config()
    else:
        config = disabled_analytics_config()
    return AnalyticsClient(config, session_id)


def format_analytics_report(client: AnalyticsClient) -> String:
    """Generate a detailed human-readable analytics report."""
    var report = String("=== Analytics Report ===\n")
    report += "Session: " + client.session_id + "\n"
    report += "Total events: " + String(client._total_events) + "\n"
    report += "Total errors: " + String(client._total_errors) + "\n"
    report += "Pending:      " + String(len(client.buffer)) + "\n"
    report += "Sequence:     " + String(client._sequence) + "\n"
    report += "Enabled:      "
    if client.config.enabled:
        report += "yes"
    else:
        report += "no"
    report += "\n"
    report += "Endpoint:     " + client.config.endpoint + "\n"
    report += "Batch size:   " + String(client.config.batch_size) + "\n"
    report += "========================"
    return report


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _current_timestamp() -> String:
    """Return a placeholder ISO-ish timestamp.

    A real implementation would call into the Python bridge or Mojo's
    time facilities.  For now we return a fixed-format placeholder so
    that all other logic can be tested deterministically.
    """
    return "2026-01-01T00:00:00Z"
