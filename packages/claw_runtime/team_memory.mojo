# runtime/team_memory.mojo — Team memory integration
#
# Shared context that persists across sessions and team members.
# Stores project-level knowledge, conventions, decisions, and
# learned patterns in .claw/team-memory/ as individual JSON files.
#
# Phase 5.6 of the Claw Code Mojo port.

from std.collections import List, Dict
from std.pathlib import Path


# ---------------------------------------------------------------------------
# MemoryEntry
# ---------------------------------------------------------------------------

@fieldwise_init
struct MemoryEntry(Copyable, Movable):
    """A single team memory entry."""
    var id: String               # Unique entry ID (e.g., "mem-001")
    var category: String         # "convention" | "decision" | "pattern" | "context" | "instruction"
    var title: String            # Short descriptive title
    var content: String          # Full memory content
    var tags: List[String]       # Searchable tags
    var created_by: String       # Author identifier
    var created_at: String       # Timestamp
    var updated_at: String       # Last update timestamp
    var priority: Int            # 0=low, 1=normal, 2=high, 3=critical
    var active: Bool             # Whether this memory is active


# ---------------------------------------------------------------------------
# TeamMemoryStore
# ---------------------------------------------------------------------------

@fieldwise_init
struct TeamMemoryStore(Copyable, Movable):
    """Manages team memory entries with persistence and search."""
    var entries: List[MemoryEntry]
    var store_dir: String        # Path to .claw/team-memory/
    var _next_id: Int


# ---------------------------------------------------------------------------
# TeamMemoryStore methods (free functions operating on the store)
# ---------------------------------------------------------------------------

def _store_load(mut store: TeamMemoryStore) raises:
    """Load all entries from store_dir."""
    var dir_path = Path(store.store_dir)
    if not dir_path.exists():
        return

    # Scan for .json files in the directory.
    # Since Mojo does not have os.listdir yet, we attempt to load
    # by known ID pattern: mem-1.json, mem-2.json, ...
    # In practice, the bridge or an OS call would provide listing.
    # For now we load by probing IDs up to _next_id + 1000 (belt & suspenders).
    var probe_limit = store._next_id + 1000
    for i in range(1, probe_limit):
        var filename = "mem-" + String(i) + ".json"
        var file_path = dir_path / filename
        if file_path.exists():
            var text = file_path.read_text()
            try:
                var entry = _deserialize_entry(text)
                store.entries.append(entry)
                # Track highest ID
                var num = _extract_id_number(entry.id)
                if num >= store._next_id:
                    store._next_id = num + 1
            except:
                pass  # Skip corrupt files


def _store_save(store: TeamMemoryStore) raises:
    """Persist all entries to store_dir as individual JSON files."""
    var dir_path = Path(store.store_dir)
    if not dir_path.exists():
        try:
            from std.os import mkdir
            mkdir(store.store_dir)
        except:
            pass

    for i in range(len(store.entries)):
        var entry = store.entries[i]
        var json = _serialize_entry(entry)
        var file_path = dir_path / (entry.id + ".json")
        file_path.write_text(json)


def _store_add(
    mut store: TeamMemoryStore,
    category: String,
    title: String,
    content: String,
    tags: List[String] = List[String](),
    created_by: String = "system",
    priority: Int = 1,
) -> String:
    """Add a new memory entry. Returns the entry ID."""
    var entry_id = _generate_id(store)
    var entry = MemoryEntry(
        id=entry_id,
        category=category,
        title=title,
        content=content,
        tags=tags,
        created_by=created_by,
        created_at="2026-04-04T00:00:00Z",
        updated_at="2026-04-04T00:00:00Z",
        priority=priority,
        active=True,
    )
    store.entries.append(entry)
    return entry_id


