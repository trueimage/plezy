import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/nocturne_theme.dart';
import 'package:plezy/theme/plezy_theme_spec.dart';

MonoPalette _copyOf(MonoPalette p) => MonoPalette(
  bg: p.bg,
  surface: p.surface,
  outline: p.outline,
  text: p.text,
  textMuted: p.textMuted,
  accent: p.accent,
);

void main() {
  group('PlezyThemeSpec equality', () {
    test('specs with equal palettes are equal and hash alike', () {
      final a = PlezyThemeSpec(_copyOf(MonoPalette.ember));
      const b = PlezyThemeSpec(MonoPalette.ember);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('specs with different palettes differ', () {
      expect(const PlezyThemeSpec(MonoPalette.dark), isNot(const PlezyThemeSpec(MonoPalette.oled)));
    });
  });

  group('monoThemeFromSpec cache', () {
    test('an equal spec built at runtime reuses the cached theme', () {
      final runtime = PlezyThemeSpec(_copyOf(MonoPalette.glacier));
      expect(
        identical(monoThemeFromSpec(runtime), monoThemeFromSpec(const PlezyThemeSpec(MonoPalette.glacier))),
        isTrue,
      );
    });

    test('monoTheme(palette) is the default-style spec theme', () {
      for (final mode in settings.ThemeMode.values) {
        final palette = ThemeProvider.paletteFor(mode);
        if (palette == null) continue;
        expect(identical(monoTheme(palette), monoThemeFromSpec(PlezyThemeSpec(palette))), isTrue, reason: mode.name);
      }
    });

    test('different specs build different themes', () {
      expect(
        identical(
          monoThemeFromSpec(const PlezyThemeSpec(MonoPalette.dark)),
          monoThemeFromSpec(const PlezyThemeSpec(MonoPalette.plum)),
        ),
        isFalse,
      );
    });
  });

  group('ThemeProvider spec resolution', () {
    test('specFor wraps paletteFor, null for System; Nocturne carries its whole spec', () {
      expect(ThemeProvider.specFor(settings.ThemeMode.system), isNull);
      expect(ThemeProvider.specFor(settings.ThemeMode.nocturne), NocturneTheme.spec());
      for (final mode in settings.ThemeMode.values) {
        if (mode == settings.ThemeMode.nocturne) continue;
        final palette = ThemeProvider.paletteFor(mode, customPalette: MonoPalette.forest);
        expect(
          ThemeProvider.specFor(mode, customPalette: MonoPalette.forest),
          palette == null ? isNull : PlezyThemeSpec(palette),
          reason: mode.name,
        );
      }
    });

    test('resolve carries the spec and its palette', () {
      final choice = ThemeProvider.resolve(settings.ThemeMode.dark, null, unlocked: true);
      expect(choice.spec, const PlezyThemeSpec(MonoPalette.dark));
      expect(choice.palette, MonoPalette.dark);
    });

    test('the spec slot themes match the palette slot themes', () {
      for (final palette in [null, MonoPalette.light, MonoPalette.dark, MonoPalette.paper, MonoPalette.ember]) {
        final spec = palette == null ? null : PlezyThemeSpec(palette);
        expect(identical(ThemeProvider.lightThemeForSpec(spec), ThemeProvider.lightThemeFor(palette)), isTrue);
        expect(identical(ThemeProvider.darkThemeForSpec(spec), ThemeProvider.darkThemeFor(palette)), isTrue);
      }
      expect(ThemeProvider.lightThemeForSpec(null).brightness, Brightness.light);
      expect(ThemeProvider.darkThemeForSpec(const PlezyThemeSpec(MonoPalette.paper)).brightness, Brightness.dark);
    });
  });
}
