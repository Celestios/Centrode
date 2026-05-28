---
activation: model_decision
description: "Apply when building UI animations, motion design, transitions, or styling spatial UI components."
---

# Rule: Motion Design & Rendering Performance

You MUST design animations and render components according to these guidelines to ensure smooth spatial canvas performance:

## 1. Motion Design & Easing
- Apply spring physics and precise easing curves (avoid default linear transitions) for:
  * Element lifecycles (creation, merging, deleting, focus transitions).
  * Viewport operations (canvas panning, zooming, and centering transitions).
  * Dynamic, database-driven style modifications.
  * Interactive hover/tap states on glass panels.
- Motion must clarify data flow and structural updates without causing user fatigue or layout distraction.

## 2. Rendering Optimization & Performance Boundaries
- **BackdropFilter Overhead**: Minimize the use of nested or overlapping `BackdropFilter` widgets, as they trigger expensive offscreen buffer operations.
- **Canvas Repaint Limits**: Ensure that panning or zooming the infinite canvas does not trigger full-screen repaints of static elements:
  * Use `RepaintBoundary` around complex widgets (such as individual nodes or toolbar overlays) to isolate rendering cycles.
- **State-Driven Easing**: Align animation lifecycles with the database-driven state updates to prevent UI-only animations from drifting from core domain truth.
- **Discrete Metrics**: Avoid using floats for UI layout coordinates to prevent sub-pixel antialiasing repaints.
