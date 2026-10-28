import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/plezy_theme_spec.dart';
import 'package:plezy/theme/surface_tokens.dart';

import '../test_helpers/theme.dart';

const _custom = SurfaceTokens(
  posterRadius: 10,
  cardRadius: 14,
  sheetRadius: 22,
  modalSheetRadius: 22,
  dialogRadius: 22,
  chipRadius: 100,
  skeletonRadius: 10,
  raisedSurface: Color(0xFF1C2029),
  overlaySurface: Color(0xFF262B36),
  spotlightSideScrim: ArtworkScrim([ScrimStop(0, alpha: 1), ScrimStop(0.24, alpha: 1), ScrimStop(0.42, alpha: 0.86)]),
  badgeFill: Color(0xFFE6C07A),
  progressHeight: 5,
);

/// [theme] with the six component themes this change states put back to
/// what ThemeData builds when they are left out.
ThemeData _withMaterialDefaults(ThemeData theme) => theme.copyWith(
  dialogTheme: const DialogThemeData(),
  bottomSheetTheme: const BottomSheetThemeData(),
  popupMenuTheme: const PopupMenuThemeData(),
  chipTheme: const ChipThemeData(),
  tabBarTheme: const TabBarThemeData(),
  navigationRailTheme: const NavigationRailThemeData(),
);

final _boundary = GlobalKey();

Future<Uint8List> _render(WidgetTester tester, ThemeData theme, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

/// Renders a sample of each component that has a stated component theme.
Widget _components() => Column(
  mainAxisSize: .min,
  children: [
    const AlertDialog(title: Text('Title'), content: Text('Body')),
    const SizedBox(
      height: 120,
      child: BottomSheet(onClosing: _noop, builder: _sheet),
    ),
    const Chip(label: Text('Chip')),
    const FilterChip(label: Text('Filter'), selected: true, onSelected: _noopBool),
    const DefaultTabController(
      length: 2,
      child: TabBar(
        tabs: [
          Tab(text: 'One'),
          Tab(text: 'Two'),
        ],
      ),
    ),
    SizedBox(
      height: 160,
      child: NavigationRail(
        selectedIndex: 0,
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
          NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
        ],
      ),
    ),
  ],
);

void _noop() {}
void _noopBool(bool _) {}
Widget _sheet(BuildContext context) => const Text('Sheet');

