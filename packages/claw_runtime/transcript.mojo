# runtime/transcript.mojo — Transcript store for conversation replay
#
# Maintains an ordered list of transcript entries that can be
# compacted, replayed, and flushed.  Ported from src/transcript.py.

from std.collections import List


@fieldwise_init
struct TranscriptStore(Copyable, Movable):
    """Ordered store of transcript entries with compaction support."""
    var entries: List[String]
    var flushed: Bool

    def append(mut self, entry: String):
        """Append a new entry and mark the store as unflushed."""
        self.entries.append(entry)
        self.flushed = False

    def compact(mut self, keep_last: Int = 10):
        """Keep only the most recent *keep_last* entries."""
        var n = len(self.entries)
        if n > keep_last:
            var trimmed = List[String]()
            var start = n - keep_last
            for i in range(start, n):
                trimmed.append(self.entries[i])
            self.entries = trimmed

    def replay(self) -> List[String]:
        """Return a copy of all entries."""
        var copy = List[String]()
        for i in range(len(self.entries)):
            copy.append(self.entries[i])
        return copy

    def flush(mut self):
        """Mark the transcript as flushed."""
        self.flushed = True


def new_transcript() -> TranscriptStore:
    """Create an empty transcript store."""
    return TranscriptStore(
        entries=List[String](),
        flushed=False,
    )
