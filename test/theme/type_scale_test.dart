import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/plezy_theme_spec.dart';
import 'package:plezy/theme/type_scale.dart';

import '../test_helpers/theme.dart';

const _custom = TypeScale(
  fontFamily: 'Manrope',
  heroTitle: TypeSize(regular: 44, phone: 32, tv: 64),
  shelfHeader: TypeSize(regular: 22, phone: 19, tv: 32),
  cardTitle: TypeSize(regular: 17, phone: 16, tv: 28),
  cardCaption: TypeSize(regular: 12.5, phone: 12, tv: 24),
);

Future<T> _read<T>(WidgetTester tester, ThemeData theme, T Function(BuildContext context) read) async {
  late T value;
  await tester.pumpWidget(
    Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          value = read(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return value;
}

void main() {
  tearDown(TvDetectionService.debugReset);

  group('fallback', () {
    test('holds the sizes the widgets drew before the tokens', () {
      const s = TypeScale.fallback;
      expect(s.fontFamily, isNull);
      expect(s.heroTitle, const TypeSize(tv: 52));
      expect(s.heroMeta, const TypeSize(regular: 14, tv: 18));
      expect(s.detailTitle.tvSize, 56);
      expect(s.detailSubtitle.tvSize, 24);
      expect(s.detailMeta.tvSize, 18);
      expect(s.detailSummary.tvSize, 18);
      expect(s.detailChip, const TypeSize(regular: 13, tv: 16));
      expect(s.sectionHeader, const TypeSize(tv: 28));
      expect(s.shelfHeader, const TypeSize(tv: 26));
      expect(s.shelfCount, const TypeSize(tv: 17));
      expect(s.shelfAction, const TypeSize(tv: 16));
      expect([s.railHeader.tvSize, s.railServer.tvSize, s.railCardTitle.tvSize], [18, 15, 13]);
      expect([s.railCardCaption.tvSize, s.railAction.tvSize], [11, 13]);
      expect([s.cardTitle.regular, s.cardCaption.regular], [13, 11]);
      expect([s.listTitle.regular, s.listSubtitle.regular, s.listMeta.regular], [13, 11, 10]);
      expect([s.labelBadge.regular, s.countBadge.regular], [9, 10]);
      expect(
        [s.navLabel, s.navCaption, s.navSection, s.navNote, s.navLibrary, s.navLibraryServer].map((t) => t.regular),
        [14, 11, 11, 12, 13, 9],
      );
    });

    test('roles without a TV size keep their regular size on TV', () {
      expect(TypeScale.fallback.cardTitle.tvSize, 13);
      expect(TypeScale.fallback.navLabel.tvSize, 14);
    });

    testWidgets('applies when the theme carries no TypeScale', (tester) async {
      final resolved = await _read(tester, ThemeData(extensions: const [testMonoTokens]), TypeScale.of);
      expect(resolved, same(TypeScale.fallback));
    });

    test('every mono theme carries the fallback and no font family', () {
      final theme = monoTheme(MonoPalette.dark);
      expect(theme.extension<TypeScale>(), TypeScale.fallback);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        ThemeData(brightness: Brightness.dark).textTheme.bodyMedium?.fontFamily,
      );
    });
  });

  group('TypeSize.resolve', () {
    testWidgets('picks the TV, phone or regular size', (tester) async {
      const size = TypeSize(regular: 20, phone: 16, tv: 30);
      final android = ThemeData(platform: TargetPlatform.android);
      final linux = ThemeData(platform: TargetPlatform.linux);
      expect(await _read(tester, android, (c) => size.resolve(c, isTv: false)), 16);
      expect(await _read(tester, linux, (c) => size.resolve(c, isTv: false)), 20);
      expect(await _read(tester, android, (c) => size.resolve(c, isTv: true)), 30);
      // No phone size: phones draw the regular one.
      expect(await _read(tester, android, (c) => const TypeSize(regular: 20).resolve(c, isTv: false)), 20);
      // Null keeps the style's own size.
      expect(await _read(tester, linux, (c) => const TypeSize(tv: 52).resolve(c, isTv: false)), isNull);
    });

    testWidgets('sizeIn follows the app TV mode', (tester) async {
      const size = TypeSize(regular: 14, tv: 18);
      final theme = ThemeData(platform: TargetPlatform.linux);
      expect(await _read(tester, theme, size.sizeIn), 14);
      TvDetectionService.debugSetAppleTVOverride(true);
      expect(await _read(tester, theme, size.sizeIn), 18);
    });
  });

  group('theme spec', () {
    test('a spec carries its type scale and font family into the theme', () {
      const spec = PlezyThemeSpec(MonoPalette.dark, type: _custom);
      final theme = monoThemeFromSpec(spec);
      expect(theme.extension<TypeScale>(), _custom);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
      expect(identical(theme, monoTheme(MonoPalette.dark)), isFalse);
      expect(identical(theme, monoThemeFromSpec(PlezyThemeSpec(MonoPalette.dark, type: _custom.copyWith()))), isTrue);
    });
  });

  group('copyWith', () {
    test('without arguments is equal', () {
      expect(_custom.copyWith(), _custom);
      expect(_custom.copyWith().hashCode, _custom.hashCode);
    });

    test('replaces only the given fields', () {
      final copy = TypeScale.fallback.copyWith(fontFamily: 'Manrope', heroMeta: const TypeSize(regular: 15));
      expect(copy.fontFamily, 'Manrope');
      expect(copy.heroMeta, const TypeSize(regular: 15));
      expect(copy.heroTitle, TypeScale.fallback.heroTitle);
    });
  });

  group('lerp', () {
    test('ends are exact', () {
      expect(TypeScale.fallback.lerp(_custom, 0), TypeScale.fallback);
      expect(TypeScale.fallback.lerp(_custom, 1), _custom);
      expect(_custom.lerp(null, 0.5), _custom);
    });

    test('sizes interpolate, unset sizes and the family snap at the midpoint', () {
      final mid = TypeScale.fallback.lerp(_custom, 0.5);
      expect(mid.heroTitle.tv, 58);
      expect(mid.cardTitle.regular, 15);
      expect(mid.heroTitle.regular, 44);
      expect(TypeScale.fallback.lerp(_custom, 0.4).heroTitle.regular, isNull);
      expect(mid.fontFamily, 'Manrope');
      expect(TypeScale.fallback.lerp(_custom, 0.4).fontFamily, isNull);
    });
  });
}
