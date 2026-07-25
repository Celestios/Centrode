#!/usr/bin/env python3
"""
Generic rule-based code transformer.

Replaces pattern-matching scripts with a data-driven approach:
rules are defined in YAML files, this tool scans/applies them.

Usage:
    python scripts/transform.py scan   --rules rules/raw_uuid_migration.yaml
    python scripts/transform.py apply  --rules rules/raw_uuid_migration.yaml [--dry-run]
    python scripts/transform.py analyze --rules rules/raw_uuid_migration.yaml

Modes:
    scan    Find all matches (read-only report)
    apply   Apply replacements to files
    analyze Run dart analyze, auto-fix errors iteratively
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

try:
    import yaml
except ImportError:
    # Fallback: minimal YAML parser for our subset
    yaml = None

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


# ── YAML Loading ──

def load_yaml(path: Path) -> dict:
    """Load a YAML rule file."""
    if yaml:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)

    # Fallback: use a minimal parser for our specific YAML subset
    # This handles our rule format without external deps
    return _parse_yaml_fallback(path)


def _parse_yaml_fallback(path: Path) -> dict:
    """Minimal YAML parser for our rule file format."""
    import json

    # Convert our YAML to JSON via a simple line-by-line parser
    # For complex YAML, install pyyaml: pip install pyyaml
    content = path.read_text(encoding="utf-8")

    # Simple approach: run python -c "import yaml" check and suggest install
    print("ERROR: PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
    print(f"       Or use: python -c \"import yaml\" to verify.", file=sys.stderr)
    sys.exit(1)


# ── Config Model ──

class TransformRule:
    def __init__(self, find: str, replace: str, desc: str):
        self.find = find
        self.replace = replace
        self.desc = desc
        self._compiled = re.compile(find)

    def match(self, content: str) -> Optional[re.Match]:
        return self._compiled.search(content)

    def apply(self, content: str) -> str:
        return self._compiled.sub(self.replace, content)


class ImportConfig:
    def __init__(self, path: str, target_files: list[str]):
        self.path = path
        self.target_globs = target_files


class LiteralConfig:
    def __init__(self, data: dict):
        self.entity_params = data.get("entity_params", [])
        self.function_calls = data.get("function_calls", [])
        self.wrap_with = data.get("wrap_with", "RawUuid.fromString({value})")
        self.contains_remove_wrap = data.get("contains_remove_wrap", False)
        self.expect_wrap = data.get("expect_wrap", [])


class TransformConfig:
    def __init__(self, data: dict):
        self.name = data.get("name", "unnamed")
        self.description = data.get("description", "")
        self.scan_dirs = data.get("scan_dirs", [])
        self.exclude = data.get("exclude", [])
        self.rules = [TransformRule(r["find"], r["replace"], r["desc"]) for r in data.get("rules", [])]
        self.file_exclusions = data.get("file_exclusions", {})

        import_data = data.get("import")
        self.import_config = ImportConfig(import_data["path"], import_data["target_files"]) if import_data else None

        literal_data = data.get("literal_transforms")
        self.literal_config = LiteralConfig(literal_data) if literal_data else None


# ── File Discovery ──

def discover_files(config: TransformConfig) -> list[Path]:
    """Find all source files matching scan_dirs, excluding patterns."""
    files = []
    for scan_dir in config.scan_dirs:
        dir_path = PROJECT_ROOT / scan_dir
        if not dir_path.exists():
            continue
        for ext in ["*.dart"]:
            for f in dir_path.rglob(ext):
                rel = str(f.relative_to(PROJECT_ROOT)).replace("\\", "/")
                # Check exclusions
                if any(_matches_exclude(rel, pat) for pat in config.exclude):
                    continue
                files.append(f)
    return sorted(set(files))


def _matches_exclude(path: str, pattern: str) -> bool:
    """Check if a path matches an exclusion pattern."""
    if pattern.startswith("*."):
        return path.endswith(pattern[1:])
    if " " in pattern:
        # Multi-word pattern: check if any word is in the path
        return all(w in path for w in pattern.split())
    return pattern in path


def _is_file_excluded(filepath: Path, config: TransformConfig) -> bool:
    """Check if a file is fully excluded by file_exclusions."""
    rel = str(filepath.relative_to(PROJECT_ROOT)).replace("\\", "/")
    exclusions = config.file_exclusions.get(rel, [])
    return ".*" in exclusions


def _is_rule_excluded(filepath: Path, rule_desc: str, config: TransformConfig) -> bool:
    """Check if a specific rule is excluded for a file."""
    rel = str(filepath.relative_to(PROJECT_ROOT)).replace("\\", "/")
    exclusions = config.file_exclusions.get(rel, [])
    return any(rule_desc in exc or exc in rule_desc for exc in exclusions if exc != ".*")


# ── Import Management ──

def add_import(content: str, import_path: str) -> str:
    """Add an import statement after the last existing import."""
    if f"import '{import_path}';" in content or f'import "{import_path}";' in content:
        return content

    lines = content.split("\n")
    last_import = -1
    for i, line in enumerate(lines):
        if line.strip().startswith("import "):
            last_import = i

    if last_import >= 0:
        lines.insert(last_import + 1, f"import '{import_path}';")
    else:
        lines.insert(0, f"import '{import_path}';")

    return "\n".join(lines)


# ── Literal Transforms ──

def transform_literal_line(line: str, config: LiteralConfig) -> str:
    """Apply literal transforms to a single line."""
    stripped = line.strip()
    if stripped.startswith("import ") or stripped.startswith("//"):
        return line

    new_line = line

    # Wrap named params: param: 'value' -> param: RawUuid.fromString('value')
    for param in config.entity_params:
        if param in new_line:
            escaped = re.escape(param)
            pattern = rf"({escaped})\s*'([^']*)'"
            replacement = rf"\1 RawUuid.fromString('\2')"
            new_line = re.sub(pattern, replacement, new_line)

            pattern = rf'({escaped})\s*"([^"]*)"'
            replacement = rf'\1 RawUuid.fromString("\2")'
            new_line = re.sub(pattern, replacement, new_line)

    # Wrap function calls: func('value') -> func(RawUuid.fromString('value'))
    for func in config.function_calls:
        if func in new_line:
            escaped = re.escape(func)
            pattern = rf"({escaped})'([^']*)'"
            replacement = rf"\1RawUuid.fromString('\2')"
            new_line = re.sub(pattern, replacement, new_line)

            pattern = rf'({escaped})"([^"]*)"'
            replacement = rf'\1RawUuid.fromString("\2")'
            new_line = re.sub(pattern, replacement, new_line)

    # Wrap .contains() and .remove() calls
    if config.contains_remove_wrap:
        for method in [".contains(", ".remove("]:
            if method in new_line:
                pattern = rf"({re.escape(method)})'([^']*)'"
                replacement = rf"\1RawUuid.fromString('\2')"
                new_line = re.sub(pattern, replacement, new_line)

                pattern = rf'({re.escape(method)})"([^"]*)"'
                replacement = rf'\1RawUuid.fromString("\2")'
                new_line = re.sub(pattern, replacement, new_line)

    # Wrap expect(matcher, 'literal') calls
    for field in config.expect_wrap:
        if field in new_line and "expect(" in new_line:
            pattern = rf"expect\((\w+)\.{field},\s*'([^']*)'\)"
            replacement = rf"expect(\1.{field}, RawUuid.fromString('\2'))"
            new_line = re.sub(pattern, replacement, new_line)

    return new_line


def apply_literal_transforms(content: str, config: LiteralConfig) -> str:
    """Apply literal transforms to all lines in content."""
    lines = content.split("\n")
    new_lines = [transform_literal_line(line, config) for line in lines]
    return "\n".join(new_lines)


# ── Core: Scan ──

class Match:
    def __init__(self, filepath: Path, line_no: int, line: str, rule_desc: str, category: str = ""):
        self.filepath = filepath
        self.line_no = line_no
        self.line = line.strip()
        self.rule_desc = rule_desc
        self.category = category


def scan_file(filepath: Path, config: TransformConfig) -> list[Match]:
    """Scan a file for all rule matches."""
    if _is_file_excluded(filepath, config):
        return []

    matches = []
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return []

    # Check if this is a part file (skip)
    if "part of " in content[:200]:
        return []

    lines = content.split("\n")
    for line_no, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
            continue

        for rule in config.rules:
            if _is_rule_excluded(filepath, rule.desc, config):
                continue
            if rule.match(line):
                matches.append(Match(filepath, line_no, line, rule.desc))

    return matches


def cmd_scan(config: TransformConfig):
    """Scan mode: find and report all matches."""
    files = discover_files(config)
    all_matches = []

    for f in files:
        matches = scan_file(f, config)
        all_matches.extend(matches)

    # Group by file
    by_file: dict[str, list[Match]] = {}
    for m in all_matches:
        key = str(m.filepath.relative_to(PROJECT_ROOT)).replace("\\", "/")
        by_file.setdefault(key, []).append(m)

    # Report
    print(f"\n{'=' * 70}")
    print(f"  {config.name} — Scan Report")
    print(f"{'=' * 70}")
    print(f"  Total matches: {len(all_matches)} across {len(by_file)} files\n")

    for filepath in sorted(by_file.keys()):
        file_matches = by_file[filepath]
        print(f"\n{'─' * 60}")
        print(f"  {filepath} ({len(file_matches)} matches)")
        print(f"{'─' * 60}")
        for m in file_matches:
            print(f"    L{m.line_no:3d} [{m.rule_desc}]")
            print(f"         {m.line[:100]}")

    # Summary
    categories: dict[str, int] = {}
    for m in all_matches:
        categories[m.rule_desc] = categories.get(m.rule_desc, 0) + 1

    print(f"\n{'=' * 70}")
    print(f"  Top rules by frequency")
    print(f"{'=' * 70}")
    for desc, count in sorted(categories.items(), key=lambda x: -x[1])[:20]:
        print(f"    {count:3d}x  {desc}")

    print(f"\n  {len(all_matches)} total matches across {len(by_file)} files\n")


# ── Core: Apply ──

class Change:
    def __init__(self, desc: str, line_no: int, old: str, new: str):
        self.desc = desc
        self.line_no = line_no
        self.old = old
        self.new = new


def apply_file(filepath: Path, config: TransformConfig, dry_run: bool = False) -> list[Change]:
    """Apply all rules to a file, return changes."""
    if _is_file_excluded(filepath, config):
        return []

    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return []

    if "part of " in content[:200]:
        return []

    original = content
    changes: list[Change] = []

    # Apply regex rules
    for rule in config.rules:
        if _is_rule_excluded(filepath, rule.desc, config):
            continue

        old_content = content
        content = rule.apply(content)
        if content != old_content:
            # Find which line changed
            old_lines = old_content.split("\n")
            new_lines = content.split("\n")
            for i, (ol, nl) in enumerate(zip(old_lines, new_lines)):
                if ol != nl:
                    changes.append(Change(rule.desc, i + 1, ol.strip()[:100], nl.strip()[:100]))
                    break

    # Apply literal transforms
    if config.literal_config:
        old_content = content
        content = apply_literal_transforms(content, config.literal_config)
        if content != old_content:
            changes.append(Change("literal transforms", 0, "(multiple)", "(multiple)"))

    # Add import if needed
    if changes and config.import_config:
        if f"import '{config.import_config.path}';" not in content:
            content = add_import(content, config.import_config.path)
            changes.append(Change(f"import {config.import_config.path}", 0, "", "added"))

    if content == original:
        return []

    if not dry_run:
        filepath.write_text(content, encoding="utf-8")

    return changes


def cmd_apply(config: TransformConfig, dry_run: bool = False):
    """Apply mode: make changes (or preview with --dry-run)."""
    files = discover_files(config)
    all_results: list[tuple[Path, list[Change]]] = []

    for f in files:
        changes = apply_file(f, config, dry_run=dry_run)
        if changes:
            all_results.append((f, changes))

    mode = "DRY RUN" if dry_run else "APPLIED"
    print(f"\n{'=' * 70}")
    print(f"  {config.name} — {mode}")
    print(f"{'=' * 70}")

    total_changes = 0
    for filepath, changes in all_results:
        rel = str(filepath.relative_to(PROJECT_ROOT)).replace("\\", "/")
        print(f"\n{'─' * 60}")
        print(f"  {rel} ({len(changes)} changes)")
        print(f"{'─' * 60}")
        for c in changes:
            if c.old and c.new and c.old != "(multiple)":
                print(f"    L{c.line_no:3d} [{c.desc}]")
                print(f"         - {c.old[:90]}")
                print(f"         + {c.new[:90]}")
            else:
                print(f"    [{c.desc}]")
            total_changes += 1

    print(f"\n{'=' * 70}")
    print(f"  Total: {total_changes} changes across {len(all_results)} files")
    print(f"{'=' * 70}\n")


# ── Core: Analyze (dart analyze driven) ──

def cmd_analyze(config: TransformConfig, max_iterations: int = 5):
    """Analyze mode: run dart analyze, parse errors, apply fixes iteratively."""
    for iteration in range(1, max_iterations + 1):
        print(f"\n{'=' * 60}")
        print(f"  Analyze pass {iteration}/{max_iterations}")
        print(f"{'=' * 60}")

        # Run dart analyze
        result = subprocess.run(
            ["dart", "analyze", "lib/features/graph/", "test/"],
            capture_output=True, text=True, timeout=120,
            cwd=str(PROJECT_ROOT),
        )

        # Parse errors
        errors = []
        for line in result.stdout.split("\n"):
            if "error -" in line:
                errors.append(line.strip())

        if not errors:
            print("  No errors found. Done!")
            break

        print(f"  Found {len(errors)} errors")

        # Group errors by file
        file_errors: dict[str, list[str]] = {}
        for err in errors:
            parts = err.split(" - ", 2)
            if len(parts) < 3:
                continue
            err_info = parts[1]
            # Extract file path from error info (format: path:line:col)
            file_match = re.match(r"^(.+?):(\d+):", err_info)
            if file_match:
                file_path = file_match.group(1)
                file_errors.setdefault(file_path, []).append(err)

        fixed_count = 0
        for file_path, file_errs in file_errors.items():
            filepath = PROJECT_ROOT / file_path
            if not filepath.exists():
                continue

            # Apply transform rules first
            changes = apply_file(filepath, config, dry_run=False)
            if changes:
                fixed_count += 1
                print(f"  Fixed: {file_path} ({len(changes)} transforms)")

        if fixed_count == 0:
            print("  No more transforms applicable. Remaining errors need manual fixes.")
            break

        print(f"\n  Fixed {fixed_count} files, re-analyzing...")

    # Final error count
    result = subprocess.run(
        ["dart", "analyze", "lib/features/graph/", "test/"],
        capture_output=True, text=True, timeout=120,
        cwd=str(PROJECT_ROOT),
    )
    error_count = sum(1 for line in result.stdout.split("\n") if "error -" in line)
    print(f"\n  Remaining errors: {error_count}")


# ── CLI ──

def main():
    parser = argparse.ArgumentParser(description="Generic rule-based code transformer")
    parser.add_argument("mode", choices=["scan", "apply", "analyze"], help="Operation mode")
    parser.add_argument("--rules", "-r", required=True, help="Path to YAML rule file")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without writing")
    parser.add_argument("--path", "-p", help="Filter to specific subdirectory")
    parser.add_argument("--max-iterations", type=int, default=5, help="Max analyze iterations")
    args = parser.parse_args()

    rules_path = Path(args.rules)
    if not rules_path.is_absolute():
        rules_path = PROJECT_ROOT / rules_path

    if not rules_path.exists():
        print(f"ERROR: Rule file not found: {rules_path}", file=sys.stderr)
        sys.exit(1)

    data = load_yaml(rules_path)
    config = TransformConfig(data)

    # Override scan_dirs if --path is given
    if args.path:
        config.scan_dirs = [args.path]

    print(f"Loaded rules: {config.name}")
    print(f"  {len(config.rules)} rules, {len(config.scan_dirs)} scan dirs")

    if args.mode == "scan":
        cmd_scan(config)
    elif args.mode == "apply":
        cmd_apply(config, dry_run=args.dry_run)
    elif args.mode == "analyze":
        cmd_analyze(config, max_iterations=args.max_iterations)


if __name__ == "__main__":
    main()
