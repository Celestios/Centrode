#!/usr/bin/env python3
"""Analyze Flutter widget rebuild counts and notification chains.

Usage:
    # Pipe flutter run output directly
    flutter run 2>&1 | python scripts/analyze_builds.py

    # Analyze a saved log file
    python scripts/analyze_builds.py --file run_output.log

    # Show only widgets with > N rebuilds
    python scripts/analyze_builds.py --file run_output.log --threshold 10

    # Output as JSON
    python scripts/analyze_builds.py --file run_output.log --json

    # Filter by time window (seconds from start)
    python scripts/analyze_builds.py --file run_output.log --start 2.0 --end 5.0

    # Show rebuild chains (what triggers what)
    python scripts/analyze_builds.py --file run_output.log --chains

    # Show rebuild timeline
    python scripts/analyze_builds.py --file run_output.log --timeline

    # Show notification chains (ChangeNotifier → listener patterns)
    python scripts/analyze_builds.py --file run_output.log --notify-chains

    # Show only cascade events (notifications triggering notifications)
    python scripts/analyze_builds.py --file run_output.log --cascades
"""
import argparse
import json
import re
import sys
import time
from collections import Counter, defaultdict
from typing import TextIO, Optional

# Matches: "Building WidgetName(...)" or "Rebuilding WidgetName(...)"
BUILD_LINE = re.compile(
    r"^(?:Building|Rebuilding)\s+([A-Za-z_][A-Za-z0-9_]*)"
)

# Matches timestamp from debug output if present
TIMESTAMP_LINE = re.compile(
    r"^(\d{2}:\d{2}:\d{2}\.\d{3})\s+"
)

# Matches: "[Notify] ParentNotifier -> ChildNotifier (depth=N)"
NOTIFY_LINE = re.compile(
    r"^\[Notify\]\s+(\S+)\s*->\s*(\S+)\s+\(depth=(\d+)\)"
)


class RebuildEvent:
    def __init__(self, widget_name: str, timestamp: float, line_num: int):
        self.widget_name = widget_name
        self.timestamp = timestamp
        self.line_num = line_num

    def to_dict(self):
        return {
            "widget": self.widget_name,
            "timestamp": self.timestamp,
            "line": self.line_num,
        }


