part of '../glass_panel.dart';

/// Configuration for the liquid-glass shader effect.
class GlassSettings {
  final double blendPx;
  final double refractStrength;
  final double distortFalloffPx;
  final double distortExponent;
  final double blurRadiusPx;

  final double specAngle;
  final double specStrength;
  final double specPower;
  final double specWidth;

  final double lightbandOffsetPx;
  final double lightbandWidthPx;
  final double lightbandStrength;
  final Color lightbandColor;

  final double bridgeReachFactor;
  final double bridgeThicknessFactor;

  final double fallbackTintAlpha;
  final double specularStrengthDivisor;
  final double maxSpecularAlpha;
  final double minSpecularAngularWidth;
  final double maxSpecularAngularWidth;
  final double specularStrokeWidthScale;
  final double rimHighlightStrokeWidthScale;

  final bool useLocalCoordinates;
  final bool forceCpuFallback;

  const GlassSettings({
    this.blendPx = 14.0,
    this.refractStrength = 0.08,
    this.distortFalloffPx = 45.0,
    this.distortExponent = 4.0,
    this.blurRadiusPx = 7.0,
    this.specAngle = 4.0,
    this.specStrength = 2.0,
    this.specPower = 100.0,
    this.specWidth = 10.0,
    this.lightbandOffsetPx = 10.0,
    this.lightbandWidthPx = 30.0,
    this.lightbandStrength = 0.9,
    this.lightbandColor = Colors.white,
    this.bridgeReachFactor = 2.0,
    this.bridgeThicknessFactor = 1.0,
    this.fallbackTintAlpha = 0.12,
    this.specularStrengthDivisor = 25.0,
    this.maxSpecularAlpha = 0.9,
    this.minSpecularAngularWidth = 0.18,
    this.maxSpecularAngularWidth = 1.2,
    this.specularStrokeWidthScale = 0.08,
    this.rimHighlightStrokeWidthScale = 0.06,
    this.useLocalCoordinates = false,
    this.forceCpuFallback = false,
  });

  GlassSettings copyWith({
    double? blendPx,
    double? refractStrength,
    double? distortFalloffPx,
    double? distortExponent,
    double? blurRadiusPx,
    double? specAngle,
    double? specStrength,
    double? specPower,
    double? specWidth,
    double? lightbandOffsetPx,
    double? lightbandWidthPx,
    double? lightbandStrength,
    Color? lightbandColor,
    double? bridgeReachFactor,
    double? bridgeThicknessFactor,
    double? fallbackTintAlpha,
    double? specularStrengthDivisor,
    double? maxSpecularAlpha,
    double? minSpecularAngularWidth,
    double? maxSpecularAngularWidth,
    double? specularStrokeWidthScale,
    double? rimHighlightStrokeWidthScale,
    bool? useLocalCoordinates,
    bool? forceCpuFallback,
  }) {
    return GlassSettings(
      blendPx: blendPx ?? this.blendPx,
      refractStrength: refractStrength ?? this.refractStrength,
      distortFalloffPx: distortFalloffPx ?? this.distortFalloffPx,
      distortExponent: distortExponent ?? this.distortExponent,
      blurRadiusPx: blurRadiusPx ?? this.blurRadiusPx,
      specAngle: specAngle ?? this.specAngle,
      specStrength: specStrength ?? this.specStrength,
      specPower: specPower ?? this.specPower,
      specWidth: specWidth ?? this.specWidth,
      lightbandOffsetPx: lightbandOffsetPx ?? this.lightbandOffsetPx,
      lightbandWidthPx: lightbandWidthPx ?? this.lightbandWidthPx,
      lightbandStrength: lightbandStrength ?? this.lightbandStrength,
      lightbandColor: lightbandColor ?? this.lightbandColor,
      bridgeReachFactor: bridgeReachFactor ?? this.bridgeReachFactor,
      bridgeThicknessFactor: bridgeThicknessFactor ?? this.bridgeThicknessFactor,
      fallbackTintAlpha: fallbackTintAlpha ?? this.fallbackTintAlpha,
      specularStrengthDivisor: specularStrengthDivisor ?? this.specularStrengthDivisor,
      maxSpecularAlpha: maxSpecularAlpha ?? this.maxSpecularAlpha,
      minSpecularAngularWidth: minSpecularAngularWidth ?? this.minSpecularAngularWidth,
      maxSpecularAngularWidth: maxSpecularAngularWidth ?? this.maxSpecularAngularWidth,
      specularStrokeWidthScale: specularStrokeWidthScale ?? this.specularStrokeWidthScale,
      rimHighlightStrokeWidthScale: rimHighlightStrokeWidthScale ?? this.rimHighlightStrokeWidthScale,
      useLocalCoordinates: useLocalCoordinates ?? this.useLocalCoordinates,
      forceCpuFallback: forceCpuFallback ?? this.forceCpuFallback,
    );
  }
}
