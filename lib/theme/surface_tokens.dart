import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'mono_tokens.dart';

/// One colour stop of an [ArtworkScrim].
@immutable
class ScrimStop {
  /// [color] at [alpha] (as is when null) at [stop]; a null [color] is the
  /// page background the scrim blends into.
  const ScrimStop(this.stop, {this.alpha, this.color});

  final double stop;
  final double? alpha;
  final Color? color;

  Color resolve(Color background) {
    final base = color ?? background;
    final alpha = this.alpha;
    return alpha == null ? base : base.withValues(alpha: alpha);
  }

  @override
  bool operator ==(Object other) =>
      other is ScrimStop && other.stop == stop && other.alpha == alpha && other.color == color;

  @override
  int get hashCode => Object.hash(stop, alpha, color);
}

/// A gradient laid over artwork so text on it stays legible, as colour stops
/// that may blend into the page background. The direction stays with the
/// widget that draws it.
@immutable
class ArtworkScrim {
  const ArtworkScrim(this.stops);

  final List<ScrimStop> stops;

  List<Color> colors(Color background) => [for (final stop in stops) stop.resolve(background)];

  List<double> get positions => [for (final stop in stops) stop.stop];

  /// The scrim as a gradient from [begin] to [end] over [background].
  LinearGradient gradient(Color background, {required Alignment begin, required Alignment end}) =>
      LinearGradient(begin: begin, end: end, colors: colors(background), stops: positions);

  @override
  bool operator ==(Object other) => other is ArtworkScrim && listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hashAll(stops);
}

/// Shapes, scrims and badges of the app's surfaces: posters, cards, sheets,
/// chips, dialogs, menus, skeletons and artwork overlays.
///
/// Read through [SurfaceTokens.of], which falls back to [fallback] when a theme
/// carries none.
@immutable
class SurfaceTokens extends ThemeExtension<SurfaceTokens> {
  const SurfaceTokens({
    this.posterRadius,
    this.cardRadius = 14,
    this.thumbnailRadius = 6,
    this.sheetRadius = 16,
    this.modalSheetRadius = 28,
    this.dialogRadius = 28,
    this.popupMenuRadius = 4,
    this.chipRadius = 20,
    this.imageChipRadius = 12,
    this.materialChipRadius = 8,
    this.skeletonRadius = 8,
    this.skeletonTextRadius = 4,
    this.raisedSurface,
    this.overlaySurface,
    this.homeHeroScrim = defaultHomeHeroScrim,
    this.homeHeroScrimTv = defaultHomeHeroScrimTv,
    this.spotlightSideScrim = defaultSpotlightSideScrim,
    this.spotlightScrim = defaultSpotlightScrim,
    this.detailHeroScrim = defaultDetailHeroScrim,
    this.detailTopScrim = defaultDetailTopScrim,
    this.badgeFill,
    this.badgeForeground,
    this.badgeShadows = defaultBadgeShadows,
    this.labelBadgeColor = const Color.from(alpha: 0.76, red: 0, green: 0, blue: 0),
    this.labelBadgeRadius = 4,
    this.progressHeight,
    this.badgeGrammar = BadgeGrammar.classic,
  });

  /// The shared default surfaces.
  static const fallback = SurfaceTokens();

  /// The theme's [SurfaceTokens], or [fallback] when it carries none.
  static SurfaceTokens of(BuildContext context) => Theme.of(context).extension<SurfaceTokens>() ?? fallback;

  /// Corner radius of poster artwork: [posterRadius], or `MonoTokens.radiusSm`.
  static double posterRadiusOf(BuildContext context) => of(context).posterRadius ?? tokens(context).radiusSm;

  static const defaultHomeHeroScrim = ArtworkScrim([
    ScrimStop(0.5, color: Colors.transparent),
    ScrimStop(0.85, alpha: 0.9),
    ScrimStop(0.94),
    ScrimStop(1.0),
  ]);
  static const defaultHomeHeroScrimTv = ArtworkScrim([
    ScrimStop(0.25, color: Colors.transparent),
    ScrimStop(0.78, alpha: 0.9),
    ScrimStop(0.94),
    ScrimStop(1.0),
  ]);
  static const defaultSpotlightSideScrim = ArtworkScrim([
    ScrimStop(0.0, alpha: 0.86),
    ScrimStop(0.56, alpha: 0.32),
    ScrimStop(1.0, color: Colors.transparent),
  ]);
  static const defaultSpotlightScrim = ArtworkScrim([
    ScrimStop(0.0, alpha: 0.45, color: Colors.black),
    ScrimStop(0.38, color: Colors.transparent),
    ScrimStop(1.0, alpha: 0.96),
  ]);