def _store_update(mut store: TeamMemoryStore, id: String, content: String) raises -> Bool:
    """Update the content of an existing entry. Returns True if found."""
    for i in range(len(store.entries)):
        if store.entries[i].id == id:
            store.entries[i].content = content
            store.entries[i].updated_at = "2026-04-04T00:00:00Z"
            return True
    return False


def _store_remove(mut store: TeamMemoryStore, id: String) -> Bool:
    """Remove an entry by ID. Returns True if found and removed."""
    for i in range(len(store.entries)):
        if store.entries[i].id == id:
            var last_idx = len(store.entries) - 1
            if i != last_idx:
                store.entries[i] = store.entries[last_idx]
            _ = store.entries.pop()
            return True
    return False


def _store_deactivate(mut store: TeamMemoryStore, id: String) -> Bool:
    """Soft-delete: mark an entry as inactive. Returns True if found."""
    for i in range(len(store.entries)):
        if store.entries[i].id == id:
            store.entries[i].active = False
            store.entries[i].updated_at = "2026-04-04T00:00:00Z"
            return True
    return False


def _store_activate(mut store: TeamMemoryStore, id: String) -> Bool:
    """Re-activate a deactivated entry. Returns True if found."""
    for i in range(len(store.entries)):
        if store.entries[i].id == id:
            store.entries[i].active = True
            store.entries[i].updated_at = "2026-04-04T00:00:00Z"
            return True
    return False


def _store_get(store: TeamMemoryStore, id: String) raises -> MemoryEntry:
    """Get a single entry by ID. Raises if not found."""
    for i in range(len(store.entries)):
        if store.entries[i].id == id:
            return store.entries[i]
    raise Error("Memory entry not found: " + id)


def _store_search(store: TeamMemoryStore, query: String) -> List[MemoryEntry]:
    """Case-insensitive substring search across title, content, and tags."""
    var results = List[MemoryEntry]()
    var q = _lower(query)
    for i in range(len(store.entries)):
        var entry = store.entries[i]
        if _lower(entry.title).find(q) >= 0:
            results.append(entry)
            continue
        if _lower(entry.content).find(q) >= 0:
            results.append(entry)
            continue
        # Check tags
        var tag_match = False
        for t in range(len(entry.tags)):
            if _lower(entry.tags[t]).find(q) >= 0:
                tag_match = True
                break
        if tag_match:
            results.append(entry)
    return results


def _store_search_by_category(store: TeamMemoryStore, category: String) -> List[MemoryEntry]:
    """Return all entries matching a category."""
    var results = List[MemoryEntry]()
    var cat = _lower(category)
    for i in range(len(store.entries)):
        if _lower(store.entries[i].category) == cat:
            results.append(store.entries[i])
    return results


def _store_search_by_tag(store: TeamMemoryStore, tag: String) -> List[MemoryEntry]:
    """Return all entries containing a specific tag (case-insensitive)."""
    var results = List[MemoryEntry]()
    var t = _lower(tag)
    for i in range(len(store.entries)):
        var entry = store.entries[i]
        for j in range(len(entry.tags)):
            if _lower(entry.tags[j]) == t:
                results.append(entry)
                break
    return results


def _store_active_entries(store: TeamMemoryStore) -> List[MemoryEntry]:
    """Return only active entries."""
    var results = List[MemoryEntry]()
    for i in range(len(store.entries)):
        if store.entries[i].active:
            results.append(store.entries[i])
    return results


def _store_count(store: TeamMemoryStore) -> Int:
    """Total number of entries (active and inactive)."""
    return len(store.entries)


def _store_active_count(store: TeamMemoryStore) -> Int:
    """Number of active entries only."""
    var count = 0
    for i in range(len(store.entries)):
        if store.entries[i].active:
            count += 1
    return count


