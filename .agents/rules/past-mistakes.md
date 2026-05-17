# Rule: Past Mistakes and Invariants

- You MUST NEVER mix Screen Space and Canvas Space metrics. If an interaction occurs inside the canvas, you MUST calculate bounding boxes using exact Canvas Space coordinates.
- You MUST allow the framework's initial physical render pass to complete before enforcing strict mathematical culling or spatial indexing.
- You MUST explicitly bind and handle appropriate input telemetry (e.g., hover events) for continuous state machine interactions rather than relying solely on drag/click defaults.
- You MUST ensure absolute symmetry between UI state fallbacks and Interaction Logic fallbacks. If one has an uninitialized bypass, the other must as well.
- You MUST provide a mathematical reference plane and explicitly disable clipping when attempting to simulate an infinite canvas to prevent zero-size collapses.
- You MUST verify end-to-end telemetry pipelines down to the reactive UI logs to ensure the frontend is actively consuming core events.
- You MUST explicitly target the specific statement index you wish to read when parsing multi-statement database query results.
- You MUST decouple pure mathematical bounding boxes from physical panning limits to prevent the camera from being trapped on empty graphs.
