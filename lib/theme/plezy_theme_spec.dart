import 'package:flutter/foundation.dart';

import 'mono_theme.dart';

/// Everything a theme is built from: the [palette], plus the style overrides
/// a theme sets on top of the shared defaults.
///
/// Equal specs build the identical [ThemeData] (see `monoThemeFromSpec`), so
/// a spec rebuilt at runtime reuses the cached theme of an equal one.
@immutable
class PlezyThemeSpec {
  const PlezyThemeSpec(this.palette);

  final MonoPalette palette;

  @override
  bool operator ==(Object other) => other is PlezyThemeSpec && other.palette == palette;

  @override
  int get hashCode => palette.hashCode;
}
