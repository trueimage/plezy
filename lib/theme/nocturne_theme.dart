import 'package:flutter/material.dart';

import '../focus/focus_tokens.dart';
import 'mono_theme.dart';
import 'plezy_layout.dart';
import 'plezy_theme_spec.dart';
import 'surface_tokens.dart';
import 'type_scale.dart';

/// The accent the Nocturne theme carries progress, primary fills and the
/// focus glow in. Value names are the persisted ids.
enum NocturneAccent {
  /// Warm gold, the default.
  champagne(Color(0xFFE6C07A)),

  /// Near-white, for monochrome chrome.
  ivory(Color(0xFFEDE6D6)),

  /// Cool blue.
  ice(Color(0xFF9CCBFF));

  const NocturneAccent(this.color);

  final Color color;
}

/// The user's choices inside the Nocturne theme: a pure black canvas for OLED
/// panels, and the accent.
@immutable
class NocturneOptions {
  const NocturneOptions({this.trueBlack = false, this.accent = NocturneAccent.champagne});

  static const defaults = NocturneOptions();

  final bool trueBlack;
  final NocturneAccent accent;

  @override
  bool operator ==(Object other) => other is NocturneOptions && other.trueBlack == trueBlack && other.accent == accent;

  @override
  int get hashCode => Object.hash(trueBlack, accent);
}

/// Nocturne's design tokens: a cinematic dark theme whose artwork carries the
/// colour, with Manrope type, a white focus ring drawn outside the art and its
/// own layout.
abstract final class NocturneTheme {
  /// The family name the bundled Manrope variable font is declared under.
  static const fontFamily = 'Manrope';

  static const background = Color(0xFF0B0D12);
  static const trueBlackBackground = Color(0xFF000000);

  /// Status colours: Direct Play and downloaded, transcode and expiring,
  /// errors.
  static const positive = Color(0xFF79D2A6);
  static const caution = Color(0xFFF0A868);
  static const negative = Color(0xFFFF7676);

  /// The palette with the default options: `MonoPalette.nocturne`.
  static const palette = MonoPalette.nocturne;

  /// The palette for [options]; true black swaps only the canvas, so surfaces
  /// stay tonal.
  static MonoPalette paletteFor(NocturneOptions options) {
    if (options == NocturneOptions.defaults) return palette;
    return palette
        .withColor(MonoPaletteSlot.bg, options.trueBlack ? trueBlackBackground : background)
        .withColor(MonoPaletteSlot.accent, options.accent.color);
  }

  /// The full theme spec for [options], or for the palette of a Nocturne
  /// theme the caller already resolved.
  static PlezyThemeSpec spec([NocturneOptions options = NocturneOptions.defaults]) {
    final palette = paletteFor(options);
    return PlezyThemeSpec(
      palette,
      focus: focus,
      surfaces: surfacesFor(palette),
      type: type,
      metrics: metrics,
      layout: PlezyLayout.nocturne,
    );
  }

  /// Elevation 2 and 3: [MonoPalette.surface] lightened by 3.5% and 7.5%, so
  /// the six-slot palette stays the single source.
  static Color raisedSurfaceOf(MonoPalette palette) => _lighten(palette.surface, 0.035);
  static Color overlaySurfaceOf(MonoPalette palette) => _lighten(palette.surface, 0.075);

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static const metrics = MonoMetrics(
    radiusXs: 6,
    radiusSm: 10,
    radiusMd: 14,
    radiusLg: 22,
    groupGap: 2,
    space: 16,
    fast: Duration(milliseconds: 120),
    normal: Duration(milliseconds: 180),
    slow: Duration(milliseconds: 280),
    expressive: Duration(milliseconds: 320),
  );

  static const _ring = Color(0xFFFFFFFF);
  static const _halo = Color.from(alpha: 0.55, red: 0, green: 0, blue: 0);

  /// Default tier: posters grow 6%, a 3px white ring outside the art with a
  /// dark hairline, one accent glow, the rest of the screen dimmed (D-pad
  /// only). High contrast drops scale, glow and dim and thickens the ring.
  static const focus = FocusTokens(
    cardScale: 1.06,
    wideScale: 1.02,
    fullCardScale: 1.06,
    controlScale: 1.10,
    ringWidth: 3,
    ringStrokeAlign: BorderSide.strokeAlignOutside,
    ringColor: _ring,
    haloWidth: 1,
    haloColor: _halo,
    radius: 10,
    glow: [FocusGlowLayer(alpha: 0.38, blurRadius: 40, offset: Offset(0, 18))],
    buttonGlow: [FocusGlowLayer(alpha: 0.38, blurRadius: 24, offset: Offset(0, 12))],
    tileGlow: [FocusGlowLayer(alpha: 0.3, blurRadius: 18, offset: Offset(0, 10))],
    duration: Duration(milliseconds: 140),
    listStyle: FocusListStyle.inverted,
    dimOtherRows: 0.72,
    dimSiblings: 0.88,
    highContrast: highContrastFocus,
  );

