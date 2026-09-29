# Glass Panel & Surfaces

---

## Overview

The surface system implements glassmorphic UI containers and interactive elements using `liquid_glass_easy` for real-time refractive optics alongside stepped specular bevels in dual surface modes (`CentrodeSurfaceMode.quality` and `CentrodeSurfaceMode.performance`).

---

## Files

| File | Role |
|------|------|
| `elements.dart` | Master barrel export |
| `centrode_panel.dart` | High-level surface container (`CentrodePanel` / `GlassPanel`) |
| `surfaces/double_edge_surface.dart` | Double stepped specular bevel container (`CentrodeDoubleEdgeSurface`) |
| `surfaces/double_edge_painter.dart` | Custom canvas stepped specular bevel painter |
| `surfaces/inset_surface.dart` | Debossed wells, capillary channels, and fields |
| `surfaces/gliding_lens.dart` | Reusable volume-conserving fluid lens selector |
| `surfaces/surface_mode.dart` | Dual surface mode scope and enum |

---

## Surface Modes & Optics

The system supports two rendering modes:
- **Quality Mode**: Real-time backdrop refraction, chromatic dispersion, and fluid lens distortions powered by `liquid_glass_easy`.
- **Performance Mode**: Lightweight, zero-shader specular double-edge borders and semi-translucent backdrops for resource-constrained environments.

---

## Usage

```dart
CentrodePanel(
  borderRadius: UiRadius.panel,
  blur: 16.0,
  accentColor: theme.colorScheme.primary,
  child: MyContent(),
)
```
