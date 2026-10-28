import 'package:flutter/foundation.dart';

import '../focus/focus_tokens.dart';
import 'mono_theme.dart';
import 'surface_tokens.dart';
import 'type_scale.dart';

/// Everything a theme is built from: the [palette], plus the style overrides
/// a theme sets on top of the shared defaults.
///
/// Equal specs on the same target platform reuse the cached theme; see
/// `monoThemeFromSpec`.
@immutable
class PlezyThemeSpec {
  const PlezyThemeSpec(this.palette, {this.focus, this.surfaces, this.type});

  final MonoPalette palette;

  /// D-pad focus; null draws [FocusTokens.fallback].
  final FocusTokens? focus;

  /// Shapes, scrims and badges; null draws [SurfaceTokens.fallback].
  final SurfaceTokens? surfaces;

  /// Text sizes and font family; null draws [TypeScale.fallback].
  final TypeScale? type;

  @override
  bool operator ==(Object other) =>
      other is PlezyThemeSpec &&
      other.palette == palette &&
      other.focus == focus &&
      other.surfaces == surfaces &&
      other.type == type;

  @override
  int get hashCode => Object.hash(palette, focus, surfaces, type);
}
