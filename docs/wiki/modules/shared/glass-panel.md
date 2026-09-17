# Glass Panel

---

## Overview

The glass panel system implements glassmorphic UI containers using a custom GLSL fragment shader for real-time rendering.

---

## Files

| File | Role |
|------|------|
| `glass_panel.dart` | Barrel export |
| `src/glass_panel_widget.dart` | Main glass container widget |
| `src/glass_shader_provider.dart` | Shader compilation and caching |
| `src/glass_settings.dart` | Effect parameters (blend, refraction, specular) |
| `src/glass_mode.dart` | Glass rendering modes |
| `src/glass_stage.dart` | Rendering stage management |
| `src/glass_alert_dialog.dart` | Glass-styled alert dialogs |
| `src/glass_group.dart` | Grouped glass elements |

---

## Shader

The liquid glass shader (`shaders/liquid_glass.frag`) implements:
- Rounded-rect SDFs with smooth `smin` union blending
- Refraction distortion and radial blur
- Directional rim lighting (lightbands)
- Angular specular highlights
- Anti-aliasing via physical pixel width

See [Shader documentation](../../design/shaders.md) for the full breakdown.

---

## Shadow and Corner Geometry

`GlassPanel` uses a `ShapeDecoration` with `ContinuousRectangleBorder` (squircle) for its outer shadow casting, specular border highlight, face fill, and backdrop clipping.
- **Continuous Curvature**: Outer multi-layered shadows conform directly to the continuous squircle curve without clipping or corner drop-off.
- **Asymmetric Radii**: Supports `customBorderRadius: BorderRadiusGeometry?` to independently round specific corners (e.g. `topRight` and `bottomRight` for docked sidebars) while maintaining smooth squircle bezier continuity.

---

## Usage

```dart
GlassPanel(
  settings: GlassSettings(
    blendPx: 20.0,
    refractStrength: 0.5,
    specStrength: 0.3,
  ),
  child: MyContent(),
)
```
