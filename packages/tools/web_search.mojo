# tools/web_search.mojo — Web search tool via bridge
#
# Searches the web using Brave Search API (or fallback).
# Requires BRAVE_API_KEY environment variable.

from std.os import getenv
from std.collections import Dict


struct WebSearchTool:
    """Search the web and return results."""

    def execute(self, query: String, max_results: Int = 5) raises -> String:
        """Search the web for a query.

        Args:
            query: Search query string.
            max_results: Maximum number of results.

        Returns:
            Formatted search results.
        """
        var api_key = getenv("BRAVE_API_KEY", "")
        if api_key == "":
            raise Error(
                "BRAVE_API_KEY not set. Configure via: "
                "openclaw configure --section web"
            )

        from bridge.http import HttpClient

        var client = HttpClient()
        var headers = Dict[String, String]()
        headers["Accept"] = "application/json"
        headers["X-Subscription-Token"] = api_key

        var url = (
            "https://api.search.brave.com/res/v1/web/search?q="
            + _url_encode(query)
            + "&count="
            + String(max_results)
        )

        var response = client.post(url, headers, "")
        if response.status >= 400:
            raise Error("Search API error: HTTP " + String(response.status))

        return response.body


def _url_encode(s: String) -> String:
    """Basic URL encoding for search queries."""
    var result = String("")
    for i in range(len(s)):
        var c = s[i]
        if c == " ":
            result += "+"
        elif c == "&":
            result += "%26"
        elif c == "=":
            result += "%3D"
        elif c == "?":
            result += "%3F"
        else:
            result += c
    return result
