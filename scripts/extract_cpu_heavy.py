#!/usr/bin/env python3
"""Extract most CPU-heavy components from a Dart DevTools JSON CPU profile.

Usage:
    python scripts/extract_cpu_heavy.py [.Archive/dart_devtools_....json]
"""

import io
import json
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def expand_stack(stack_frames, frame_id):
    """Yield all frame ids in a call stack by following parent links."""
    visited = set()
    current = frame_id
    while current and current not in visited:
        visited.add(current)
        yield current
        current = stack_frames.get(current, {}).get("parent")


def main():
    if len(sys.argv) < 2:
        default = next(
            Path(".Archive").glob("dart_devtools_*.json"), None
        )
        if not default:
            print("Usage: python scripts/extract_cpu_heavy.py <devtools.json>")
            sys.exit(1)
        path = default
    else:
        path = Path(sys.argv[1])

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    profiler = data["cpu-profiler"]
    stack_frames = profiler["stackFrames"]
    trace_events = profiler["traceEvents"]
    time_extent_us = profiler["timeExtentMicros"]
    sample_period_us = profiler["samplePeriod"]
    total_samples = profiler["sampleCount"]

    print(f"File: {path.name}")
    print(f"Duration: {time_extent_us / 1000:.1f}ms | Samples: {total_samples} | Period: {sample_period_us}\u03bcs")
    print()

    # Count how many samples each frame appears in (full stack attribution)
    frame_sample_count = defaultdict(int)
    # Count top-of-stack samples
    tos_count = defaultdict(int)

    for event in trace_events:
        if event.get("ph") != "P":
            continue
        top_frame = event.get("sf", "")
        for fid in expand_stack(stack_frames, top_frame):
            frame_sample_count[fid] += 1
        tos_count[top_frame] += 1

    # Group by package
    package_samples = defaultdict(int)
    package_tos = defaultdict(int)
    package_files = defaultdict(lambda: defaultdict(int))
    file_methods = defaultdict(lambda: defaultdict(int))

    for fid, count in frame_sample_count.items():
        info = stack_frames.get(fid, {})
        pkg = info.get("packageUri", info.get("resolvedUrl", "unknown"))
        package_samples[pkg] += count

    for fid, count in tos_count.items():
        info = stack_frames.get(fid, {})
        pkg = info.get("packageUri", info.get("resolvedUrl", "unknown"))
        package_tos[pkg] += count
        url = info.get("resolvedUrl", "")
        if url:
            # Extract relative file path
            rel = url.split("/lib/")[-1] if "/lib/" in url else url.split("/")[-1]
            package_files[pkg][rel] += count
        name = info.get("name", "")
        file_methods[pkg][name] += count

    # Print packages ranked by total sample attribution
    print("=" * 80)
    print("CPU HEAVY PACKAGES (by sample attribution)")
    print("=" * 80)
    print(f"{'Package':<60} {'Stack%':>7} {'TOS%':>7}")
    print("-" * 80)

    for pkg in sorted(package_samples, key=lambda p: package_samples[p], reverse=True):
        stack_pct = package_samples[pkg] / total_samples * 100
        tos_pct = package_tos.get(pkg, 0) / total_samples * 100
        short_pkg = pkg.split("package:")[-1] if "package:" in pkg else Path(pkg).name
        print(f"  {short_pkg:<58} {stack_pct:>6.1f}% {tos_pct:>6.1f}%")

    # Top files per package
    print()
    print("=" * 80)
    print("CPU HEAVY FILES (top-of-stack attribution)")
    print("=" * 80)
    print(f"{'File':<70} {'TOS%':>7}")
    print("-" * 80)

    all_files = []
    for pkg, files in package_files.items():
        for rel, count in files.items():
            all_files.append((rel, count, pkg))
    all_files.sort(key=lambda x: x[1], reverse=True)

    for rel, count, pkg in all_files[:30]:
        tos_pct = count / total_samples * 100
        if tos_pct >= 0.5:
            print(f"  {rel:<68} {tos_pct:>6.1f}%")

    # Top methods
    print()
    print("=" * 80)
    print("TOP CPU-HEAVY METHODS (top-of-stack)")
    print("=" * 80)
    print(f"{'Method':<60} {'Samples':>8} {'%':>7}")
    print("-" * 80)

    all_methods = []
    for pkg, methods in file_methods.items():
        for name, count in methods.items():
            all_methods.append((name, count, pkg))
    all_methods.sort(key=lambda x: x[1], reverse=True)

    for name, count, pkg in all_methods[:25]:
        pct = count / total_samples * 100
        if pct >= 0.5:
            short_pkg = pkg.split("package:")[-1] if "package:" in pkg else Path(pkg).name
            print(f"  {name:<60} {count:>7} {pct:>6.1f}%")

    # Flamegraph-style: self + children breakdown
    print()
    print("=" * 80)
    print("SELF TIME (top-of-stack only — actual execution)")
    print("=" * 80)

    self_time = []
    for fid, count in tos_count.items():
        info = stack_frames.get(fid, {})
        name = info.get("name", "<unknown>")
        url = info.get("resolvedUrl", "")
        rel = url.split("/lib/")[-1] if "/lib/" in url else url
        self_time.append((name, rel, count))

    self_time.sort(key=lambda x: x[2], reverse=True)

    print(f"{'Method':<45} {'File':<40} {'TOS':>6} {'%':>6}")
    print("-" * 100)
    for name, rel, count in self_time[:25]:
        pct = count / total_samples * 100
        if pct >= 0.3:
            print(f"  {name:<43} {rel:<40} {count:>5} {pct:>5.1f}%")


if __name__ == "__main__":
    main()
