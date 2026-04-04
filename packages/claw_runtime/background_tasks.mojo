# runtime/background_tasks.mojo — Background task support (subprocess-based isolation)
#
# Ported from TS background agent/task concepts.
# Since Mojo lacks async/await, tasks use file-based state tracking
# with subprocess isolation for background work.

from std.collections import List, Dict


def _dict_get(d: Dict[String, String], key: String, default: String) -> String:
    """Return d[key] if key exists, otherwise return default.

    Mojo's Dict does not have a .get(key, default) overload like Python.
    Dict.get(key) returns Optional[V], so this helper provides the familiar
    two-argument form.
    """
    if key in d:
        return d[key]
    return default


@fieldwise_init
struct BackgroundTask(Copyable, Movable):
    """A background task tracked via file-based state."""
    var id: String
    var description: String
    var command: String
    var status: String           # "pending" | "running" | "completed" | "failed" | "cancelled"
    var output: String           # Captured stdout
    var error_output: String     # Captured stderr
    var exit_code: Int
    var created_at: String
    var completed_at: String
    var working_directory: String

    def is_terminal(self) -> Bool:
        """Return True if the task is in a terminal state."""
        return (
            self.status == "completed"
            or self.status == "failed"
            or self.status == "cancelled"
        )

    def is_running(self) -> Bool:
        """Return True if the task is currently running."""
        return self.status == "running"

    def is_pending(self) -> Bool:
        """Return True if the task has not yet started."""
        return self.status == "pending"

    def succeeded(self) -> Bool:
        """Return True if the task completed with exit code 0."""
        return self.status == "completed" and self.exit_code == 0

    def serialize(self) -> String:
        """Serialize task state to a simple key=value format for persistence."""
        var lines = List[String]()
        lines.append("id=" + self.id)
        lines.append("description=" + self.description)
        lines.append("command=" + self.command)
        lines.append("status=" + self.status)
        lines.append("output=" + self.output)
        lines.append("error_output=" + self.error_output)
        lines.append("exit_code=" + String(self.exit_code))
        lines.append("created_at=" + self.created_at)
        lines.append("completed_at=" + self.completed_at)
        lines.append("working_directory=" + self.working_directory)
        var result = String("")
        for i in range(len(lines)):
            if i > 0:
                result += "\n"
            result += lines[i]
        return result


def _deserialize_task(content: String) raises -> BackgroundTask:
    """Deserialize a task from key=value line format."""
    var fields = Dict[String, String]()
    # Parse each line as key=value
    var current_key = String("")
    var current_val = String("")
    var in_value = False
    var line_start = 0

    # Simple line-by-line parse
    var lines = List[String]()
    var buf = String("")
    for i in range(len(content)):
        if content[i] == "\n":
            lines.append(buf)
            buf = String("")
        else:
            buf += content[i]
    if len(buf) > 0:
        lines.append(buf)

    for i in range(len(lines)):
        var line = lines[i]
        # Find first '='
        var eq_pos = -1
        for j in range(len(line)):
            if line[j] == "=":
                eq_pos = j
                break
        if eq_pos > 0:
            var key = String("")
            for j in range(eq_pos):
                key += line[j]
            var val = String("")
            for j in range(eq_pos + 1, len(line)):
                val += line[j]
            fields[key] = val

    var exit_code = 0
    var ec_str = _dict_get(fields, "exit_code", String("0"))
    exit_code = Int(ec_str)

    return BackgroundTask(
        id=_dict_get(fields, "id", String("")),
        description=_dict_get(fields, "description", String("")),
        command=_dict_get(fields, "command", String("")),
        status=_dict_get(fields, "status", String("pending")),
        output=_dict_get(fields, "output", String("")),
        error_output=_dict_get(fields, "error_output", String("")),
        exit_code=exit_code,
        created_at=_dict_get(fields, "created_at", String("")),
        completed_at=_dict_get(fields, "completed_at", String("")),
        working_directory=_dict_get(fields, "working_directory", String(".")),
    )


@fieldwise_init
struct TaskResult(Copyable, Movable):
    """Summary of a completed task."""
    var task_id: String
    var success: Bool
    var output: String
    var duration_hint: String


