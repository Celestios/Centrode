library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'liquid_glass_settings.dart';
import 'liquid_glass_shader_provider.dart';

part 'liquid_glass_shape.dart';
part 'liquid_glass_stage.dart';
part 'liquid_glass_droplet.dart';
part 'liquid_glass_group.dart';

/// A backwards-compatible single-rect glass widget that uses [LiquidGlassGroup]
/// and [LiquidGlass] internally to preserve existing codebase references.
class LiquidGlassMenu extends StatelessWidget {
  final bool enabled;
  final double? width;
  final double? height;
  final Color color;
  final double borderRadius;
  final BoxShadow? shadow;
  final Widget? child;
  final LiquidGlassSettings settings;

  const LiquidGlassMenu({
    super.key,
    this.enabled = true,
    this.width,
    this.height,
    this.color = const Color(0x1AFFFFFF),
    this.borderRadius = 16.0,
    this.shadow,
    this.child,
    this.settings = const LiquidGlassSettings(),
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return SizedBox(width: width, height: height, child: child);
    }

    return LiquidGlassGroup(
      settings: settings,
      child: LiquidGlass(
        width: width,
        height: height,
        borderRadius: borderRadius,
        color: color,
        shadow: shadow,
        child: child,
      ),
    );
  }
}
