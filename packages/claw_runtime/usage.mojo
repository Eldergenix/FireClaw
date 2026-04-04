# runtime/usage.mojo — Token usage and cost tracking

from std.collections import Dict


@fieldwise_init
struct ModelPricing(Copyable, Movable):
    """Pricing per million tokens for a model."""
    var input_per_m: Float64
    var output_per_m: Float64
    var cache_write_per_m: Float64
    var cache_read_per_m: Float64


def get_pricing(model: String) -> ModelPricing:
    """Get pricing for a known model."""
    if "opus" in model:
        return ModelPricing(
            input_per_m=15.0,
            output_per_m=75.0,
            cache_write_per_m=18.75,
            cache_read_per_m=1.50,
        )
    elif "sonnet" in model:
        return ModelPricing(
            input_per_m=3.0,
            output_per_m=15.0,
            cache_write_per_m=3.75,
            cache_read_per_m=0.30,
        )
    elif "haiku" in model:
        return ModelPricing(
            input_per_m=0.80,
            output_per_m=4.0,
            cache_write_per_m=1.0,
            cache_read_per_m=0.08,
        )
    # Default to sonnet pricing
    return ModelPricing(
        input_per_m=3.0,
        output_per_m=15.0,
        cache_write_per_m=3.75,
        cache_read_per_m=0.30,
    )


@fieldwise_init
struct UsageTracker(Copyable, Movable):
    """Track cumulative token usage and cost across a session."""
    var model: String
    var total_input: Int
    var total_output: Int
    var total_cache_write: Int
    var total_cache_read: Int
    var turn_count: Int

    def cost_usd(self) -> Float64:
        """Calculate total cost in USD."""
        var pricing = get_pricing(self.model)
        return (
            self.total_input * pricing.input_per_m / 1_000_000.0
            + self.total_output * pricing.output_per_m / 1_000_000.0
            + self.total_cache_write * pricing.cache_write_per_m / 1_000_000.0
            + self.total_cache_read * pricing.cache_read_per_m / 1_000_000.0
        )

    def summary(self) -> String:
        """Return a formatted usage summary."""
        return (
            "Tokens: "
            + String(self.total_input)
            + " in / "
            + String(self.total_output)
            + " out"
            + " | Cache: "
            + String(self.total_cache_write)
            + " write / "
            + String(self.total_cache_read)
            + " read"
            + " | Cost: $"
            + String(self.cost_usd())
            + " | Turns: "
            + String(self.turn_count)
        )


def new_tracker(model: String = "claude-opus-4-6") -> UsageTracker:
    """Create a fresh usage tracker."""
    return UsageTracker(
        model=model,
        total_input=0,
        total_output=0,
        total_cache_write=0,
        total_cache_read=0,
        turn_count=0,
    )
