@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/screens/discover_screen.dart';
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

  goldenMatrix(
    'nocturne_home_variants',
    themes: [nocturneTrueBlackIvoryGoldenTheme],
    formFactors: const [GoldenFormFactor.tv],
    body: pumpNocturneHome,
  );
}

/// Pumps the home screen inside the navigation shell, against the fixture
/// server's Continue Watching and hubs.
Future<void> pumpNocturneHome(WidgetTester tester, GoldenCase golden) async {
  final multiServer = testMultiServer(clients: [GoldenMediaServerClient()]).provider;
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
