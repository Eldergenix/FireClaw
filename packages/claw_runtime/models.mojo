# runtime/models.mojo — Core data models for the porting workflow

from std.collections import List


@fieldwise_init
struct Subsystem(Copyable, Movable):
    """A discovered subsystem within the source codebase."""
    var name: String
    var path: String
    var file_count: Int
    var notes: String


@fieldwise_init
struct PortingModule(Copyable, Movable):
    """A single module tracked in the porting backlog."""
    var name: String
    var responsibility: String
    var source_hint: String
    var status: String


def new_porting_module(
    name: String,
    responsibility: String,
    source_hint: String,
    status: String = "planned",
) -> PortingModule:
    """Create a PortingModule with an optional default status."""
    return PortingModule(
        name=name,
        responsibility=responsibility,
        source_hint=source_hint,
        status=status,
    )


@fieldwise_init
struct PermissionDenial(Copyable, Movable):
    """Record of a tool invocation that was denied."""
    var tool_name: String
    var reason: String


@fieldwise_init
struct UsageSummary(Copyable, Movable):
    """Lightweight token-usage snapshot (word-count approximation)."""
    var input_tokens: Int
    var output_tokens: Int

    def add_turn(self, prompt: String, output: String) -> UsageSummary:
        """Return a new UsageSummary with token counts incremented by
        the word counts of the given prompt and output strings."""
        return UsageSummary(
            input_tokens=self.input_tokens + len(prompt.split()),
            output_tokens=self.output_tokens + len(output.split()),
        )


def new_usage_summary(
    input_tokens: Int = 0,
    output_tokens: Int = 0,
) -> UsageSummary:
    """Create a UsageSummary with optional default zero counts."""
    return UsageSummary(
        input_tokens=input_tokens,
        output_tokens=output_tokens,
    )


@fieldwise_init
struct PortingBacklog(Copyable, Movable):
    """Mutable backlog of modules to be ported."""
    var title: String
    var modules: List[PortingModule]

    def summary_lines(self) -> List[String]:
        """Return a formatted summary line for each module."""
        var lines = List[String]()
        for i in range(len(self.modules)):
            var module = self.modules[i]
            lines.append(
                "- "
                + module.name
                + " ["
                + module.status
                + "] — "
                + module.responsibility
                + " (from "
                + module.source_hint
                + ")"
            )
        return lines


def new_porting_backlog(title: String) -> PortingBacklog:
    """Create a PortingBacklog with an empty module list."""
    return PortingBacklog(
        title=title,
        modules=List[PortingModule](),
    )
