import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/theme/nocturne_theme.dart';
import 'package:plezy/widgets/nocturne/nocturne_home.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

final _resume = testMediaItem(
  id: 'ep',
  kind: MediaKind.episode,
  title: 'Signal Decay',
  grandparentTitle: 'Halcyon Station',
  parentIndex: 2,
  index: 4,
  durationMs: 50 * 60000,
  viewOffsetMs: 27 * 60000,
);
final _movie = testMediaItem(id: 'movie', title: 'Glass Ocean', year: 2024, durationMs: 100 * 60000);

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  late List<String> log;
  late ValueNotifier<MediaItem?> spotlight;
  late ValueNotifier<int> activeHub;
  final homeKey = GlobalKey<NocturneTvHomeState>();
  final rowFocus = FocusNode(debugLabel: 'row');
  tearDownAll(rowFocus.dispose);

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.reset);
    log = [];
    spotlight = ValueNotifier(_resume);
    activeHub = ValueNotifier(0);
    addTearDown(spotlight.dispose);
    addTearDown(activeHub.dispose);
    final hub = MediaHub(id: 'cw', title: 'Continue Watching', type: 'mixed', items: [_resume, _movie], size: 2);
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoThemeFromSpec(NocturneTheme.spec(const NocturneOptions())),
            home: NocturneTvHome(
              key: homeKey,
              hubs: [hub],
              spotlight: spotlight,
              resolveSpotlight: () => spotlight.value,
              resolveClient: (_) => null,
              activeHubIndex: activeHub,
              rows: Focus(focusNode: rowFocus, child: const SizedBox.expand()),
              onPlay: (item) => log.add('play ${item.id}'),
              onDetails: (item) => log.add('details ${item.id}'),
              onNavigateDown: () {
                log.add('down');
                rowFocus.requestFocus();
              },
              onNavigateUp: () => log.add('up'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('nothing takes focus on its own, and Up from the rows reaches Resume', (tester) async {
    await pumpHome(tester);
    rowFocus.requestFocus();
    await tester.pump();

    // The spotlight follows the focused card without moving focus.
    spotlight.value = _movie;
    await tester.pump(const Duration(milliseconds: 400));
    expect(rowFocus.hasPrimaryFocus, isTrue);
    expect(find.text('Glass Ocean'), findsWidgets);

    // The screen's Up handler from the first row lands on the primary action.
    homeKey.currentState!.focusPrimaryAction();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nocturne_spotlight_primary');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, contains('play movie'));
  });

  testWidgets('Down from the spotlight actions returns to the rows; Up goes to the toolbar', (tester) async {
    await pumpHome(tester);
    homeKey.currentState!.focusPrimaryAction();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(log.last, 'up');

    homeKey.currentState!.focusPrimaryAction();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(log.last, 'down');
    expect(rowFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('the band shows Resume with the time left, and folds to one line past the first row', (tester) async {
    await pumpHome(tester);
    expect(find.text(t.common.resume), findsOneWidget);
    expect(find.text(t.nocturne.details), findsOneWidget);

    activeHub.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.common.resume), findsNothing);
    expect(find.textContaining('Halcyon Station', findRichText: true), findsOneWidget);
  });
}
