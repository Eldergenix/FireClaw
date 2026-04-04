# bridge/async_io.mojo — Async I/O patterns via Python asyncio
#
# Mojo's async runtime is deferred to Phase 2 of language development.
# This module wraps Python's asyncio for streaming and concurrent I/O.
#
# Python dependency: (stdlib) asyncio

from python import Python


def run_async(coro: PythonObject) raises -> PythonObject:
    """Run a Python coroutine synchronously.

    This is the bridge between Mojo's synchronous execution model
    and Python's async libraries (httpx, websockets, etc.).
    """
    var asyncio = Python.import_module("asyncio")
    return asyncio.run(coro)


def create_event_loop() raises -> PythonObject:
    """Create a new Python asyncio event loop."""
    var asyncio = Python.import_module("asyncio")
    return asyncio.new_event_loop()


def gather(loop: PythonObject, coros: PythonObject) raises -> PythonObject:
    """Run multiple coroutines concurrently."""
    var asyncio = Python.import_module("asyncio")
    return loop.run_until_complete(asyncio.gather(*coros))
