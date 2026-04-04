# tests/test_team_memory.mojo — Tests for team memory integration

from std.testing import assert_equal, assert_true
from std.collections import List

from claw_runtime.team_memory import (
    MemoryEntry,
    TeamMemoryStore,
    new_team_memory,
    format_memory_list,
    format_memory_detail,
    memory_categories,
    format_memory_context,
    _store_add,
    _store_get,
    _store_remove,
    _store_deactivate,
    _store_activate,
    _store_update,
    _store_search,
    _store_search_by_category,
    _store_search_by_tag,
    _store_active_entries,
    _store_count,
    _store_active_count,
    _store_as_context,
    _store_as_markdown,
    _store_summary,
    _serialize_entry,
    _deserialize_entry,
)


def test_memory_store_creation():
    """Create store, verify count is 0."""
    var store = new_team_memory("/tmp/test-team-memory")
    assert_equal(_store_count(store), 0)
    assert_equal(store.store_dir, "/tmp/test-team-memory")
    assert_equal(store._next_id, 1)


def test_add_entry():
    """Add an entry, verify count is 1, verify returned ID."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id = _store_add(store, "convention", "Use def for all functions", "Always use def, never fn.")
    assert_equal(_store_count(store), 1)
    assert_equal(id, "mem-1")


def test_add_multiple():
    """Add 3 entries, verify count is 3, verify unique IDs."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id1 = _store_add(store, "convention", "Title 1", "Content 1")
    var id2 = _store_add(store, "decision", "Title 2", "Content 2")
    var id3 = _store_add(store, "pattern", "Title 3", "Content 3")
    assert_equal(_store_count(store), 3)
    assert_equal(id1, "mem-1")
    assert_equal(id2, "mem-2")
    assert_equal(id3, "mem-3")
    # All unique
    assert_true(id1 != id2)
    assert_true(id2 != id3)
    assert_true(id1 != id3)


def test_get_entry():
    """Add entry, get by ID, verify title and content match."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id = _store_add(store, "convention", "Mojo naming", "Use snake_case for functions.")
    var entry = _store_get(store, id)
    assert_equal(entry.title, "Mojo naming")
    assert_equal(entry.content, "Use snake_case for functions.")
    assert_equal(entry.category, "convention")
    assert_true(entry.active)


def test_get_nonexistent():
    """Try to get nonexistent ID, verify raises."""
    var store = new_team_memory("/tmp/test-team-memory")
    var raised = False
    try:
        var _entry = _store_get(store, "mem-999")
    except:
        raised = True
    assert_true(raised)


def test_remove_entry():
    """Add entry, remove it, verify count is 0."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id = _store_add(store, "decision", "Use Mojo", "We decided to use Mojo.")
    assert_equal(_store_count(store), 1)
    var removed = _store_remove(store, id)
    assert_true(removed)
    assert_equal(_store_count(store), 0)


def test_deactivate_activate():
    """Add entry, deactivate, verify active_count decreases. Activate, verify increases."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id = _store_add(store, "pattern", "Singleton", "Use singleton pattern.")
    assert_equal(_store_active_count(store), 1)

    var deactivated = _store_deactivate(store, id)
    assert_true(deactivated)
    assert_equal(_store_active_count(store), 0)
    assert_equal(_store_count(store), 1)  # Still exists

    var activated = _store_activate(store, id)
    assert_true(activated)
    assert_equal(_store_active_count(store), 1)


def test_search_by_title():
    """Add entries with different titles, search, verify matches."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Use def for functions", "Always use def.")
    _ = _store_add(store, "decision", "Database choice", "We chose PostgreSQL.")
    _ = _store_add(store, "pattern", "Error handling pattern", "Use raises keyword.")

    var results = _store_search(store, "def")
    assert_equal(len(results), 1)
    assert_equal(results[0].title, "Use def for functions")


