# tools/skill.mojo — Skill loading and execution tool
#
# Discovers and loads SKILL.md files from configured directories.

from std.pathlib import Path
from std.collections import List, Dict
from std.os import listdir


@fieldwise_init
struct SkillDefinition(Copyable, Movable, Writable):
    """A loaded skill with its metadata and content."""
    var name: String
    var description: String
    var content: String
    var file_path: String

    def __str__(self) -> String:
        return "Skill(" + self.name + ")"


struct SkillTool:
    """Load and execute skills from SKILL.md files."""
    var skills: Dict[String, SkillDefinition]
    var search_dirs: List[String]

    def __init__(out self):
        self.skills = Dict[String, SkillDefinition]()
        self.search_dirs = List[String]()

    def add_search_dir(mut self, dir_path: String):
        """Add a directory to search for skills."""
        self.search_dirs.append(dir_path)

    def discover(mut self) raises:
        """Discover all skills in configured search directories."""
        for dir_path in self.search_dirs:
            var path = Path(dir_path[])
            if not path.exists():
                continue
            var entries = listdir(path)
            for entry in entries:
                var child = path / entry[]
                if child.is_dir():
                    var skill_file = child / "SKILL.md"
                    if skill_file.exists():
                        var content = skill_file.read_text()
                        var skill = _parse_skill(String(skill_file), content)
                        self.skills[skill.name] = skill

    def get(self, name: String) raises -> SkillDefinition:
        """Get a skill by name."""
        if name not in self.skills:
            raise Error("Skill not found: " + name)
        return self.skills[name]

    def list_skills(self) -> List[String]:
        """List all discovered skill names."""
        var names = List[String]()
        for entry in self.skills.items():
            names.append(entry[].key)
        return names


def _parse_skill(file_path: String, content: String) -> SkillDefinition:
    """Parse a SKILL.md file into a SkillDefinition.

    Expected format:
    ---
    name: skill-name
    description: What the skill does
    ---
    Content here...
    """
    var name = String("")
    var description = String("")
    var body = content

    # Parse frontmatter if present
    if content.startswith("---"):
        var end = content.find("---", 3)
        if end > 0:
            var frontmatter = content[3:end]
            body = content[end + 3 :].strip()

            # Extract name
            var name_pos = frontmatter.find("name:")
            if name_pos >= 0:
                var line_end = frontmatter.find("\n", name_pos)
                if line_end < 0:
                    line_end = len(frontmatter)
                name = frontmatter[name_pos + 5 : line_end].strip()

            # Extract description
            var desc_pos = frontmatter.find("description:")
            if desc_pos >= 0:
                var line_end = frontmatter.find("\n", desc_pos)
                if line_end < 0:
                    line_end = len(frontmatter)
                description = frontmatter[desc_pos + 12 : line_end].strip()

    # Fallback: use directory name as skill name
    if name == "":
        var parts = file_path.split("/")
        if len(parts) >= 2:
            name = parts[len(parts) - 2]

    return SkillDefinition(
        name=name,
        description=description,
        content=body,
        file_path=file_path,
    )
