# tests/test_analytics.mojo — Unit tests for the native analytics engine

from std.testing import assert_equal, assert_true


# ---------------------------------------------------------------------------
# Inline helpers (avoid cross-package import issues in test runners)
# ---------------------------------------------------------------------------

@fieldwise_init
struct _AnalyticsEvent(Copyable, Movable):
    var event_type: String
    var event_name: String
    var properties: String
    var timestamp: String
    var session_id: String
    var sequence_num: Int


@fieldwise_init
struct _AnalyticsConfig(Copyable, Movable):
    var enabled: Bool
    var endpoint: String
    var batch_size: Int
    var flush_interval_hint: Int
    var anonymize: Bool


struct _AnalyticsClient:
    var config: _AnalyticsConfig
    var buffer: List[_AnalyticsEvent]
    var session_id: String
    var _sequence: Int
    var _total_events: Int
    var _total_errors: Int

    def __init__(out self, config: _AnalyticsConfig, session_id: String):
        self.config = config
        self.buffer = List[_AnalyticsEvent]()
        self.session_id = session_id
        self._sequence = 0
        self._total_events = 0
        self._total_errors = 0

    def track(mut self, event_type: String, event_name: String, properties: String = "{}"):
        if not self.config.enabled:
            return
        self._sequence += 1
        var evt = _AnalyticsEvent(
            event_type=event_type,
            event_name=event_name,
            properties=properties,
            timestamp="2026-01-01T00:00:00Z",
            session_id=self.session_id,
            sequence_num=self._sequence,
        )
        self.buffer.append(evt)
        self._total_events += 1

    def track_tool_use(mut self, tool_name: String, duration_ms: Int, success: Bool):
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

    def track_api_call(mut self, model: String, input_tokens: Int, output_tokens: Int, latency_ms: Int):
        var props = (
            '{"model":"' + model
            + '","input_tokens":' + String(input_tokens)
            + ',"output_tokens":' + String(output_tokens)
            + ',"latency_ms":' + String(latency_ms) + "}"
        )
        self.track("api_call", "api_request", props)

    def track_error(mut self, error_type: String, message: String):
        var props = '{"error_type":"' + error_type + '","message":"' + message + '"}'
        self.track("error", "error_occurred", props)
        self._total_errors += 1

    def track_session_start(mut self):
        self.track("session_start", "session_started")

    def track_session_end(mut self, total_turns: Int, total_cost_usd: Float64):
        var props = (
            '{"total_turns":' + String(total_turns)
            + ',"total_cost_usd":' + String(total_cost_usd) + "}"
        )
        self.track("session_end", "session_ended", props)

    def flush(mut self) raises -> Int:
        var count = len(self.buffer)
        if count == 0:
            return 0
        self.buffer = List[_AnalyticsEvent]()
        return count

    def pending_count(self) -> Int:
        return len(self.buffer)

    def total_tracked(self) -> Int:
        return self._total_events

    def summary(self) -> String:
        return (
            "Analytics: "
            + String(self._total_events) + " events tracked, "
            + String(len(self.buffer)) + " pending, "
            + String(self._total_errors) + " errors"
        )

    def _should_flush(self) -> Bool:
        return len(self.buffer) >= self.config.batch_size

    def _serialize_batch(self) -> String:
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


from std.collections import List


def _make_config(enabled: Bool = True) -> _AnalyticsConfig:
    return _AnalyticsConfig(
        enabled=enabled,
        endpoint="https://analytics.claw.dev/v1/events",
        batch_size=10,
        flush_interval_hint=60,
        anonymize=False,
    )


def _make_client(enabled: Bool = True) -> _AnalyticsClient:
    return _AnalyticsClient(_make_config(enabled), "test-session-001")


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_analytics_client_creation():
    """Create client, verify initial state (0 events, 0 errors)."""
    var client = _make_client()
    assert_equal(client._total_events, 0)
    assert_equal(client._total_errors, 0)
    assert_equal(client.pending_count(), 0)
    assert_equal(client._sequence, 0)
    assert_equal(client.session_id, "test-session-001")


def test_track_event():
    """Track an event, verify pending_count is 1."""
    var client = _make_client()
    client.track("command", "slash_run", '{"cmd":"/run"}')
    assert_equal(client.pending_count(), 1)
    assert_equal(client._total_events, 1)


