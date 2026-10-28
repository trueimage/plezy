@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/screens/discover_screen.dart';
import 'package:plezy/screens/libraries/libraries_screen.dart';
import 'package:plezy/screens/search_screen.dart';
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/watch_together/watch_together.dart';
import 'package:provider/provider.dart';

import '../test_helpers/profile_stack.dart';
import '../test_helpers/multi_server_fixtures.dart';
import 'golden_fixtures.dart';
import 'golden_harness.dart';
import 'golden_shell.dart';

/// Screens only the Nocturne layout draws: the home spotlight in every form
/// factor, and on TV its high-contrast and reduced tiers and its True black
/// and Ivory settings.
void main() {
  setUpAll(() => initializeDateFormatting('en'));

  goldenMatrix('nocturne_home', themes: [nocturneGoldenTheme], body: pumpNocturneHome);

  goldenMatrix('nocturne_library', themes: [nocturneGoldenTheme], body: pumpNocturneLibrary);

  // The home's loading, empty and server-unavailable states.
  goldenMatrix(
    'nocturne_state_loading',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => pumpNocturneHome(tester, golden, client: _StalledClient()),
  );
  goldenMatrix(
    'nocturne_state_empty',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => pumpNocturneHome(tester, golden, client: _EmptyClient()),
  );
  goldenMatrix(
    'nocturne_state_offline',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => pumpNocturneHome(tester, golden, client: _FailingClient()),
  );

  goldenMatrix(
    'nocturne_search',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => pumpNocturneSearch(tester, golden, query: 'harbor'),
  );

  goldenMatrix(
    'nocturne_search_none',
    themes: [nocturneGoldenTheme],
    body: (tester, golden) => pumpNocturneSearch(tester, golden, query: 'zzyzx'),
  );

  goldenMatrix(
    'nocturne_home_variants',
    themes: [nocturneTrueBlackIvoryGoldenTheme],
    formFactors: const [GoldenFormFactor.tv],
    body: pumpNocturneHome,
  );

  // The high-contrast tier: no scale, no glow, a 4 px ring with a 2 px halo.
  goldenMatrix(
    'nocturne_home_hc',
    themes: [nocturneGoldenTheme],
    formFactors: const [GoldenFormFactor.tv],
    body: (tester, golden) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpNocturneHome(tester, golden);
    },
  );

  // The reduced visual-effects tier: the same focus end state, snapped, with
  // no glow.
  goldenMatrix(
    'nocturne_home_reduced',
    themes: [nocturneGoldenTheme],
    formFactors: const [GoldenFormFactor.tv],
    body: (tester, golden) async {
      await DevicePerformance.getInstance(override: VisualEffectsSetting.reduced);
      DevicePerformance.setOverrideSync(VisualEffectsSetting.reduced);
      addTearDown(() => DevicePerformance.setOverrideSync(VisualEffectsSetting.auto));
      expect(DevicePerformance.isReduced, isTrue);
      await pumpNocturneHome(tester, golden);
    },
  );
}

/// Pumps the home screen inside the navigation shell, against the fixture
/// server's Continue Watching and hubs.
Future<void> pumpNocturneHome(WidgetTester tester, GoldenCase golden, {GoldenMediaServerClient? client}) async {
  final multiServer = testMultiServer(clients: [client ?? GoldenMediaServerClient()]).provider;
  final hiddenLibraries = HiddenLibrariesProvider();
  final libraries = LibrariesProvider();
  final watchTogether = WatchTogetherProvider();
  final companionRemote = CompanionRemoteProvider();
  final profiles = await ProfileStack.create();
  final discover = DiscoverProvider(
    multiServer,
    hiddenLibraries,
    libraries,
    profileId: null,
    isProfileBinding: () => profiles.active.isBinding,
  );
  addTearDown(() async {
    discover.dispose();
    companionRemote.dispose();
    watchTogether.dispose();
    libraries.dispose();
    hiddenLibraries.dispose();
    await profiles.dispose();
  });

  await pumpGoldenShell(
    tester,
    golden,
    selectedTab: NavigationTabId.discover,
    multiServerProvider: multiServer,
    providers: [
      ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ChangeNotifierProvider<CompanionRemoteProvider>.value(value: companionRemote),
      ChangeNotifierProvider<ActiveProfileProvider>.value(value: profiles.active),
      ChangeNotifierProvider<DiscoverProvider>.value(value: discover),
    ],
    content: const DiscoverScreen(),
    // The phone and desktop hero keep a periodic timer; step the clock instead
    // of settling.
    settle: false,
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Pumps the Movies library screen inside the navigation shell: the chips,
/// the title count and the A–Z jump rail over the fixture grid.
Future<void> pumpNocturneLibrary(WidgetTester tester, GoldenCase golden) async {
  final multiServer = testMultiServer(clients: [GoldenMediaServerClient()]).provider;
  final storage = await StorageService.getInstance();
  await storage.saveLibraryTab(goldenBrowseLibraries.first.globalKey, LibraryTabType.browse.name);
  await pumpGoldenShell(
    tester,
    golden,
    multiServerProvider: multiServer,
    libraries: goldenBrowseLibraries,
    content: const LibrariesScreen(),
    settle: false,
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Pumps the search screen inside the navigation shell and runs [query]
/// against the fixture server.
Future<void> pumpNocturneSearch(WidgetTester tester, GoldenCase golden, {required String query}) async {
  final multiServer = testMultiServer(clients: [GoldenMediaServerClient()]).provider;
  await pumpGoldenShell(
    tester,
    golden,
    selectedTab: NavigationTabId.search,
    multiServerProvider: multiServer,
    content: const SearchScreen(),
    settle: false,
  );
  await tester.pump(const Duration(milliseconds: 250));
  await tester.enterText(find.byType(TextField).first, query);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// A server whose home never answers: the loading skeleton.
class _StalledClient extends GoldenMediaServerClient {
  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) =>
      Completer<List<MediaItem>>().future;

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) => Completer<List<MediaHub>>().future;
}

/// A server with nothing to show: the empty home.
class _EmptyClient extends GoldenMediaServerClient {
  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) async =>
      const [];

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) async => const [];

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) async => const [];
}

/// A server that cannot be reached: the server-unavailable state.
class _FailingClient extends GoldenMediaServerClient {
  static Never _unreachable() =>
      throw MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'Server unreachable');

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) async =>
      _unreachable();

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) async => _unreachable();

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => _unreachable();
}
