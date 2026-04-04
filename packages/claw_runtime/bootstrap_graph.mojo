# runtime/bootstrap_graph.mojo — Bootstrap graph stages
#
# Ported from src/bootstrap_graph.py.
# Enumerates the ordered startup stages of the Claw Code runtime.

from std.collections import List


@fieldwise_init
struct BootstrapGraph(Copyable, Movable):
    """Immutable graph of bootstrap stages executed during startup."""
    var stages: List[String]

    def as_markdown(self) -> String:
        """Render the bootstrap graph as Markdown text."""
        var lines = List[String]()
        lines.append("# Bootstrap Graph")
        lines.append("")
        for i in range(len(self.stages)):
            lines.append("- " + self.stages[i])
        var result = String("")
        for i in range(len(lines)):
            if i > 0:
                result += "\n"
            result += lines[i]
        return result


def build_bootstrap_graph() -> BootstrapGraph:
    """Build the default bootstrap graph with all startup stages."""
    var stages = List[String]()
    stages.append("top-level prefetch side effects")
    stages.append("warning handler and environment guards")
    stages.append("CLI parser and pre-action trust gate")
    stages.append("setup() + commands/agents parallel load")
    stages.append("deferred init after trust")
    stages.append(
        "mode routing: local / remote / ssh / teleport / direct-connect / deep-link"
    )
    stages.append("query engine submit loop")
    return BootstrapGraph(stages=stages)