  /// A light dim over the whole art that eases into solid background by 94%;
  /// see the media detail hero for why the stops sit where they do.
  static const defaultDetailHeroScrim = ArtworkScrim([
    ScrimStop(0.94 * 0.0, alpha: 0.20),
    ScrimStop(0.94 * 0.125, alpha: 0.234),
    ScrimStop(0.94 * 0.25, alpha: 0.325),
    ScrimStop(0.94 * 0.375, alpha: 0.453),
    ScrimStop(0.94 * 0.5, alpha: 0.60),
    ScrimStop(0.94 * 0.625, alpha: 0.747),
    ScrimStop(0.94 * 0.75, alpha: 0.875),
    ScrimStop(0.94 * 0.875, alpha: 0.985),
    ScrimStop(0.94 * 0.9375, alpha: 0.998),
    ScrimStop(0.94 * 1.0, alpha: 1.0),
    ScrimStop(1.0),
  ]);
  static const defaultDetailTopScrim = ArtworkScrim([
    ScrimStop(0.0, alpha: 0.8),
    ScrimStop(0.3, alpha: 0.5),
    ScrimStop(1.0, alpha: 0),
  ]);
  static const defaultBadgeShadows = [
    BoxShadow(color: Color.from(alpha: 0.3, red: 0, green: 0, blue: 0), blurRadius: 4),
  ];

  /// Corner radius of poster artwork; null follows `MonoTokens.radiusSm`.
  final double? posterRadius;

  /// Corner radius of [Card]s.
  final double cardRadius;

  /// Corner radius of episode stills and season thumbnails.
  final double thumbnailRadius;

  /// Corner radius of the app's overlay sheets.
  final double sheetRadius;

  /// Top corner radius of Material modal bottom sheets.
  final double modalSheetRadius;
  final double dialogRadius;
  final double popupMenuRadius;

  /// Corner radius of the app's focusable filter and tab chips, and of a tab
  /// chip that shows a season poster.
  final double chipRadius;
  final double imageChipRadius;

  /// Corner radius of Material [Chip]s.
  final double materialChipRadius;

  /// Corner radius of a skeleton poster, and of its text lines.
  final double skeletonRadius;
  final double skeletonTextRadius;

  /// Reserved elevation-2 surface for chips, inputs and rows; not yet rendered.
  final Color? raisedSurface;

  /// Background override for Material bottom sheets, dialogs and popup menus;
  /// null keeps their respective scheme-derived defaults in `monoThemeFromSpec`.
  final Color? overlaySurface;

  /// Bottom fade of the home hero into the page, on phones and desktops and
  /// on TV.
  final ArtworkScrim homeHeroScrim;
  final ArtworkScrim homeHeroScrimTv;

  /// Left-to-right fade behind the TV spotlight's text column.
  final ArtworkScrim spotlightSideScrim;

  /// Top-to-bottom TV spotlight scrim: a dark top edge, clear middle, and a
  /// fade into the page.
  final ArtworkScrim spotlightScrim;

  /// Top-to-bottom fade of the media detail hero art into the page.
  final ArtworkScrim detailHeroScrim;

  /// Fade behind the media detail app bar.
  final ArtworkScrim detailTopScrim;

  /// Fill colour of the watched check and unwatched count; null uses `MonoTokens.text`.
  final Color? badgeFill;

  /// Glyph colour of the watched check and unwatched count; null uses `MonoTokens.bg`.
  final Color? badgeForeground;
  final List<BoxShadow> badgeShadows;

  /// Text labels on artwork, such as the catalog badges.
  final Color labelBadgeColor;
  final double labelBadgeRadius;

  /// Height of the progress bar along the bottom of artwork; null keeps the
  /// size preset's.
  final double? progressHeight;

  /// Which badges artwork carries and where.
  final BadgeGrammar badgeGrammar;

