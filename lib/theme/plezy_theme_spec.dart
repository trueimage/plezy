import 'package:flutter/foundation.dart';

import '../focus/focus_tokens.dart';
import 'mono_theme.dart';
import 'surface_tokens.dart';

/// Everything a theme is built from: the [palette], plus the style overrides
/// a theme sets on top of the shared defaults.
///
/// Equal specs build the identical [ThemeData] (see `monoThemeFromSpec`), so
/// a spec rebuilt at runtime reuses the cached theme of an equal one.
@immutable
class PlezyThemeSpec {
  const PlezyThemeSpec(this.palette, {this.focus, this.surfaces});

  final MonoPalette palette;

  /// D-pad focus; null draws [FocusTokens.fallback].
  final FocusTokens? focus;

  /// Shapes, scrims and badges; null draws [SurfaceTokens.fallback].
  final SurfaceTokens? surfaces;

  @override
  bool operator ==(Object other) =>
      other is PlezyThemeSpec && other.palette == palette && other.focus == focus && other.surfaces == surfaces;

  @override
  int get hashCode => Object.hash(palette, focus, surfaces);
}
