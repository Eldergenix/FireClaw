# bridge/analytics.mojo — HTTP bridge for sending analytics batches
#
# Uses bridge/http.mojo HttpClient to POST analytics event payloads
# to a remote endpoint.  Also provides an endpoint health check.

from python import Python
from std.collections import Dict


struct AnalyticsSender:
    """Sends analytics event batches over HTTP via the Python bridge."""
    var _client: PythonObject
    var _httpx: PythonObject

    def __init__(out self) raises:
        """Create an AnalyticsSender backed by a Python httpx client."""
        var httpx = Python.import_module("httpx")
        self._httpx = httpx
        self._client = httpx.Client(timeout=30.0)

    def send_batch(self, endpoint: String, payload: String) raises -> Bool:
        """POST a JSON batch of analytics events to the endpoint.

        Args:
            endpoint: The URL to POST to.
            payload: A JSON string (typically a JSON array of events).

        Returns:
            True if the server responded with a 2xx status code.
        """
        var headers = Python.dict()
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"

        var response = self._client.post(
            str(endpoint), headers=headers, content=str(payload)
        )
        var status = Int(response.status_code)
        return status >= 200 and status < 300

    def check_endpoint(self, endpoint: String) raises -> Bool:
        """Verify that the analytics endpoint is reachable (HEAD request).

        Args:
            endpoint: The URL to check.

        Returns:
            True if the server responds with a 2xx status code.
        """
        var response = self._client.head(str(endpoint))
        var status = Int(response.status_code)
        return status >= 200 and status < 300


def send_analytics_batch(endpoint: String, events_json: String) raises -> Bool:
    """Convenience free function: create a sender and POST a batch.

    Args:
        endpoint: The analytics endpoint URL.
        events_json: Serialized JSON array of analytics events.

    Returns:
        True on success (2xx).
    """
    var sender = AnalyticsSender()
    return sender.send_batch(endpoint, events_json)
