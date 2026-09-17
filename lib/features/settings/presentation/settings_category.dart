import 'package:flutter/material.dart';

enum SettingsCategory {
  appearance(
    label: 'Appearance',
    subtitle: 'Theming, liquid glass shaders, and typography',
    icon: Icons.palette_outlined,
  ),
  canvas(
    label: 'Canvas & Viewport',
    subtitle: 'Grid presets, snapping tolerance, and navigation mechanics',
    icon: Icons.grid_view_rounded,
  ),
  physics(
    label: 'Graph Physics',
    subtitle: 'Force-directed simulation, link stiffness, and repulsion',
    icon: Icons.bolt_outlined,
  ),
  relations(
    label: 'Relation Routing',
    subtitle: 'Pathfinding algorithms, corner radius, and edge styles',
    icon: Icons.alt_route_rounded,
  ),
  ontology(
    label: 'Ontology & AI',
    subtitle: 'Controlled vocabulary, vector similarity, and LLM reasoning',
    icon: Icons.psychology_outlined,
  ),
  storage(
    label: 'Storage & System',
    subtitle: 'Autosave intervals, workspace paths, and telemetry diagnostics',
    icon: Icons.storage_outlined,
  );

  final String label;
  final String subtitle;
  final IconData icon;

  const SettingsCategory({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}
