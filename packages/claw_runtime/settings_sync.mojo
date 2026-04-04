# runtime/settings_sync.mojo — Settings sync (via bridge)
#
# Synchronizes local settings with a remote settings service.
# Local settings live in .claw/settings.json and .claw/settings.local.json.
# The sync layer detects changes, merges remote updates, and persists back.

from std.collections import List, Dict
from std.pathlib import Path
from std.os import getenv


# ---------------------------------------------------------------------------
# SettingsEntry
# ---------------------------------------------------------------------------

@fieldwise_init
struct SettingsEntry(Copyable, Movable):
    """A single settings key-value pair with provenance."""
    var key: String
    var value: String
    var source: String          # "local" | "remote" | "default" | "env"
    var last_modified: String   # ISO-ish timestamp or empty


# ---------------------------------------------------------------------------
# SyncResult
# ---------------------------------------------------------------------------

@fieldwise_init
struct SyncResult(Copyable, Movable):
    """Outcome of a sync operation."""
    var pulled: Int       # entries pulled from remote
    var pushed: Int       # entries pushed to remote
    var conflicts: Int    # entries with conflicts
    var success: Bool

    def summary(self) -> String:
        """Human-readable summary of the sync result."""
        if not self.success:
            return "Sync failed"
        return (
            "Sync complete: "
            + String(self.pulled) + " pulled, "
            + String(self.pushed) + " pushed, "
            + String(self.conflicts) + " conflicts"
        )


# ---------------------------------------------------------------------------
# SettingsDiff
# ---------------------------------------------------------------------------

@fieldwise_init
struct SettingsDiff(Copyable, Movable):
    """Difference between two settings stores for a single key."""
    var key: String
    var local_value: String
    var remote_value: String
    var action: String    # "add" | "update" | "delete" | "conflict"


# ---------------------------------------------------------------------------
# SettingsStore
# ---------------------------------------------------------------------------

@fieldwise_init
struct SettingsStore(Copyable, Movable):
    """Manages settings across multiple layers with sync support."""
    var entries: List[SettingsEntry]
    var project_path: String       # Path to .claw/settings.json
    var local_path: String         # Path to .claw/settings.local.json
    var remote_endpoint: String    # URL for remote sync
    var sync_enabled: Bool
    var _dirty: Bool


def _make_settings_store(project_root: String) -> SettingsStore:
    """Internal helper to build paths and create a store."""
    var root = project_root
    if root == "":
        root = "."
    var claw_dir = root + "/.claw"
    return SettingsStore(
        entries=List[SettingsEntry](),
        project_path=claw_dir + "/settings.json",
        local_path=claw_dir + "/settings.local.json",
        remote_endpoint="",
        sync_enabled=False,
        _dirty=False,
    )


# --- SettingsStore methods (free functions operating on SettingsStore) ------
# Mojo struct methods below.

def _store_load(mut store: SettingsStore) raises:
    """Load settings from all layers: defaults, project, local, env."""
    # 1. Apply built-in defaults
    var defaults = default_settings()
    for i in range(len(defaults)):
        _store_merge_entry(
            store, defaults[i].key, defaults[i].value, defaults[i].source
        )

    # 2. Load project-level settings.json
    var proj = Path(store.project_path)
    if proj.exists():
        _store_load_json_file(store, store.project_path, "local")

    # 3. Load local overrides
    var loc = Path(store.local_path)
    if loc.exists():
        _store_load_json_file(store, store.local_path, "local")

    # 4. Env overrides
    _store_apply_env_overrides(store)


def _store_get(store: SettingsStore, key: String) -> String:
    """Get value for key, or empty string if not found."""
    for i in range(len(store.entries)):
        if store.entries[i].key == key:
            return store.entries[i].value
    return ""


def _store_set(mut store: SettingsStore, key: String, value: String, source: String = "local"):
    """Set a key-value pair. Updates existing or appends new."""
    for i in range(len(store.entries)):
        if store.entries[i].key == key:
            store.entries[i].value = value
            store.entries[i].source = source
            store.entries[i].last_modified = ""
            store._dirty = True
            return
    store.entries.append(
        SettingsEntry(key=key, value=value, source=source, last_modified="")
    )
    store._dirty = True


def _store_delete(mut store: SettingsStore, key: String) -> Bool:
    """Delete a key. Returns True if found and removed."""
    for i in range(len(store.entries)):
        if store.entries[i].key == key:
            # Remove by replacing with last element and popping
            var last_idx = len(store.entries) - 1
            if i != last_idx:
                store.entries[i] = store.entries[last_idx]
            _ = store.entries.pop()
            store._dirty = True
            return True
    return False


