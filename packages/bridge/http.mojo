# bridge/http.mojo — HTTP client via Python httpx
#
# Wraps Python's httpx library for HTTP/HTTPS requests.
# This is the primary network transport for the API client.
#
# Python dependency: httpx >= 0.27

from python import Python


@fieldwise_init
struct HttpResponse(Copyable, Movable):
    """Response from an HTTP request."""
    var status: Int
    var body: String
    var headers: String  # Simplified: JSON string of headers


struct HttpClient:
    """HTTP client wrapping Python httpx."""
    var _httpx: PythonObject
    var _client: PythonObject

    def __init__(out self) raises:
        var httpx = Python.import_module("httpx")
        self._httpx = httpx
        self._client = httpx.Client(timeout=120.0)

    def post(
        self,
        url: String,
        headers: Dict[String, String],
        body: String,
    ) raises -> HttpResponse:
        """Send an HTTP POST request.

        Args:
            url: The target URL.
            headers: Request headers.
            body: Request body string.

        Returns:
            HttpResponse with status, body, and headers.
        """
        var py_headers = Python.dict()
        for entry in headers.items():
            py_headers[str(entry[].key)] = str(entry[].value)

        var response = self._client.post(
            str(url), headers=py_headers, content=str(body)
        )
        return HttpResponse(
            status=Int(response.status_code),
            body=String(str(response.text)),
            headers="{}",
        )

    def stream_post(
        self,
        url: String,
        headers: Dict[String, String],
        body: String,
    ) raises -> PythonObject:
        """Send a streaming POST request, returning a Python response iterator.

        The caller should iterate over the response lines for SSE parsing.
        """
        var py_headers = Python.dict()
        for entry in headers.items():
            py_headers[str(entry[].key)] = str(entry[].value)

        # Use httpx streaming
        var request = self._httpx.Request("POST", str(url), headers=py_headers, content=str(body))
        var response = self._client.send(request, stream=True)

        if Int(response.status_code) != 200:
            var error_body = String(str(response.text))
            raise Error(
                "API request failed with status "
                + str(Int(response.status_code))
                + ": "
                + error_body
            )

        return response


from std.collections import Dict
