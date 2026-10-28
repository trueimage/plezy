import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/main_screen.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_helpers/multi_server_fixtures.dart';
import 'golden_fixtures.dart';
import 'golden_harness.dart';

/// Pumps [GoldenShell] with the providers the navigation needs.
Future<void> pumpGoldenShell(
  WidgetTester tester,
  GoldenCase golden, {
  FocusNode? firstCardFocusNode,
  Widget? content,
  NavigationTabId selectedTab = NavigationTabId.libraries,
  List<SingleChildWidget> providers = const [],
  MultiServerProvider? multiServerProvider,
  List<MediaLibrary>? libraries,
  bool settle = true,
}) async {
  final librariesProvider = LibrariesProvider();
  await librariesProvider.updateLibraryOrder(libraries ?? goldenLibraries);
  addTearDown(librariesProvider.dispose);
  final hiddenLibrariesProvider = HiddenLibrariesProvider();
  await hiddenLibrariesProvider.ensureInitialized();
  addTearDown(hiddenLibrariesProvider.dispose);
  final multiServer = multiServerProvider ?? testMultiServerProvider(MultiServerManager());
  if (multiServerProvider == null) addTearDown(multiServer.dispose);

  await pumpGoldenApp(
    tester,
    golden,
    providers: [
      ChangeNotifierProvider<LibrariesProvider>.value(value: librariesProvider),
      ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibrariesProvider),
      ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
      ...providers,
    ],
    home: GoldenShell(firstCardFocusNode: firstCardFocusNode, content: content, selectedTab: selectedTab),
    settle: settle,
  );
}

/// The main screen's navigation around the Movies library grid, laid out the
/// way MainScreen does it: the bottom NavigationBar on the phone, the
/// SideNavigationRail beside the content on desktop and TV, and the
/// OverlaySheetHost around both. Honours the sidebar and nav-label settings.
class GoldenShell extends StatelessWidget {
  const GoldenShell({super.key, this.firstCardFocusNode, this.content, this.selectedTab = NavigationTabId.libraries});

  final FocusNode? firstCardFocusNode;

  /// The screen inside the navigation; the Movies grid when null.
  final Widget? content;
  final NavigationTabId selectedTab;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final grid = Material(
      type: MaterialType.transparency,
      child: content ?? GoldenMovieGrid(firstCardFocusNode: firstCardFocusNode),
    );

    if (!PlatformDetector.shouldUseSideNavigation(context)) {
      final hideLabels = !settings.read(SettingsService.showNavBarLabels);
      final tabs = mainScreenBottomNavigationTabs(
        visibleTabs: NavigationTab.getVisibleTabs(isOffline: false),
        isMobile: true,
        isOffline: false,
        currentTab: selectedTab,
      );
      return OverlaySheetHost(
        child: Scaffold(
          body: SafeArea(bottom: false, child: grid),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarTheme.of(context).copyWith(height: hideLabels ? 56 : null),
            child: NavigationBar(
              selectedIndex: tabs.indexWhere((tab) => tab.id == selectedTab),
              labelBehavior: hideLabels
                  ? NavigationDestinationLabelBehavior.alwaysHide
                  : NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [for (final tab in tabs) tab.toDestination()],
            ),
          ),
        ),
      );
    }

    final alwaysExpanded = settings.read(SettingsService.alwaysKeepSidebarOpen);
    final contentLeft = alwaysExpanded
        ? SideNavigationRailState.expandedWidthForContext(context)
        : SideNavigationRailState.collapsedWidthForContext(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    return OverlaySheetHost(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: contentLeft,
              right: 0,
              child: content == null
                  ? grid
                  : MainScreenFocusScope(
                      focusSidebar: () {},
                      sideNavigationWidth: contentLeft,
                      reservedSideNavigationWidth: contentLeft,
                      foregroundLeft: contentLeft,
                      foregroundWidth: viewportWidth - contentLeft,
                      viewportWidth: viewportWidth,
                      child: grid,
                    ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SideNavigationRail(
                selectedTab: selectedTab,
                selectedLibraryKey: selectedTab == NavigationTabId.libraries ? goldenLibraries.first.globalKey : null,
                alwaysExpanded: alwaysExpanded,
                onDestinationSelected: (_) {},
                onLibrarySelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [goldenMovies] in the library grid: the shared sliver layout and focusable
/// cards the library tabs build, with the user's view settings.
class GoldenMovieGrid extends StatelessWidget {
  const GoldenMovieGrid({super.key, this.firstCardFocusNode});

  /// Attached to the first card, for captures of its focus chrome.
  final FocusNode? firstCardFocusNode;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final base = GridLayoutConstants.gridPadding;
    return CustomScrollView(
      slivers: [
        MediaCardSliverLayout(
          viewMode: settings.read(SettingsService.viewMode),
          itemCount: goldenMovies.length,
          density: settings.read(SettingsService.libraryDensity),
          // The library tabs add room for the focus decoration above row one.
          padding: base.copyWith(top: base.top + 3),
          itemBuilder: (context, position) => FocusableMediaCard(
            key: ValueKey(goldenMovies[position.index].id),
            item: goldenMovies[position.index],
            focusNode: position.index == 0 ? firstCardFocusNode : null,
            disableScale: position.disableScale,
          ),
        ),
      ],
    );
  }
}
