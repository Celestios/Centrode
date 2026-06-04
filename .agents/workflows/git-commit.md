---
description: Unified Git & Release Management workflow to audit branch names, commit changes, synchronize package versions, and tag releases.
---

# Workflow: Git & Release Manager (/git-commit)

This workflow guides the agent and developer through validating branch names, committing workspace changes with Conventional Commits, syncing version numbers between the Flutter app and Rust core, and creating release tags.

---

## Branch Naming Standards

To keep the repository clean and maintain parity with Conventional Commit scopes, all feature, fix, and refactoring branches should follow a standardized naming convention:

### Format
`<type>/<scope>-<kebab-case-description>`

Where:
* **`<type>`**: Must be one of `feat`, `fix`, `refactor`, `perf`, `docs`, `chore`, `test`.
* **`<scope>`**: Standard scopes representing the feature domain:
  * `graph` - Entire graph data structures, sync, or coordination.
  * `node` - Node fields, styling, layouts, node interactions.
  * `relation` - Relation paths, styles, port connections, layout strategies.
  * `tags` - Tag CRUD, tag attachments, tagging UI.
  * `ui` - General UI components, panels, canvas overlay, toolbar, zoom, panning.
  * `ffi` - Flutter-Rust bridge, bindings, serialization.
  * `db` - Rust SurrealDB implementation, transactions, queries.
  * `workflow` - Agent prompts, workflows, CI/CD, scripting.
* **`<kebab-case-description>`**: A concise, lowercase, hyphenated summary of the task (e.g., `relation-styles`).

### Examples
* `feat/graph-relation-styles`
* `fix/ui-toolbar-overflow`
* `refactor/ffi-tag-serialization`
* `perf/node-rendering`
* `feat/tags-node-attachment`

---

## Steps

### 1. Workspace Analysis & Branch Verification
- **Task**: Inspect active changes, validate branch naming, and verify scope relevance.
- **Action**:
  - Run the preparation command:
    ```powershell
    powershell -ExecutionPolicy Bypass -File ./scripts/git-commit.ps1 -Prepare
    ```
  - **Read Analysis Outputs**:
    - Read `file:///.git/active_branch.txt` to see the current branch name.
    - Read `file:///.git/active_status.txt` to inspect the git status.
    - Read `file:///.git/active_diff.patch` to review the unified diff of changes.
    - Read `file:///.git/active_validation.json` to verify the branch validation status and check for scope mismatch warnings.
  - **Verify Branch Context**:
    - If `active_validation.json` reports any warnings (e.g. branch name format is invalid, scope does not match the modified files, or user is committing to `main`/`master`), display these warnings to the user.
    - If the branch name is invalid (e.g. not in `<type>/<scope>-<kebab-case-description>` format), prompt the user and offer to rename it using `git branch -m <new-name>`.

---

### Action Option 1: Standard Commit

#### A. Commit Message Drafting
- Formulate a Conventional Commit message based on the changes in `.git/active_diff.patch`:
  - **Header format**: `<type>(<scope>): <subject>` (or `<type>: <subject>` if no scope).
  - **Type**: Must match the branch type (e.g., `feat`, `fix`, `refactor`).
  - **Subject rules**: Standard lowercase, imperative mood ("add feature" not "added feature"), no trailing period, strictly under `max_subject_length` (default 50) characters.
  - **Body**: (Optional) Explain *why* the changes were made and *what* was done. Wrap lines at `72` characters.
  - **Footer**: Include breaking changes (`BREAKING CHANGE: <description>`) if it is a breaking change.

#### B. Execution
- Run the commit command with direct parameters (recommended for speed and automation):
  ```powershell
  powershell -ExecutionPolicy Bypass -File ./scripts/git-commit.ps1 -CommitMsg "<message-text>" -Stage "file/path/or/pattern1", "pattern2"
  ```
  *(Pass `-StageAll` instead of `-Stage` to automatically stage all changes in the workspace).*
- Alternatively, draft the message in a file first:
  - Write the message to a temporary file: `.git/proposed_commit_msg.txt`.
  - Display the drafted message and list of affected files to the user.
  - Execute the commit:
    ```powershell
    powershell -ExecutionPolicy Bypass -File ./scripts/git-commit.ps1 -CommitMsgFile .git/proposed_commit_msg.txt
    ```
- When committing, the script automatically applies your staging preferences, validates the commit format, commits, and removes temporary workspace report files (`active_status.txt`, `active_branch.txt`, `active_diff.patch`, `active_validation.json`).

---

### Action Option 2: Bilingual Version Sync

#### A. Action
- Prompt the user to choose a bump strategy: `minor`, `patch`, `build`, or a custom version string (e.g., `0.2.0`).
- Run the version sync command:
  ```powershell
  powershell -ExecutionPolicy Bypass -File ./scripts/git-commit.ps1 -SyncVersion <bump-strategy>
  ```
- Review the modified `pubspec.yaml` and `rust/Cargo.toml` files.

---

### Action Option 3: Prepare Tagged Release

#### A. Determine Version Bump
- Analyze current versions in `pubspec.yaml` and `rust/Cargo.toml`.
- Determine whether a `minor` or `patch` bump is appropriate.

#### B. Execute Release
- Run the release preparation command:
  ```powershell
  powershell -ExecutionPolicy Bypass -File ./scripts/git-commit.ps1 -PrepareRelease <bump-strategy>
  ```
- The script will bump versions, stage modified files, commit the release (`chore(release): bump version to <version>`), and tag it locally with an annotated tag `v<version>`.
- Instruct the user to push the release tag to the remote origin:
  ```powershell
  git push origin main --tags
  ```
