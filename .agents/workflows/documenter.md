# Documenter Workflow

Update `docs/wiki/` to reflect codebase changes. Ensures wiki stays consistent with the actual code and with itself.

## Trigger

This workflow runs when:
- A feature is implemented or refactored (after `/implementer`)
- A bug fix changes behavior (after `/bug-fixer`)
- A code health audit identifies documentation gaps (after `/code-health`)
- Manually requested via `/documenter`

## Steps

### 1. Load the wiki consistency skill

```
read_file(D:/Projects/Open/flutter/code/centrode/.agents/skills/documentation/wiki-consistency/SKILL.md)
```

Follow all rules and conventions defined there.

### 2. Identify affected wiki pages

Run git diff to find changed source files:
```bash
git diff --name-only HEAD~1
```

Map changed files to wiki pages using this cross-reference:

| Source Path | Wiki Page(s) |
|-------------|-------------|
| `lib/features/graph/models/graph_node.dart` | `modules/graph/node-types.md`, `architecture/overview.md` |
| `lib/features/graph/models/commands/` | `modules/graph/commands.md` |
| `lib/features/graph/store/` | `modules/graph/store.md` |
| `lib/features/graph/engine/` | `modules/graph/interaction-engine.md` |
| `lib/features/graph/ui/canvas/` | `modules/graph/canvas.md` |
| `lib/features/graph/presentation/` | `modules/graph/presentation.md` |
| `rust/src/domain/` | `backend/domain.md` |
| `rust/src/persistence/` | `backend/persistence.md` |
| `rust/src/relation_engine/` | `backend/relation-engine.md` |
| `rust/src/layout_engine/` | `backend/layout-engine.md` |
| `rust/src/services/` | `backend/services.md` |
| `rust/src/bridge/` | `ffi/README.md`, `ffi/api-surface.md` |
| `rust/src/format/` | `backend/format.md` |
| `lib/features/workspace/` | `modules/workspace/README.md` |
| `lib/shared/` | `modules/shared/README.md` |
| `lib/infrastructure/` | `modules/infrastructure/README.md` |

### 3. Read and analyze each affected page

For each wiki page that maps to changed source files:
```
read_file(D:/Projects/Open/flutter/code/centrode/docs/wiki/<page>.md)
```

Check for:
- Descriptions that no longer match the code
- File counts or module counts that changed
- New classes, functions, or patterns that should be documented
- Removed features that should be cleaned up from docs

### 4. Verify factual claims against code

For numerical claims in wiki files, verify against the actual codebase:

```bash
# Count node types
rg "class \w+UiNode" lib/features/graph/models/ --count

# Count commands
rg "class \w+Command " lib/features/graph/models/commands/ --count

# Count store modules
ls lib/features/graph/store/modules/ | measure

# Count FSM states
rg "class \w+State " lib/features/graph/engine/states/ --count
```

Update any wiki file where the count doesn't match.

### 5. Update affected wiki pages

Apply changes following the wiki consistency rules:
- Maintain heading hierarchy
- Update cross-references
- Keep link text aligned with page headings
- Add new concept cross-references where appropriate
- Update INDEX.md if adding new pages

### 6. Run consistency check

```bash
dart scripts/check_wiki_consistency.dart
```

Fix any issues found. The script must exit with code 0.

### 7. Update INDEX.md "Last verified" date

In `docs/wiki/INDEX.md`, update the `Last verified` date to today:
```markdown
> Last verified: YYYY-MM-DD
```

### 8. Summary

Report what was updated:
- Which wiki pages were modified
- What factual claims were verified or corrected
- Any new cross-references added
- Consistency check result (pass/fail)

## Handling New Features

When a new feature is added that doesn't map to existing wiki pages:

1. Create a new wiki page following naming conventions (kebab-case.md)
2. Place it in the correct directory (`modules/`, `backend/`, `design/`, etc.)
3. Add it to INDEX.md in the appropriate section
4. Add cross-references from related pages
5. Run consistency check

## Handling Removed Features

When code is deleted:

1. Remove or update references in wiki pages
2. Remove the page from INDEX.md
3. Delete the wiki file (use `git rm` to preserve history)
4. Check for orphaned inbound links from other wiki files
5. Run consistency check