struct TaskManager(Copyable, Movable):
    """Manages background tasks with file-based state persistence."""
    var tasks: List[BackgroundTask]
    var max_concurrent: Int
    var task_dir: String
    var _counter: Int

    def __init__(
        out self,
        task_dir: String = ".claw/tasks",
        max_concurrent: Int = 5,
    ):
        self.tasks = List[BackgroundTask]()
        self.max_concurrent = max_concurrent
        self.task_dir = task_dir
        self._counter = 0

    def __copyinit__(out self, *, copy: Self):
        self.tasks = copy.tasks
        self.max_concurrent = copy.max_concurrent
        self.task_dir = copy.task_dir
        self._counter = copy._counter

    def __moveinit__(out self, *, deinit take: Self):
        self.tasks = take.tasks
        self.max_concurrent = take.max_concurrent
        self.task_dir = take.task_dir
        self._counter = take._counter

    def _generate_id(mut self) -> String:
        """Generate a unique task ID using an incrementing counter."""
        self._counter += 1
        return "task-" + String(self._counter)

    def submit(
        mut self,
        description: String,
        command: String,
        working_dir: String = ".",
    ) raises -> String:
        """Submit a new background task. Returns the task ID.

        Creates the task in 'pending' state and persists it to the task directory.
        The actual subprocess execution would be triggered separately.
        """
        if self.running_count() >= self.max_concurrent:
            raise Error(
                "Max concurrent tasks ("
                + String(self.max_concurrent)
                + ") reached"
            )

        var task_id = self._generate_id()
        var task = BackgroundTask(
            id=task_id,
            description=description,
            command=command,
            status="pending",
            output=String(""),
            error_output=String(""),
            exit_code=-1,
            created_at=String("now"),  # Placeholder; real impl would use clock
            completed_at=String(""),
            working_directory=working_dir,
        )
        self.tasks.append(task)
        self._save_task_state(task)
        return task_id

    def poll(mut self, task_id: String) raises -> BackgroundTask:
        """Poll a task by ID, refreshing its state from persisted storage.

        Returns the updated BackgroundTask. Raises if task not found.
        """
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                # In a full implementation, we would read the state file
                # to check if an external process updated it.
                # For now, return current in-memory state.
                var loaded = self._load_task_state(task_id)
                self.tasks[i] = loaded
                return loaded
        raise Error("Task not found: " + task_id)

    def poll_all(mut self) raises -> List[BackgroundTask]:
        """Poll all non-terminal tasks and return the full task list."""
        for i in range(len(self.tasks)):
            if not self.tasks[i].is_terminal():
                var loaded = self._load_task_state(self.tasks[i].id)
                self.tasks[i] = loaded
        return self.tasks

    def cancel(mut self, task_id: String) raises:
        """Attempt to cancel a task by marking it as cancelled.

        Only pending or running tasks can be cancelled.
        """
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                if self.tasks[i].is_terminal():
                    raise Error(
                        "Cannot cancel task in terminal state: "
                        + self.tasks[i].status
                    )
                self.tasks[i].status = "cancelled"
                self.tasks[i].completed_at = "now"
                self._save_task_state(self.tasks[i])
                return
        raise Error("Task not found: " + task_id)

    def get_task(self, task_id: String) raises -> BackgroundTask:
        """Get a task by ID from the in-memory list."""
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                return self.tasks[i]
        raise Error("Task not found: " + task_id)

    def list_tasks(self, status_filter: String = "") -> List[BackgroundTask]:
        """List tasks, optionally filtered by status.

        If status_filter is empty, returns all tasks.
        """
        if len(status_filter) == 0:
            return self.tasks
        var filtered = List[BackgroundTask]()
        for i in range(len(self.tasks)):
            if self.tasks[i].status == status_filter:
                filtered.append(self.tasks[i])
        return filtered

    def cleanup_completed(mut self) -> Int:
        """Remove all tasks in terminal states. Returns count removed."""
        var remaining = List[BackgroundTask]()
        var removed = 0
        for i in range(len(self.tasks)):
            if self.tasks[i].is_terminal():
                removed += 1
            else:
                remaining.append(self.tasks[i])
        self.tasks = remaining
        return removed

    def running_count(self) -> Int:
        """Count tasks that are currently running or pending."""
        var count = 0
        for i in range(len(self.tasks)):
            if self.tasks[i].status == "running" or self.tasks[i].status == "pending":
                count += 1
        return count

    def _save_task_state(self, task: BackgroundTask) raises:
        """Persist task state to a file in the task directory.

        File path: <task_dir>/<task_id>.state
        In a full implementation this would use filesystem I/O.
        Currently stores state in-memory only (file write is a no-op placeholder).
        """
        # Placeholder: real implementation would do:
        #   var path = self.task_dir + "/" + task.id + ".state"
        #   write_file(path, task.serialize())
        # For now, state is maintained in the tasks list.
        pass

    def _load_task_state(self, task_id: String) raises -> BackgroundTask:
        """Load task state from a persisted file.

        In a full implementation, reads <task_dir>/<task_id>.state.
        Currently returns the in-memory state as a fallback.
        """
        # Placeholder: real implementation would do:
        #   var path = self.task_dir + "/" + task_id + ".state"
        #   var content = read_file(path)
        #   return _deserialize_task(content)
        # For now, return from in-memory list.
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                return self.tasks[i]
        raise Error("Task state not found: " + task_id)

    def mark_running(mut self, task_id: String) raises:
        """Transition a pending task to running state."""
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                if self.tasks[i].status != "pending":
                    raise Error(
                        "Can only start pending tasks, current status: "
                        + self.tasks[i].status
                    )
                self.tasks[i].status = "running"
                self._save_task_state(self.tasks[i])
                return
        raise Error("Task not found: " + task_id)

    def mark_completed(
        mut self,
        task_id: String,
        exit_code: Int,
        output: String = "",
        error_output: String = "",
    ) raises:
        """Mark a running task as completed or failed based on exit code."""
        for i in range(len(self.tasks)):
            if self.tasks[i].id == task_id:
                if exit_code == 0:
                    self.tasks[i].status = "completed"
                else:
                    self.tasks[i].status = "failed"
                self.tasks[i].exit_code = exit_code
                self.tasks[i].output = output
                self.tasks[i].error_output = error_output
                self.tasks[i].completed_at = "now"
                self._save_task_state(self.tasks[i])
                return
        raise Error("Task not found: " + task_id)

    def to_result(self, task_id: String) raises -> TaskResult:
        """Convert a terminal task to a TaskResult summary."""
        var task = self.get_task(task_id)
        if not task.is_terminal():
            raise Error("Task is not yet complete: " + task_id)
        return TaskResult(
            task_id=task.id,
            success=task.succeeded(),
            output=task.output,
            duration_hint="elapsed",  # Placeholder
        )


