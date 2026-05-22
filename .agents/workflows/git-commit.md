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

### 1. Branch Naming & Workspace Analysis
- **Task**: Inspect active changes and validate the current branch configuration.
- **Action**:
  - Run `git status` to see staged, unstaged, and untracked files.
  - Run `git branch --show-current` to identify the current branch name.
  - **Verify Branch Context**:
    - If the current branch is `main` or `master`, confirm that the user is ONLY performing a release (`Action Option 3`). Direct commits of features, bug fixes, or refactoring to `main` are strictly blocked.
    - If the current branch is a feature/bug-fix branch:
      1. Verify that it matches the `<type>/<scope>-<description>` format. If it does not, warn the user and offer to rename it (e.g., `git branch -m <new-name>`).
      2. **Verify Relevance**: Compare the modified files with the branch's `<scope>`. If the changes do not relate to the branch's scope (e.g., you are on `feat/tags-node-attachment` but the only changes are under `lib/features/graph/ui/widgets/relations/`), alert the user, point out the mismatch, and offer to branch off to a relevant branch instead of committing to the current branch.

### 2. Initial Configuration (Action Type & Variables)
- **Task**: Determine what action to perform and configure options.
- **Rules**:
  - **Implicit Flow (Default)**: If the user requested a standard commit (e.g. "/git-commit" or "commit changes") and did not request custom variables or a release/sync, **automatically select Standard Commit and proceed using defaults**. Do not prompt the user for configuration or confirmation at this stage.
  - **Explicit Flow**: Prompt for action type or variable overrides only if the user explicitly asks to tweak them or if the intent is ambiguous.
- **Action Types**:
  1. **Standard Commit**: Stage changes and draft a Conventional Commit message.
  2. **Bilingual Version Sync**: Sync Dart and Rust versions manually or bump the build number.
  3. **Prepare Tagged Release**: Sync version, commit the bump, and tag a release (allowed on `main`).
- **Customizable Variables** (Apply to Standard Commit):
  | Variable | Default Value | Description |
  | :--- | :--- | :--- |
  | `max_subject_length` | `50` | Maximum character length for the subject line. (Hard limit of 72 is maintained). |
  | `max_body_line_length` | `72` | Wrap limit for lines in the body of the commit message. |
  | `commit_style` | `Conventional Commits` | The standard to follow (e.g., "Conventional Commits", "Detailed", "Minimal"). |
  | `detail_level` | `high` | Level of explanation in the body: `high` (full rationale + detailed changes), `medium` (brief summary of changes), or `low` (subject-line only). |
  | `scope` | *Auto-detected* | The optional scope for the commit header. |
  | `breaking_change` | `false` | Whether to flag the commit as a breaking change (adds `!` to the header). |
  | `custom_focus` | *None* | A user-provided instruction or context to emphasize in the commit message. |

---

### Action Option 1: Standard Commit

#### A. Direct Commit to Main Protection
- **Rule**: If the current branch is `main` or `master`:
  1. Draft the Conventional Commit message first to obtain the `<type>`, `<scope>`, and `<subject>`.
  2. Auto-generate a branch name from the draft commit header: `<type>/<scope>-<kebab-case-subject-slug>`.
     * *Example:* For `feat(ui): add orthogonal line routes`, generate `feat/ui-add-orthogonal-line-routes`.
  3. Automatically run `git checkout -b <branch-name>` to create and check out the new branch.
  4. Continue the commit execution on this new branch.

#### B. Parameter Auto-Detection (Non-main Branch)
- Extract `<type>` and `<scope>` from the branch name (if it follows the standard) and pre-fill them as defaults. For instance, if the branch is `feat/ui-floating-toolbar`, set the default commit type to `feat` and scope to `ui`.

#### C. Commit Message Drafting
- Formulate a commit message matching the Conventional Commits specification:
  - **Header format**: `<type>(<scope>): <subject>` (or `<type>: <subject>` if no scope).
  - **Type**: Must match the branch type (e.g. `feat`, `fix`, `refactor`).
  - **Subject rules**: Standard lowercase, imperative mood ("add feature" not "added feature"), no trailing period, strictly under `max_subject_length` characters.
  - **Body**: Separate from header with a blank line. Explain *why* the changes were made and *what* was done. Wrap lines at `max_body_line_length`.
  - **Footer**: Include breaking changes (`BREAKING CHANGE: <description>`) if `breaking_change` is true.

#### D. Review & Execution
- Display the generated message in a code block and list the affected files.
- If a new branch was auto-created, clearly notify the user: `Branch '<branch-name>' was successfully created and checked out.`
- Provide the user options to:
  1. **Commit Staged Changes**: Commit currently staged changes.
  2. **Stage & Commit All**: Stage all tracked/untracked changes, then commit.
  3. **Abort**: Cancel the process.
- **PAUSE** execution and wait for the user to make a choice or provide feedback.
- Execute the commit. To avoid complex command-line escaping, write the commit message to a temporary file (`.git/temp_commit_msg.txt`), run `git commit -F .git/temp_commit_msg.txt`, and delete the file.

---

### Action Option 2: Bilingual Version Sync

#### A. Action
- Prompt the user to choose a bump strategy: `minor`, `patch`, `build`, or a custom version string (e.g., `0.2.0`).
- Run the Dart synchronization script:
  ```powershell
  dart scripts/sync_version.dart <bump-strategy>
  ```
- Review the modified `pubspec.yaml` and `rust/Cargo.toml` files.

---

### Action Option 3: Prepare Tagged Release

#### A. Determine Version Bump
- Analyze current versions in `pubspec.yaml` and `rust/Cargo.toml`.
- Determine whether a `minor` or `patch` bump is appropriate based on the commits since the last release tag (or ask the user directly).

#### B. Sync & Commit Release
- Run `dart scripts/sync_version.dart <bump-strategy>` to synchronize files.
- Stage the version changes: `git add pubspec.yaml rust/Cargo.toml`.
- Create a release commit using a message matching:
  ```
  chore(release): bump version to <new-version>
  ```

#### C. Tag the Release
- Draft and run the git tag command using an annotated tag:
  ```powershell
  git tag -a v<new-version> -m "Release v<new-version>"
  ```
- Instruct the user to push the new release to the remote origin:
  ```powershell
  git push origin main --tags
  ```
