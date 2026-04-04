# bridge/json_compat.mojo — JSON operations via Python json module
#
# Fallback JSON parsing when EmberJson is unavailable.
# Provides dict-like access to parsed JSON data.
#
# Python dependency: (stdlib) json

from python import Python
from std.collections import Dict, List


def parse_json(text: String) raises -> PythonObject:
    """Parse a JSON string into a Python dict/list."""
    var json_mod = Python.import_module("json")
    return json_mod.loads(str(text))


def to_json(obj: PythonObject) raises -> String:
    """Serialize a Python object to JSON string."""
    var json_mod = Python.import_module("json")
    return String(str(json_mod.dumps(obj)))


def get_string(obj: PythonObject, key: String) raises -> String:
    """Extract a string value from a Python dict by key."""
    var value = obj[str(key)]
    return String(str(value))


def get_int(obj: PythonObject, key: String) raises -> Int:
    """Extract an integer value from a Python dict by key."""
    var value = obj[str(key)]
    return Int(value)


def get_list(obj: PythonObject, key: String) raises -> PythonObject:
    """Extract a list value from a Python dict by key."""
    return obj[str(key)]


def has_key(obj: PythonObject, key: String) raises -> Bool:
    """Check if a Python dict contains a key."""
    return Bool(str(key) in obj)
