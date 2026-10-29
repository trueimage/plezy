@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/appearance_settings_screen.dart';
import 'package:plezy/screens/settings/theme_settings_screen.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:provider/provider.dart';

import 'golden_harness.dart';

/// Settings → Appearance and the theme picker it opens, with the Supporter
/// perks available so the picker lists the presets and Custom.
void main() {
  goldenMatrix(
    'settings_appearance',
    themes: lightDarkGoldenThemes,
    body: (tester, golden) => _pumpSettings(tester, golden, const AppearanceSettingsScreen()),
  );

  goldenMatrix(
    'theme_picker',
    themes: lightDarkGoldenThemes,
    body: (tester, golden) => _pumpSettings(tester, golden, ThemeSettingsScreen(openSupporterSheet: (_) async {})),
  );
}

Future<void> _pumpSettings(WidgetTester tester, GoldenCase golden, Widget screen) async {
  final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
  addTearDown(supporter.dispose);
  final theme = ThemeProvider(supporter: supporter);
  addTearDown(theme.dispose);
  await pumpGoldenApp(
    tester,
    golden,
    providers: [
      ChangeNotifierProvider<SupporterService>.value(value: supporter),
      ChangeNotifierProvider<ThemeProvider>.value(value: theme),
    ],
    home: screen,
  );
}
