#!/usr/bin/env python3
"""Analyze Flutter widget rebuild counts from debugPrintRebuildDirtyWidgets output.

Usage:
    # Pipe flutter run output directly
    flutter run 2>&1 | python scripts/analyze_builds.py

    # Analyze a saved log file
    python scripts/analyze_builds.py --file run_output.log

    # Show only widgets with > N rebuilds
    python scripts/analyze_builds.py --file run_output.log --threshold 10

    # Output as JSON
    python scripts/analyze_builds.py --file run_output.log --json
"""

import argparse
import json
import re
import sys
from collections import Counter
from typing import TextIO

# Matches: "Building WidgetName(...)" or "Rebuilding WidgetName(...)"
BUILD_LINE = re.compile(
    r"^(?:Building|Rebuilding)\s+([A-Za-z_][A-Za-z0-9_]*)"
)


def parse_line(line: str) -> str | None:
    """Extract widget class name from a Flutter rebuild log line."""
    m = BUILD_LINE.match(line)
    if m:
        return m.group(1)
    return None


def analyze_stream(stream: TextIO) -> Counter:
    """Read a stream and count widget rebuilds."""
    counts: Counter = Counter()
    for line in stream:
        name = parse_line(line)
        if name:
            counts[name] += 1
    return counts


def print_report(counts: Counter, threshold: int = 0) -> None:
    """Print a formatted rebuild report."""
    if not counts:
        print("No rebuild data found.", file=sys.stderr)
        print(
            "\nMake sure debugPrintRebuildDirtyWidgets = true is set in main.dart\n"
            "and you're capturing stderr (flutter run 2>&1).",
            file=sys.stderr,
        )
        return

    filtered = {k: v for k, v in counts.items() if v > threshold}
    total = sum(counts.values())
    shown = sum(filtered.values())
    top = sorted(filtered.items(), key=lambda x: -x[1])

    print(f"\n{'='*60}")
    print(f"  Widget Rebuild Report")
    print(f"{'='*60}")
    print(f"  Total rebuilds: {total}")
    print(f"  Unique widgets: {len(counts)}")
    if threshold > 0:
        print(f"  Showing: {len(filtered)} widgets with >{threshold} rebuilds ({shown} rebuilds)")
    print(f"{'='*60}\n")

    if not top:
        print("  No widgets exceed the threshold.\n")
        return

    max_name = max(len(n) for n, _ in top)
    max_count = max(v for _, v in top)
    bar_width = 30

    print(f"  {'Widget':<{max_name}}  {'Count':>6}  Bar")
    print(f"  {'-'*max_name}  {'-'*6}  {'-'*bar_width}")

    for name, count in top[:50]:
        bar_len = int((count / max_count) * bar_width) if max_count > 0 else 0
        bar = "#" * bar_len

        if count > 50:
            tag = " [!!!]"
        elif count > 20:
            tag = " [!!]"
        elif count > 5:
            tag = " [!]"
        else:
            tag = ""

        print(f"  {name:<{max_name}}  {count:>6}  {bar}{tag}")

    print(f"\n  [!!!] >50 (critical)  [!!] >20 (watch)  [!] >5 (normal)\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze Flutter widget rebuild counts")
    parser.add_argument("--file", "-f", help="Log file to analyze (default: stdin)")
    parser.add_argument("--threshold", "-t", type=int, default=0, help="Minimum rebuilds to show (default: 0)")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    parser.add_argument("--output", "-o", help="Save report to file (default: stdout only)")
    parser.add_argument("--top", "-n", type=int, default=50, help="Max widgets to show (default: 50)")
    args = parser.parse_args()

    if args.file:
        with open(args.file, "r", encoding="utf-8", errors="replace") as f:
            counts = analyze_stream(f)
    else:
        if sys.stdin.isatty():
            print("Reading from stdin... (press Ctrl+D when done, or pipe flutter run output)", file=sys.stderr)
        counts = analyze_stream(sys.stdin)

    if args.json:
        top = sorted(counts.items(), key=lambda x: -x[1])[:args.top]
        output = json.dumps({"total": sum(counts.values()), "widgets": dict(top)}, indent=2)
    else:
        import io
        buf = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = buf
        print_report(counts, args.threshold)
        sys.stdout = old_stdout
        output = buf.getvalue()

    print(output, end="")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"\nReport saved to: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
