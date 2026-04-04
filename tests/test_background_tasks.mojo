# tests/test_background_tasks.mojo — Tests for background task support
#
# Validates TaskManager, BackgroundTask, and formatting functions.

from std.testing import assert_equal, assert_true
from std.collections import List

from fireclaw.packages.claw_runtime.background_tasks import (
    BackgroundTask,
    TaskManager,
    TaskResult,
    new_task_manager,
    format_task_list,
    format_task_detail,
    _deserialize_task,
)


def test_task_manager_creation():
    """Create a manager and verify it starts with an empty task list."""
    var mgr = new_task_manager()
    var tasks = mgr.list_tasks()
    assert_equal(len(tasks), 0)
    assert_equal(mgr.max_concurrent, 5)
    assert_equal(mgr.task_dir, ".claw/tasks")


def test_task_manager_custom_params():
    """Create a manager with custom parameters."""
    var mgr = new_task_manager(task_dir="/tmp/my_tasks", max_concurrent=3)
    assert_equal(mgr.max_concurrent, 3)
    assert_equal(mgr.task_dir, "/tmp/my_tasks")


def test_submit_task():
    """Submit a task and verify ID returned and status is pending."""
    var mgr = new_task_manager()
    var task_id = mgr.submit(
        description="Run tests",
        command="mojo test",
        working_dir="/project",
    )
    assert_equal(task_id, "task-1")

    var task = mgr.get_task(task_id)
    assert_equal(task.status, "pending")
    assert_equal(task.description, "Run tests")
    assert_equal(task.command, "mojo test")
    assert_equal(task.working_directory, "/project")
    assert_true(task.is_pending())
    assert_true(not task.is_running())
    assert_true(not task.is_terminal())


def test_list_tasks_empty():
    """New manager should have an empty task list."""
    var mgr = new_task_manager()
    var all_tasks = mgr.list_tasks()
    assert_equal(len(all_tasks), 0)
    var filtered = mgr.list_tasks(status_filter="pending")
    assert_equal(len(filtered), 0)


def test_list_tasks_with_filter():
    """Submit multiple tasks, filter by status."""
    var mgr = new_task_manager()
    var id1 = mgr.submit(description="Task A", command="echo a")
    var id2 = mgr.submit(description="Task B", command="echo b")
    var id3 = mgr.submit(description="Task C", command="echo c")

    # All three should be pending
    var pending = mgr.list_tasks(status_filter="pending")
    assert_equal(len(pending), 3)

    # Mark one as running
    mgr.mark_running(id2)
    pending = mgr.list_tasks(status_filter="pending")
    assert_equal(len(pending), 2)

    var running = mgr.list_tasks(status_filter="running")
    assert_equal(len(running), 1)
    assert_equal(running[0].id, "task-2")

    # Complete one
    mgr.mark_completed(id2, exit_code=0, output="done")
    var completed = mgr.list_tasks(status_filter="completed")
    assert_equal(len(completed), 1)
    assert_equal(completed[0].output, "done")

    # No filter returns all
    var all_tasks = mgr.list_tasks()
    assert_equal(len(all_tasks), 3)


def test_running_count():
    """Submit tasks and verify running_count tracks pending+running."""
    var mgr = new_task_manager()
    assert_equal(mgr.running_count(), 0)

    var id1 = mgr.submit(description="A", command="cmd_a")
    assert_equal(mgr.running_count(), 1)  # pending counts

    var id2 = mgr.submit(description="B", command="cmd_b")
    assert_equal(mgr.running_count(), 2)

    mgr.mark_running(id1)
    assert_equal(mgr.running_count(), 2)  # running also counts

    mgr.mark_completed(id1, exit_code=0)
    assert_equal(mgr.running_count(), 1)  # only id2 pending now

    mgr.mark_running(id2)
    mgr.mark_completed(id2, exit_code=1)
    assert_equal(mgr.running_count(), 0)


def test_cleanup_completed():
    """Add tasks in various states, cleanup completed, verify count."""
    var mgr = new_task_manager()
    var id1 = mgr.submit(description="A", command="cmd_a")
    var id2 = mgr.submit(description="B", command="cmd_b")
    var id3 = mgr.submit(description="C", command="cmd_c")

    # Complete two tasks
    mgr.mark_running(id1)
    mgr.mark_completed(id1, exit_code=0)
    mgr.mark_running(id2)
    mgr.mark_completed(id2, exit_code=1)  # failed

    # id3 remains pending
    var removed = mgr.cleanup_completed()
    assert_equal(removed, 2)  # completed + failed are both terminal

    var remaining = mgr.list_tasks()
    assert_equal(len(remaining), 1)
    assert_equal(remaining[0].id, "task-3")


def test_cancel_task():
    """Cancel a pending task and verify state."""
    var mgr = new_task_manager()
    var task_id = mgr.submit(description="Cancellable", command="sleep 100")
    mgr.cancel(task_id)

    var task = mgr.get_task(task_id)
    assert_equal(task.status, "cancelled")
    assert_true(task.is_terminal())


