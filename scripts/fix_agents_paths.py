#!/usr/bin/env python3
"""Convert absolute file:/// paths in .agents/ markdown files to relative paths."""

import os
import re
import sys
from pathlib import Path, PurePosixPath

PROJECT_ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = PROJECT_ROOT / ".agents"
ABS_PATTERN = re.compile(r"\(file:///d:/Projects/Open/flutter/code/centrode/([^\)]+)\)")

def to_relative(target: str, source_file: Path) -> str:
    """Return project-root-relative path (e.g. rust/src/domain)."""
    return target

def convert_file(path: Path) -> int:
    """Convert absolute paths in a single file. Returns number of replacements."""
    original = path.read_text(encoding="utf-8")

    def replacer(m):
        target = m.group(1)
        return "(" + to_relative(target, path) + ")"

    new = ABS_PATTERN.sub(replacer, original)
    if new != original:
        count = len(ABS_PATTERN.findall(original))
        path.write_text(new, encoding="utf-8")
        return count
    return 0

def main():
    if not AGENTS_DIR.is_dir():
        print(f"Error: {AGENTS_DIR} not found")
        sys.exit(1)

    total = 0
    files_changed = 0
    for md_file in sorted(AGENTS_DIR.rglob("*.md")):
        n = convert_file(md_file)
        if n:
            rel = md_file.relative_to(PROJECT_ROOT)
            print(f"  {rel}: {n} path(s) converted")
            total += n
            files_changed += 1

    print(f"\nDone: {total} path(s) converted across {files_changed} file(s).")

if __name__ == "__main__":
    main()
