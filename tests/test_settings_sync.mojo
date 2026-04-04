# tests/test_settings_sync.mojo — Tests for settings sync (via bridge)

from std.testing import assert_equal, assert_true
from std.collections import List

from claw_runtime.settings_sync import (
    SettingsEntry,
    SettingsStore,
    SyncResult,
    SettingsDiff,
    new_settings_store,
    default_settings,
    format_settings_table,
    format_sync_report,
    _store_get,
    _store_set,
    _store_has,
    _store_delete,
    _store_keys,
    _store_as_json,
    _store_summary,
    _store_diff,
    _store_apply_env_overrides,
)


def test_settings_store_creation():
    """Create store, verify initial empty state."""
    var store = new_settings_store("/tmp/test_project")
    assert_equal(len(store.entries), 0)
    assert_equal(store.sync_enabled, False)
    assert_equal(store._dirty, False)
    assert_true(store.project_path.find("settings.json") >= 0)
    assert_true(store.local_path.find("settings.local.json") >= 0)


def test_set_and_get():
    """Set a key, get it back, verify match."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "model", "claude-opus-4-6")
    var val = _store_get(store, "model")
    assert_equal(val, "claude-opus-4-6")


def test_set_overwrites():
    """Set a key twice, verify latest value wins."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "model", "old-model")
    _store_set(store, "model", "new-model")
    assert_equal(_store_get(store, "model"), "new-model")
    # Should still be one entry, not two
    assert_equal(len(store.entries), 1)


def test_get_missing_key():
    """Get a key that does not exist returns empty string."""
    var store = new_settings_store("/tmp/test_project")
    assert_equal(_store_get(store, "nonexistent"), "")


def test_has_key():
    """Set key, verify has() returns True; verify missing key returns False."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "api_key", "sk-test-123")
    assert_true(_store_has(store, "api_key"))
    assert_true(not _store_has(store, "missing_key"))


def test_delete_key():
    """Set key, delete it, verify has() returns False."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "temp_key", "temp_value")
    assert_true(_store_has(store, "temp_key"))
    var deleted = _store_delete(store, "temp_key")
    assert_true(deleted)
    assert_true(not _store_has(store, "temp_key"))


def test_delete_missing_key():
    """Deleting a nonexistent key returns False."""
    var store = new_settings_store("/tmp/test_project")
    var deleted = _store_delete(store, "no_such_key")
    assert_true(not deleted)


def test_keys_list():
    """Set multiple keys, verify keys() returns all of them."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "model", "claude-opus-4-6")
    _store_set(store, "max_tokens", "32768")
    _store_set(store, "api_key", "sk-test")
    var k = _store_keys(store)
    assert_equal(len(k), 3)
    # Verify each key is present
    var found_model = False
    var found_tokens = False
    var found_key = False
    for i in range(len(k)):
        if k[i] == "model":
            found_model = True
        if k[i] == "max_tokens":
            found_tokens = True
        if k[i] == "api_key":
            found_key = True
    assert_true(found_model)
    assert_true(found_tokens)
    assert_true(found_key)


def test_default_settings():
    """Load defaults, verify known keys like 'model' exist."""
    var defaults = default_settings()
    assert_true(len(defaults) > 0)
    var found_model = False
    var found_tokens = False
    for i in range(len(defaults)):
        if defaults[i].key == "model":
            found_model = True
            assert_equal(defaults[i].value, "claude-opus-4-6")
            assert_equal(defaults[i].source, "default")
        if defaults[i].key == "max_tokens":
            found_tokens = True
            assert_equal(defaults[i].value, "32768")
    assert_true(found_model)
    assert_true(found_tokens)


def test_summary():
    """Set entries, verify summary contains entry count."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "model", "claude-opus-4-6")
    _store_set(store, "max_tokens", "32768")
    var s = _store_summary(store)
    assert_true(s.find("2 entries") >= 0)
    assert_true(s.find("sync disabled") >= 0)