  @override
  SurfaceTokens copyWith({
    double? posterRadius,
    double? cardRadius,
    double? thumbnailRadius,
    double? sheetRadius,
    double? modalSheetRadius,
    double? dialogRadius,
    double? popupMenuRadius,
    double? chipRadius,
    double? imageChipRadius,
    double? materialChipRadius,
    double? skeletonRadius,
    double? skeletonTextRadius,
    Color? raisedSurface,
    Color? overlaySurface,
    ArtworkScrim? homeHeroScrim,
    ArtworkScrim? homeHeroScrimTv,
    ArtworkScrim? spotlightSideScrim,
    ArtworkScrim? spotlightScrim,
    ArtworkScrim? detailHeroScrim,
    ArtworkScrim? detailTopScrim,
    Color? badgeFill,
    Color? badgeForeground,
    List<BoxShadow>? badgeShadows,
    Color? labelBadgeColor,
    double? labelBadgeRadius,
    double? progressHeight,
    BadgeGrammar? badgeGrammar,
  }) => SurfaceTokens(
    posterRadius: posterRadius ?? this.posterRadius,
    cardRadius: cardRadius ?? this.cardRadius,
    thumbnailRadius: thumbnailRadius ?? this.thumbnailRadius,
    sheetRadius: sheetRadius ?? this.sheetRadius,
    modalSheetRadius: modalSheetRadius ?? this.modalSheetRadius,
    dialogRadius: dialogRadius ?? this.dialogRadius,
    popupMenuRadius: popupMenuRadius ?? this.popupMenuRadius,
    chipRadius: chipRadius ?? this.chipRadius,
    imageChipRadius: imageChipRadius ?? this.imageChipRadius,
    materialChipRadius: materialChipRadius ?? this.materialChipRadius,
    skeletonRadius: skeletonRadius ?? this.skeletonRadius,
    skeletonTextRadius: skeletonTextRadius ?? this.skeletonTextRadius,
    raisedSurface: raisedSurface ?? this.raisedSurface,
    overlaySurface: overlaySurface ?? this.overlaySurface,
    homeHeroScrim: homeHeroScrim ?? this.homeHeroScrim,
    homeHeroScrimTv: homeHeroScrimTv ?? this.homeHeroScrimTv,
    spotlightSideScrim: spotlightSideScrim ?? this.spotlightSideScrim,
    spotlightScrim: spotlightScrim ?? this.spotlightScrim,
    detailHeroScrim: detailHeroScrim ?? this.detailHeroScrim,
    detailTopScrim: detailTopScrim ?? this.detailTopScrim,
    badgeFill: badgeFill ?? this.badgeFill,
    badgeForeground: badgeForeground ?? this.badgeForeground,
    badgeShadows: badgeShadows ?? this.badgeShadows,
    labelBadgeColor: labelBadgeColor ?? this.labelBadgeColor,
    labelBadgeRadius: labelBadgeRadius ?? this.labelBadgeRadius,
    progressHeight: progressHeight ?? this.progressHeight,
    badgeGrammar: badgeGrammar ?? this.badgeGrammar,
  );

