---
activation: model_decision
description: "Apply when modifying canvas elements, coordinate metrics, spatial UI invariants, or rendering loops."
---

# Rule: Canvas & UI Spatial Invariants

- **Coordinate Metrics**: You MUST NEVER mix Screen Space and Canvas Space metrics. Bounding boxes and interactions inside the canvas must be calculated using exact Canvas Space coordinates.
- **Numerical Precisions**: You MUST NOT use floats for any UI-related canvas variables. Use discrete values. Only the Rust side is permitted to use float types for advanced computations.
- **Infinite Canvas Simulation**: 
  - Provide a mathematical reference plane and explicitly disable clipping when simulating the infinite canvas to prevent zero-size collapses.
  - Decouple pure mathematical bounding boxes from physical panning limits to prevent the camera from being trapped on empty graphs.
- **Render Pass Handling**: Allow the framework's initial physical render pass to complete before enforcing strict mathematical culling or spatial indexing.
- **Telemetry & Interaction**: Explicitly bind and handle appropriate input telemetry (e.g., hover events) for continuous state machine interactions rather than relying solely on drag/click defaults.
