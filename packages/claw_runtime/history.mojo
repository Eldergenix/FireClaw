from std.collections import List


@fieldwise_init
struct HistoryEvent(Copyable, Movable):
    var title: String
    var detail: String


struct HistoryLog(Copyable, Movable):
    var events: List[HistoryEvent]

    def __init__(out self):
        self.events = List[HistoryEvent]()

    def __init__(out self, events: List[HistoryEvent]):
        self.events = events

    def __copyinit__(out self, *, copy: Self):
        self.events = copy.events

    def __moveinit__(out self, *, deinit take: Self):
        self.events = take.events^

    def add(mut self, title: String, detail: String) -> None:
        self.events.append(HistoryEvent(title=title, detail=detail))

    def as_markdown(self) -> String:
        var result: String = "# Session History\n"
        for i in range(len(self.events)):
            result += "\n- " + self.events[i].title + ": " + self.events[i].detail
        return result
