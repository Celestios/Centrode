---
description: Canvas rendering analysis, repaint boundaries, gesture latency, and query tuning.
---

# Workflow: /perf-profiler

This workflow is used when profiling, diagnosing, and optimizing performance bottlenecks in the Centrode workspace, particularly around rendering, FFI communication, and database performance.

## Execution Steps

### Step 1: Bottleneck Profiling
- Identify the performance target:
  - **Tier 1 (Presentation & Interface)**: Frame rates, repaint counts, lag on panning/zooming. LOWEST tier.
  - **FFI Boundary**: Payload serialization sizes, bridge round-trip times.
  - **Tier 3 (Core Domain & Storage)**: SurrealQL execution times, transaction blocking, index matching. HIGHEST tier.

### Step 2: Load Style and Performance Rules
- Based on the area of optimization:
  - For Dart/Flutter optimizations: View and activate the [dart-coding](.agents/skills/coding/dart-coding/SKILL.md) skill.
  - For Rust/Database optimizations: View and activate the [rust-coding](.agents/skills/coding/rust-coding/SKILL.md) skill.

### Step 3: Performance Auditing
- Verify common performance hotspots:
  - **Repaint Boundaries**: Ensure fast-moving canvas elements (nodes during drag, selection boxes) are wrapped in `RepaintBoundary` to prevent repainting the entire viewport.
  - **Glassmorphism Filters**: Audit `BackdropFilter` usage. Ensure they are minimized and not placed inside repeating list views or heavy scroll regions.
  - **FFI Bandwidth**: Check if large structures are passed repeatedly across the bridge; optimize with partial patches or IDs where possible.
  - **Database Queries**: Audit the schema for missing indexes and optimize transaction queries to avoid table lockouts.

### Step 4: Propose & Implement Optimizations
- Draft the optimization plan detailing specific code changes.
- Implement the changes cleanly.

### Step 5: Verification
- Ask the user to run profiling tools (Flutter DevTools performance overlay, cargo bench, or SurrealDB query explain log) to confirm performance improvement.