class RebuildAnalyzer:
    def __init__(self):
        self.events: list[RebuildEvent] = []
        self.counts: Counter = Counter()
        self.parent_child: dict[str, Counter] = defaultdict(Counter)
        self._last_widget: Optional[str] = None
        self._start_time: Optional[float] = None

    def add_event(self, event: RebuildEvent):
        self.events.append(event)
        self.counts[event.widget_name] += 1

        if self._last_widget and self._last_widget != event.widget_name:
            self.parent_child[self._last_widget][event.widget_name] += 1

        self._last_widget = event.widget_name

    def filter_by_time(self, start: float, end: float) -> 'RebuildAnalyzer':
        filtered = RebuildAnalyzer()
        for event in self.events:
            if start <= event.timestamp <= end:
                filtered.add_event(event)
        return filtered

    def get_top_chains(self, n: int = 10) -> list[tuple[str, str, int]]:
        chains = []
        for parent, children in self.parent_child.items():
            for child, count in children.most_common(3):
                chains.append((parent, child, count))
        chains.sort(key=lambda x: -x[2])
        return chains[:n]

    def get_timeline(self, bucket_size: float = 0.5) -> dict[float, Counter]:
        if not self.events:
            return {}

        min_t = self.events[0].timestamp
        max_t = self.events[-1].timestamp

        buckets: dict[float, Counter] = {}
        t = min_t
        while t <= max_t:
            buckets[t] = Counter()
            t += bucket_size

        for event in self.events:
            bucket = min_t + ((event.timestamp - min_t) // bucket_size) * bucket_size
            if bucket in buckets:
                buckets[bucket][event.widget_name] += 1

        return buckets


class NotifyEvent:
    def __init__(self, parent: str, child: str, depth: int, timestamp: float, line_num: int):
        self.parent = parent
        self.child = child
        self.depth = depth
        self.timestamp = timestamp
        self.line_num = line_num

    def to_dict(self):
        return {
            "parent": self.parent,
            "child": self.child,
            "depth": self.depth,
            "timestamp": self.timestamp,
            "line": self.line_num,
        }


class NotifyAnalyzer:
    def __init__(self):
        self.events: list[NotifyEvent] = []
        self.edge_counts: Counter = Counter()
        self.source_counts: Counter = Counter()
        self.target_counts: Counter = Counter()
        self.depth_counts: Counter = Counter()
        self._start_time: Optional[float] = None

    def add_event(self, event: NotifyEvent):
        self.events.append(event)
        self.edge_counts[(event.parent, event.child)] += 1
        self.source_counts[event.parent] += 1
        self.target_counts[event.child] += 1
        self.depth_counts[event.depth] += 1

    def get_cascades(self) -> list[tuple[str, str, int]]:
        """Find edges where depth > 1 (notification triggering notification)."""
        cascades = [(p, c, n) for (p, c), n in self.edge_counts.items() if self.depth_counts.get(1, 0) > 0]
        return sorted(cascades, key=lambda x: -x[2])

    def get_top_sources(self, n: int = 10) -> list[tuple[str, int]]:
        return self.source_counts.most_common(n)

    def get_top_targets(self, n: int = 10) -> list[tuple[str, int]]:
        return self.target_counts.most_common(n)

    def get_max_depth(self) -> int:
        return max(self.depth_counts.keys()) if self.depth_counts else 0

    def filter_by_time(self, start: float, end: float) -> 'NotifyAnalyzer':
        filtered = NotifyAnalyzer()
        for event in self.events:
            if start <= event.timestamp <= end:
                filtered.add_event(event)
        return filtered


def parse_stream(stream: TextIO) -> tuple[RebuildAnalyzer, NotifyAnalyzer]:
    rebuild_analyzer = RebuildAnalyzer()
    notify_analyzer = NotifyAnalyzer()
    start_time = time.time()

    for i, line in enumerate(stream, 1):
        line = line.strip()
        if not line:
            continue

        m = BUILD_LINE.match(line)
        if m:
            widget_name = m.group(1)
            timestamp = time.time() - start_time
            event = RebuildEvent(widget_name, timestamp, i)
            rebuild_analyzer.add_event(event)
            continue

        nm = NOTIFY_LINE.match(line)
        if nm:
            parent, child, depth = nm.group(1), nm.group(2), int(nm.group(3))
            timestamp = time.time() - start_time
            event = NotifyEvent(parent, child, depth, timestamp, i)
            notify_analyzer.add_event(event)

    return rebuild_analyzer, notify_analyzer


def print_report(analyzer: RebuildAnalyzer, threshold: int = 0, top_n: int = 50) -> None:
    counts = analyzer.counts

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

    for name, count in top[:top_n]:
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


def print_chains(analyzer: RebuildAnalyzer, top_n: int = 10) -> None:
    chains = analyzer.get_top_chains(top_n)
    if not chains:
        print("No rebuild chains found.")
        return

    print(f"\n{'='*60}")
    print(f"  Top Rebuild Chains (parent → child)")
    print(f"{'='*60}\n")

    for parent, child, count in chains:
        print(f"  {parent} → {child}: {count} times")

    print()


def print_notify_chains(analyzer: NotifyAnalyzer, top_n: int = 20) -> None:
    if not analyzer.events:
        print("No notification chain data found.")
        print(
            "\nTo enable, add TraceableNotifier mixin to your ChangeNotifiers:\n"
            "  import 'package:mycelium/shared/traceable_notifier.dart';\n"
            "  class MyNotifier extends ChangeNotifier with TraceableNotifier {\n"
            "    MyNotifier() : super('MyNotifier');\n"
            "  }\n"
            "Then set DebugNotifierTracer.enabled = true in main.dart.",
            file=sys.stderr,
        )
        return

    edges = analyzer.edge_counts.most_common(top_n)

    print(f"\n{'='*60}")
    print(f"  Notification Chains")
    print(f"{'='*60}")
    print(f"  Total notifications: {sum(analyzer.source_counts.values())}")
    print(f"  Unique sources: {len(analyzer.source_counts)}")
    print(f"  Unique targets: {len(analyzer.target_counts)}")
    print(f"  Max cascade depth: {analyzer.get_max_depth()}")
    print(f"{'='*60}\n")

    print(f"  {'Parent':<25} {'Child':<25} {'Count':>6}")
    print(f"  {'-'*25} {'-'*25} {'-'*6}")

    for (parent, child), count in edges:
        depth_indicator = " ↳" if count > 5 else ""
        print(f"  {parent:<25} {child:<25} {count:>6}{depth_indicator}")

    print()


def print_cascades(analyzer: NotifyAnalyzer) -> None:
    if not analyzer.events:
        print("No notification data found.")
        return

    # Find chains where notifications trigger more notifications
    top_sources = analyzer.get_top_sources(10)
    top_targets = analyzer.get_top_targets(10)

    # Find notifiers that appear as both source and target (cascade nodes)
    source_set = set(s for s, _ in top_sources)
    target_set = set(t for t, _ in top_targets)
    cascade_nodes = source_set & target_set

    print(f"\n{'='*60}")
    print(f"  Notification Cascade Analysis")
    print(f"{'='*60}\n")

    if cascade_nodes:
        print(f"  Cascade notifiers (trigger AND are triggered):")
        for node in sorted(cascade_nodes):
            src = analyzer.source_counts[node]
            tgt = analyzer.target_counts[node]
            print(f"    {node}: triggers {src} times, triggered {tgt} times")
    else:
        print(f"  No cascade notifiers found (clean pattern).")

    # Show notification depth distribution
    if analyzer.depth_counts:
        print(f"\n  Depth distribution:")
        for depth in sorted(analyzer.depth_counts.keys()):
            count = analyzer.depth_counts[depth]
            bar = "#" * min(count, 40)
            print(f"    depth {depth}: {count:>5}  {bar}")

    print()


def print_timeline(analyzer: RebuildAnalyzer, bucket_size: float = 0.5) -> None:
    timeline = analyzer.get_timeline(bucket_size)
    if not timeline:
        print("No timeline data found.")
        return

    print(f"\n{'='*60}")
    print(f"  Rebuild Timeline ({bucket_size}s buckets)")
    print(f"{'='*60}\n")

    max_count = max(sum(c.values()) for c in timeline.values()) if timeline else 1

    for t, counts in sorted(timeline.items()):
        total = sum(counts.values())
        if total == 0:
            continue

        bar_len = int((total / max_count) * 40) if max_count > 0 else 0
        bar = "#" * bar_len

        # Show top 3 widgets in this bucket
        top_widgets = counts.most_common(3)
        widgets_str = ", ".join(f"{w}({c})" for w, c in top_widgets)

        print(f"  {t:6.1f}s  {total:>4}  {bar}  {widgets_str}")

    print()


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze Flutter widget rebuild counts and notification chains")
    parser.add_argument("--file", "-f", help="Log file to analyze (default: stdin)")
    parser.add_argument("--threshold", "-t", type=int, default=0, help="Minimum rebuilds to show (default: 0)")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    parser.add_argument("--output", "-o", help="Save report to file (default: stdout only)")
    parser.add_argument("--top", "-n", type=int, default=50, help="Max widgets to show (default: 50)")
    parser.add_argument("--start", type=float, default=0, help="Start time in seconds for filtering")
    parser.add_argument("--end", type=float, default=float('inf'), help="End time in seconds for filtering")
    parser.add_argument("--chains", "-c", action="store_true", help="Show rebuild chains")
    parser.add_argument("--timeline", "-l", action="store_true", help="Show rebuild timeline")
    parser.add_argument("--bucket", "-b", type=float, default=0.5, help="Timeline bucket size in seconds (default: 0.5)")
    parser.add_argument("--notify-chains", "-N", action="store_true", help="Show notification chains")
    parser.add_argument("--cascades", "-C", action="store_true", help="Show notification cascade analysis")
    args = parser.parse_args()

    if args.file:
        with open(args.file, "r", encoding="utf-8", errors="replace") as f:
            rebuild_analyzer, notify_analyzer = parse_stream(f)
    else:
        if sys.stdin.isatty():
            print("Reading from stdin... (press Ctrl+D when done, or pipe flutter run output)", file=sys.stderr)
        rebuild_analyzer, notify_analyzer = parse_stream(sys.stdin)

    # Apply time filter if specified
    if args.start > 0 or args.end < float('inf'):
        rebuild_analyzer = rebuild_analyzer.filter_by_time(args.start, args.end)
        notify_analyzer = notify_analyzer.filter_by_time(args.start, args.end)
        print(f"\n  Filtered to time window: {args.start:.1f}s - {args.end:.1f}s")

    if args.json:
        top = sorted(rebuild_analyzer.counts.items(), key=lambda x: -x[1])[:args.top]
        output = json.dumps({
            "rebuilds": {
                "total": sum(rebuild_analyzer.counts.values()),
                "widgets": dict(top),
                "chains": [
                    {"parent": p, "child": c, "count": n}
                    for p, c, n in rebuild_analyzer.get_top_chains(20)
                ],
            },
            "notifications": {
                "total": sum(notify_analyzer.source_counts.values()),
                "sources": dict(notify_analyzer.get_top_sources(20)),
                "targets": dict(notify_analyzer.get_top_targets(20)),
                "edges": [
                    {"parent": p, "child": c, "count": n}
                    for (p, c), n in notify_analyzer.edge_counts.most_common(20)
                ],
                "max_depth": notify_analyzer.get_max_depth(),
            },
        }, indent=2)
        print(output)
    else:
        import io
        buf = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = buf

        print_report(rebuild_analyzer, args.threshold, args.top)

        if args.chains:
            print_chains(rebuild_analyzer)

        if args.notify_chains or args.cascades:
            if args.notify_chains:
                print_notify_chains(notify_analyzer)
            if args.cascades:
                print_cascades(notify_analyzer)

        if args.timeline:
            print_timeline(rebuild_analyzer, args.bucket)

        sys.stdout = old_stdout
        output = buf.getvalue()
        print(output, end="")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"\nReport saved to: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
