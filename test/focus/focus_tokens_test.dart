import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/focus/focus_tokens.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/plezy_theme_spec.dart';

import '../test_helpers/theme.dart';

const _custom = FocusTokens(
  cardScale: 1.06,
  ringWidth: 3,
  ringStrokeAlign: BorderSide.strokeAlignOutside,
  ringColor: Color(0xFFFFFFFF),
  haloWidth: 1,
  glow: [FocusGlowLayer(alpha: 0.38, blurRadius: 48, offset: Offset(0, 18))],
  glowColor: Color(0xFFE6C07A),
  duration: Duration(milliseconds: 140),
  listStyle: FocusListStyle.inverted,
  dimOtherRows: 0.72,
  dimSiblings: 0.88,
  highContrast: FocusTokens(ringWidth: 4, haloWidth: 2, cardScale: 1, glow: []),
);

Future<FocusTokens> _resolve(WidgetTester tester, ThemeData theme, {bool highContrast = false}) async {
  late FocusTokens resolved;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            resolved = FocusTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return resolved;
}

void main() {
  group('fallback', () {
    test('matches the classic focus constants', () {
      const f = FocusTokens.fallback;
      expect(f.cardScale, FocusTheme.focusScale);
      expect(f.wideScale, FocusTheme.focusScale);
      expect(f.fullCardScale, FocusTheme.fullCardFocusScale);
      expect(f.controlScale, FocusTheme.playerControlFocusScale);
      expect(f.ringWidth, FocusTheme.focusBorderWidth);
      expect(f.ringStrokeAlign, BorderSide.strokeAlignInside);
      expect(f.ringColor, isNull);
      expect(f.haloWidth, 0);
      expect(f.radius, FocusTheme.defaultBorderRadius);
      expect(f.glowExtent, FocusTheme.focusGlowOuterBlurRadius * 2 + FocusTheme.focusGlowSpreadRadius);
      expect(f.dimOtherRows, 1);
      expect(f.dimSiblings, 1);
      expect(f.highContrast, isNull);
    });

    test('the classic glow shadows are unchanged', () {
      const color = Color(0xFF336699);
      expect(FocusTheme.focusGlowShadows(color), [
        BoxShadow(color: color.withValues(alpha: 0.34), blurRadius: 18, spreadRadius: 1.5),
        BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 34),
      ]);
    });

    testWidgets('applies when the theme carries no FocusTokens', (tester) async {
      final resolved = await _resolve(tester, ThemeData(extensions: const [testMonoTokens]));
      expect(resolved, same(FocusTokens.fallback));
    });

    testWidgets('every mono theme carries the fallback', (tester) async {
      expect(monoTheme(MonoPalette.dark).extension<FocusTokens>(), FocusTokens.fallback);
      expect(await _resolve(tester, monoTheme(MonoPalette.light)), FocusTokens.fallback);
    });

    testWidgets('decorations without tokens keep the classic ring', (tester) async {
      late BoxDecoration decoration;
      late Duration duration;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.dark(primary: Colors.teal),
            extensions: const [testMonoTokens],
          ),
          child: Builder(
            builder: (context) {
              decoration = FocusTheme.focusDecoration(context, isFocused: true);
              duration = FocusTheme.getAnimationDuration(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(decoration.borderRadius, BorderRadius.circular(8));
      final border = decoration.border! as Border;
      expect(border.top.width, 2.5);
      expect(border.top.color, Colors.teal);
      expect(border.top.strokeAlign, BorderSide.strokeAlignInside);
      expect(decoration.boxShadow, isNull);
      expect(duration, testMonoTokens.fast);
    });
  });

  group('theme spec', () {
    testWidgets('a spec carries its focus into the theme', (tester) async {
      const spec = PlezyThemeSpec(MonoPalette.dark, focus: _custom);
      final theme = monoThemeFromSpec(spec);
      expect(theme.extension<FocusTokens>(), _custom);
      expect(identical(theme, monoTheme(MonoPalette.dark)), isFalse);
      expect(identical(theme, monoThemeFromSpec(spec.copyWithFocus())), isTrue);

      final resolved = await _resolve(tester, theme);
      expect(resolved, _custom);
    });

    testWidgets('high contrast swaps in its own tokens', (tester) async {
      final theme = monoThemeFromSpec(const PlezyThemeSpec(MonoPalette.dark, focus: _custom));
      expect(await _resolve(tester, theme, highContrast: true), _custom.highContrast);
      // Without a high-contrast set the request changes nothing.
      expect(await _resolve(tester, monoTheme(MonoPalette.dark), highContrast: true), FocusTokens.fallback);
    });

    test('specs differing only in focus are distinct', () {
      expect(const PlezyThemeSpec(MonoPalette.dark), isNot(const PlezyThemeSpec(MonoPalette.dark, focus: _custom)));
      expect(
        const PlezyThemeSpec(MonoPalette.dark, focus: _custom).hashCode,
        PlezyThemeSpec(MonoPalette.dark, focus: _custom.copyWith()).hashCode,
      );
    });
  });

  group('copyWith', () {
    test('without arguments is equal', () {
      expect(_custom.copyWith(), _custom);
      expect(FocusTokens.fallback.copyWith(), FocusTokens.fallback);
    });

    test('replaces only the given fields', () {
      final copy = FocusTokens.fallback.copyWith(cardScale: 1.06, ringColor: Colors.white);
      expect(copy.cardScale, 1.06);
      expect(copy.ringColor, Colors.white);
      expect(copy.wideScale, FocusTokens.fallback.wideScale);
      expect(copy.glow, FocusTokens.fallback.glow);
    });
  });

  group('lerp', () {
    test('ends are exact', () {
      expect(FocusTokens.fallback.lerp(_custom, 0), FocusTokens.fallback);
      expect(FocusTokens.fallback.lerp(_custom, 1), _custom);
      expect(_custom.lerp(null, 0.5), _custom);
    });

    test('numbers interpolate, discrete values snap at the midpoint', () {
      final mid = FocusTokens.fallback.lerp(_custom, 0.5);
      expect(mid.cardScale, closeTo(1.04, 1e-9));
      expect(mid.ringWidth, closeTo(2.75, 1e-9));
      expect(mid.dimOtherRows, closeTo(0.86, 1e-9));
      expect(mid.listStyle, FocusListStyle.inverted);
      expect(FocusTokens.fallback.lerp(_custom, 0.49).listStyle, FocusListStyle.fill);
      // Glows with a different layer count snap rather than mis-pairing.
      expect(FocusTokens.fallback.lerp(_custom, 0.25).glow, FocusTokens.fallback.glow);
      expect(mid.duration, _custom.duration);
    });

    test('glows with matching layers interpolate', () {
      const a = FocusTokens(tileGlow: [FocusGlowLayer(alpha: 0.2, blurRadius: 10)]);
      const b = FocusTokens(tileGlow: [FocusGlowLayer(alpha: 0.4, blurRadius: 30)]);
      final mid = a.lerp(b, 0.5).tileGlow.single;
      expect(mid.alpha, closeTo(0.3, 1e-9));
      expect(mid.blurRadius, 20);
    });
  });
}

extension on PlezyThemeSpec {
  PlezyThemeSpec copyWithFocus() => PlezyThemeSpec(
    MonoPalette(
      bg: palette.bg,
      surface: palette.surface,
      outline: palette.outline,
      text: palette.text,
      textMuted: palette.textMuted,
      accent: palette.accent,
    ),
    focus: focus?.copyWith(),
  );
}