def test_search_by_content():
    """Add entries, search by content substring, verify matches."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Naming", "Use snake_case for variables.")
    _ = _store_add(store, "convention", "Types", "Use String(x) for conversion.")
    _ = _store_add(store, "decision", "DB", "We chose PostgreSQL for persistence.")

    var results = _store_search(store, "postgresql")
    assert_equal(len(results), 1)
    assert_equal(results[0].title, "DB")


def test_search_by_category():
    """Add entries in different categories, filter, verify correct subset."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Conv 1", "Content 1")
    _ = _store_add(store, "convention", "Conv 2", "Content 2")
    _ = _store_add(store, "decision", "Dec 1", "Content 3")
    _ = _store_add(store, "pattern", "Pat 1", "Content 4")

    var conventions = _store_search_by_category(store, "convention")
    assert_equal(len(conventions), 2)

    var decisions = _store_search_by_category(store, "decision")
    assert_equal(len(decisions), 1)
    assert_equal(decisions[0].title, "Dec 1")

    var patterns = _store_search_by_category(store, "pattern")
    assert_equal(len(patterns), 1)


def test_search_by_tag():
    """Add entries with tags, search by tag, verify matches."""
    var store = new_team_memory("/tmp/test-team-memory")
    var tags1 = List[String]()
    tags1.append("mojo")
    tags1.append("syntax")
    _ = _store_add(store, "convention", "Tagged entry", "Content here", tags1)

    var tags2 = List[String]()
    tags2.append("database")
    _ = _store_add(store, "decision", "DB choice", "PostgreSQL", tags2)

    var results = _store_search_by_tag(store, "mojo")
    assert_equal(len(results), 1)
    assert_equal(results[0].title, "Tagged entry")

    var db_results = _store_search_by_tag(store, "database")
    assert_equal(len(db_results), 1)

    var no_results = _store_search_by_tag(store, "nonexistent")
    assert_equal(len(no_results), 0)


def test_active_entries():
    """Add 3, deactivate 1, verify active_entries returns 2."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id1 = _store_add(store, "convention", "Entry 1", "Content 1")
    _ = _store_add(store, "decision", "Entry 2", "Content 2")
    _ = _store_add(store, "pattern", "Entry 3", "Content 3")

    _ = _store_deactivate(store, id1)

    var active = _store_active_entries(store)
    assert_equal(len(active), 2)
    assert_equal(_store_active_count(store), 2)


def test_as_context():
    """Add entries, generate context, verify contains '## Team Memory'."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Use def", "Always use def not fn.")
    _ = _store_add(store, "decision", "Framework choice", "Chose Mojo for performance.")

    var ctx = _store_as_context(store)
    assert_true(ctx.find("## Team Memory") >= 0)
    assert_true(ctx.find("[Convention]") >= 0)
    assert_true(ctx.find("[Decision]") >= 0)
    assert_true(ctx.find("Use def") >= 0)
    assert_true(ctx.find("Framework choice") >= 0)


def test_as_markdown():
    """Add entries, generate markdown, verify structure."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Naming rules", "Use snake_case.")
    _ = _store_add(store, "pattern", "Error pattern", "Use raises keyword.")

    var md = _store_as_markdown(store)
    assert_true(md.find("# Team Memory Export") >= 0)
    assert_true(md.find("Total entries: 2") >= 0)
    assert_true(md.find("Naming rules") >= 0)
    assert_true(md.find("Error pattern") >= 0)
    assert_true(md.find("**Category:**") >= 0)
    assert_true(md.find("**Status:**") >= 0)


def test_summary():
    """Add entries, verify summary contains count."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "Entry 1", "Content 1")
    _ = _store_add(store, "decision", "Entry 2", "Content 2")

    var s = _store_summary(store)
    assert_true(s.find("2 entries") >= 0)
    assert_true(s.find("2 active") >= 0)
    assert_true(s.find("TeamMemoryStore") >= 0)


