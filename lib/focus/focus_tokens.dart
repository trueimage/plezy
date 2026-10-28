import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'focus_theme.dart';

/// One blurred layer of a focus glow, tinted with the glow colour at [alpha].
@immutable
class FocusGlowLayer {
  const FocusGlowLayer({
    required this.alpha,
    required this.blurRadius,
    this.spreadRadius = 0,
    this.offset = Offset.zero,
  });

  final double alpha;
  final double blurRadius;
  final double spreadRadius;
  final Offset offset;

  BoxShadow shadow(Color color) => BoxShadow(
    color: color.withValues(alpha: alpha),
    blurRadius: blurRadius,
    spreadRadius: spreadRadius,
    offset: offset,
  );

  static FocusGlowLayer lerp(FocusGlowLayer a, FocusGlowLayer b, double t) => FocusGlowLayer(
    alpha: lerpDouble(a.alpha, b.alpha, t)!,
    blurRadius: lerpDouble(a.blurRadius, b.blurRadius, t)!,
    spreadRadius: lerpDouble(a.spreadRadius, b.spreadRadius, t)!,
    offset: Offset.lerp(a.offset, b.offset, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is FocusGlowLayer &&
      other.alpha == alpha &&
      other.blurRadius == blurRadius &&
      other.spreadRadius == spreadRadius &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(alpha, blurRadius, spreadRadius, offset);
}

/// How a focused row in a list (settings tiles, options, episodes) shows focus.
enum FocusListStyle {
  /// A translucent text-coloured fill behind the row.
  fill,

  /// The row inverts: a light fill with dark text.
  inverted,
}

/// The geometry and colours of D-pad focus: scale, ring, halo, glow and dim.
///
/// Read through `FocusTheme.of(context)`, which falls back to [fallback] when a
/// theme carries none. [fallback] is the focus every built-in theme draws.
@immutable
class FocusTokens extends ThemeExtension<FocusTokens> {
  const FocusTokens({
    this.cardScale = FocusTheme.focusScale,
    this.wideScale = FocusTheme.focusScale,
    this.fullCardScale = FocusTheme.fullCardFocusScale,
    this.controlScale = FocusTheme.playerControlFocusScale,
    this.ringWidth = FocusTheme.focusBorderWidth,
    this.ringStrokeAlign = BorderSide.strokeAlignInside,
    this.ringColor,
    this.haloWidth = 0,
    this.haloColor = const Color.from(alpha: 0.55, red: 0, green: 0, blue: 0),
    this.radius = FocusTheme.defaultBorderRadius,
    this.glow = defaultGlow,
    this.glowColor,
    this.buttonGlow = defaultButtonGlow,
    this.tileGlow = defaultTileGlow,
    this.duration,
    this.backgroundFill = const Color.from(alpha: 0.2, red: 1, green: 1, blue: 1),
    this.textFillAlpha = 0.12,
    this.controlFill = Colors.white,
    this.controlActiveFill = const Color(0xFFFFC107), // Colors.amber
    this.listStyle = FocusListStyle.fill,
    this.dimOtherRows = 1,
    this.dimSiblings = 1,
    this.highContrast,
  });

  /// The focus every built-in theme draws.
  static const fallback = FocusTokens();

  static const defaultGlow = [
    FocusGlowLayer(
      alpha: 0.34,
      blurRadius: FocusTheme.focusGlowInnerBlurRadius,
      spreadRadius: FocusTheme.focusGlowSpreadRadius,
    ),
    FocusGlowLayer(alpha: 0.2, blurRadius: FocusTheme.focusGlowOuterBlurRadius),
  ];
  static const defaultButtonGlow = [FocusGlowLayer(alpha: 0.35, blurRadius: 28, spreadRadius: 4)];
  static const defaultTileGlow = [FocusGlowLayer(alpha: 0.2, blurRadius: 18, spreadRadius: 1)];

  /// Scale of a focused poster or media card.
  final double cardScale;

  /// Scale of every other focusable: wide cards, buttons, chips and rows.
  final double wideScale;

  /// Scale of a focused card in the full-card (full-bleed) layout.
  final double fullCardScale;

  /// Scale of a small control, such as a round player button, where the card
  /// scale is too small to see.
  final double controlScale;

  final double ringWidth;

  /// [BorderSide.strokeAlign] of the ring: inside the shape, centred, or
  /// outside it. Callers that state their own alignment keep it.
  final double ringStrokeAlign;

  /// Ring colour; null draws it in `colorScheme.primary`.
  final Color? ringColor;

  /// Width of a dark hairline around the ring, so a light ring stays legible
  /// on light artwork; 0 for none. The classic ring draws no halo.
  final double haloWidth;
  final Color haloColor;

  /// Default corner radius of the ring when a caller states none.
  final double radius;

  /// The glow around a focused card, drawn above its neighbours.
  final List<FocusGlowLayer> glow;

  /// Glow colour; null draws it in `colorScheme.primary`.
  final Color? glowColor;

  /// The glow around the focused home hero Play button.
  final List<FocusGlowLayer> buttonGlow;

  /// The glow around a focused action tile at the end of a TV row.
  final List<FocusGlowLayer> tileGlow;

  /// Focus transition length; null uses `MonoTokens.fast`.
  final Duration? duration;

  /// Fill of the background-style focus used on video-control surfaces.
  final Color backgroundFill;

  /// Alpha of the text-coloured fill on mono surfaces (lists, the rail).
  final double textFillAlpha;

  /// Fill of a focused round control over video, and of an active one.
  final Color controlFill;
  final Color controlActiveFill;

  final FocusListStyle listStyle;

  /// Opacity of the rows other than the focused one, and of the cards beside
  /// the focused card in its row; 1 dims nothing.
  final double dimOtherRows;
  final double dimSiblings;

  /// The focus to draw instead when the platform asks for high contrast; null
  /// keeps this one.
  final FocusTokens? highContrast;

  /// How far [glow] visibly reaches beyond the card edge, used to size the
  /// overlay the glow paints in so its blur is not clipped.
  double get glowExtent => glowExtentOf(glow);

  static double glowExtentOf(List<FocusGlowLayer> layers) {
    var blur = 0.0;
    var spread = 0.0;
    var offset = 0.0;
    for (final layer in layers) {
      blur = math.max(blur, layer.blurRadius);
      spread = math.max(spread, layer.spreadRadius);
      offset = math.max(offset, math.max(layer.offset.dx.abs(), layer.offset.dy.abs()));
    }
    return blur * 2 + spread + offset;
  }

  @override
  FocusTokens copyWith({
    double? cardScale,
    double? wideScale,
    double? fullCardScale,
    double? controlScale,
    double? ringWidth,
    double? ringStrokeAlign,
    Color? ringColor,
    double? haloWidth,
    Color? haloColor,
    double? radius,
    List<FocusGlowLayer>? glow,
    Color? glowColor,
    List<FocusGlowLayer>? buttonGlow,
    List<FocusGlowLayer>? tileGlow,
    Duration? duration,
    Color? backgroundFill,
    double? textFillAlpha,
    Color? controlFill,
    Color? controlActiveFill,
    FocusListStyle? listStyle,
    double? dimOtherRows,
    double? dimSiblings,
    FocusTokens? highContrast,
  }) => FocusTokens(
    cardScale: cardScale ?? this.cardScale,
    wideScale: wideScale ?? this.wideScale,
    fullCardScale: fullCardScale ?? this.fullCardScale,
    controlScale: controlScale ?? this.controlScale,
    ringWidth: ringWidth ?? this.ringWidth,
    ringStrokeAlign: ringStrokeAlign ?? this.ringStrokeAlign,
    ringColor: ringColor ?? this.ringColor,
    haloWidth: haloWidth ?? this.haloWidth,
    haloColor: haloColor ?? this.haloColor,
    radius: radius ?? this.radius,
    glow: glow ?? this.glow,
    glowColor: glowColor ?? this.glowColor,
    buttonGlow: buttonGlow ?? this.buttonGlow,
    tileGlow: tileGlow ?? this.tileGlow,
    duration: duration ?? this.duration,
    backgroundFill: backgroundFill ?? this.backgroundFill,
    textFillAlpha: textFillAlpha ?? this.textFillAlpha,
    controlFill: controlFill ?? this.controlFill,
    controlActiveFill: controlActiveFill ?? this.controlActiveFill,
    listStyle: listStyle ?? this.listStyle,
    dimOtherRows: dimOtherRows ?? this.dimOtherRows,
    dimSiblings: dimSiblings ?? this.dimSiblings,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  FocusTokens lerp(covariant FocusTokens? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    T snap<T>(T a, T b) => t < 0.5 ? a : b;
    Color? c(Color? a, Color? b) => a == null || b == null ? snap(a, b) : Color.lerp(a, b, t);
    List<FocusGlowLayer> layers(List<FocusGlowLayer> a, List<FocusGlowLayer> b) =>
        a.length == b.length ? [for (var i = 0; i < a.length; i++) FocusGlowLayer.lerp(a[i], b[i], t)] : snap(a, b);
    final duration = this.duration;
    final otherDuration = other.duration;
    return FocusTokens(
      cardScale: d(cardScale, other.cardScale),
      wideScale: d(wideScale, other.wideScale),
      fullCardScale: d(fullCardScale, other.fullCardScale),
      controlScale: d(controlScale, other.controlScale),
      ringWidth: d(ringWidth, other.ringWidth),
      ringStrokeAlign: d(ringStrokeAlign, other.ringStrokeAlign),
      ringColor: c(ringColor, other.ringColor),
      haloWidth: d(haloWidth, other.haloWidth),
      haloColor: c(haloColor, other.haloColor)!,
      radius: d(radius, other.radius),
      glow: layers(glow, other.glow),
      glowColor: c(glowColor, other.glowColor),
      buttonGlow: layers(buttonGlow, other.buttonGlow),
      tileGlow: layers(tileGlow, other.tileGlow),
      duration: duration == null || otherDuration == null
          ? snap(duration, otherDuration)
          : Duration(
              microseconds: d(duration.inMicroseconds.toDouble(), otherDuration.inMicroseconds.toDouble()).round(),
            ),
      backgroundFill: c(backgroundFill, other.backgroundFill)!,
      textFillAlpha: d(textFillAlpha, other.textFillAlpha),
      controlFill: c(controlFill, other.controlFill)!,
      controlActiveFill: c(controlActiveFill, other.controlActiveFill)!,
      listStyle: snap(listStyle, other.listStyle),
      dimOtherRows: d(dimOtherRows, other.dimOtherRows),
      dimSiblings: d(dimSiblings, other.dimSiblings),
      highContrast: snap(highContrast, other.highContrast),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FocusTokens &&
      other.cardScale == cardScale &&
      other.wideScale == wideScale &&
      other.fullCardScale == fullCardScale &&
      other.controlScale == controlScale &&
      other.ringWidth == ringWidth &&
      other.ringStrokeAlign == ringStrokeAlign &&
      other.ringColor == ringColor &&
      other.haloWidth == haloWidth &&
      other.haloColor == haloColor &&
      other.radius == radius &&
      listEquals(other.glow, glow) &&
      other.glowColor == glowColor &&
      listEquals(other.buttonGlow, buttonGlow) &&
      listEquals(other.tileGlow, tileGlow) &&
      other.duration == duration &&
      other.backgroundFill == backgroundFill &&
      other.textFillAlpha == textFillAlpha &&
      other.controlFill == controlFill &&
      other.controlActiveFill == controlActiveFill &&
      other.listStyle == listStyle &&
      other.dimOtherRows == dimOtherRows &&
      other.dimSiblings == dimSiblings &&
      other.highContrast == highContrast;

  @override
  int get hashCode => Object.hashAll([
    cardScale,
    wideScale,
    fullCardScale,
    controlScale,
    ringWidth,
    ringStrokeAlign,
    ringColor,
    haloWidth,
    haloColor,
    radius,
    Object.hashAll(glow),
    glowColor,
    Object.hashAll(buttonGlow),
    Object.hashAll(tileGlow),
    duration,
    backgroundFill,
    textFillAlpha,
    controlFill,
    controlActiveFill,
    listStyle,
    dimOtherRows,
    dimSiblings,
    highContrast,
  ]);
}