def _store_has(store: SettingsStore, key: String) -> Bool:
    """Check if a key exists."""
    for i in range(len(store.entries)):
        if store.entries[i].key == key:
            return True
    return False


def _store_keys(store: SettingsStore) -> List[String]:
    """Return all keys."""
    var result = List[String]()
    for i in range(len(store.entries)):
        result.append(store.entries[i].key)
    return result


def _store_save(store: SettingsStore) raises:
    """Persist dirty changes to disk as JSON."""
    if not store._dirty:
        return

    var json = _store_as_json(store)

    # Ensure .claw directory exists
    var dir_path = Path(store.project_path).parent()
    if not dir_path.exists():
        dir_path.mkdir()

    # Write project settings
    Path(store.project_path).write_text(json)


def _store_sync_from_remote(mut store: SettingsStore) raises -> SyncResult:
    """Pull remote changes. Guarded by sync_enabled flag."""
    if not store.sync_enabled:
        return SyncResult(pulled=0, pushed=0, conflicts=0, success=True)

    if store.remote_endpoint == "":
        return SyncResult(pulled=0, pushed=0, conflicts=0, success=False)

    # Bridge HTTP call would go here. For now return empty result
    # indicating the bridge is not yet wired up.
    return SyncResult(pulled=0, pushed=0, conflicts=0, success=True)


def _store_sync_to_remote(store: SettingsStore) raises -> SyncResult:
    """Push local changes to remote. Guarded by sync_enabled flag."""
    if not store.sync_enabled:
        return SyncResult(pulled=0, pushed=0, conflicts=0, success=True)

    if store.remote_endpoint == "":
        return SyncResult(pulled=0, pushed=0, conflicts=0, success=False)

    # Bridge HTTP call would go here. For now return empty result.
    return SyncResult(pulled=0, pushed=0, conflicts=0, success=True)


def _store_diff(store_a: SettingsStore, store_b: SettingsStore) -> List[SettingsDiff]:
    """Compare two stores and produce a list of diffs."""
    var diffs = List[SettingsDiff]()

    # Check entries in A against B
    for i in range(len(store_a.entries)):
        var k = store_a.entries[i].key
        var v_a = store_a.entries[i].value
        var found = False
        var v_b = String("")
        for j in range(len(store_b.entries)):
            if store_b.entries[j].key == k:
                found = True
                v_b = store_b.entries[j].value
                break
        if not found:
            diffs.append(
                SettingsDiff(
                    key=k,
                    local_value=v_a,
                    remote_value="",
                    action="delete",
                )
            )
        elif v_a != v_b:
            diffs.append(
                SettingsDiff(
                    key=k,
                    local_value=v_a,
                    remote_value=v_b,
                    action="update",
                )
            )

    # Check entries only in B (additions)
    for j in range(len(store_b.entries)):
        var k = store_b.entries[j].key
        var found = False
        for i in range(len(store_a.entries)):
            if store_a.entries[i].key == k:
                found = True
                break
        if not found:
            diffs.append(
                SettingsDiff(
                    key=k,
                    local_value="",
                    remote_value=store_b.entries[j].value,
                    action="add",
                )
            )

    return diffs


def _store_as_json(store: SettingsStore) -> String:
    """Serialize all entries as JSON object."""
    var parts = List[String]()
    for i in range(len(store.entries)):
        var entry = store.entries[i]
        parts.append('  "' + entry.key + '": "' + entry.value + '"')
    var body = String("")
    for i in range(len(parts)):
        if i > 0:
            body = body + ",\n"
        body = body + parts[i]
    return "{\n" + body + "\n}"


def _store_summary(store: SettingsStore) -> String:
    """Human-readable summary of the store."""
    var count = len(store.entries)
    var msg = "SettingsStore: " + String(count) + " entries"
    if store.sync_enabled:
        msg = msg + " (sync enabled)"
    else:
        msg = msg + " (sync disabled)"
    if store._dirty:
        msg = msg + " [dirty]"
    return msg