# ---------------------------------------------------------------------------
# Free functions
# ---------------------------------------------------------------------------


def new_task_manager(
    task_dir: String = ".claw/tasks", max_concurrent: Int = 5
) -> TaskManager:
    """Create a fresh TaskManager instance."""
    return TaskManager(task_dir=task_dir, max_concurrent=max_concurrent)


def format_task_list(tasks: List[BackgroundTask]) -> String:
    """Render a list of tasks as a Markdown table."""
    var lines = List[String]()
    lines.append("| ID | Status | Description |")
    lines.append("|------|----------|---------------|")
    for i in range(len(tasks)):
        var t = tasks[i]
        lines.append("| " + t.id + " | " + t.status + " | " + t.description + " |")
    if len(tasks) == 0:
        lines.append("| (none) | - | - |")
    var result = String("")
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result


def format_task_detail(task: BackgroundTask) -> String:
    """Render a detailed view of a single task."""
    var lines = List[String]()
    lines.append("## Task: " + task.id)
    lines.append("")
    lines.append("- **Description:** " + task.description)
    lines.append("- **Status:** " + task.status)
    lines.append("- **Command:** `" + task.command + "`")
    lines.append("- **Working Dir:** " + task.working_directory)
    lines.append("- **Exit Code:** " + String(task.exit_code))
    lines.append("- **Created:** " + task.created_at)
    if len(task.completed_at) > 0:
        lines.append("- **Completed:** " + task.completed_at)
    if len(task.output) > 0:
        lines.append("")
        lines.append("### Output")
        lines.append("```")
        lines.append(task.output)
        lines.append("```")
    if len(task.error_output) > 0:
        lines.append("")
        lines.append("### Errors")
        lines.append("```")
        lines.append(task.error_output)
        lines.append("```")
    var result = String("")
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result