  /// Numbers and colours interpolate; scrims and shadows, which have no
  /// meaningful in-between, switch at the midpoint.
  @override
  SurfaceTokens lerp(covariant SurfaceTokens? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    T snap<T>(T a, T b) => t < 0.5 ? a : b;
    double? nd(double? a, double? b) => a == null || b == null ? snap(a, b) : d(a, b);
    Color? c(Color? a, Color? b) => a == null || b == null ? snap(a, b) : Color.lerp(a, b, t);
    return SurfaceTokens(
      posterRadius: nd(posterRadius, other.posterRadius),
      cardRadius: d(cardRadius, other.cardRadius),
      thumbnailRadius: d(thumbnailRadius, other.thumbnailRadius),
      sheetRadius: d(sheetRadius, other.sheetRadius),
      modalSheetRadius: d(modalSheetRadius, other.modalSheetRadius),
      dialogRadius: d(dialogRadius, other.dialogRadius),
      popupMenuRadius: d(popupMenuRadius, other.popupMenuRadius),
      chipRadius: d(chipRadius, other.chipRadius),
      imageChipRadius: d(imageChipRadius, other.imageChipRadius),
      materialChipRadius: d(materialChipRadius, other.materialChipRadius),
      skeletonRadius: d(skeletonRadius, other.skeletonRadius),
      skeletonTextRadius: d(skeletonTextRadius, other.skeletonTextRadius),
      raisedSurface: c(raisedSurface, other.raisedSurface),
      overlaySurface: c(overlaySurface, other.overlaySurface),
      homeHeroScrim: snap(homeHeroScrim, other.homeHeroScrim),
      homeHeroScrimTv: snap(homeHeroScrimTv, other.homeHeroScrimTv),
      spotlightSideScrim: snap(spotlightSideScrim, other.spotlightSideScrim),
      spotlightScrim: snap(spotlightScrim, other.spotlightScrim),
      detailHeroScrim: snap(detailHeroScrim, other.detailHeroScrim),
      detailTopScrim: snap(detailTopScrim, other.detailTopScrim),
      badgeFill: c(badgeFill, other.badgeFill),
      badgeForeground: c(badgeForeground, other.badgeForeground),
      badgeShadows: snap(badgeShadows, other.badgeShadows),
      labelBadgeColor: c(labelBadgeColor, other.labelBadgeColor)!,
      labelBadgeRadius: d(labelBadgeRadius, other.labelBadgeRadius),
      progressHeight: nd(progressHeight, other.progressHeight),
      badgeGrammar: snap(badgeGrammar, other.badgeGrammar),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SurfaceTokens &&
      other.posterRadius == posterRadius &&
      other.cardRadius == cardRadius &&
      other.thumbnailRadius == thumbnailRadius &&
      other.sheetRadius == sheetRadius &&
      other.modalSheetRadius == modalSheetRadius &&
      other.dialogRadius == dialogRadius &&
      other.popupMenuRadius == popupMenuRadius &&
      other.chipRadius == chipRadius &&
      other.imageChipRadius == imageChipRadius &&
      other.materialChipRadius == materialChipRadius &&
      other.skeletonRadius == skeletonRadius &&
      other.skeletonTextRadius == skeletonTextRadius &&
      other.raisedSurface == raisedSurface &&
      other.overlaySurface == overlaySurface &&
      other.homeHeroScrim == homeHeroScrim &&
      other.homeHeroScrimTv == homeHeroScrimTv &&
      other.spotlightSideScrim == spotlightSideScrim &&
      other.spotlightScrim == spotlightScrim &&
      other.detailHeroScrim == detailHeroScrim &&
      other.detailTopScrim == detailTopScrim &&
      other.badgeFill == badgeFill &&
      other.badgeForeground == badgeForeground &&
      listEquals(other.badgeShadows, badgeShadows) &&
      other.labelBadgeColor == labelBadgeColor &&
      other.labelBadgeRadius == labelBadgeRadius &&
      other.progressHeight == progressHeight &&
      other.badgeGrammar == badgeGrammar;

  @override
  int get hashCode => Object.hashAll([
    posterRadius,
    cardRadius,
    thumbnailRadius,
    sheetRadius,
    modalSheetRadius,
    dialogRadius,
    popupMenuRadius,
    chipRadius,
    imageChipRadius,
    materialChipRadius,
    skeletonRadius,
    skeletonTextRadius,
    raisedSurface,
    overlaySurface,
    homeHeroScrim,
    homeHeroScrimTv,
    spotlightSideScrim,
    spotlightScrim,
    detailHeroScrim,
    detailTopScrim,
    badgeFill,
    badgeForeground,
    Object.hashAll(badgeShadows),
    labelBadgeColor,
    labelBadgeRadius,
    progressHeight,
    badgeGrammar,
  ]);
}

/// The badges artwork carries. Every flag is off in the classic grammar, so
/// existing themes draw exactly what they did.
@immutable
class BadgeGrammar {
  const BadgeGrammar({this.unwatchedDot = false, this.countTopLeft = false, this.reasonTag = false});

  /// Classic: a check when watched, the unwatched count top-right.
  static const classic = BadgeGrammar();

  /// An accent dot top-right on an unwatched, unstarted movie.
  final bool unwatchedDot;

  /// The unwatched-episode count is an accent pill top-left, clear of the
  /// check.
  final bool countTopLeft;

  /// A reason tag ("Next up") top-left on Continue Watching cards that
  /// have not been started.
  final bool reasonTag;

  @override
  bool operator ==(Object other) =>
      other is BadgeGrammar &&
      other.unwatchedDot == unwatchedDot &&
      other.countTopLeft == countTopLeft &&
      other.reasonTag == reasonTag;

  @override
  int get hashCode => Object.hash(unwatchedDot, countTopLeft, reasonTag);
}
