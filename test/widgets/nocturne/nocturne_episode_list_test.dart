import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:provider/provider.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';
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
  summary: 'Episode synopsis',
  serverId: 'server',
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
    String? initialEpisodeId,
    int selectedSeason = 0,
    TvRailTrailing trailing = TvRailTrailing.none,
    bool hideSpoilers = false,
    WatchStateStore? watchState,
  }) async {
    log = [];
    final store = watchState ?? WatchStateStore();
    if (watchState == null) addTearDown(store.dispose);
    final hubs = seasons ?? [_season(1, 3), _season(2, 2)];
    await tester.pumpWidget(
      ChangeNotifierProvider<WatchStateStore>.value(
        value: store,
        child: TranslationProvider(
          child: InputModeTracker(
            child: MaterialApp(
              theme: monoThemeFromSpec(NocturneTheme.spec(const NocturneOptions())),
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  child: NocturneEpisodeList(
                    key: listKey,
                    seasons: hubs,
                    selectedSeason: selectedSeason,
                    initialEpisodeId: initialEpisodeId,
                    trailingForHub: (_) => trailing,
                    onRetryHub: (hub) => log.add('retry ${hub.id}'),
                    hideSpoilers: hideSpoilers,
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
      ),
    );
    await tester.pump();
  }

  String? focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  testWidgets('reveals a distant resume episode before focusing and playing it', (tester) async {
    await pumpList(tester, seasons: [_season(1, 40)], initialEpisodeId: 's1e20');
    listKey.currentState!.requestFocus();
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'nocturne_episode_19');
    expect(log, contains('focus s1e20'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, contains('play s1e20'));
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(log, contains('focus s1e1'));
    expect(log.last, 'up');
  });

  testWidgets('resolves a resume target after loading and changing seasons', (tester) async {
    await pumpList(tester, seasons: [_season(1, 0)], initialEpisodeId: 's1e20');
    listKey.currentState!.requestFocus();
    await pumpList(tester, seasons: [_season(1, 40)], initialEpisodeId: 's1e20');
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'nocturne_episode_19');
    await pumpList(tester, seasons: [_season(1, 40), _season(2, 30)], selectedSeason: 1, initialEpisodeId: 's2e25');
    listKey.currentState!.requestFocus();
    await tester.pumpAndSettle();
    expect(log, contains('focus s2e25'));
  });

  for (final hubId in ['season_1', 'detail_episodes']) {
    for (final count in [0, 20]) {
      testWidgets('$hubId retries a failed page after $count episodes', (tester) async {
        final hub = _season(1, count);
        final seasons = [MediaHub(id: hubId, title: hub.title, type: hub.type, items: hub.items)];
        await pumpList(
          tester,
          seasons: seasons,
          initialEpisodeId: count == 0 ? null : 's1e$count',
          trailing: TvRailTrailing.error,
        );
        listKey.currentState!.requestFocus();
        await tester.pumpAndSettle();
        if (count > 0) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        }
        expect(focusedLabel(), 'nocturne_episode_retry');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(log, contains('retry $hubId'));
        if (count == 0) {
          await pumpList(
            tester,
            seasons: [MediaHub(id: hubId, title: hub.title, type: hub.type, items: _season(1, 3).items)],
          );
          await tester.pumpAndSettle();
          expect(log, contains('focus s1e1'));
        }
      });
    }
  }

  testWidgets('reveals season chips sideways and when returning from rows', (tester) async {
    await pumpList(tester, seasons: [for (var season = 1; season <= 30; season++) _season(season, 1)]);
    listKey.currentState!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    for (var i = 0; i < 29; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(focusedLabel(), 'nocturne_season_29');
    final chip = find.text('Season 30', findRichText: true);
    final viewport = find.byType(SingleChildScrollView);
    expect(tester.getRect(chip).left, greaterThanOrEqualTo(tester.getRect(viewport).left));
    expect(tester.getRect(chip).right, lessThanOrEqualTo(tester.getRect(viewport).right));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'nocturne_season_0');
    expect(
      tester.getRect(find.text('Season 1', findRichText: true)).left,
      greaterThanOrEqualTo(tester.getRect(viewport).left),
    );
  });

  testWidgets('shows loading while an episode page is pending', (tester) async {
    await pumpList(tester, seasons: [_season(1, 0)], trailing: TvRailTrailing.loading);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('watch patches update progress, watched markers and spoiler protection', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    await pumpList(tester, seasons: [_season(1, 1)], hideSpoilers: true, watchState: store);
    ImageFiltered thumbnail() => tester.widget<ImageFiltered>(find.byType(ImageFiltered));
    expect(thumbnail().enabled, isTrue);
    expect(thumbnail().imageFilter, ImageFilter.blur(sigmaX: 12, sigmaY: 12));
    expect(find.text('Episode synopsis'), findsNothing);
    WatchStateNotifier().notify(
      WatchStateEvent(
        itemId: 's1e1',
        serverId: const ServerId('server'),
        parentChain: const [],
        changeType: WatchStateChangeType.progressUpdate,
        viewOffset: 60000,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) => widget is FractionallySizedBox && widget.widthFactor == 1 / 45),
      findsOneWidget,
    );
    WatchStateNotifier().notify(
      WatchStateEvent(
        itemId: 's1e1',
        serverId: const ServerId('server'),
        parentChain: const [],
        changeType: WatchStateChangeType.watched,
        isNowWatched: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.nocturne.watched), findsOneWidget);
    expect(find.text('Episode synopsis'), findsOneWidget);
    expect(thumbnail().enabled, isFalse);
  });

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
