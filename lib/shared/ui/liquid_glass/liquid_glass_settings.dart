import 'package:flutter/material.dart';

/// Configuration class that holds all visual parameters for the liquid glass shader effect.
/// These parameters control various aspects like refraction, blur, lighting, and color.
class LiquidGlassSettings {
  // Shader uniform parameters - these control the visual appearance of the glass effect
  final double blendPx;           // Edge blending distance in pixels for smooth transitions
  final double refractStrength;   // Strength of light refraction (-1.0 to 1.0, negative = concave lens)
  final double distortFalloffPx;  // Distance over which distortion effect fades out
  final double distortExponent;   // Controls how sharply distortion falls off (higher = sharper)
  final double blurRadiusPx;      // Base blur radius applied to the glass area
  
  // Specular highlight parameters - creates the shiny reflection on glass surface
  final double specAngle;         // Light source angle for specular highlights
  final double specStrength;      // Intensity of specular highlights
  final double specPower;         // Sharpness of specular highlights (higher = sharper)
  final double specWidth;         // Specular width in px
  
  // Light band effect - creates a bright band across the glass for realism
  final double lightbandOffsetPx; // Distance from edge where light band appears
  final double lightbandWidthPx;  // Width of the light band effect
  final double lightbandStrength; // Intensity of the light band
  final Color lightbandColor;     // Color of the light band

  // Bridge blending parameters
  final double bridgeReachFactor;     // How far bridges reach between elements
  final double bridgeThicknessFactor; // Thickness multiplier for the bridges

  // Fallback and specular specific tuning
  final double fallbackTintAlpha;
  final double specularStrengthDivisor;
  final double maxSpecularAlpha;
  final double minSpecularAngularWidth;
  final double maxSpecularAngularWidth;
  final double specularStrokeWidthScale;
  final double rimHighlightStrokeWidthScale;

  // Coordinate system configuration
  final bool useLocalCoordinates; // True for Impeller (local logical coordinates), false for Skia (global physical coordinates)
  
  // Debug/Test settings
  final bool forceCpuFallback; // Forcing fallback rendering when shader is not supported or for testing

  const LiquidGlassSettings({
    this.blendPx = 14.0,
    this.refractStrength = 0.0,
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

    this.useLocalCoordinates = true,
    this.forceCpuFallback = false,
  });

  /// Creates a copy of this settings object with the given fields replaced with new values.
  LiquidGlassSettings copyWith({
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
    return LiquidGlassSettings(
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
