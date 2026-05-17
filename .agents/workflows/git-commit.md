---
description: Generate a standard-compliant Git commit message from staged or unstaged changes, customize it via variables, and commit the changes.
---

# Workflow: /git-commit

This workflow guides the agent through analyzing active workspace changes, configuring commit options via parameters, generating a high-quality commit message adhering to standard conventions (Conventional Commits), and executing the git commit with the user's approval.

## Customizable Variables

When executing this workflow, the agent must check and allow the user to tweak the following configuration variables:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `max_subject_length` | `50` | Maximum character length for the subject line. (Hard limit of 72 is maintained). |
| `max_body_line_length` | `72` | Wrap limit for lines in the body of the commit message. |
| `commit_style` | `Conventional Commits` | The standard to follow (e.g., "Conventional Commits", "Detailed", "Minimal"). |
| `detail_level` | `high` | Level of explanation in the body: `high` (full rationale + detailed changes), `medium` (brief summary of changes), or `low` (subject-line only). |
| `scope` | *Auto-detected* | The optional scope for the commit header (e.g., `core`, `ui`, `ffi`, `docs`, `workflow`). |
| `breaking_change` | `false` | Whether to flag the commit as a breaking change (adds `!` to the header and appends a footer). |
| `custom_focus` | *None* | A user-provided instruction or context to emphasize in the commit message (e.g., "emphasize FFI improvements"). |

---

## Steps

### 1. Change Analysis & Discovery
- **Task**: Identify what changes are currently in the workspace.
- **Action**:
  - Run `git status` to see staged, unstaged, and untracked files.
  - Run `git diff --cached` to inspect staged modifications.
  - Run `git diff` to inspect unstaged modifications.
  - Summarize the affected modules, packages, or architectural layers.

### 2. Variable Configuration
- **Task**: Inform the user about the active parameters.
- **Action**:
  - Present a brief summary of the changes detected.
  - List the active variables (using defaults above or values explicitly requested by the user).
  - Give the user a quick chance to override these before generation (e.g., "I'm going to generate a message. Let me know if you want to change any limits or focus!").

### 3. Commit Message Drafting
- **Task**: Generate the commit message following the configured parameters and conventional standards.
- **Action**:
  - Formulate a commit message matching the selected `commit_style` (default: **Conventional Commits**):
    - **Header format**: `<type>(<scope>): <subject>` (or `<type>: <subject>` if no scope).
    - **Type**: Must be one of `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `build`, `ci`, or `revert`.
    - **Subject rules**: Standard lowercase, imperative mood ("add feature" not "added feature"), no trailing period, strictly under `max_subject_length` characters.
    - **Body**: Separate from header with a blank line. Wrap lines at `max_body_line_length`. Explain *why* the changes were made and *what* was done. Respect the `detail_level`.
    - **Footer**: Include breaking changes (`BREAKING CHANGE: <description>`) if `breaking_change` is true, and any issue references (e.g., `Closes #123`).
  
### 4. Interactive Review & Tweaks
- **Task**: Present the draft message and offer commit/tweak options.
- **Action**:
  - Display the generated message in a clear git-commit code block.
  - Display the list of files that will be included in the commit.
  - Present the user with a list of interactive choices to choose from:
    1. **Commit Staged Changes**: Commit currently staged changes using the generated message.
    2. **Stage & Commit All**: Stage all tracked/untracked changes, then commit with the message.
    3. **Tweak Variables**: Let the user adjust parameters (e.g. "change character limit to 70", "make detail level low") and regenerate.
    4. **Manual Edit**: Accept a user's edited version of the message.
    5. **Abort**: Cancel the process.
  - **PAUSE** execution and wait for the user to make a choice or provide feedback.

### 5. Git Execution
- **Task**: Perform the selected git actions.
- **Action**:
  - If Option 1: Execute `git commit -m "<message>"`.
  - If Option 2: Execute `git add -A` followed by `git commit -m "<message>"`.
  - Report the output of the git command, including the new commit hash and a success message.
