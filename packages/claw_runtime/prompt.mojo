# runtime/prompt.mojo — CLAW.md discovery and system prompt assembly
#
# Walks the directory tree upward from CWD to find CLAW.md files,
# reads them, and assembles the system prompt with injected context.

from std.pathlib import Path
from std.collections import List
# std.time.now not available in Mojo 0.26.2


@fieldwise_init
struct DiscoveredFile(Copyable, Movable):
    """A discovered CLAW.md or SKILL.md file with its content."""
    var path: String
    var content: String
    var depth: Int  # 0 = CWD, 1 = parent, etc.


def discover_claw_files(start_dir: String = "") raises -> List[DiscoveredFile]:
    """Walk up the directory tree from start_dir, collecting CLAW.md files.

    Files are returned in root-first order (deepest ancestor first)
    so that project-level config takes precedence over repo-level.
    """
    var result = List[DiscoveredFile]()
    var current = Path(start_dir) if start_dir != "" else Path()
    var depth = 0

    while True:
        var candidate = current / "CLAW.md"
        if candidate.exists():
            var content = candidate.read_text()
            result.append(
                DiscoveredFile(
                    path=String(candidate), content=content, depth=depth
                )
            )
        var parent = current.parent()
        if String(parent) == String(current):
            break
        current = parent
        depth += 1

    # Reverse so root-level files come first (outermost → innermost)
    var reversed_result = List[DiscoveredFile]()
    for i in range(len(result) - 1, -1, -1):
        reversed_result.append(result[i])
    return reversed_result


def assemble_system_prompt(
    claw_files: List[DiscoveredFile],
    tools_profile: String = "coding",
    model: String = "claude-opus-4-6",
    cwd: String = "",
) raises -> String:
    """Assemble the full system prompt from discovered CLAW.md files and config.

    The system prompt structure mirrors the TypeScript reference:
      1. Role and identity preamble
      2. Environment context (OS, CWD, date, model)
      3. Tool usage guidelines (based on tools_profile)
      4. CLAW.md content (project-specific guidance)
    """
    var prompt = String("")

    # Identity preamble
    prompt += "You are Claw, an AI coding assistant powered by " + model + ".\n"
    prompt += "You help users with software engineering tasks.\n\n"

    # Environment context
    var working_dir = cwd if cwd != "" else String(Path())
    prompt += "# Environment\n"
    prompt += "- Working directory: " + working_dir + "\n"
    prompt += "- Platform: darwin\n"  # TODO: detect at runtime
    prompt += "- Model: " + model + "\n"
    prompt += "- Tools profile: " + tools_profile + "\n\n"

    # Tool guidelines based on profile
    if tools_profile == "coding":
        prompt += "# Tools\n"
        prompt += "You have access to file read/write, shell execution, "
        prompt += "glob search, grep search, and other coding tools.\n"
        prompt += "Use dedicated tools instead of shell equivalents when available.\n\n"
    elif tools_profile == "messaging":
        prompt += "# Tools\n"
        prompt += "You have limited tool access for messaging contexts.\n\n"
    elif tools_profile == "full":
        prompt += "# Tools\n"
        prompt += "You have full tool access including gateway, cron, and agent spawning.\n\n"

    # Inject CLAW.md content
    if len(claw_files) > 0:
        prompt += "# Project Context\n"
        for i in range(len(claw_files)):
            prompt += "\n## From " + claw_files[i].path + "\n\n"
            prompt += claw_files[i].content + "\n"

    return prompt
