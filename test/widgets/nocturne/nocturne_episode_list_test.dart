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
import 'package:plezy/widgets/nocturne/nocturne_episode_list.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

MediaItem _episode(int season, int index) => testMediaItem(
  id: 's${season}e$index',
  kind: MediaKind.episode,
  title: 'Episode $index',
  parentIndex: season,
  index: index,
  grandparentTitle: 'Halcyon Station',
  durationMs: 45 * 60000,
);

MediaHub _season(int season, int count) {
  final items = [for (var i = 1; i <= count; i++) _episode(season, i)];
  return MediaHub(id: 'season_$season', title: 'Season $season', type: 'episode', items: items, size: count);
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  late List<String> log;
  final listKey = GlobalKey<NocturneEpisodeListState>();

  Future<void> pumpList(
    WidgetTester tester, {
    List<MediaHub>? seasons,
    int? Function(int seasonIndex)? unwatchedCountOf,
  }) async {
    log = [];
    final hubs = seasons ?? [_season(1, 3), _season(2, 2)];
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoThemeFromSpec(NocturneTheme.spec(const NocturneOptions())),
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: NocturneEpisodeList(
                  key: listKey,
                  seasons: hubs,
                  selectedSeason: 0,
                  clientFor: (_) => null,
                  unwatchedCountOf: unwatchedCountOf,
                  onSeasonSelected: (season, index) => log.add('season $index'),
                  onEpisodeFocused: (season, episode) => log.add('focus ${episode.id}'),
                  onEpisodeActivated: (season, episode) => log.add('play ${episode.id}'),
                  onNavigateUp: () => log.add('up'),
                  onBack: () => log.add('back'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String? focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  testWidgets('Down past the last episode stays put', (tester) async {
    await pumpList(tester);
    listKey.currentState!.requestFocus();
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(log.last, 'focus s1e3');
    expect(listKey.currentState!.mounted, isTrue);
  });

  testWidgets('Up climbs from the first episode to the season chips, then out', (tester) async {
    await pumpList(tester);
    listKey.currentState!.requestFocus();
    await tester.pump();
    expect(log, contains('focus s1e1'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focusedLabel(), startsWith('nocturne_season_'));
    expect(log, isNot(contains('up')));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(log.last, 'up');
  });

  testWidgets('Left and Right on an episode row keep focus on it', (tester) async {
    await pumpList(tester);
    listKey.currentState!.requestFocus();
    await tester.pump();
    final before = FocusManager.instance.primaryFocus;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, before);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, before);
  });

  testWidgets('Back from an episode or a chip runs the screen Back', (tester) async {
    await pumpList(tester);
    listKey.currentState!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(log.last, 'back');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(log.where((entry) => entry == 'back'), hasLength(2));
  });

  testWidgets('Select on an episode plays it; on a chip, selects the season', (tester) async {
    await pumpList(tester);
    listKey.currentState!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, contains('play s1e2'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, contains('season 1'));
  });

  testWidgets('a season chip shows its unwatched count, and nothing when it has none', (tester) async {
    await pumpList(tester, unwatchedCountOf: (index) => index == 1 ? 4 : 0);
    expect(find.textContaining('4 new', findRichText: true), findsOneWidget);
    expect(find.textContaining('0 new', findRichText: true), findsNothing);
  });

  testWidgets('a single season shows no chips: Up from the first episode leaves the list', (tester) async {
    await pumpList(tester, seasons: [_season(1, 2)]);
    listKey.currentState!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(log.last, 'up');
  });
}
