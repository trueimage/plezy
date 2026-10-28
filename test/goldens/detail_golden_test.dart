@Tags(['golden'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/media_detail_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/widgets/episode_card.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/profile_navigation.dart';
import 'golden_fixtures.dart';
import 'golden_harness.dart';

/// The media detail screen: the hero for a movie in every theme, and a
/// season's episode list in Light, Dark and Nocturne.
void main() {
  // Classic themes first: Nocturne bakes its own scrim gradients into the
  // process-wide RasterizedGradient strip cache, which would push out the ones
  // the classic TV backdrop has already baked and change how it paints.
  bool classic(GoldenTheme theme) => theme.mode != settings.ThemeMode.nocturne;
  _detailMatrices(
    themes: allGoldenThemes.where(classic).toList(),
    episodeThemes: screenGoldenThemes.where(classic).toList(),
  );
  // Nocturne's hero draws media-info chips and the Versions and Trailer
  // actions, so it shows the movie that has them.
  _detailMatrices(
    themes: [nocturneGoldenTheme],
    episodeThemes: [nocturneGoldenTheme],
    movie: goldenDetailMovieWithMedia,
  );
  // A show's page: Nocturne's season chips with their "N new" count.
  goldenMatrix(
    'nocturne_detail_show',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => _pumpDetail(tester, golden, goldenShowSeasons),
  );
}

void _detailMatrices({required List<GoldenTheme> themes, required List<GoldenTheme> episodeThemes, MediaItem? movie}) {
  goldenMatrix(
    'detail_hero',
    themes: themes,
    body: (tester, golden) => _pumpDetail(tester, golden, movie ?? goldenDetailMovie),
  );

  goldenMatrix(
    'episode_list',
    themes: episodeThemes,
    body: (tester, golden) async {
      await _pumpDetail(tester, golden, goldenSeason);
      // TV lays a season's episodes out as a card row that is already on
      // screen; the other form factors list them below the hero.
      if (!golden.isTV) {
        await tester.ensureVisible(find.byType(EpisodeCard).first);
        await tester.pumpAndSettle();
      }
    },
  );
}

Future<void> _pumpDetail(WidgetTester tester, GoldenCase golden, MediaItem metadata) async {
  final provider = testMultiServer(clients: [GoldenMediaServerClient()]).provider;
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(database);
  JellyfinApiCache.initialize(database);
  final downloadManager = DownloadManagerService(
    database: database,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  )..recoveryFuture = Future<void>.value();
  final downloads = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
  await downloads.ensureInitialized();
  addTearDown(() async {
    downloads.dispose();
    downloadManager.dispose();
    await database.close();
  });

  await pumpGoldenApp(
    tester,
    golden,
    providers: [
      ChangeNotifierProvider<MultiServerProvider>.value(value: provider),
      ChangeNotifierProvider<DownloadProvider>.value(value: downloads),
    ],
    home: withProfileNavigationScope(child: MediaDetailScreen(metadata: metadata)),
  );
}