def test_format_memory_list():
    """Format list, verify output contains entry titles."""
    var store = new_team_memory("/tmp/test-team-memory")
    _ = _store_add(store, "convention", "First entry", "Content 1")
    _ = _store_add(store, "decision", "Second entry", "Content 2")

    var table = format_memory_list(store.entries)
    assert_true(table.find("ID") >= 0)
    assert_true(table.find("Category") >= 0)
    assert_true(table.find("Title") >= 0)
    assert_true(table.find("First entry") >= 0)
    assert_true(table.find("Second entry") >= 0)
    assert_true(table.find("convention") >= 0)
    assert_true(table.find("decision") >= 0)


def test_format_memory_detail():
    """Format single entry, verify all fields present."""
    var store = new_team_memory("/tmp/test-team-memory")
    var tags = List[String]()
    tags.append("mojo")
    tags.append("best-practice")
    var id = _store_add(store, "convention", "Test detail", "Detailed content here.", tags, "alice", 2)
    var entry = _store_get(store, id)

    var detail = format_memory_detail(entry)
    assert_true(detail.find("=== Memory Entry ===") >= 0)
    assert_true(detail.find("mem-1") >= 0)
    assert_true(detail.find("convention") >= 0)
    assert_true(detail.find("Test detail") >= 0)
    assert_true(detail.find("Detailed content here.") >= 0)
    assert_true(detail.find("alice") >= 0)
    assert_true(detail.find("mojo") >= 0)
    assert_true(detail.find("best-practice") >= 0)
    assert_true(detail.find("2") >= 0)  # priority


def test_memory_categories():
    """Verify categories list contains 'convention', 'decision', 'pattern'."""
    var cats = memory_categories()
    assert_equal(len(cats), 5)

    var found_convention = False
    var found_decision = False
    var found_pattern = False
    var found_context = False
    var found_instruction = False
    for i in range(len(cats)):
        if cats[i] == "convention":
            found_convention = True
        if cats[i] == "decision":
            found_decision = True
        if cats[i] == "pattern":
            found_pattern = True
        if cats[i] == "context":
            found_context = True
        if cats[i] == "instruction":
            found_instruction = True
    assert_true(found_convention)
    assert_true(found_decision)
    assert_true(found_pattern)
    assert_true(found_context)
    assert_true(found_instruction)


def test_update_entry():
    """Add entry, update content, get again, verify new content."""
    var store = new_team_memory("/tmp/test-team-memory")
    var id = _store_add(store, "convention", "Updatable", "Original content.")
    var entry_before = _store_get(store, id)
    assert_equal(entry_before.content, "Original content.")

    var updated = _store_update(store, id, "Updated content.")
    assert_true(updated)

    var entry_after = _store_get(store, id)
    assert_equal(entry_after.content, "Updated content.")
    assert_equal(entry_after.title, "Updatable")  # Title unchanged


def test_serialize_deserialize():
    """Add entry, serialize, deserialize, verify round-trip."""
    var tags = List[String]()
    tags.append("mojo")
    tags.append("testing")
    var entry = MemoryEntry(
        id="mem-42",
        category="pattern",
        title="Round-trip test",
        content="This content should survive serialization.",
        tags=tags,
        created_by="tester",
        created_at="2026-04-04T12:00:00Z",
        updated_at="2026-04-04T12:30:00Z",
        priority=2,
        active=True,
    )

    var json = _serialize_entry(entry)
    assert_true(json.find('"mem-42"') >= 0)
    assert_true(json.find('"pattern"') >= 0)
    assert_true(json.find('"Round-trip test"') >= 0)

    var restored = _deserialize_entry(json)
    assert_equal(restored.id, "mem-42")
    assert_equal(restored.category, "pattern")
    assert_equal(restored.title, "Round-trip test")
    assert_equal(restored.content, "This content should survive serialization.")
    assert_equal(restored.created_by, "tester")
    assert_equal(restored.created_at, "2026-04-04T12:00:00Z")
    assert_equal(restored.updated_at, "2026-04-04T12:30:00Z")
    assert_equal(restored.priority, 2)
    assert_true(restored.active)
    assert_equal(len(restored.tags), 2)
    assert_equal(restored.tags[0], "mojo")
    assert_equal(restored.tags[1], "testing")
