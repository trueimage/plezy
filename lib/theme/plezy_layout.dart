import 'package:flutter/material.dart';

/// Which structure the app's screens are laid out in.
enum LayoutVariant {
  /// Plezy's own layout, drawn by every built-in theme.
  classic,

  /// The cinematic layout of the Nocturne theme: icon rail, focus-driven home
  /// spotlight, logo-box detail hero, vertical episode list and a reachable
  /// jump rail.
  nocturne,
}

/// The stored layout choice. [auto] follows the theme in use.
enum LayoutVariantSetting { auto }

/// The layout a theme draws, and the measurements the [LayoutVariant.nocturne]
/// screens are built from, at 1080p on TV (scale them with
/// `TvLayoutConstants.scaleOf`).
///
/// Read through [PlezyLayout.of], which falls back to [classic] when a theme
/// carries none. Only the layout branch points read it; everything else draws
/// from the theme's tokens.
@immutable
class PlezyLayout extends ThemeExtension<PlezyLayout> {
  const PlezyLayout({this.variant = LayoutVariant.classic});

  /// What every built-in theme draws.
  static const classic = PlezyLayout();

  static const nocturne = PlezyLayout(variant: LayoutVariant.nocturne);

  /// The theme's [PlezyLayout], or [classic] when it carries none.
  static PlezyLayout of(BuildContext context) => Theme.of(context).extension<PlezyLayout>() ?? classic;

  /// Whether the theme in [context] draws the Nocturne layout.
  static bool isNocturne(BuildContext context) => of(context).variant == LayoutVariant.nocturne;

  /// Device pixels per design pixel on TV: the layout's lengths are drawn at
  /// 1080p, so a 960x540 dp TV draws them at half size. Unlike the classic
  /// TV scale, it is not floored at 0.85, which would draw the design at
  /// 1.7 times its proportions on the common 540 dp screen.
  static double designScaleOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).height / 1080).clamp(0.5, 1.35).toDouble();

  final LayoutVariant variant;

  /// Width of the collapsed TV icon rail, and of the rail held open over the
  /// content.
  final double railWidth = 88;
  final double railOpenWidth = 380;

  /// TV safe margins for text and focusables; artwork bleeds past them.
  final double safeX = 80;
  final double safeY = 48;

  /// Share of the screen height the backdrop takes.
  final double backdropHeight = 0.62;

  /// Top of the first row under the home spotlight at 1080p.
  final double rowFocusLine = 592;

  /// The box a clear logo is fitted into, reserved whether or not it loads.
  final Size logoBox = const Size(520, 128);

  final double jumpRailWidth = 44;

  @override
  PlezyLayout copyWith() => this;

  /// A layout has no in-between: it switches at the midpoint.
  @override
  PlezyLayout lerp(covariant PlezyLayout? other, double t) => other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) => other is PlezyLayout && other.variant == variant;

  @override
  int get hashCode => variant.hashCode;
}
