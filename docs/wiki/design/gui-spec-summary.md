# GUI Specification Summary

> Last verified: 2026-08-16

Highlights from the full GUI specification (`gui_specification.yaml`, 1700+ lines).

---

## Full Spec

See [gui_specification.yaml](../gui_specification.yaml) for the complete specification.

---

## Theme Colors

### Core
| Token | Hex | Description |
|-------|-----|-------------|
| primary | `#1976D2` | Material Blue 700 |
| secondary | `#47A2FF` | Lighter blue accent |
| accent | `#FF4081` | Material Pink A200 |
| scaffold_background | `#F5F5F5` | Light grey |
| card | `#FFFFFF` | White |
| text | `#212121` | Dark grey |

### Interaction States
| Token | Hex | Description |
|-------|-----|-------------|
| hover_accent | `#90CAF9` | Light blue hover |
| selection_accent | `#42A5F5` | Blue selection ring |
| editing_accent | `#2196F3` | Blue editing state |

### Node States
| Token | ARGB | Description |
|-------|------|-------------|
| editing_shadow | `0x602196F3` | 37% alpha blue |
| selected_shadow | `0x4442A5F5` | 27% alpha blue |
| editing_border | `#2196F3` | Blue border |
| selected_border | `#42A5F5` | Blue border |

### Metadata Sphere
| Token | Hex | Description |
|-------|-----|-------------|
| tags_and_comments | `#EC407A` | Pink |
| tags_only | `#5C6BC0` | Indigo |
| comments_only | `#26A69A` | Teal |

---

## Node Type Colors

| Type | Hex | Preview |
|------|-----|---------|
| Info | `#90CAF9` | Light blue |
| Task | `#A5D6A7` | Green |
| Comment | `#B0BEC5` | Blue grey |
| Drawing | `#CE93D8` | Purple |
| Shape | `#FFCC80` | Orange |
| Frame | `#BCAAA4` | Brown |
| Container | `#64B5F6` | Blue |
| Media | `#80CBC4` | Teal |
| Inter | `#FFF59D` | Yellow |

---

## Canvas Specifications

- **Grid size**: Configurable (default 20px)
- **Min zoom**: 0.1x
- **Max zoom**: 5.0x
- **Node default size**: 100 x 80
- **Port radius**: 6px
- **Selection ring width**: 2px
- **Auto-pan threshold**: 50px from viewport edge

---

## Interaction Specifications

| Gesture | Action |
|---------|--------|
| Left click + drag on node | Move node |
| Left click + drag on empty | Pan canvas |
| Shift + left click + drag | Marquee select |
| Double click on node | Edit text |
| Right click | Context menu |
| Scroll wheel | Zoom |
| Ctrl+Z | Undo |
| Ctrl+Y / Ctrl+Shift+Z | Redo |
| Delete/Backspace | Delete selected |
| Ctrl+C | Copy |
| Ctrl+V | Paste |
