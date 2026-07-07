---
name: telemetry-diagnostics
description: Activate this skill when planning structured log trace structures, adding logging hooks, defining error reporting channels, or tracking telemetry performance metrics.
---

# Skill: Telemetry & Diagnostics

Use this skill when designing or implementing telemetry trackers, error metrics logging, and tracing schemas.

## Guidelines

- **Structured Warnings & Logs**: Enforce standardized formats for warn/error logs. Do not use print statements.
- **Diagnostics Metrics**: Design metric capture points for performance issues (canvas fps drops, gesture latency anomalies, long SurrealDB queries).
- **FFI Event Tracing**: Coordinate telemetry spans tracing events across the FFI bridge for debugger visualizers.