def test_format_task_list():
    """Format a list of tasks and verify output contains task IDs."""
    var mgr = new_task_manager()
    _ = mgr.submit(description="Alpha", command="echo alpha")
    _ = mgr.submit(description="Beta", command="echo beta")

    var output = format_task_list(mgr.list_tasks())
    # Should contain markdown table header
    assert_true(len(output) > 0)
    # Check that task IDs appear in the output
    assert_true(output.find("task-1") >= 0)
    assert_true(output.find("task-2") >= 0)
    # Check table structure
    assert_true(output.find("| ID |") >= 0)
    assert_true(output.find("Alpha") >= 0)
    assert_true(output.find("Beta") >= 0)


def test_format_task_list_empty():
    """Format an empty task list."""
    var empty = List[BackgroundTask]()
    var output = format_task_list(empty)
    assert_true(output.find("(none)") >= 0)


def test_format_task_detail():
    """Format a single task in detail view."""
    var task = BackgroundTask(
        id="task-42",
        description="Build project",
        command="mojo build",
        status="completed",
        output="Build succeeded",
        error_output="",
        exit_code=0,
        created_at="2026-04-04T00:00:00",
        completed_at="2026-04-04T00:01:00",
        working_directory="/project",
    )
    var output = format_task_detail(task)
    assert_true(output.find("task-42") >= 0)
    assert_true(output.find("Build project") >= 0)
    assert_true(output.find("completed") >= 0)
    assert_true(output.find("mojo build") >= 0)
    assert_true(output.find("Build succeeded") >= 0)


def test_generate_unique_ids():
    """Submit multiple tasks and verify all IDs are unique."""
    var mgr = new_task_manager()
    var ids = List[String]()
    for i in range(10):
        var task_id = mgr.submit(
            description="Task " + String(i),
            command="echo " + String(i),
        )
        # Verify this ID has not been seen before
        for j in range(len(ids)):
            assert_true(ids[j] != task_id)
        ids.append(task_id)

    # Verify we have exactly 10 unique IDs
    assert_equal(len(ids), 10)


def test_task_lifecycle():
    """Test the full lifecycle: submit -> running -> completed -> result."""
    var mgr = new_task_manager()
    var task_id = mgr.submit(description="Full cycle", command="echo hello")

    # Pending
    var task = mgr.get_task(task_id)
    assert_equal(task.status, "pending")

    # Running
    mgr.mark_running(task_id)
    task = mgr.get_task(task_id)
    assert_equal(task.status, "running")
    assert_true(task.is_running())

    # Completed
    mgr.mark_completed(task_id, exit_code=0, output="hello")
    task = mgr.get_task(task_id)
    assert_equal(task.status, "completed")
    assert_equal(task.exit_code, 0)
    assert_equal(task.output, "hello")
    assert_true(task.succeeded())

    # Result
    var result = mgr.to_result(task_id)
    assert_true(result.success)
    assert_equal(result.output, "hello")
    assert_equal(result.task_id, task_id)


def test_failed_task():
    """A task that fails should have status 'failed'."""
    var mgr = new_task_manager()
    var task_id = mgr.submit(description="Fail test", command="exit 1")
    mgr.mark_running(task_id)
    mgr.mark_completed(task_id, exit_code=1, error_output="command failed")

    var task = mgr.get_task(task_id)
    assert_equal(task.status, "failed")
    assert_equal(task.exit_code, 1)
    assert_equal(task.error_output, "command failed")
    assert_true(task.is_terminal())
    assert_true(not task.succeeded())


def test_serialize_roundtrip():
    """Serialize a task and deserialize it, verifying fields match."""
    var original = BackgroundTask(
        id="task-99",
        description="Roundtrip test",
        command="echo roundtrip",
        status="completed",
        output="ok",
        error_output="",
        exit_code=0,
        created_at="t0",
        completed_at="t1",
        working_directory="/tmp",
    )
    var serialized = original.serialize()
    var restored = _deserialize_task(serialized)

    assert_equal(restored.id, "task-99")
    assert_equal(restored.description, "Roundtrip test")
    assert_equal(restored.command, "echo roundtrip")
    assert_equal(restored.status, "completed")
    assert_equal(restored.output, "ok")
    assert_equal(restored.exit_code, 0)
    assert_equal(restored.working_directory, "/tmp")


def test_poll_task():
    """Poll a task and verify it returns current state."""
    var mgr = new_task_manager()
    var task_id = mgr.submit(description="Poll me", command="echo poll")
    var polled = mgr.poll(task_id)
    assert_equal(polled.id, task_id)
    assert_equal(polled.status, "pending")


def test_poll_all():
    """Poll all tasks and get back the full list."""
    var mgr = new_task_manager()
    _ = mgr.submit(description="A", command="echo a")
    _ = mgr.submit(description="B", command="echo b")
    var all_tasks = mgr.poll_all()
    assert_equal(len(all_tasks), 2)
