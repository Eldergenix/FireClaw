from std.collections import List


@fieldwise_init
struct ToolPermissionContext(Copyable, Movable):
    var deny_names: List[String]
    var deny_prefixes: List[String]

    @staticmethod
    def from_iterables(
        deny_names: List[String] = List[String](),
        deny_prefixes: List[String] = List[String](),
    ) -> ToolPermissionContext:
        var lowered_names = List[String]()
        for i in range(len(deny_names)):
            lowered_names.append(deny_names[i].lower())

        var lowered_prefixes = List[String]()
        for i in range(len(deny_prefixes)):
            lowered_prefixes.append(deny_prefixes[i].lower())

        return ToolPermissionContext(
            deny_names=lowered_names,
            deny_prefixes=lowered_prefixes,
        )

    def blocks(self, tool_name: String) -> Bool:
        var lowered: String = tool_name.lower()

        for i in range(len(self.deny_names)):
            if lowered == self.deny_names[i]:
                return True

        for i in range(len(self.deny_prefixes)):
            if lowered.startswith(self.deny_prefixes[i]):
                return True

        return False
