import 'package:flutter/material.dart';
import '../services/device_performance.dart';
import '../theme/mono_tokens.dart';
import '../utils/platform_detector.dart';
import 'focus_tokens.dart';

class FocusTheme {
  FocusTheme._();

  // The classic focus every built-in theme draws: the [FocusTokens] defaults.
  static const double focusScale = 1.02;
  static const double fullCardFocusScale = 1.03;

  /// Round 40px player controls: the card scale is imperceptible on a
  /// control that small, so the focused disc grows enough to be seen move.
  static const double playerControlFocusScale = 1.12;
  static const double focusBorderWidth = 2.5;
  static const double defaultBorderRadius = 8.0;
  static const double focusGlowInnerBlurRadius = 18;
  static const double focusGlowOuterBlurRadius = 34;
  static const double focusGlowSpreadRadius = 1.5;

  /// The focus the theme draws: its [FocusTokens], or [FocusTokens.fallback]
  /// when it carries none, swapped for [FocusTokens.highContrast] when the
  /// platform asks for high contrast and the theme has one.
  static FocusTokens of(BuildContext context) {
    final focus = Theme.of(context).extension<FocusTokens>() ?? FocusTokens.fallback;
    final highContrast = focus.highContrast;
    if (highContrast == null) return focus;
    return MediaQuery.maybeHighContrastOf(context) ?? false ? highContrast : focus;
  }

  static Color getFocusBorderColor(BuildContext context) {
    return of(context).ringColor ?? Theme.of(context).colorScheme.primary;
  }

  /// The colour of the focus glow around a card.
  static Color getFocusGlowColor(BuildContext context) {
    return of(context).glowColor ?? Theme.of(context).colorScheme.primary;
  }

  static Duration getAnimationDuration(BuildContext context) {
    // Reduced tier: snap focus transitions (scale/border/glow) instead of
    // animating — each animation frame re-rasterizes the focused card.
    if (DevicePerformance.isReduced) return Duration.zero;
    return of(context).duration ?? Theme.of(context).extension<MonoTokens>()?.fast ?? const Duration(milliseconds: 150);
  }

  /// How long a TV row (or the hub list) glides after one D-pad focus step.
  ///
  /// Apple TV keeps the ~500ms ease-out measured from the native focus
  /// engine's scrollable containers (issue #2006): Siri Remote swipes chain
  /// steps into one continuous glide and users expect that inertia. D-pad
  /// platforms have no such reference: Leanback's `GridLayoutManager` prices a
  /// one-card step at roughly 100-150ms, so a 500ms glide there trails the
  /// focus border on every press and reads as input lag next to the launcher.
  /// Successive presses (including hold-repeats) retarget the animation from
  /// wherever the row currently is, so a fast series still glides continuously.
  static Duration navigationScrollDuration() =>
      PlatformDetector.isAppleTV() ? const Duration(milliseconds: 500) : const Duration(milliseconds: 150);

  /// [radii] overrides [borderRadius] when per-corner radii are needed
  /// (M3E grouped cards: large outer / small inner corners). A null
  /// [borderRadius] or [borderStrokeAlign] uses the theme's.
  static BoxDecoration focusDecoration(
    BuildContext context, {
    required bool isFocused,
    double? borderRadius,
    BorderRadius? radii,
    double? borderStrokeAlign,
    Color? color,
  }) {
    final focus = of(context);
    final focusColor = color ?? getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius ?? focus.radius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.transparent,
        width: focus.ringWidth,
        strokeAlign: borderStrokeAlign ?? focus.ringStrokeAlign,
      ),
    );
  }

  /// The dark hairline drawn just outside the focus ring of [focusDecoration]
  /// so a light ring stays legible on light artwork; the theme's
  /// [FocusTokens.haloWidth] and [FocusTokens.haloColor].
  static BoxDecoration focusHaloDecoration(
    BuildContext context, {
    required bool isFocused,
    double? borderRadius,
    BorderRadius? radii,
  }) {
    final focus = of(context);
    final halo = focus.haloWidth;
    // Where the ring ends, measured from the shape's edge: nothing for an
    // inside ring, its whole width for an outside one.
    final ringOutset = focus.ringWidth * (focus.ringStrokeAlign + 1) / 2;
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius ?? focus.radius),
      border: Border.all(
        color: isFocused ? focus.haloColor : Colors.transparent,
        width: halo,
        // Centred half a hairline beyond the ring.
        strokeAlign: (2 * ringOutset + halo) / halo,
      ),
    );
  }

  /// The focus glow around a card as a list of [BoxShadow]s.
  ///
  /// Rendered by [FocusGlowOverlay] in the root overlay so the glow paints
  /// above sibling cards on all four sides (an in-tree background shadow is
  /// occluded by later-painted neighbours, which produced the one-sided halo).
  static List<BoxShadow> focusGlowShadows(Color color, [FocusTokens focus = FocusTokens.fallback]) =>
      glowShadows(focus.glow, color);

  /// [layers] tinted with [color].
  static List<BoxShadow> glowShadows(List<FocusGlowLayer> layers, Color color) => [
    for (final layer in layers) layer.shadow(color),
  ];

  /// Build focus decoration with background color instead of border.
  /// Useful for video controls where it should match the native hover style.
  /// [radii] overrides [borderRadius] when per-corner radii are needed.
  static BoxDecoration focusBackgroundDecoration(
    BuildContext context, {
    required bool isFocused,
    double? borderRadius,
    BorderRadius? radii,
  }) {
    final focus = of(context);
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius ?? focus.radius),
      color: isFocused ? focus.backgroundFill : Colors.transparent,
    );
  }

  /// Focus background fill derived from the theme's text color, so it stays
  /// visible on BOTH light and dark surfaces — the white-based
  /// [focusBackgroundDecoration] disappears on light ones. This is the mono
  /// convention used by [TrackRow], the navigation rail, and the music player
  /// surfaces. Prefer this for any new mono-themed surface.
  static BoxDecoration textFillFocusDecoration(
    BuildContext context, {
    required bool isFocused,
    double? borderRadius,
    BorderRadius? radii,
  }) {
    final focus = of(context);
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius ?? focus.radius),
      color: isFocused ? tokens(context).text.withValues(alpha: focus.textFillAlpha) : Colors.transparent,
    );
  }
}
