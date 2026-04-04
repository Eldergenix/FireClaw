# runtime/cost_tracker.mojo — Cost tracking (ported from src/cost_tracker.py + src/costHook.py)

from std.collections import List


@fieldwise_init
struct CostTracker(Copyable, Movable):
    """Track cumulative cost units and event labels across a session."""
    var total_units: Int
    var events: List[String]

    def record(mut self, label: String, units: Int):
        """Record a cost event by adding units and appending an event label."""
        self.total_units += units
        self.events.append(label + ":" + String(units))


def new_cost_tracker() -> CostTracker:
    """Create a zero-state CostTracker."""
    return CostTracker(total_units=0, events=List[String]())


def apply_cost_hook(mut tracker: CostTracker, label: String, units: Int):
    """Convenience wrapper: record a cost event on the tracker."""
    tracker.record(label, units)
