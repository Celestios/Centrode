# Shaders

---

## Liquid Glass Shader

`shaders/liquid_glass.frag` — GLSL 460 core fragment shader implementing glassmorphic rendering.

---

## Technique

The shader renders glass-like panels using:

1. **Rounded-rect SDFs** — Signed Distance Functions for rectangular shapes
2. **Smooth union (`smin`)** — Organic blending between overlapping rectangles
3. **Refraction distortion** — Background distortion through the glass
4. **Radial blur** — Physical-coordinate blur falloff
5. **Directional rim lighting** — Lightbands for depth perception
6. **Angular specular highlights** — Shininess based on view angle
7. **Anti-aliasing** — Physical pixel width for smooth edges

---

## Uniforms

### Global
| Uniform | Type | Description |
|---------|------|-------------|
| `u_path_mode` | float | Rendering path (local bounds vs full background) |
| `u_layer_size` | vec2 | Physical dimensions |
| `u_inflated_offset` | vec2 | Inflation offset |
| `u_global_offset` | vec2 | Global position offset |
| `u_bg_size` | vec2 | Background snapshot size |
| `uBlendPx` | float | Blend radius (physical px) |
| `uRefractStrength` | float | Refraction strength |
| `uDistortFalloffPx` | float | Distortion falloff distance |
| `uRadialBlurPx` | float | Radial blur radius |
| `uSpecAngle` | float | Specular highlight angle |
| `uSpecStrength` | float | Specular intensity |
| `uSpecPower` | float | Specular exponent |
| `uLightbandOffsetPx` | float | Rim light offset |
| `uLightbandWidthPx` | float | Rim light width |
| `uLightbandStrength` | float | Rim light intensity |
| `uLightbandColor` | vec3 | Rim light color |
| `uAAPx` | float | Anti-aliasing width |
| `uRectCount` | float | Number of active rectangles |
| `uBridgeThicknessFactor` | float | Bridge blend thickness |

### Per-Rectangle (up to 4)
| Uniform | Type | Description |
|---------|------|-------------|
| `uRect0..3` | vec4 | Center (xy) + half-size (zw) in physical px |
| `uCorner0..3` | float | Corner radius |
| `uTintColor0..3` | vec4 | Tint color (RGBA) |

---

## Rendering Pipeline

1. Compute SDF for each rectangle
2. Blend SDFs using smooth union
3. Sample background texture
4. Apply refraction distortion based on SDF gradient
5. Apply radial blur based on distance from center
6. Compute rim lighting based on SDF gradient direction
7. Compute specular highlight based on view angle
8. Composite glass effect over background
9. Apply anti-aliasing at edges

---

## Usage in Dart

`GlassShaderProvider` compiles and caches the shader:

```dart
await GlassShaderProvider.load();
```

`GlassPanelWidget` uses the shader via `CustomPaint` with a `FragmentProgram`.
