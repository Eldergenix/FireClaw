# bridge/regex.mojo — Regex operations via Python re module
#
# Mojo stdlib has no regex support. This bridges Python's re module.
#
# Python dependency: (stdlib) re

from python import Python
from std.collections import List


def regex_match(pattern: String, text: String) raises -> Bool:
    """Check if text matches a regex pattern."""
    var re = Python.import_module("re")
    var result = re.search(str(pattern), str(text))
    return result is not None


def regex_find_all(pattern: String, text: String) raises -> List[String]:
    """Find all matches of pattern in text."""
    var re = Python.import_module("re")
    var matches = re.findall(str(pattern), str(text))
    var result = List[String]()
    for i in range(len(matches)):
        result.append(String(str(matches[i])))
    return result


def regex_replace(pattern: String, replacement: String, text: String) raises -> String:
    """Replace all matches of pattern with replacement in text."""
    var re = Python.import_module("re")
    var result = re.sub(str(pattern), str(replacement), str(text))
    return String(str(result))
