# tools/todo.mojo — Todo/task list management tool

from std.collections import List


@fieldwise_init
struct TodoItem(Copyable, Movable, Writable):
    """A single todo item with status tracking."""
    var content: String
    var status: String  # "pending" | "in_progress" | "completed"
    var active_form: String

    def __str__(self) -> String:
        var icon: String
        if self.status == "completed":
            icon = "[x]"
        elif self.status == "in_progress":
            icon = "[>]"
        else:
            icon = "[ ]"
        return icon + " " + self.content


struct TodoWriteTool:
    """Manage a structured task list for tracking work progress."""
    var items: List[TodoItem]

    def __init__(out self):
        self.items = List[TodoItem]()

    def execute(mut self, todos: List[TodoItem]):
        """Replace the entire todo list with updated items."""
        self.items = todos

    def render(self) -> String:
        """Render the todo list as formatted text."""
        if len(self.items) == 0:
            return "No tasks."
        var result = String("")
        for i in range(len(self.items)):
            result += String(i + 1) + ". " + String(self.items[i]) + "\n"
        return result

    def active_task(self) -> String:
        """Return the description of the currently in-progress task."""
        for item in self.items:
            if item[].status == "in_progress":
                return item[].active_form
        return ""
