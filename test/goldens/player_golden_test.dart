@Tags(['golden'])
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:provider/provider.dart';

import '../test_helpers/mock_player_channels.dart';
import 'golden_fixtures.dart';
import 'golden_harness.dart';

/// The video player: its on-screen controls raised over steady playback, and
/// the route's loading surface as it opens against the mock native channels.
void main() {
  setUpAll(() => initializeDateFormatting('en'));

  goldenMatrix('player_controls', themes: screenGoldenThemes, body: _pumpControls);

  goldenMatrix(
    'player_loading',
    themes: screenGoldenThemes,
    body: (tester, golden) => withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        await pumpGoldenApp(
          tester,
          golden,
          settle: false,
          providers: [ChangeNotifierProvider(create: (_) => PlaybackStateProvider())],
          home: VideoPlayerScreen(metadata: goldenEpisodes[2], isOffline: true),
        );
        await tester.pump(const Duration(milliseconds: 500));
      },
    ),
  );
}

Future<void> _pumpControls(WidgetTester tester, GoldenCase golden) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final player = _PlayingPlayer();
  final chrome = PlayerChromeController(initiallyVisible: true);
  final toast = PlayerToastController();
  final volume = VideoVolumeController(player: player, settings: SettingsService.instance, initialVolume: 100);
  final playbackState = PlaybackStateProvider();
  final watchTogether = WatchTogetherProvider();
  final hasFirstFrame = ValueNotifier<bool>(true);
  addTearDown(() async {
    hasFirstFrame.dispose();
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await database.close();
  });

  await pumpGoldenApp(
    tester,
    golden,
    settle: false,
    providers: [
      Provider<AppDatabase>.value(value: database),
      ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
      ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
    ],
    home: Scaffold(
      backgroundColor: Colors.black,
      body: PlexVideoControls(
        player: player,
        volumeController: volume,
        metadata: goldenEpisodes[2],
        toastController: toast,
        chromeController: chrome,
        hasFirstFrame: hasFirstFrame,
        canNavigateMediaItems: false,
      ),
    ),
  );
  chrome.show();
  await tester.pumpAndSettle();
  // Hold the chrome up for the capture; auto-hide would otherwise fire.
  chrome.cancelAutoHide();
}

/// A [Player] in steady playback partway through the episode.
class _PlayingPlayer implements Player {
  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => const PlayerState(
    playing: true,
    position: Duration(minutes: 21, seconds: 14),
    duration: Duration(minutes: 47),
    seekable: true,
  );

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: const Stream<Duration>.empty(),
    duration: const Stream<Duration>.empty(),
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: const Stream<double>.empty(),
    rate: const Stream<double>.empty(),
    tracks: const Stream<Tracks>.empty(),
    track: const Stream<TrackSelection>.empty(),
    log: const Stream<PlayerLog>.empty(),
    error: const Stream<PlayerError>.empty(),
    audioDevice: const Stream<AudioDevice>.empty(),
    audioDevices: const Stream<List<AudioDevice>>.empty(),
    bufferRanges: const Stream<List<BufferRange>>.empty(),
    playbackRestart: const Stream<void>.empty(),
    backendSwitched: const Stream<void>.empty(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