def _store_as_context(store: TeamMemoryStore) -> String:
    """Format all active entries as system prompt context.

    Output format:
        ## Team Memory

        ### [Convention] Title
        Content here...
        Tags: tag1, tag2
    """
    var active = _store_active_entries(store)
    if len(active) == 0:
        return "## Team Memory\n\nNo active memories.\n"

    var out = String("## Team Memory\n\n")
    for i in range(len(active)):
        var entry = active[i]
        var cat_label = _capitalize(entry.category)
        out = out + "### [" + cat_label + "] " + entry.title + "\n"
        out = out + entry.content + "\n"
        if len(entry.tags) > 0:
            out = out + "Tags: "
            for t in range(len(entry.tags)):
                if t > 0:
                    out = out + ", "
                out = out + entry.tags[t]
            out = out + "\n"
        out = out + "\n"
    return out


def _store_as_markdown(store: TeamMemoryStore) -> String:
    """Full markdown export of all entries."""
    var out = String("# Team Memory Export\n\n")
    out = out + "Total entries: " + String(len(store.entries)) + "\n"
    out = out + "Active: " + String(_store_active_count(store)) + "\n\n"

    for i in range(len(store.entries)):
        var entry = store.entries[i]
        var status = "active" if entry.active else "inactive"
        out = out + "---\n\n"
        out = out + "## " + entry.id + ": " + entry.title + "\n\n"
        out = out + "- **Category:** " + entry.category + "\n"
        out = out + "- **Status:** " + status + "\n"
        out = out + "- **Priority:** " + String(entry.priority) + "\n"
        out = out + "- **Created by:** " + entry.created_by + "\n"
        out = out + "- **Created at:** " + entry.created_at + "\n"
        out = out + "- **Updated at:** " + entry.updated_at + "\n"
        if len(entry.tags) > 0:
            out = out + "- **Tags:** "
            for t in range(len(entry.tags)):
                if t > 0:
                    out = out + ", "
                out = out + entry.tags[t]
            out = out + "\n"
        out = out + "\n" + entry.content + "\n\n"
    return out


def _store_summary(store: TeamMemoryStore) -> String:
    """Quick summary string."""
    var total = len(store.entries)
    var active = _store_active_count(store)
    return (
        "TeamMemoryStore: "
        + String(total) + " entries ("
        + String(active) + " active), dir=" + store.store_dir
    )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _generate_id(mut store: TeamMemoryStore) -> String:
    """Generate the next sequential ID: 'mem-<counter>'."""
    var id_num = store._next_id
    store._next_id += 1
    return "mem-" + String(id_num)


def _extract_id_number(id: String) -> Int:
    """Extract the numeric part from 'mem-<N>'."""
    if id.find("mem-") == 0:
        var num_str = String(id[4:])
        try:
            return Int(num_str)
        except:
            return 0
    return 0


