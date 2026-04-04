# runtime/plugins.mojo — Plugin system using subprocess JSON-over-stdio protocol
#
# Plugins are external executables that communicate via stdin/stdout.
# Each plugin declares its capabilities (channels, tools, bindings) in a manifest.

from std.collections import List, Dict
from std.pathlib import Path
from std.os import listdir


@fieldwise_init
struct PluginManifest(Copyable, Movable):
    """Manifest declaring a plugin's identity and capabilities."""
    var name: String
    var version: String
    var executable: String
    var capabilities: List[String]  # "channel", "tool", "binding", "command"
    var description: String


@fieldwise_init
struct PluginMessage(Copyable, Movable):
    """A message in the plugin JSON-over-stdio protocol."""
    var type: String  # "request" | "response" | "event"
    var method: String
    var params: String  # JSON string
    var id: String


struct PluginManager:
    """Manage plugin discovery, lifecycle, and communication."""
    var plugins: Dict[String, PluginManifest]
    var plugin_dirs: List[String]

    def __init__(out self):
        self.plugins = Dict[String, PluginManifest]()
        self.plugin_dirs = List[String]()

    def add_plugin_dir(mut self, dir_path: String):
        """Add a directory to scan for plugins."""
        self.plugin_dirs.append(dir_path)

    def discover(mut self) raises:
        """Discover plugins from configured directories."""
        for dir_path in self.plugin_dirs:
            var path = Path(dir_path[])
            if not path.exists():
                continue
            var entries = listdir(path)
            for entry in entries:
                var child = path / entry[]
                if child.is_dir():
                    var manifest_path = child / "manifest.json"
                    if manifest_path.exists():
                        var content = manifest_path.read_text()
                        var manifest = _parse_manifest(content, entry[])
                        self.plugins[manifest.name] = manifest

    def start_plugin(mut self, name: String) raises -> String:
        """Start a plugin subprocess.

        Returns plugin process ID.
        """
        if name not in self.plugins:
            raise Error("Plugin not found: " + name)

        # TODO: Spawn subprocess, send initialize message
        return "plugin-" + name

    def stop_plugin(mut self, name: String) raises:
        """Stop a running plugin."""
        # TODO: Send shutdown message, wait for process exit
        pass

    def send_message(self, name: String, message: PluginMessage) raises -> String:
        """Send a message to a plugin and return the response."""
        # TODO: Write JSON to plugin stdin, read response from stdout
        raise Error("Plugin communication not yet implemented")

    def list_plugins(self) -> List[String]:
        """List all discovered plugin names."""
        var names = List[String]()
        for entry in self.plugins.items():
            names.append(entry[].key)
        return names


def _parse_manifest(json_content: String, fallback_name: String) -> PluginManifest:
    """Parse a plugin manifest from JSON."""
    # Simplified extraction — full parsing via EmberJson or bridge
    return PluginManifest(
        name=fallback_name,
        version="0.0.0",
        executable="",
        capabilities=List[String](),
        description="",
    )
