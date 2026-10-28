import 'package:flutter/foundation.dart';

import '../focus/focus_tokens.dart';
import 'mono_theme.dart';
import 'plezy_layout.dart';
import 'surface_tokens.dart';
import 'type_scale.dart';

/// Everything a theme is built from: the [palette], plus the style overrides
/// a theme sets on top of the shared defaults.
///
/// Equal specs on the same target platform reuse the cached theme; see
/// `monoThemeFromSpec`.
@immutable
class PlezyThemeSpec {
  const PlezyThemeSpec(this.palette, {this.focus, this.surfaces, this.type, this.metrics, this.layout});

  final MonoPalette palette;

  /// D-pad focus; null draws [FocusTokens.fallback].
  final FocusTokens? focus;

  /// Shapes, scrims and badges; null draws [SurfaceTokens.fallback].
  final SurfaceTokens? surfaces;

  /// Text sizes and font family; null draws [TypeScale.fallback].
  final TypeScale? type;

  /// Radii, spacing and motion; null carries [MonoMetrics.classic].
  final MonoMetrics? metrics;

  /// The layout the theme draws; null for [PlezyLayout.classic], which the
  /// theme then does not carry at all.
  final PlezyLayout? layout;

  PlezyThemeSpec copyWith({MonoPalette? palette, PlezyLayout? layout}) => PlezyThemeSpec(
    palette ?? this.palette,
    focus: focus,
    surfaces: surfaces,
    type: type,
    metrics: metrics,
    layout: layout ?? this.layout,
  );

  /// This spec drawing the classic layout.
  PlezyThemeSpec withoutLayout() =>
      PlezyThemeSpec(palette, focus: focus, surfaces: surfaces, type: type, metrics: metrics);

  @override
  bool operator ==(Object other) =>
      other is PlezyThemeSpec &&
      other.palette == palette &&
      other.focus == focus &&
      other.surfaces == surfaces &&
      other.type == type &&
      other.metrics == metrics &&
      other.layout == layout;

  @override
  int get hashCode => Object.hash(palette, focus, surfaces, type, metrics, layout);
}