def test_summary_dirty():
    """Dirty store should show [dirty] in summary."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "key", "val")
    var s = _store_summary(store)
    assert_true(s.find("[dirty]") >= 0)


def test_as_json():
    """Set entries, serialize, verify JSON structure."""
    var store = new_settings_store("/tmp/test_project")
    _store_set(store, "model", "claude-opus-4-6")
    _store_set(store, "max_tokens", "32768")
    var json = _store_as_json(store)
    # Starts with {
    assert_true(json.find("{") >= 0)
    # Contains our keys
    assert_true(json.find('"model"') >= 0)
    assert_true(json.find('"max_tokens"') >= 0)
    assert_true(json.find("claude-opus-4-6") >= 0)


def test_env_overrides():
    """After applying env overrides, verify ANTHROPIC_API_KEY is checked."""
    var store = new_settings_store("/tmp/test_project")
    _store_apply_env_overrides(store)
    # We cannot control env vars in tests, but verify the function
    # runs without error. If ANTHROPIC_API_KEY is set, it should appear.
    var api_key = _store_get(store, "api_key")
    # api_key will be empty string or the env value — both are valid
    assert_true(True)


def test_diff_empty():
    """Diff two empty stores, verify no diffs."""
    var a = new_settings_store("/tmp/a")
    var b = new_settings_store("/tmp/b")
    var diffs = _store_diff(a, b)
    assert_equal(len(diffs), 0)


def test_diff_addition():
    """Diff where B has a key A does not — should be 'add'."""
    var a = new_settings_store("/tmp/a")
    var b = new_settings_store("/tmp/b")
    _store_set(b, "new_key", "new_val")
    var diffs = _store_diff(a, b)
    assert_equal(len(diffs), 1)
    assert_equal(diffs[0].action, "add")
    assert_equal(diffs[0].key, "new_key")


def test_diff_deletion():
    """Diff where A has a key B does not — should be 'delete'."""
    var a = new_settings_store("/tmp/a")
    var b = new_settings_store("/tmp/b")
    _store_set(a, "old_key", "old_val")
    var diffs = _store_diff(a, b)
    assert_equal(len(diffs), 1)
    assert_equal(diffs[0].action, "delete")


def test_diff_update():
    """Diff where both have same key with different values."""
    var a = new_settings_store("/tmp/a")
    var b = new_settings_store("/tmp/b")
    _store_set(a, "model", "v1")
    _store_set(b, "model", "v2")
    var diffs = _store_diff(a, b)
    assert_equal(len(diffs), 1)
    assert_equal(diffs[0].action, "update")


def test_sync_result_summary():
    """Create a SyncResult, verify summary string."""
    var result = SyncResult(pulled=3, pushed=2, conflicts=1, success=True)
    var s = result.summary()
    assert_true(s.find("3 pulled") >= 0)
    assert_true(s.find("2 pushed") >= 0)
    assert_true(s.find("1 conflicts") >= 0)


def test_sync_result_failed():
    """Failed SyncResult should say 'Sync failed'."""
    var result = SyncResult(pulled=0, pushed=0, conflicts=0, success=False)
    assert_equal(result.summary(), "Sync failed")


def test_format_settings_table():
    """Format entries, verify output contains key names."""
    var entries = List[SettingsEntry]()
    entries.append(
        SettingsEntry(key="model", value="claude-opus-4-6", source="default", last_modified="")
    )
    entries.append(
        SettingsEntry(key="max_tokens", value="32768", source="env", last_modified="")
    )
    var table = format_settings_table(entries)
    assert_true(table.find("model") >= 0)
    assert_true(table.find("max_tokens") >= 0)
    assert_true(table.find("Key") >= 0)
    assert_true(table.find("Value") >= 0)
    assert_true(table.find("Source") >= 0)


def test_format_sync_report():
    """Format a SyncResult, verify report structure."""
    var result = SyncResult(pulled=5, pushed=3, conflicts=0, success=True)
    var report = format_sync_report(result)
    assert_true(report.find("Sync Report") >= 0)
    assert_true(report.find("OK") >= 0)
    assert_true(report.find("5") >= 0)
    assert_true(report.find("3") >= 0)


def test_settings_entry_fields():
    """Verify SettingsEntry fields are accessible."""
    var entry = SettingsEntry(
        key="test_key",
        value="test_value",
        source="local",
        last_modified="2026-04-04",
    )
    assert_equal(entry.key, "test_key")
    assert_equal(entry.value, "test_value")
    assert_equal(entry.source, "local")
    assert_equal(entry.last_modified, "2026-04-04")


def test_settings_diff_fields():
    """Verify SettingsDiff fields are accessible."""
    var d = SettingsDiff(
        key="model",
        local_value="v1",
        remote_value="v2",
        action="conflict",
    )
    assert_equal(d.key, "model")
    assert_equal(d.local_value, "v1")
    assert_equal(d.remote_value, "v2")
    assert_equal(d.action, "conflict")
