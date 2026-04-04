# tools/web_fetch.mojo — Web fetching tool via bridge
#
# Fetches web pages and returns their text content.
# Delegates HTTP to bridge/http.mojo.

from std.collections import Dict


struct WebFetchTool:
    """Fetch web page content."""

    def execute(self, url: String) raises -> String:
        """Fetch a URL and return its text content.

        Args:
            url: The URL to fetch.

        Returns:
            Page content as text.
        """
        from bridge.http import HttpClient

        var client = HttpClient()
        var headers = Dict[String, String]()
        headers["User-Agent"] = "Claw-Code/0.1.0 (Mojo)"
        headers["Accept"] = "text/html,text/plain,application/json"

        var response = client.post(url, headers, "")  # GET not available yet, use empty POST
        if response.status >= 400:
            raise Error(
                "HTTP " + String(response.status) + " fetching " + url
            )
        return response.body