  static const highContrastFocus = FocusTokens(
    cardScale: 1,
    wideScale: 1,
    fullCardScale: 1,
    controlScale: 1,
    ringWidth: 4,
    ringStrokeAlign: BorderSide.strokeAlignOutside,
    ringColor: _ring,
    haloWidth: 2,
    haloColor: Color(0xFF000000),
    radius: 10,
    glow: [],
    buttonGlow: [],
    tileGlow: [],
    duration: Duration(milliseconds: 140),
    listStyle: FocusListStyle.inverted,
  );

  /// The report's Manrope scale: TV sizes at 1080p, then desktop and phone.
  /// The TV browse rail's own labels stay near their classic sizes, because
  /// the rail sizes its cards for them.
  static const type = TypeScale(
    fontFamily: fontFamily,
    heroTitle: TypeSize(regular: 44, phone: 32, tv: 64),
    heroMeta: TypeSize(regular: 15, phone: 15, tv: 28),
    detailTitle: TypeSize(regular: 44, phone: 32, tv: 64),
    detailSubtitle: TypeSize(regular: 17, phone: 16, tv: 30),
    detailMeta: TypeSize(regular: 15, phone: 15, tv: 28),
    detailSummary: TypeSize(regular: 17, phone: 16, tv: 30),
    detailChip: TypeSize(regular: 14, phone: 13, tv: 24),
    sectionHeader: TypeSize(regular: 22, phone: 19, tv: 32),
    shelfHeader: TypeSize(regular: 22, phone: 19, tv: 32),
    shelfCount: TypeSize(regular: 12.5, phone: 12, tv: 24),
    shelfAction: TypeSize(regular: 14, phone: 14, tv: 26),
    railHeader: TypeSize(tv: 24),
    railServer: TypeSize(tv: 16),
    railCardTitle: TypeSize(tv: 14),
    railCardCaption: TypeSize(tv: 12),
    railAction: TypeSize(tv: 14),
    cardTitle: TypeSize(regular: 15, phone: 14),
    cardCaption: TypeSize(regular: 12.5, phone: 12),
    listTitle: TypeSize(regular: 14),
    listSubtitle: TypeSize(regular: 12),
    listMeta: TypeSize(regular: 11),
    labelBadge: TypeSize(regular: 10),
    countBadge: TypeSize(regular: 11),
    navLabel: TypeSize(regular: 14),
    navCaption: TypeSize(regular: 12),
    navSection: TypeSize(regular: 11),
    navNote: TypeSize(regular: 12),
    navLibrary: TypeSize(regular: 14),
    navLibraryServer: TypeSize(regular: 10),
  );

  /// Pre-rasterised scrims (never blur): a side fade behind the text column,
  /// a bottom fade into the page and a dark top edge for the rail and clock.
  static const sideScrim = ArtworkScrim([
    ScrimStop(0.0),
    ScrimStop(0.24),
    ScrimStop(0.42, alpha: 0.86),
    ScrimStop(0.70, alpha: 0),
  ]);
  static const bottomScrim = ArtworkScrim([ScrimStop(0.48, alpha: 0), ScrimStop(0.74, alpha: 0.72), ScrimStop(1.0)]);
  static const topScrim = ArtworkScrim([
    ScrimStop(0.0, alpha: 0.42, color: Color(0xFF000000)),
    ScrimStop(0.22, alpha: 0, color: Color(0xFF000000)),
  ]);

  /// High contrast: the same fades, held darker for longer.
  static const sideScrimStrong = ArtworkScrim([
    ScrimStop(0.0),
    ScrimStop(0.36),
    ScrimStop(0.56, alpha: 0.94),
    ScrimStop(0.82, alpha: 0),
  ]);

  static SurfaceTokens surfacesFor(MonoPalette palette) => SurfaceTokens(
    posterRadius: 10,
    cardRadius: 14,
    thumbnailRadius: 10,
    sheetRadius: 22,
    modalSheetRadius: 22,
    dialogRadius: 22,
    popupMenuRadius: 14,
    chipRadius: 999,
    imageChipRadius: 14,
    materialChipRadius: 999,
    skeletonRadius: 10,
    skeletonTextRadius: 6,
    raisedSurface: raisedSurfaceOf(palette),
    overlaySurface: overlaySurfaceOf(palette),
    spotlightSideScrim: sideScrim,
    detailTopScrim: topScrim,
    badgeShadows: const [],
    progressHeight: 5,
  );
}
