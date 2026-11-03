# Centrode

<p align="center">
  <img src="assets/branding/banner.png" alt="Centrode Banner" width="100%">
</p>

<p align="center">
  <a href="#license"><img src="https://img.shields.io/badge/license-Proprietary-red.svg?style=flat-square" alt="License"></a>
  <a href="https://github.com/Celestios/Centrode/releases"><img src="https://img.shields.io/badge/version-v0.10.1--preview-blue.svg?style=flat-square" alt="Version 0.10.0 Preview"></a>
  <a href="https://github.com/Celestios/Centrode/releases"><img src="https://img.shields.io/badge/platform-Windows%20%7C%20Android-green.svg?style=flat-square" alt="Platform"></a>
  <img src="https://img.shields.io/badge/architecture-Flutter%20%7C%20Rust-orange.svg?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/storage-Local%20First-00D4B2.svg?style=flat-square" alt="Storage">
</p>

<p align="center">
  <strong>The central hub for your personal knowledge, connections, and thought.</strong><br>
  <em>Because your mind isn’t linear. Your tools shouldn’t be either.</em>
</p>

<p align="center">
  <a href="README.md">English</a> • <a href="README_fa.md">فارسی</a>
</p>

---

## Visual Preview

<p align="center">
  <img src="assets/screenshots/canvas_main.png" alt="Centrode Infinite Canvas Workspace" width="100%">
  <br>
  <em>Infinite spatial canvas with connection routing and nested structures</em>
</p>

<p align="center">
  <img src="assets/screenshots/workspace_hub.png" alt="Centrode Workspace Hub" width="49%">
  <img src="assets/screenshots/container_nesting.png" alt="Centrode Nested Nodes" width="49%">
</p>

---

## What is Centrode?

Centrode is a local-first, privacy-focused personal knowledge tool designed to organize ideas, research, and project structures into an interconnected visual network.

Unlike web-based or Electron-wrapped tools, Centrode operates completely offline and pairs a native Flutter graphical interface with an embedded Rust database engine via high-speed native bindings. All graph structures, notes, and attachments are stored locally on your device with content-addressable asset management—ensuring complete data privacy with zero external server dependencies, instant startup, and minimal memory consumption.

Currently distributed for modern **Windows (64-bit)** and **Android (ARM64)** devices.

---

## Downloads

> **Note:** Centrode is currently in active pre-release development. Version **v0.10.1-preview** is available for testing on Windows and Android.

Download pre-compiled binaries from [GitHub Releases](https://github.com/Celestios/Centrode/releases/latest):

| Platform | Package | Architecture | Download |
| :--- | :--- | :--- | :--- |
| **Windows** | Setup Installer | x64 | [centrode-windows-x64-installer.exe](https://github.com/Celestios/Centrode/releases/download/v0.10.1/centrode-windows-x64-installer.exe) |
| **Windows** | Standalone Portable Archive | x64 | [centrode-windows-x64.zip](https://github.com/Celestios/Centrode/releases/download/v0.10.1/centrode-windows-x64.zip) |
| **Android** | Standalone APK | ARM64 (v8a) | [app-arm64-v8a-release.apk](https://github.com/Celestios/Centrode/releases/download/v0.10.1/app-arm64-v8a-release.apk) |

*For previous builds and release notes, visit the [Releases page](https://github.com/Celestios/Centrode/releases).*

---

## Core Capabilities

### Dynamic Workspace & Spatial Canvas
- **Infinite Canvas**: Pan, zoom, and organize information freely across an expansive spatial workspace.
- **Hierarchical Nodes**: Nest concept groups and sub-canvases inside parent nodes with smooth zoom transitions.
- **Structural Frames**: Group related nodes across the canvas using visual container boundaries.
- **Flexible Node Placement**: Quickly create and position nodes anywhere across your workspace.
- **Connection Routing**: Draw connections between nodes with automated path routing around canvas obstacles.

### Native Typography & Formatting Engine
- **Markdown Support**: Formatted text editing and layout directly inside canvas nodes.
- **Bidirectional (BiDi) Text**: Built-in support for Right-to-Left (RTL), Left-to-Right (LTR), and mixed-direction scripts.

---

## Roadmap & Future Plans

### Immediate Focus: Stabilization & Optimization
*Active refinement and performance tuning currently in progress:*

- [ ] **Performance & Shader Optimization**: Profiling memory consumption and optimizing glass and blur rendering pipelines.
- [ ] **Routing Stability**: Improving relation path calculation, shape consistency, and crossing avoidance.
- [ ] **Node & Connection Customization**: Expanded visual styling, color palettes, and edge controls.
- [ ] **Portable Packaging (`.cent`)**: Single-file map export and import bundling graph structure, schemas, and asset payloads.
- [ ] **Embedded Transformer Intelligence**: Lightweight, on-device encoder models for local semantic search, relation inference, and contextual tagging.

### Near-Term Pipeline
*Features scheduled following the stabilization phase:*

- [ ] **External Agent Protocol (MCP / API)**: Deep API and Model Context Protocol (MCP) integration with leading generative LLMs, enabling a collaborative human-AI workspace where models inspect, co-create, and reason across your knowledge graph alongside you.
- [ ] **Alternate Structural Perspectives**: Dedicated Timeline and Global Graph explorer views.

### Long-Term Vision
- [ ] **Integrated Execution System**: Task tracking architecture, task node variants, calendar timelines, and scheduling workflows.

---

## License

Centrode is a proprietary, closed-source application. All rights reserved. Unauthorized decompilation, reverse engineering, redistribution, or duplication of this software and its associated distribution assets is strictly prohibited. For licensing inquiries and distribution requests, refer to the official application documentation.
