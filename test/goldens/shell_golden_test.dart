@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/dialogs.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';

import 'golden_harness.dart';
import 'golden_shell.dart';

/// The navigation shell around a library grid, and what opens over it.
void main() {
  // Every theme at every form factor: this alone pins each palette's
  // navigation chrome and card styling.
  goldenMatrix('shell', themes: allGoldenThemes, body: pumpGoldenShell);

  // The other navigation states: the rail held open with its library list on
  // desktop and TV, the label-less bottom bar on the phone.
  goldenMatrix(
    'navigation',
    themes: screenGoldenThemes,
    body: (tester, golden) async {
      await SettingsService.instance.write(SettingsService.alwaysKeepSidebarOpen, true);
      await SettingsService.instance.write(SettingsService.showNavBarLabels, false);
      await pumpGoldenShell(tester, golden);
      expect(find.byType(SideNavigationRail), golden.isPhone ? findsNothing : findsOneWidget);
    },
  );

  // The first grid card focused in keyboard (D-pad) mode: the TV focus ring,
  // scale and glow, in every theme because the ring takes the accent colour.
  goldenMatrix(
    'tv_focus',
    themes: allGoldenThemes,
    formFactors: const [GoldenFormFactor.tv],
    body: (tester, golden) async {
      final focusNode = FocusNode(debugLabel: 'golden-first-card');
      addTearDown(focusNode.dispose);
      await pumpGoldenShell(tester, golden, firstCardFocusNode: focusNode);
      expect(PlatformDetector.isTV(), isTrue);
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasPrimaryFocus, isTrue);
    },
  );

  goldenMatrix(
    'dialog',
    themes: screenGoldenThemes,
    body: (tester, golden) async {
      await pumpGoldenShell(tester, golden);
      final context = tester.element(find.byType(GoldenMovieGrid));
      showConfirmDialog(
        context,
        title: 'Delete download?',
        message: 'The Quiet Harbor will be removed from this device. You can download it again later.',
        confirmText: 'Delete',
        isDestructive: true,
      ).ignore();
      await tester.pumpAndSettle();
    },
  );

  goldenMatrix(
    'overlay_sheet',
    themes: screenGoldenThemes,
    body: (tester, golden) async {
      await pumpGoldenShell(tester, golden);
      final context = tester.element(find.byType(GoldenMovieGrid));
      OverlaySheetController.of(context)
          .show<void>(
            showDragHandle: true,
            builder: (_) => const AppMenuSheet<String>(
              title: 'The Quiet Harbor',
              entries: [
                AppMenuItem(value: 'play', label: 'Play', icon: Symbols.play_arrow_rounded),
                AppMenuItem(value: 'watched', label: 'Mark as watched', icon: Symbols.check_rounded),
                AppMenuItem(value: 'playlist', label: 'Add to playlist', icon: Symbols.playlist_add_rounded),
                AppMenuItem(value: 'download', label: 'Download', icon: Symbols.download_rounded),
                AppMenuDivider(),
                AppMenuItem(value: 'delete', label: 'Delete', icon: Symbols.delete_rounded, destructive: true),
              ],
            ),
          )
          .ignore();
      await tester.pumpAndSettle();
    },
  );
}
