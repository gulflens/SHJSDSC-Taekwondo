"""
One-shot sweep: insert `.bareToolbarButton()` as the last modifier on every
`Button` / `Menu` declared inside a `ToolbarItem` (or directly inside
`.toolbar { … }`) across the iOS app source.

Approach: scan each `.swift` file line-by-line, track brace depth inside
`ToolbarItem { … }` blocks, and at the closing `}` of each ToolbarItem,
inject `.bareToolbarButton()` immediately before it — but only when the
block actually contains a Button/Menu and is not already styled. Skips
ShareLink / ExportButton / ProgressView / NavigationLink containers since
those aren't user Buttons we should restyle.

Usage:
    python3 scripts/apply_bare_toolbar.py
Re-run safely; it skips blocks that already have `.bareToolbarButton()`.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
TARGETS = [ROOT / "Features", ROOT / "App", ROOT / "Roles"]

SKIP_IF_CONTAINS = ("ShareLink", "ExportButton", "ProgressView()")

def needs_modifier(block_text: str) -> bool:
    if ".bareToolbarButton()" in block_text:
        return False
    if not re.search(r"\b(Button|Menu)\b", block_text):
        return False
    if any(s in block_text for s in SKIP_IF_CONTAINS):
        return False
    return True


def process(path: Path) -> int:
    src = path.read_text()
    if "ToolbarItem" not in src:
        return 0
    lines = src.splitlines(keepends=True)

    out: list[str] = []
    i = 0
    edits = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        # Match either `ToolbarItem` or `ToolbarItem(...)` followed by `{`
        is_toolbar_open = (
            re.match(r"ToolbarItem(?!Group)\b", stripped) is not None
            and "{" in line
        )
        if not is_toolbar_open:
            out.append(line)
            i += 1
            continue

        # Capture the whole block until braces balance back to 0.
        depth = line.count("{") - line.count("}")
        block_lines = [line]
        j = i + 1
        while j < len(lines) and depth > 0:
            block_lines.append(lines[j])
            depth += lines[j].count("{") - lines[j].count("}")
            j += 1

        if depth != 0:
            # Malformed; bail out without modifying.
            out.extend(block_lines)
            i = j
            continue

        block_text = "".join(block_lines)
        if not needs_modifier(block_text):
            out.extend(block_lines)
            i = j
            continue

        # Insert `.bareToolbarButton()` on a new line right before the
        # closing brace of the ToolbarItem. Indent it one level deeper
        # than the ToolbarItem's own indent.
        closing_line = block_lines[-1]
        toolbar_indent = re.match(r"(\s*)", lines[i]).group(1)
        button_indent = toolbar_indent + "    "
        new_line = f"{button_indent}.bareToolbarButton()\n"

        out.extend(block_lines[:-1])
        out.append(new_line)
        out.append(closing_line)
        edits += 1
        i = j

    if edits:
        path.write_text("".join(out))
    return edits


def main() -> None:
    total_files = 0
    total_edits = 0
    for root in TARGETS:
        for path in sorted(root.rglob("*.swift")):
            n = process(path)
            if n:
                total_files += 1
                total_edits += n
                print(f"  +{n}  {path.relative_to(ROOT)}")
    print(f"\nDone. {total_edits} toolbar buttons patched across {total_files} files.")


if __name__ == "__main__":
    main()