def _q(s: String) -> String:
    """JSON-escape and quote a string value."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def _serialize_entry(entry: MemoryEntry) -> String:
    """Serialize a MemoryEntry to a JSON string."""
    var json = String("{\n")
    json += '  "id": ' + _q(entry.id) + ",\n"
    json += '  "category": ' + _q(entry.category) + ",\n"
    json += '  "title": ' + _q(entry.title) + ",\n"
    json += '  "content": ' + _q(entry.content) + ",\n"
    json += '  "tags": ['
    for i in range(len(entry.tags)):
        if i > 0:
            json += ", "
        json += _q(entry.tags[i])
    json += "],\n"
    json += '  "created_by": ' + _q(entry.created_by) + ",\n"
    json += '  "created_at": ' + _q(entry.created_at) + ",\n"
    json += '  "updated_at": ' + _q(entry.updated_at) + ",\n"
    json += '  "priority": ' + String(entry.priority) + ",\n"
    json += '  "active": ' + ("true" if entry.active else "false") + "\n"
    json += "}"
    return json


def _deserialize_entry(json: String) raises -> MemoryEntry:
    """Deserialize a JSON string to a MemoryEntry.

    Uses a simple key-value parser similar to session_store patterns.
    """
    var id = _extract_json_string(json, "id")
    var category = _extract_json_string(json, "category")
    var title = _extract_json_string(json, "title")
    var content = _extract_json_string(json, "content")
    var created_by = _extract_json_string(json, "created_by")
    var created_at = _extract_json_string(json, "created_at")
    var updated_at = _extract_json_string(json, "updated_at")
    var priority = _extract_json_int(json, "priority")
    var active = _extract_json_bool(json, "active")
    var tags = _extract_json_string_array(json, "tags")

    return MemoryEntry(
        id=id,
        category=category,
        title=title,
        content=content,
        tags=tags,
        created_by=created_by,
        created_at=created_at,
        updated_at=updated_at,
        priority=priority,
        active=active,
    )


def _extract_json_string(json: String, key: String) -> String:
    """Extract a string value for the given key from a JSON string."""
    var search = '"' + key + '"'
    var pos = json.find(search)
    if pos < 0:
        return ""
    # Find the colon after the key
    var colon = json.find(":", pos + len(search))
    if colon < 0:
        return ""
    # Find the opening quote of the value
    var val_start = json.find('"', colon + 1)
    if val_start < 0:
        return ""
    # Find the closing quote (handle escaped quotes)
    var val_end = val_start + 1
    while val_end < len(json):
        if json[val_end] == "\\" and val_end + 1 < len(json):
            val_end += 2  # Skip escaped char
            continue
        if json[val_end] == '"':
            break
        val_end += 1
    var raw = String(json[val_start + 1 : val_end])
    # Unescape
    raw = raw.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
    return raw


def _extract_json_int(json: String, key: String) -> Int:
    """Extract an integer value for the given key from a JSON string."""
    var search = '"' + key + '"'
    var pos = json.find(search)
    if pos < 0:
        return 0
    var colon = json.find(":", pos + len(search))
    if colon < 0:
        return 0
    # Skip whitespace after colon
    var start = colon + 1
    while start < len(json) and (json[start] == " " or json[start] == "\n" or json[start] == "\t"):
        start += 1
    # Collect digits (and optional leading minus)
    var end = start
    if end < len(json) and json[end] == "-":
        end += 1
    while end < len(json) and json[end] >= "0" and json[end] <= "9":
        end += 1
    if end == start:
        return 0
    try:
        return Int(String(json[start:end]))
    except:
        return 0


def _extract_json_bool(json: String, key: String) -> Bool:
    """Extract a boolean value for the given key from a JSON string."""
    var search = '"' + key + '"'
    var pos = json.find(search)
    if pos < 0:
        return False
    var colon = json.find(":", pos + len(search))
    if colon < 0:
        return False
    # Look for 'true' or 'false' after colon
    var rest = String(json[colon + 1 :])
    var true_pos = rest.find("true")
    var false_pos = rest.find("false")
    if true_pos >= 0 and (false_pos < 0 or true_pos < false_pos):
        return True
    return False


def _extract_json_string_array(json: String, key: String) -> List[String]:
    """Extract a string array value for the given key from a JSON string."""
    var result = List[String]()
    var search = '"' + key + '"'
    var pos = json.find(search)
    if pos < 0:
        return result
    var bracket_start = json.find("[", pos + len(search))
    if bracket_start < 0:
        return result
    var bracket_end = json.find("]", bracket_start)
    if bracket_end < 0:
        return result
    var inner = String(json[bracket_start + 1 : bracket_end])
    # Parse quoted strings from inner
    var cursor = 0
    while cursor < len(inner):
        var q_start = inner.find('"', cursor)
        if q_start < 0:
            break
        var q_end = q_start + 1
        while q_end < len(inner):
            if inner[q_end] == "\\" and q_end + 1 < len(inner):
                q_end += 2
                continue
            if inner[q_end] == '"':
                break
            q_end += 1
        var val = String(inner[q_start + 1 : q_end])
        val = val.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
        result.append(val)
        cursor = q_end + 1
    return result


def _lower(s: String) -> String:
    """Simple lowercase conversion for ASCII letters."""
    var result = String("")
    for i in range(len(s)):
        var c = s[i]
        if c >= "A" and c <= "Z":
            # Shift to lowercase via ordinal math
            var o = ord(c) + 32
            result += chr(o)
        else:
            result += c
    return result


def _capitalize(s: String) -> String:
    """Capitalize the first letter of a string."""
    if len(s) == 0:
        return s
    var first = s[0]
    if first >= "a" and first <= "z":
        var upper = chr(ord(first) - 32)
        return upper + String(s[1:])
    return s


# ---------------------------------------------------------------------------
# Free functions
# ---------------------------------------------------------------------------

def new_team_memory(store_dir: String = ".claw/team-memory") -> TeamMemoryStore:
    """Create a new empty TeamMemoryStore."""
    return TeamMemoryStore(
        entries=List[MemoryEntry](),
        store_dir=store_dir,
        _next_id=1,
    )


def format_memory_list(entries: List[MemoryEntry]) -> String:
    """Format a list of entries as a concise table."""
    var header = "ID          | Category    | Title                          | Active\n"
    var sep = "------------+-------------+--------------------------------+--------\n"
    var body = String("")
    for i in range(len(entries)):
        var e = entries[i]
        var id_col = e.id
        while len(id_col) < 12:
            id_col = id_col + " "
        var cat_col = e.category
        while len(cat_col) < 12:
            cat_col = cat_col + " "
        var title_col = e.title
        if len(title_col) > 30:
            title_col = String(title_col[:27]) + "..."
        while len(title_col) < 32:
            title_col = title_col + " "
        var active_str = "yes" if e.active else "no"
        body = body + id_col + "| " + cat_col + "| " + title_col + "| " + active_str + "\n"
    return header + sep + body


def format_memory_detail(entry: MemoryEntry) -> String:
    """Format a single entry as a detailed view."""
    var status = "active" if entry.active else "inactive"
    var out = String("=== Memory Entry ===\n")
    out = out + "ID:         " + entry.id + "\n"
    out = out + "Category:   " + entry.category + "\n"
    out = out + "Title:      " + entry.title + "\n"
    out = out + "Priority:   " + String(entry.priority) + "\n"
    out = out + "Status:     " + status + "\n"
    out = out + "Created by: " + entry.created_by + "\n"
    out = out + "Created at: " + entry.created_at + "\n"
    out = out + "Updated at: " + entry.updated_at + "\n"
    if len(entry.tags) > 0:
        out = out + "Tags:       "
        for t in range(len(entry.tags)):
            if t > 0:
                out = out + ", "
            out = out + entry.tags[t]
        out = out + "\n"
    out = out + "\n" + entry.content + "\n"
    out = out + "====================\n"
    return out


def memory_categories() -> List[String]:
    """Return the list of valid memory categories."""
    var cats = List[String]()
    cats.append("convention")
    cats.append("decision")
    cats.append("pattern")
    cats.append("context")
    cats.append("instruction")
    return cats


def format_memory_context(entries: List[MemoryEntry]) -> String:
    """Format entries for system prompt injection (active entries only)."""
    var active = List[MemoryEntry]()
    for i in range(len(entries)):
        if entries[i].active:
            active.append(entries[i])

    if len(active) == 0:
        return ""

    var out = String("## Team Memory\n\n")
    for i in range(len(active)):
        var entry = active[i]
        var cat_label = _capitalize(entry.category)
        out = out + "### [" + cat_label + "] " + entry.title + "\n"
        out = out + entry.content + "\n"
        if len(entry.tags) > 0:
            out = out + "Tags: "
            for t in range(len(entry.tags)):
                if t > 0:
                    out = out + ", "
                out = out + entry.tags[t]
            out = out + "\n"
        out = out + "\n"
    return out
