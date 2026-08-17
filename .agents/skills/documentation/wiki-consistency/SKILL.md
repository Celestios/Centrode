# Wiki Consistency Skill

Activate this skill when editing, creating, or reviewing any file under `docs/wiki/`. Ensures cross-file consistency through pre-edit checks, inline rules, and post-edit validation.

## Pre-Edit Checklist

Before modifying any wiki file, run these checks:

### 1. Read the target file and its neighbors
```
read_file(docs/wiki/<target>.md)
```
Understand the existing structure, heading hierarchy, and cross-references before making changes.

### 2. Check what links TO this file
Use grep to find all inbound references:
```
grep(pattern='\[.*\]\(.*<filename>', path='docs/wiki', include='*.md')
```
These files may need updates if you rename headings or change the file's purpose.

### 3. Run the consistency checker
```bash
dart scripts/check_wiki_consistency.dart --json
```
Review the JSON output for existing issues. Fix any broken links or conflicts before introducing new ones.

## Cross-Reference Rules

### Linking between wiki files
- **Always use relative paths** from the current file's directory
- **Never use absolute paths** (e.g., `docs/wiki/backend/domain.md`)
- **Use `../` prefix** to go up directories (e.g., `../../design/shaders.md`)
- **Verify the link target exists** before committing

### Heading anchors
- Links to headings use `#` suffix: `[text](file.md#heading-name)`
- Anchors are derived from headings: lowercase, spaces to hyphens, strip non-alphanumeric
- After renaming a heading, search for all `#old-heading` references and update them

### Concept cross-references
When mentioning a key concept that has its own wiki page, link to it on first mention:
- `The [GraphApi](modules/graph/store.md) abstract interface...`
- `The [UiNode](modules/graph/node-types.md) sealed class...`

Key concepts and their canonical pages:
| Concept | Canonical Page |
|---------|---------------|
| UiNode | `modules/graph/node-types.md` |
| GraphApi | `modules/graph/store.md` |
| GraphCommand | `modules/graph/commands.md` |
| InteractionEngine | `modules/graph/interaction-engine.md` |
| AppHandle | `ffi/README.md` |
| Repository | `backend/persistence.md` |
| GraphService | `backend/services.md` |
| RelationEngine | `backend/relation_engine.md` |
| LayoutEngine | `backend/layout-engine.md` |
| SurrealDB | `backend/persistence.md` |
| FRB / Flutter Rust Bridge | `ffi/README.md` |
| .cent format | `backend/format.md` |

### INDEX.md synchronization
- Every new wiki page MUST be added to `docs/wiki/INDEX.md`
- Place it in the correct section with a one-line description
- Use the same link text as the page's `# Heading`
- Verify after adding: `dart scripts/check_wiki_consistency.dart`

## Consistency Invariants

These must always hold across the wiki:

1. **No orphan pages**: Every `.md` file (except INDEX.md) must be linked from at least one other page or from INDEX.md
2. **No broken links**: Every `[text](target.md)` must resolve to an existing file
3. **No conflicting facts**: Numerical claims (node types, commands, modules, etc.) must be identical across all files that mention them
4. **No description drift**: INDEX.md link text should match the actual page `# Heading`
5. **No missing anchors**: Links to `#heading` must target an existing heading in the target file

## Post-Edit Validation

After making changes to wiki files:

### Step 1: Validate your changes
```bash
dart scripts/check_wiki_consistency.dart
```
Exit code 0 = clean, 1 = issues found.

### Step 2: Check affected files
If you changed a heading, grep for old anchor references:
```
grep(pattern='#old-heading-name', path='docs/wiki', include='*.md')
```

### Step 3: Verify INDEX.md
If you created a new file, ensure it's in INDEX.md. If you renamed a file, update INDEX.md.

### Step 4: Verify inbound links
If you renamed a heading or changed file purpose, check all files that link to this file:
```
grep(pattern='<filename>', path='docs/wiki', include='*.md')
```

## File Naming Conventions

- Use `kebab-case.md` for all wiki files
- Use `README.md` for module/index pages
- Match the filename to the concept: `relation-engine.md` for the relation engine docs
- Avoid spaces, underscores, or camelCase in filenames

## Table Formatting

Wiki tables should use consistent column headers within each section:

| Section | Expected Columns |
|---------|-----------------|
| Module tables | `Module`, `Path`, `Responsibility` |
| File tables | `File`, `Role` |
| Command tables | `Command`, `Category`, `Debounced?`, `Undoable?`, `FFI Target` |
| Node type tables | `Property`, `Type`, `Description` |

## Auto-Fix Mode

The consistency script supports auto-fixing common issues:
```bash
dart scripts/check_wiki_consistency.dart --fix
```

Auto-fix capabilities:
- Adds missing pages to INDEX.md under the correct section
- Updates INDEX.md link text to match actual page headings
- Adds `> **See also**` notes for unlinked concept references

Use `--fix` when bulk-updating the wiki, then review the changes.
