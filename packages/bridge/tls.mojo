# bridge/tls.mojo — TLS context management via Python ssl
#
# Provides TLS certificate and context utilities for secure connections.
#
# Python dependency: (stdlib) ssl

from python import Python


def create_default_ssl_context() raises -> PythonObject:
    """Create a default SSL context with system CA certificates."""
    var ssl = Python.import_module("ssl")
    return ssl.create_default_context()


def create_unverified_context() raises -> PythonObject:
    """Create an SSL context that does not verify certificates.

    WARNING: Only use for development/testing.
    """
    var ssl = Python.import_module("ssl")
    var ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx
