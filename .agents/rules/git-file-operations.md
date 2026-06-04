---
trigger: always_on
description: Rules for performing file operations like deletions, renames, and moves using Git.
---

## Git File Operations

Rules:
- **Deletions**: Always delete files using `git rm` rather than standard file deletion commands or tools, so that Git explicitly tracks the deletion.
- **Renames & Moves**: Always rename or move files using `git mv` rather than deleting and creating, or using standard file system move operations, to ensure Git preserves the file history and tracks the move.
- **Verification**: After deleting, renaming, or moving files, verify the status using `git status` to ensure the changes are correctly staged.