def _store_load_json_file(mut store: SettingsStore, path: String, source: String) raises:
    """Load key-value pairs from a simple JSON file."""
    var content = Path(path).read_text()
    # Simple parser: find all "key": "value" pairs
    var pos = 0
    while pos < len(content):
        # Find next key
        var key_start = content.find('"', pos)
        if key_start < 0:
            break
        var key_end = content.find('"', key_start + 1)
        if key_end < 0:
            break
        var key_str = String(content[key_start + 1 : key_end])

        # Find colon
        var colon = content.find(":", key_end + 1)
        if colon < 0:
            break

        # Find value opening quote
        var val_start = content.find('"', colon + 1)
        if val_start < 0:
            # Not a string value, skip ahead
            pos = colon + 1
            continue
        var val_end = content.find('"', val_start + 1)
        if val_end < 0:
            break
        var val_str = String(content[val_start + 1 : val_end])

        _store_merge_entry(store, key_str, val_str, source)
        pos = val_end + 1


def _store_apply_env_overrides(mut store: SettingsStore):
    """Check CLAW_* and ANTHROPIC_* environment variables for overrides."""
    var api_key = getenv("ANTHROPIC_API_KEY", "")
    if api_key != "":
        _store_merge_entry(store, "api_key", api_key, "env")

    var model = getenv("CLAW_MODEL", "")
    if model != "":
        _store_merge_entry(store, "model", model, "env")

    var max_tokens = getenv("CLAW_MAX_TOKENS", "")
    if max_tokens != "":
        _store_merge_entry(store, "max_tokens", max_tokens, "env")

    var base_url = getenv("ANTHROPIC_BASE_URL", "")
    if base_url != "":
        _store_merge_entry(store, "base_url", base_url, "env")

    var thinking = getenv("CLAW_THINKING_LEVEL", "")
    if thinking != "":
        _store_merge_entry(store, "thinking_level", thinking, "env")


def _store_merge_entry(mut store: SettingsStore, key: String, value: String, source: String):
    """Merge a single entry: update if exists, append if new."""
    for i in range(len(store.entries)):
        if store.entries[i].key == key:
            store.entries[i].value = value
            store.entries[i].source = source
            store.entries[i].last_modified = ""
            return
    store.entries.append(
        SettingsEntry(key=key, value=value, source=source, last_modified="")
    )


# ---------------------------------------------------------------------------
# Free functions
# ---------------------------------------------------------------------------

def new_settings_store(project_root: String = ".") -> SettingsStore:
    """Create a new SettingsStore rooted at the given project directory."""
    return _make_settings_store(project_root)


def default_settings() -> List[SettingsEntry]:
    """Return built-in default settings entries."""
    var defaults = List[SettingsEntry]()
    defaults.append(
        SettingsEntry(key="model", value="claude-opus-4-6", source="default", last_modified="")
    )
    defaults.append(
        SettingsEntry(key="max_tokens", value="32768", source="default", last_modified="")
    )
    defaults.append(
        SettingsEntry(key="thinking_level", value="adaptive", source="default", last_modified="")
    )
    defaults.append(
        SettingsEntry(key="tools_profile", value="coding", source="default", last_modified="")
    )
    defaults.append(
        SettingsEntry(key="context_1m", value="true", source="default", last_modified="")
    )
    defaults.append(
        SettingsEntry(
            key="base_url",
            value="https://api.anthropic.com",
            source="default",
            last_modified="",
        )
    )
    defaults.append(
        SettingsEntry(key="max_turns", value="1000", source="default", last_modified="")
    )
    return defaults


def format_settings_table(entries: List[SettingsEntry]) -> String:
    """Format settings entries as a human-readable table."""
    var header = "Key                     | Value                          | Source\n"
    var sep = "------------------------+--------------------------------+--------\n"
    var body = String("")
    for i in range(len(entries)):
        var e = entries[i]
        var key_col = e.key
        # Pad key to 24 chars
        while len(key_col) < 24:
            key_col = key_col + " "
        var val_col = e.value
        # Truncate and pad value to 32 chars
        if len(val_col) > 30:
            val_col = String(val_col[:27]) + "..."
        while len(val_col) < 32:
            val_col = val_col + " "
        body = body + key_col + "| " + val_col + "| " + e.source + "\n"
    return header + sep + body


def format_sync_report(result: SyncResult) -> String:
    """Format a SyncResult as a detailed report string."""
    var report = "=== Sync Report ===\n"
    report = report + "Status:    " + ("OK" if result.success else "FAILED") + "\n"
    report = report + "Pulled:    " + String(result.pulled) + "\n"
    report = report + "Pushed:    " + String(result.pushed) + "\n"
    report = report + "Conflicts: " + String(result.conflicts) + "\n"
    report = report + "===================\n"
    return report