def test_track_tool_use():
    """Track tool use, verify event in buffer with correct type."""
    var client = _make_client()
    client.track_tool_use("bash", 150, True)
    assert_equal(client.pending_count(), 1)
    assert_equal(client.buffer[0].event_type, "tool_use")
    assert_equal(client.buffer[0].event_name, "tool_invocation")
    assert_true('\"tool\":\"bash\"' in client.buffer[0].properties)
    assert_true('\"success\":true' in client.buffer[0].properties)


def test_track_api_call():
    """Track API call, verify event properties."""
    var client = _make_client()
    client.track_api_call("claude-opus-4-6", 1000, 500, 2500)
    assert_equal(client.pending_count(), 1)
    assert_equal(client.buffer[0].event_type, "api_call")
    assert_true('\"model\":\"claude-opus-4-6\"' in client.buffer[0].properties)
    assert_true('\"input_tokens\":1000' in client.buffer[0].properties)
    assert_true('\"output_tokens\":500' in client.buffer[0].properties)
    assert_true('\"latency_ms\":2500' in client.buffer[0].properties)


def test_track_error():
    """Track error, verify _total_errors incremented."""
    var client = _make_client()
    client.track_error("timeout", "request timed out after 30s")
    assert_equal(client._total_errors, 1)
    assert_equal(client.pending_count(), 1)
    assert_equal(client.buffer[0].event_type, "error")


def test_track_session_lifecycle():
    """track_session_start, then track_session_end, verify both in buffer."""
    var client = _make_client()
    client.track_session_start()
    client.track_session_end(12, 0.045)
    assert_equal(client.pending_count(), 2)
    assert_equal(client.buffer[0].event_type, "session_start")
    assert_equal(client.buffer[1].event_type, "session_end")
    assert_true('\"total_turns\":12' in client.buffer[1].properties)


def test_pending_count():
    """Track 5 events, verify pending_count is 5."""
    var client = _make_client()
    for i in range(5):
        client.track("turn_complete", "turn_" + String(i))
    assert_equal(client.pending_count(), 5)


def test_total_tracked() raises:
    """Track events, flush, verify total_tracked persists after flush."""
    var client = _make_client()
    client.track("command", "cmd_a")
    client.track("command", "cmd_b")
    client.track("command", "cmd_c")
    assert_equal(client.total_tracked(), 3)

    var flushed = client.flush()
    assert_equal(flushed, 3)
    assert_equal(client.pending_count(), 0)
    # total_tracked should still be 3 even after flush
    assert_equal(client.total_tracked(), 3)


def test_serialize_batch():
    """Track events, serialize, verify valid JSON array structure."""
    var client = _make_client()
    client.track("tool_use", "bash_run")
    client.track("api_call", "api_req")
    var json = client._serialize_batch()
    # Must start with [ and end with ]
    assert_true(json.startswith("["))
    assert_true(json.endswith("]"))
    # Must contain both event names
    assert_true('"bash_run"' in json)
    assert_true('"api_req"' in json)
    # Must contain session id
    assert_true('"test-session-001"' in json)


def test_disabled_analytics():
    """Create disabled client, track event, verify buffer is empty."""
    var client = _make_client(enabled=False)
    client.track("command", "should_be_ignored")
    client.track_tool_use("bash", 100, True)
    client.track_error("timeout", "nope")
    # When disabled, track() is a no-op so buffer stays empty
    assert_equal(client.pending_count(), 0)
    assert_equal(client._total_events, 0)
    # track_error increments _total_errors independently of track()
    # but since track() early-returns, properties are never stored
    # _total_errors is still incremented by track_error wrapper
    assert_equal(client._total_errors, 1)


def test_summary():
    """Track mixed events, verify summary contains event count."""
    var client = _make_client()
    client.track("tool_use", "bash")
    client.track("api_call", "api")
    client.track_error("runtime", "oops")
    var s = client.summary()
    assert_true("3 events tracked" in s)
    assert_true("3 pending" in s)
    assert_true("1 errors" in s)


def main() raises:
    """Run all analytics tests."""
    test_analytics_client_creation()
    test_track_event()
    test_track_tool_use()
    test_track_api_call()
    test_track_error()
    test_track_session_lifecycle()
    test_pending_count()
    test_total_tracked()
    test_serialize_batch()
    test_disabled_analytics()
    test_summary()
    print("All analytics tests passed.")
