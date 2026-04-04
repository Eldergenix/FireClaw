# runtime/direct_modes.mojo — Direct-connect and deep-link mode simulations
#
# Ported from src/direct_modes.py.
# Provides stub implementations for direct-connect and deep-link runtime modes.


@fieldwise_init
struct DirectModeReport(Copyable, Movable):
    """Report from a direct-connect or deep-link mode execution."""
    var mode: String
    var target: String
    var active: Bool

    def as_text(self) -> String:
        """Render the report as plain text."""
        return (
            "mode=" + self.mode
            + "\ntarget=" + self.target
            + "\nactive=" + String(self.active)
        )


def run_direct_connect(target: String) -> DirectModeReport:
    """Simulate a direct-connect mode session."""
    return DirectModeReport(mode="direct-connect", target=target, active=True)


def run_deep_link(target: String) -> DirectModeReport:
    """Simulate a deep-link mode session."""
    return DirectModeReport(mode="deep-link", target=target, active=True)
