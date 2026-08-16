# Glass Panel

> Last verified: 2026-08-16
> Tier: 1 (Presentation)

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
