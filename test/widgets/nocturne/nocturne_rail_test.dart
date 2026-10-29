import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/nocturne_theme.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';

/// The Nocturne TV rail: an 88 px icon strip that opens as a 380 px overlay,
/// so the content never reflows. Every other theme keeps the classic rail.
void main() {
  setUp(() async {
    TvDetectionService.debugReset();
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
  });
  tearDown(TvDetectionService.debugReset);

  Future<BuildContext> pumpTheme(WidgetTester tester, ThemeData theme) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.reset);
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('Nocturne opens the TV rail over the content', (tester) async {
    final context = await pumpTheme(tester, monoThemeFromSpec(NocturneTheme.spec(const NocturneOptions())));
    expect(SideNavigationRailState.overlaysContent(context), isTrue);
    expect(SideNavigationRailState.collapsedWidthForContext(context), 88);
    expect(SideNavigationRailState.expandedWidthForContext(context), 380);
  });

  testWidgets('a classic theme keeps the rail that pushes the content', (tester) async {
    final context = await pumpTheme(tester, monoTheme(MonoPalette.dark));
    expect(SideNavigationRailState.overlaysContent(context), isFalse);
    expect(SideNavigationRailState.collapsedWidthForContext(context), SideNavigationRailState.tvCollapsedWidth);
    expect(SideNavigationRailState.expandedWidthForContext(context), SideNavigationRailState.expandedWidth);
  });
}
