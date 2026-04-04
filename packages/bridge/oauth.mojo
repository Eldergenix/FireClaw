# bridge/oauth.mojo — OAuth PKCE flow via Python
#
# Delegates to Python's httpx + secrets for the OAuth code exchange.
# Token storage uses native Mojo file I/O.
#
# Python dependencies: httpx >= 0.27

from python import Python
from std.pathlib import Path


@fieldwise_init
struct OAuthToken(Copyable, Movable):
    """An OAuth access token with metadata."""
    var access_token: String
    var refresh_token: String
    var expires_at: String
    var token_type: String


def oauth_pkce_exchange(
    token_url: String,
    client_id: String,
    code: String,
    code_verifier: String,
    redirect_uri: String,
) raises -> OAuthToken:
    """Exchange an authorization code for tokens using PKCE.

    Args:
        token_url: The OAuth token endpoint URL.
        client_id: The OAuth client ID.
        code: The authorization code.
        code_verifier: The PKCE code verifier.
        redirect_uri: The redirect URI used in the auth request.

    Returns:
        OAuthToken with access and refresh tokens.
    """
    var httpx = Python.import_module("httpx")
    var json_mod = Python.import_module("json")

    var data = Python.dict()
    data["grant_type"] = "authorization_code"
    data["client_id"] = str(client_id)
    data["code"] = str(code)
    data["code_verifier"] = str(code_verifier)
    data["redirect_uri"] = str(redirect_uri)

    var response = httpx.post(str(token_url), data=data)
    var body = json_mod.loads(response.text)

    return OAuthToken(
        access_token=String(str(body["access_token"])),
        refresh_token=String(str(body.get("refresh_token", ""))),
        expires_at=String(str(body.get("expires_at", ""))),
        token_type=String(str(body.get("token_type", "bearer"))),
    )


def generate_pkce_pair() raises -> Tuple[String, String]:
    """Generate a PKCE code verifier and challenge pair.

    Returns:
        Tuple of (code_verifier, code_challenge).
    """
    var secrets = Python.import_module("secrets")
    var hashlib = Python.import_module("hashlib")
    var base64_mod = Python.import_module("base64")

    var verifier = String(str(secrets.token_urlsafe(32)))
    var digest = hashlib.sha256(verifier.encode()).digest()
    var challenge = String(
        str(base64_mod.urlsafe_b64encode(digest).rstrip(b"=").decode())
    )

    return (verifier, challenge)


def save_token(token: OAuthToken, path: String) raises:
    """Save an OAuth token to disk."""
    var json = '{"access_token":"' + token.access_token + '"'
    json += ',"refresh_token":"' + token.refresh_token + '"'
    json += ',"expires_at":"' + token.expires_at + '"'
    json += ',"token_type":"' + token.token_type + '"}'
    Path(path).write_text(json)
