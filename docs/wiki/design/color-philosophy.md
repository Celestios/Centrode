# Color Philosophy

---

## Overview

Centrode uses a **5-Anchor Chromatic Engine** grounded in human-perceptual color science ([OKLCH color space](themes.md#color-harmony)). Rather than specifying dozens of uncoordinated hex values, the visual system defines **5 mathematically independent anchor colors**. A deterministic derivation engine (`CentrodeDerivedPalette` at `lib/shared/theme/theme_derived_palette.dart`) programmatically derives all 20+ specialized UI element tokens across the canvas, chrome, and feedback tiers.

No derivative colors (such as desaturated tints or darkened shades of an anchor) are stored in the root theme palette. Everything that can be derived is computed dynamically.

---

## The 5 Thematic Pillars

The 5 anchor colors are cleanly distributed across visual roles, anchored by the **Primary (Active Focus) $\longleftrightarrow$ Tertiary (Border Boundary)** $180^\circ$ complementary axis in OKLCH perceptual space, with **Secondary** providing the background surface:

| Anchor | Default Dark Hex | Role | Semantic Purpose |
|---|---|---|---|
| `primaryColor` | `#818CF8` | **Active Elements & Focus** | Selected tabs, active buttons, focus rings, selection marquees, interactive active overlays |
| `secondaryColor` | `#101216` | **Background & Surfaces** | Infinite canvas background, card/panel bases, frosted glass body fill |
| `tertiaryColor` | `#B49700` | **Borders & Boundaries** | Exact $180^\circ$ OKLCH complement to Primary; glass specular rims, card borders, dividers |
| `accentColor` | `#F43F5E` | **Alerts & Urgency** | High-energy Rose Coral; unread badges, dirty dots, hot port snapping, destructive actions |
| `canvasAccentColor` | `#06B6D4` | **Tools & Topology** | Electric Cyan; tool ribbon modes, search lens, wire connection routes, minimap lens |

---

## Systematic Derivation Mapping

UI components must **never** hardcode colors. Every current and future UI element derives its color according to this systematic decision matrix:

### 1. `primaryColor` Derivations (Active Elements & Focus)
- **Selection Outlines**: Solid `primaryColor` (`selectionBorder`)
- **Selection Fills**: `primaryColor` with `UiAlpha.tint` (12%)
- **Interactive Overlays**: Hover wash with `UiAlpha.subtle` (8%), pressed overlay with `UiAlpha.medium` (25%)
- **Active Chrome**: Active tool button pill, active tab underline, minimap viewport lens & border
- **Semantic Info**: General informative notices, active execution state chips (`info`)
- **Node Types**: `infoNode` (direct primary), `commentNode` (soft monochromatic step)

### 2. `secondaryColor` Derivations (Background & Surfaces)
- **Scaffold Canvas**: Direct `secondaryColor` base canvas fill
- **Card Surfaces**: Stepped lightness elevation from `secondaryColor`
- **Glass Body**: `cardColor` with frosted alpha (65% dark, 85% light)
- **Dialog & Sheet Backdrops**: Derived modal and drawer backdrops

### 3. `tertiaryColor` Derivations (Borders & Boundaries)
- **Glass Specular Rims**: Illuminated specular sweep gradient in `_GlassSpecularBorderPainter` based on `tertiaryColor`
- **Subtle Borders**: `borderSubtle` (`tertiaryColor` with `UiAlpha.borderSubtle`, 18%) for glass panel rims, row dividers, sub-blocks
- **Strong Borders**: `borderStrong` (`tertiaryColor` with `UiAlpha.borderStrong`, 35%) for modal perimeters, card elevation borders
- **Frame Outlines**: Grouping frames on the infinite canvas (`frameBorder`)
- **Cautionary Feedback**: Warning chips, cautionary status toasts (`warning`)
- **Node Types**: `frameNode` (clustering frame outlines), `interNode` (bridge/interface nodes)

### 4. `accentColor` Derivations (Alerts & Urgency)
- **High Urgency**: Destructive action buttons (delete, purge, discard), critical error badges (`danger`)
- **Active Port Snapping**: Highlighted port socket when dragging a relation wire directly over a target (`portIndicatorActive`)
- **Attention Demands**: Overdue task chips, broken relation link highlights, unread/dirty badges
- **Expressive Freehand**: `drawingNode` (freehand sketches, annotations, ink), `shapeNode` (callout geometry)

### 5. `canvasAccentColor` Derivations (Tools & Topology)
- **Graph Topology**: Inactive node ports (`portIndicator`), relation line arrows/heads, bezier routing tension guides
- **Tool Ribbon**: Canvas navigation/pan tool icon, zoom percentage label, search magnifying glass
- **Grouping Containers**: Multi-node group containers (`containerBorder`), bounding box resize handles
- **External Data**: Web hyperlinks, external media badges, embed cards
- **Node Types**: `containerNode` (nesting containers), `mediaNode` (images, documents, file attachments)

### 6. Neutral Surfaces and Optical Elevation Model
All surfaces, canvas zones, cards, and interactive wells derive deterministically from `secondaryColor` using a **Universal Optical Elevation Model** in OKLCH space calibrated by polarity ($\text{polarity} = \text{isDark} ? -1.0 : 1.0$):
- **Elevation Constants**:
  - `elevationStep = 0.04` (standard optical elevation between surfaces)
  - `microElevationStep = 0.025` (subtle container nesting and secondary placeholders)
  - `recessedStep = 0.05` (control button and input well depth)
- **Brightness Derivation**: Evaluated dynamically via `ColorTheoryEngine.deriveBrightness(anchors)`. The perceptual luminance of `secondaryColor` (the background surface) dictates theme brightness: `relativeLuminance(secondaryColor) < 0.40 ? Brightness.dark : Brightness.light`. No manual `brightness` key exists in the theme configuration.
- **Scaffold Background**: Equal to `secondaryColor` directly.
- **Workspace Canvas (`workspaceBackground`)**:
  - Dark mode: $L = 0.0$ (ground zero, pure black).
  - Light mode: $L = 1.0 - \text{elevationStep} = 0.96$ (calibrated ground with headroom for floating cards, eliminating harsh pure white glare while preserving theme undertone).
- **Side Panel (`panel`)**:
  - Dark mode: $L = \text{secOklch.l}$ (dark grey secondary anchor).
  - Light mode: $L = \text{secOklch.l} + \text{elevationStep}$ (clean crisp bright panel elevated above the canvas for clear separation).
- **Floating Cards (`card`)**:
  - Dark mode: $L = \text{secOklch.l} + \text{elevationStep}$ (elevated dark card).
  - Light mode: $L = 1.0$ (pure crisp white floating cards).
- **Controls & Buttons (`control`)**:
  - Symmetrically recessed or elevated: $L = \text{secOklch.l} + (\text{polarity} \times \text{recessedStep})$. In dark mode, buttons are recessed wells; in light mode, they are elevated bright crisp surfaces.
- **Subtle Containers (`subtleSurface`)**:
  - Symmetrically stepped: $L = \text{secOklch.l} + (\text{polarity} \times \text{microElevationStep})$ for nested sub-blocks and secondary placeholders (like analytics box).
- **Dividers & Borders**: Derived from `tertiaryColor` with calibrated alpha.
- **Smart Adaptive Text**: Computed dynamically via `ColorTheoryEngine.bestContrastingTextColor(surface)` guaranteeing WCAG AAA ($\ge 7:1$) contrast across any underlying background.

---

## Standard Derivation Rules

When creating new components:
1. **Active Elements & Focus** $\to$ Derive from `primaryColor`.
2. **Backgrounds & Surfaces** $\to$ Derive from `secondaryColor`.
3. **Borders & Dividers** $\to$ Derive from `tertiaryColor` with calibrated alpha.
4. **Alerts, Destructive & Badges** $\to$ Derive from `accentColor`.
5. **Tools, Navigation & Routes** $\to$ Derive from `canvasAccentColor`.
6. **Perceptual Hue Shifts** $\to$ When adjacent varieties are required, rotate in OKLCH space using `ColorTheoryEngine.shiftHue(anchor, degrees)` to strictly preserve perceived lightness and chroma.
7. **Zero Fallbacks** $\to$ Never hardcode hex surfaces or fallback branches. If a color is derivable from the 5 pillars, compute it via `ColorTheoryEngine` or `CentrodeDerivedPalette`.

---

> **See also**: [Theme System](themes.md), [GUI Specification](../gui_specification.yaml)