void main() {
  group('fallback', () {
    test('holds the values the widgets drew before the tokens', () {
      const s = SurfaceTokens.fallback;
      expect(s.posterRadius, isNull);
      expect(s.cardRadius, 14);
      expect(s.thumbnailRadius, 6);
      expect(s.sheetRadius, 16);
      expect(s.modalSheetRadius, 28);
      expect(s.dialogRadius, 28);
      expect(s.popupMenuRadius, 4);
      expect(s.chipRadius, 20);
      expect(s.imageChipRadius, 12);
      expect(s.materialChipRadius, 8);
      expect(s.skeletonRadius, 8);
      expect(s.skeletonTextRadius, 4);
      expect(s.raisedSurface, isNull);
      expect(s.overlaySurface, isNull);
      expect(s.badgeFill, isNull);
      expect(s.badgeShadows, [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]);
      expect(s.labelBadgeColor, Colors.black.withValues(alpha: 0.76));
      expect(s.progressHeight, isNull);
    });

    test('scrims reproduce the gradients they replaced', () {
      const bg = Color(0xFF0E0F12);
      const s = SurfaceTokens.fallback;
      expect(s.homeHeroScrimTv.colors(bg), [Colors.transparent, bg.withValues(alpha: 0.9), bg, bg]);
      expect(s.homeHeroScrimTv.positions, [0.25, 0.78, 0.94, 1.0]);
      expect(s.homeHeroScrim.positions, [0.5, 0.85, 0.94, 1.0]);
      expect(
        s.spotlightScrim.gradient(bg, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, bg.withValues(alpha: 0.96)],
          stops: const [0.0, 0.38, 1.0],
        ),
      );
      expect(s.spotlightSideScrim.colors(bg), [
        bg.withValues(alpha: 0.86),
        bg.withValues(alpha: 0.32),
        Colors.transparent,
      ]);
      expect(s.detailTopScrim.colors(bg), [
        bg.withValues(alpha: 0.8),
        bg.withValues(alpha: 0.5),
        bg.withValues(alpha: 0),
      ]);
      const alphas = [0.20, 0.234, 0.325, 0.453, 0.60, 0.747, 0.875, 0.985, 0.998, 1.0];
      const xs = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 0.9375, 1.0];
      expect(s.detailHeroScrim.colors(bg), [for (final a in alphas) bg.withValues(alpha: a), bg]);
      expect(s.detailHeroScrim.positions, [for (final x in xs) 0.94 * x, 1.0]);
    });

    testWidgets('applies when the theme carries no SurfaceTokens', (tester) async {
      late SurfaceTokens resolved;
      late double posterRadius;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(extensions: const [testMonoTokensAnimated]),
          child: Builder(
            builder: (context) {
              resolved = SurfaceTokens.of(context);
              posterRadius = SurfaceTokens.posterRadiusOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, same(SurfaceTokens.fallback));
      // Posters follow the theme's small radius until a theme sets their own.
      expect(posterRadius, testMonoTokensAnimated.radiusSm);
    });

    test('every mono theme carries the fallback and a 14 px card', () {
      final theme = monoTheme(MonoPalette.dark);
      expect(theme.extension<SurfaceTokens>(), SurfaceTokens.fallback);
      expect(theme.cardTheme.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))));
    });
  });

  group('component themes', () {
    for (final palette in [MonoPalette.light, MonoPalette.dark, MonoPalette.oled, MonoPalette.ember]) {
      testWidgets('render as the Material 3 defaults (${palette.bg})', (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = monoTheme(palette);
        final stated = await _render(tester, theme, _components());
        final defaults = await _render(tester, _withMaterialDefaults(theme), _components());
        expect(stated, orderedEquals(defaults));
      });
    }

    testWidgets('the comparison sees a changed component theme', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = monoTheme(MonoPalette.dark);
      final stated = await _render(tester, theme, _components());
      final squared = await _render(
        tester,
        theme.copyWith(dialogTheme: theme.dialogTheme.copyWith(shape: const RoundedRectangleBorder())),
        _components(),
      );
      expect(stated, isNot(orderedEquals(squared)));
    });

    test('follow the spec surfaces', () {
      final theme = monoThemeFromSpec(const PlezyThemeSpec(MonoPalette.dark, surfaces: _custom));
      expect(theme.extension<SurfaceTokens>(), _custom);
      expect(theme.dialogTheme.backgroundColor, _custom.overlaySurface);
      expect(
        theme.dialogTheme.shape,
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
      );
      expect(theme.popupMenuTheme.color, _custom.overlaySurface);
      expect(
        theme.bottomSheetTheme.shape,
        const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      );
    });
  });

  group('spec', () {
    test('specs differing only in surfaces are distinct and cache apart', () {
      const plain = PlezyThemeSpec(MonoPalette.dark);
      const styled = PlezyThemeSpec(MonoPalette.dark, surfaces: _custom);
      expect(plain, isNot(styled));
      expect(identical(monoThemeFromSpec(plain), monoThemeFromSpec(styled)), isFalse);
      expect(
        identical(
          monoThemeFromSpec(styled),
          monoThemeFromSpec(PlezyThemeSpec(MonoPalette.dark, surfaces: _custom.copyWith())),
        ),
        isTrue,
      );
    });
  });

  group('copyWith', () {
    test('without arguments is equal', () {
      expect(_custom.copyWith(), _custom);
      expect(_custom.copyWith().hashCode, _custom.hashCode);
    });

    test('replaces only the given fields', () {
      final copy = SurfaceTokens.fallback.copyWith(sheetRadius: 22, overlaySurface: Colors.red);
      expect(copy.sheetRadius, 22);
      expect(copy.overlaySurface, Colors.red);
      expect(copy.dialogRadius, SurfaceTokens.fallback.dialogRadius);
      expect(copy.detailHeroScrim, SurfaceTokens.fallback.detailHeroScrim);
    });
  });

  group('lerp', () {
    test('ends are exact', () {
      expect(SurfaceTokens.fallback.lerp(_custom, 0), SurfaceTokens.fallback);
      expect(SurfaceTokens.fallback.lerp(_custom, 1), _custom);
      expect(_custom.lerp(null, 0.3), _custom);
    });

    test('numbers interpolate, scrims and unset values snap at the midpoint', () {
      final mid = SurfaceTokens.fallback.lerp(_custom, 0.5);
      expect(mid.sheetRadius, 19);
      expect(mid.dialogRadius, 25);
      expect(mid.posterRadius, 10);
      expect(SurfaceTokens.fallback.lerp(_custom, 0.4).posterRadius, isNull);
      expect(SurfaceTokens.fallback.lerp(_custom, 0.4).spotlightSideScrim, SurfaceTokens.defaultSpotlightSideScrim);
      expect(mid.spotlightSideScrim, _custom.spotlightSideScrim);
      final colours = const SurfaceTokens(
        labelBadgeColor: Colors.black,
      ).lerp(const SurfaceTokens(labelBadgeColor: Colors.white), 0.5);
      expect(colours.labelBadgeColor, Color.lerp(Colors.black, Colors.white, 0.5));
    });
  });
}
