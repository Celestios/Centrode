# Shaders & Surface Optics

---

## Liquid Glass Engine

Centrode uses `liquid_glass_easy` for hardware-accelerated refractive glass optics, supporting both Flutter Impeller (Vulkan/Metal) and Skia backends.

The previous prototype shader (`shaders/liquid_glass.frag`) and custom `GlassShaderProvider` have been replaced by this unified, high-performance engine coupled with Centrode's dual surface system:

1. **`CentrodeSurfaceMode.quality`**: Real-time backdrop refraction, continuous squircle SDF edges, chromatic dispersion, fluid droplet condensation, and dynamic specular highlights.
2. **`CentrodeSurfaceMode.performance`**: Lightweight, zero-shader canvas rendering using stepped specular bevels (`CentrodeDoubleEdgePainter`) and semi-translucent backdrops for resource-constrained environments.

---

## Surface Mechanics & Physics

- **Double-Edge Stepped Specular Bevels (`CentrodeDoubleEdgePainter`)**: Two-step specular highlight geometry simulating multi-faceted glass bevels with inner and outer light reflections.
- **Gliding Lens (`CentrodeGlidingLens`)**: Reusable volume-conserving fluid lens selector featuring stretch-then-glide physics (+42% width stretch, 2.5px height squash) for tab switchers, segmented controls, and dropdown selectors.
- **Debossed Wells (`CentrodeInsetPainter`)**: Multi-layered capillary inset channels for sliders and track grooves.

---

## Usage in Dart

Surfaces are accessed via the centralized `elements.dart` barrel:

```dart
// Quality mode lens with real-time backdrop refraction
LiquidGlassLens(
  style: LiquidGlassStyle(
    shape: LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 12.0),
    refraction: LiquidGlassRefraction(distortion: 0.2, magnification: 1.1),
  ),
  child: ContentWidget(),
)

// Master double-edge surface container
CentrodeDoubleEdgeSurface(
  borderRadius: BorderRadius.circular(12.0),
  accentColor: theme.colorScheme.primary,
  child: ContentWidget(),
)
```
