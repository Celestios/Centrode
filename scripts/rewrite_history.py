"""
Safe git history rewriting script.
Removes specific .py files from the last 3 commits while preserving them in the working directory.

Uses git rebase with GIT_SEQUENCE_EDITOR for safe, non-interactive history editing.
All dirty files are backed up to temp dirs (not git stash) since rebase invalidates stash refs.
"""

import subprocess
import shutil
import os
import sys
import tempfile

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(REPO_ROOT)

PY_FILES_TO_REMOVE = [
    "scripts/fix_command_target_id.py",
    "scripts/fix_generated_ui.py",
    "scripts/fix_test_files.py",
    "scripts/fix_test_files_v2.py",
    "scripts/fix_ui_errors.py",
    "scripts/layer6_fix_remaining.py",
    "scripts/layer6_identify.py",
    "scripts/layer6_replace.py",
    "scripts/layer6_safe_replace.py",
]

COMMIT_COUNT = 3


def run(cmd, **kwargs):
    print(f"  > {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    if result.returncode != 0 and kwargs.get("check", False):
        print(f"  ERROR: {result.stderr.strip()}")
        sys.exit(1)
    return result


def backup_py_files():
    backup_dir = tempfile.mkdtemp(prefix="py_scripts_")
    backed = []
    for f in PY_FILES_TO_REMOVE:
        if os.path.exists(f):
            dest = os.path.join(backup_dir, os.path.basename(f))
            shutil.copy2(f, dest)
            backed.append(f)
            print(f"  Backed up: {f}")
    return backup_dir, backed


def restore_py_files(backup_dir, backed):
    for f in backed:
        src = os.path.join(backup_dir, os.path.basename(f))
        shutil.copy2(src, f)
        print(f"  Restored: {f}")
    shutil.rmtree(backup_dir)


def backup_dirty_files():
    """Save all modified/untracked files to temp dir, keyed by relative path."""
    status = run(["git", "status", "--porcelain"])
    lines = [l for l in status.stdout.strip().split("\n") if l.strip()]
    if not lines:
        print("  Working tree clean.")
        return None

    backup_root = tempfile.mkdtemp(prefix="dirty_backup_")
    count = 0
    for line in lines:
        # status format: XY filename
        path = line[3:].strip().strip('"')
        if not os.path.exists(path):
            continue
        dest = os.path.join(backup_root, path.replace("/", "_").replace("\\", "_"))
        if os.path.isfile(path):
            shutil.copy2(path, dest)
            count += 1
        elif os.path.isdir(path):
            shutil.copytree(path, dest)
            count += 1

    # Save the raw status for restore
    with open(os.path.join(backup_root, "_STATUS.txt"), "w") as sf:
        sf.write(status.stdout)

    print(f"  Backed up {count} dirty file(s).")
    return backup_root


def restore_dirty_files(backup_root):
    """Restore modified/untracked files from backup."""
    if backup_root is None:
        return

    status_file = os.path.join(backup_root, "_STATUS.txt")
    if not os.path.exists(status_file):
        shutil.rmtree(backup_root)
        return

    with open(status_file, "r") as sf:
        lines = [l for l in sf.read().strip().split("\n") if l.strip()]

    restored = 0
    for line in lines:
        path = line[3:].strip().strip('"')
        backup_key = path.replace("/", "_").replace("\\", "_")
        backup_path = os.path.join(backup_root, backup_key)
        if os.path.exists(backup_path):
            if os.path.isfile(backup_path):
                os.makedirs(os.path.dirname(path) if os.path.dirname(path) else ".", exist_ok=True)
                shutil.copy2(backup_path, path)
                restored += 1
            elif os.path.isdir(backup_path):
                if os.path.exists(path):
                    shutil.rmtree(path)
                shutil.copytree(backup_path, path)
                restored += 1

    shutil.rmtree(backup_root)
    print(f"  Restored {restored} dirty file(s).")


def clean_tree():
    """Remove all untracked files and reset modified files to get a clean tree for rebase."""
    run(["git", "checkout", "--", "."])
    run(["git", "clean", "-fd"])


def create_editor_script():
    script_path = os.path.join(tempfile.gettempdir(), "rebase_editor.py")
    with open(script_path, "w") as ef:
        ef.write(
            """import sys
todo_file = sys.argv[1]
with open(todo_file, "r") as f:
    lines = f.readlines()
with open(todo_file, "w") as f:
    for line in lines:
        if line.startswith("pick "):
            f.write("edit " + line[5:])
        else:
            f.write(line)
"""
        )
    return script_path


def main():
    print("=== Git History Rewrite ===")
    print(f"Removing {len(PY_FILES_TO_REMOVE)} .py files from last {COMMIT_COUNT} commits\n")

    # 1. Backup .py scripts
    print("[1/7] Backing up .py scripts...")
    py_backup, py_backed = backup_py_files()
    if not py_backed:
        print("  No .py files found. Aborting.")
        sys.exit(1)

    # 2. Backup ALL dirty files
    print("\n[2/7] Backing up dirty files...")
    dirty_backup = backup_dirty_files()

    # 3. Clean the working tree (safe now that everything is backed up)
    print("\n[3/7] Cleaning working tree for rebase...")
    clean_tree()

    # 4. Create editor script
    print("\n[4/7] Preparing rebase editor...")
    editor_script = create_editor_script()

    # 5. Start rebase
    print(f"\n[5/7] Starting rebase of last {COMMIT_COUNT} commits...")
    env = os.environ.copy()
    env["GIT_SEQUENCE_EDITOR"] = f'python "{editor_script}"'
    env["GIT_EDITOR"] = "true"
    env["GIT_MERGE_AUTOEDIT"] = "false"

    result = run(["git", "rebase", "-i", f"HEAD~{COMMIT_COUNT}"], env=env)
    if result.returncode != 0:
        print(f"  Rebase failed: {result.stderr.strip()}")
        run(["git", "rebase", "--abort"])
        restore_py_files(py_backup, py_backed)
        restore_dirty_files(dirty_backup)
        sys.exit(1)

    # 6. Edit each commit
    print(f"\n[6/7] Editing commits to remove .py files...")
    for i in range(COMMIT_COUNT):
        print(f"\n  --- Commit {i + 1}/{COMMIT_COUNT} ---")
        run(["git", "log", "-1", "--oneline"])

        for f in PY_FILES_TO_REMOVE:
            run(["git", "rm", "--cached", "--ignore-unmatch", f])

        diff_cached = run(["git", "diff", "--cached", "--name-only"])
        if diff_cached.stdout.strip():
            run(["git", "commit", "--amend", "--no-edit"])
            print(f"  Amended.")
        else:
            print(f"  No .py files here, skipping.")

        env2 = os.environ.copy()
        env2["GIT_EDITOR"] = "true"
        env2["GIT_MERGE_AUTOEDIT"] = "false"
        result = run(["git", "rebase", "--continue"], env=env2)
        if result.returncode != 0:
            if "No changes" in (result.stdout + result.stderr):
                run(["git", "rebase", "--skip"])
            else:
                print(f"  Rebase continue failed: {result.stderr.strip()}")
                run(["git", "rebase", "--abort"])
                restore_py_files(py_backup, py_backed)
                restore_dirty_files(dirty_backup)
                sys.exit(1)

    # 7. Restore everything
    print(f"\n[7/7] Restoring files...")
    restore_py_files(py_backup, py_backed)
    restore_dirty_files(dirty_backup)

    # Verify
    print("\n=== Done! ===\n")
    run(["git", "log", "--oneline", f"-{COMMIT_COUNT}"])
    print()
    for f in PY_FILES_TO_REMOVE:
        tag = "OK" if os.path.exists(f) else "MISSING"
        print(f"  [{tag}] {f}")

    tracked = run(["git", "ls-files", "--"] + PY_FILES_TO_REMOVE)
    if tracked.stdout.strip():
        print(f"\n  WARNING: Still tracked:")
        for line in tracked.stdout.strip().split("\n"):
            print(f"    {line}")
    else:
        print("\n  All .py files removed from git history (exist on disk as untracked).")


if __name__ == "__main__":
    main()
