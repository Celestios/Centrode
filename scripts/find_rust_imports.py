#!/usr/bin/env python3
"""
Rust Import & Path Expression Detector
======================================

An automated diagnostic script to identify top-level imports, inline (non-top) `use` statements, 
and inline qualified path expressions (e.g. `crate::domain::...` or `std::sync::Arc`) in Rust source files.

Key Features & Rules:
---------------------
1. **Top Section Boundary Detection**:
   - The top preamble of a Rust file starts at line 1.
   - It permits shebangs (`#!`), module/crate doc comments (`//!`), inner/outer attributes (`#![...]`, `#[...]`), 
     comments, blank lines, and top-level `use` statements.
   - The preamble ends at the line index of the first code item declaration (such as `fn`, `struct`, `enum`, 
     `impl`, `trait`, `mod`, `const`, `static`, `macro_rules!`, `type`).
   - Any `use` statement or qualified path expression found after this boundary is classified as **non-top**.

2. **Test Exclusions**:
   - By default, test directories (`/tests/`), test files (`*_test.rs`, `*_tests.rs`), and inline `#[cfg(test)]` 
     or `#[test]` modules are excluded from analysis.
   - Pass `--include-tests` to include test code in the analysis.

3. **Crate / Inline Import Filtering**:
   - By default, the detector focuses on inline `use ...;` statements and path expressions explicitly starting with `crate::...`.
   - Pass `--all-paths` to match all path expressions containing `::`, and adjust `--min-colons` to control the depth of `::` separators.

Usage Examples:
---------------
  # Scan rust/src for non-top imports (excluding tests):
  python scripts/find_rust_imports.py --dir rust/src --only-non-top

  # Output full analysis in JSON format:
  python scripts/find_rust_imports.py --dir rust/src --json

  # Match all path expressions with at least 3 colons (e.g. A::B::C::D):
  python scripts/find_rust_imports.py --dir rust/src --all-paths --min-colons 3

  # Include tests and generated files:
  python scripts/find_rust_imports.py --dir rust/src --include-tests --include-generated
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

# Regular expressions for Rust code parsing
RE_USE_STMT = re.compile(r'^\s*(?:pub\s+(?:\([^)]+\)\s+)?)?use\s+([^;]+);')
RE_TOP_DECLARATION = re.compile(
    r'^\s*(?:pub(?:\([^)]+\))?\s+)?(?:async\s+)?(?:const\s+)?(?:unsafe\s+)?'
    r'\b(fn|struct|enum|union|impl|trait|mod|const|static|macro_rules!|type)\b'
)

# Regex to strip single-line comments and string literals for clean path matching
RE_SINGLE_LINE_COMMENT = re.compile(r'//.*$')
RE_STRING_LITERAL = re.compile(r'r#".*?"#|r".*?"|"(?:\\.|[^"\\])*"')
RE_PATH_EXPR = re.compile(r'\b(crate::[A-Za-z0-9_:]+|[A-Za-z0-9_]+::[A-Za-z0-9_:]+|::[A-Za-z0-9_:]+)\b')


def clean_line_code(line: str) -> str:
    """Strips comments and string literals from a Rust source code line.

    Args:
        line (str): Raw line of code from a Rust file.

    Returns:
        str: Cleaned code string free of single-line comments (`// ...`) and string literals (`"..."`).
    """
    line = RE_SINGLE_LINE_COMMENT.sub('', line)
    line = RE_STRING_LITERAL.sub('""', line)
    return line.strip()


def find_top_boundary(lines: List[str]) -> int:
    """Determines the line index (1-based) where the top-level import block (preamble) ends.

    The top block consists of shebangs (`#!`), module/crate doc comments (`//!`, `///`), 
    inner/outer attributes (`#![...]`, `#[...]`), blank lines, and top-level `use` statements.
    The boundary is defined by the line index of the first code item declaration 
    (`fn`, `struct`, `enum`, `impl`, `mod`, `trait`, `const`, `static`, etc.).

    Args:
        lines (List[str]): All lines of text from the Rust source file.

    Returns:
        int: 1-based line number representing the start of item declarations (end of top preamble).
    """
    in_block_comment = False
    first_code_item_line = len(lines) + 1

    for idx, line in enumerate(lines, start=1):
        stripped = line.strip()

        # Handle multiline block comments /* ... */
        if in_block_comment:
            if '*/' in stripped:
                in_block_comment = False
            continue
        if stripped.startswith('/*'):
            if '*/' not in stripped:
                in_block_comment = True
            continue

        # Skip empty lines, comments, shebangs, and attributes
        if not stripped or stripped.startswith('//') or stripped.startswith('#') or stripped.startswith('//!'):
            continue

        # Top-level `use` statement is permitted in top preamble
        if RE_USE_STMT.match(line):
            continue

        # If line matches a top-level code declaration (fn, struct, enum, impl, mod, etc.)
        if RE_TOP_DECLARATION.match(line):
            first_code_item_line = idx
            break

    return first_code_item_line


def is_test_file(file_path: Path) -> bool:
    """Checks if a file path belongs to a test directory or test suite.

    Args:
        file_path (Path): Path to the Rust source file.

    Returns:
        bool: True if file is located in `/tests/` or named `*test.rs` / `*tests.rs`.
    """
    path_str = str(file_path).replace('\\', '/').lower()
    if '/tests/' in path_str or 'tests.rs' in path_str or 'test.rs' in path_str:
        return True
    return False


def analyze_rust_file(
    file_path: Path, 
    min_colons: int = 1, 
    crate_or_use_only: bool = True, 
    exclude_tests: bool = True
) -> Optional[Dict[str, Any]]:
    """Analyzes a single Rust file for top-level vs non-top imports and qualified path expressions.

    Args:
        file_path (Path): Path to the Rust file to inspect.
        min_colons (int, optional): Minimum number of '::' occurrences to match a path when `crate_or_use_only` is False. Defaults to 1.
        crate_or_use_only (bool, optional): If True, restricts path expression matching strictly to expressions starting with `crate::`. Defaults to True.
        exclude_tests (bool, optional): If True, skips files in test paths and lines inside `#[cfg(test)]` modules. Defaults to True.

    Returns:
        Optional[Dict[str, Any]]: Dictionary containing file metrics, top boundary line, top imports, 
        non-top `use` statements, and non-top qualified path expressions; or None if skipped/error.
    """
    if exclude_tests and is_test_file(file_path):
        return None

    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception:
        return None

    lines = content.splitlines()
    top_boundary = find_top_boundary(lines)

    top_imports: List[Dict[str, Any]] = []
    non_top_uses: List[Dict[str, Any]] = []
    non_top_qualified_paths: List[Dict[str, Any]] = []

    in_test_cfg = False
    brace_depth = 0
    test_cfg_depth = None

    for idx, raw_line in enumerate(lines, start=1):
        stripped = raw_line.strip()
        code_only = clean_line_code(raw_line)

        # Track #[cfg(test)] module boundaries to exclude inline test modules
        if '#[cfg(test)]' in stripped or '#[test]' in stripped:
            in_test_cfg = True

        if in_test_cfg:
            if test_cfg_depth is None and '{' in stripped:
                test_cfg_depth = brace_depth
            brace_depth += stripped.count('{') - stripped.count('}')
            if test_cfg_depth is not None and brace_depth <= test_cfg_depth:
                in_test_cfg = False
                test_cfg_depth = None
            if exclude_tests:
                continue

        # Check for `use` statements
        use_match = RE_USE_STMT.match(raw_line)
        if use_match:
            item = {
                'line': idx,
                'content': raw_line.strip(),
                'import_path': use_match.group(1).strip()
            }
            if idx < top_boundary:
                top_imports.append(item)
            else:
                non_top_uses.append(item)
            continue

        # If line is after top preamble boundary, check for inline `crate::...` or path expressions
        if idx >= top_boundary and code_only:
            if stripped.startswith('//') or stripped.startswith('#'):
                continue

            matches = RE_PATH_EXPR.findall(code_only)

            if crate_or_use_only:
                # Strictly filter for expressions starting with `crate::`
                filtered_matches = [m for m in matches if m.startswith('crate::')]
            else:
                filtered_matches = [m for m in matches if m.count('::') >= min_colons]

            if filtered_matches:
                non_top_qualified_paths.append({
                    'line': idx,
                    'content': raw_line.strip(),
                    'matches': sorted(list(set(filtered_matches)))
                })

    return {
        'file': str(file_path),
        'total_lines': len(lines),
        'top_boundary_line': top_boundary,
        'top_imports': top_imports,
        'non_top_uses': non_top_uses,
        'non_top_qualified_paths': non_top_qualified_paths
    }


def scan_directory(
    target_dir: Path, 
    min_colons: int = 1, 
    crate_or_use_only: bool = True, 
    exclude_tests: bool = True, 
    include_generated: bool = False
) -> List[Dict[str, Any]]:
    """Recursively scans a directory for Rust files and analyzes each file.

    Args:
        target_dir (Path): Root directory path to scan.
        min_colons (int, optional): Minimum number of '::' occurrences for path matches. Defaults to 1.
        crate_or_use_only (bool, optional): Restricts path matches to `crate::...` when True. Defaults to True.
        exclude_tests (bool, optional): Excludes test files/modules when True. Defaults to True.
        include_generated (bool, optional): Includes auto-generated files (e.g. `frb_generated.rs`) when True. Defaults to False.

    Returns:
        List[Dict[str, Any]]: List of analysis result dictionaries for all matching Rust files.
    """
    results = []
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith('.rs'):
                if not include_generated and ('frb_generated' in file or file.endswith('.g.rs')):
                    continue
                file_path = Path(root) / file
                res = analyze_rust_file(
                    file_path, 
                    min_colons=min_colons, 
                    crate_or_use_only=crate_or_use_only, 
                    exclude_tests=exclude_tests
                )
                if res:
                    results.append(res)
    return results


def main() -> None:
    """CLI entry point for running the Rust Import & Path Expression Detector."""
    parser = argparse.ArgumentParser(
        description="Identify top and non-top imports/path expressions in Rust source files."
    )
    parser.add_argument(
        "--dir", 
        type=str, 
        default="rust/src", 
        help="Target Rust directory (default: rust/src)"
    )
    parser.add_argument(
        "--only-non-top", 
        action="store_true", 
        help="Display only non-top imports and inline qualified expressions"
    )
    parser.add_argument(
        "--json", 
        action="store_true", 
        help="Output results in machine-readable JSON format"
    )
    parser.add_argument(
        "--include-generated", 
        action="store_true", 
        help="Include auto-generated files (e.g. frb_generated.rs)"
    )
    parser.add_argument(
        "--include-tests", 
        action="store_true", 
        help="Include test files and #[cfg(test)] modules (excluded by default)"
    )
    parser.add_argument(
        "--all-paths", 
        action="store_true", 
        help="Match all path expressions with :: instead of restricting to crate:: or use"
    )
    parser.add_argument(
        "--min-colons", 
        type=int, 
        default=1, 
        help="Minimum number of '::' separators required when --all-paths is set"
    )

    args = parser.parse_args()
    target_path = Path(args.dir)

    if not target_path.exists():
        print(f"Error: Path '{target_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    results = scan_directory(
        target_path,
        min_colons=args.min_colons,
        crate_or_use_only=not args.all_paths,
        exclude_tests=not args.include_tests,
        include_generated=args.include_generated
    )

    if args.json:
        print(json.dumps(results, indent=2))
        return

    total_files = len(results)
    total_top_uses = sum(len(r['top_imports']) for r in results)
    total_non_top_uses = sum(len(r['non_top_uses']) for r in results)
    total_non_top_paths = sum(len(r['non_top_qualified_paths']) for r in results)

    print("=" * 80)
    print(" RUST IMPORT & QUALIFIED PATH ANALYSIS REPORT")
    print("=" * 80)
    print(f"Target Directory:          {target_path}")
    print(f"Total Rust Files Scanned:  {total_files}")
    print(f"Top-Level `use` Statements: {total_top_uses}")
    print(f"Non-Top `use` Statements:   {total_non_top_uses}")
    print(f"Non-Top `::`/`crate` Paths: {total_non_top_paths}")
    print("=" * 80)
    print()

    for r in results:
        file_rel = r['file']
        has_non_top = len(r['non_top_uses']) > 0 or len(r['non_top_qualified_paths']) > 0

        if args.only_non_top and not has_non_top:
            continue

        print(f"File: {file_rel}")
        print(f"  Preamble / Top Section Boundary Line: {r['top_boundary_line']}")

        if not args.only_non_top:
            print(f"  Top-Level Imports ({len(r['top_imports'])}):")
            if r['top_imports']:
                for imp in r['top_imports']:
                    print(f"    Line {imp['line']:4d} | {imp['content']}")
            else:
                print("    (None)")

        print(f"  Non-Top `use` Statements ({len(r['non_top_uses'])}):")
        if r['non_top_uses']:
            for imp in r['non_top_uses']:
                print(f"    Line {imp['line']:4d} | [NON-TOP USE] {imp['content']}")
        else:
            print("    (None)")

        print(f"  Non-Top Qualified Expressions (`crate::` / `::`) ({len(r['non_top_qualified_paths'])}):")
        if r['non_top_qualified_paths']:
            for path_match in r['non_top_qualified_paths']:
                matches_str = ", ".join(path_match['matches'])
                print(f"    Line {path_match['line']:4d} | [{matches_str}] -> {path_match['content']}")
        else:
            print("    (None)")

        print("-" * 80)


if __name__ == "__main__":
    main()
