import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/services/settings_service.dart' as settings;
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/wall_clock.dart';
import 'package:plezy/widgets/system_clock.dart';
import 'package:plezy/widgets/video_controls/widgets/finish_time_builder.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_helpers/prefs.dart';

/// Tag carried by every golden test, so `--exclude-tags golden` and
/// `--tags golden` can split them from the rest of the suite.
const goldenTag = 'golden';

/// Whether this host renders the committed images: Linux x64, as in CI and
/// `scripts/update_goldens.sh`.
///
/// Other hosts lay out identically but rasterise text, gradients and
/// anti-aliasing slightly differently (Linux arm64 included), so they render
/// the screens without comparing pixels.
bool get goldenHostRenders => Abi.current() == Abi.linuxX64;

/// The form factors every screen is captured at, as logical size at 1x.
///
/// TV is 1920x1080 logical, the size [TvLayoutConstants] scales against, with
/// TV mode forced the way the Force TV setting does it.
enum GoldenFormFactor {
  phone(Size(390, 844)),
  desktop(Size(1280, 800)),
  tv(Size(1920, 1080));

  const GoldenFormFactor(this.size);

  final Size size;

  /// Theme platform: Android for the phone and TV, Linux for desktop, the
  /// desktop OS the goldens are rendered on.
  TargetPlatform get platform => this == desktop ? TargetPlatform.linux : TargetPlatform.android;
}

/// A fixed palette under test, keyed by the [settings.ThemeMode] that selects it.
@immutable
class GoldenTheme {
  const GoldenTheme(this.mode, this.palette);

  final settings.ThemeMode mode;
  final MonoPalette palette;

  String get name => mode.name;
}

/// A deliberately saturated custom palette, so a refactor that drops any of
/// the six slots shows up as a colour change.
const goldenCustomPalette = MonoPalette(
  bg: Color(0xFF0E1A24),
  surface: Color(0xFF172A3A),
  outline: Color(0x3346B5D0),
  text: Color(0xFFEAF6FA),
  textMuted: Color(0xFF8FB3C2),
  accent: Color(0xFFF2A541),
);

/// Every selectable fixed theme plus Custom with [goldenCustomPalette]. System
/// is not a palette of its own: it resolves to Light or Dark.
final List<GoldenTheme> allGoldenThemes = [
  for (final mode in settings.ThemeMode.values)
    if (ThemeProvider.paletteFor(mode, customPalette: goldenCustomPalette) case final palette?)
      GoldenTheme(mode, palette),
];

/// The two built-in themes every screen is captured in.
final List<GoldenTheme> lightDarkGoldenThemes = [
  for (final theme in allGoldenThemes)
    if (theme.mode == settings.ThemeMode.light || theme.mode == settings.ThemeMode.dark) theme,
];

/// One cell of a golden matrix.
@immutable
class GoldenCase {
  const GoldenCase(this.formFactor, this.theme);

  final GoldenFormFactor formFactor;
  final GoldenTheme theme;

  bool get isTV => formFactor == GoldenFormFactor.tv;
  bool get isPhone => formFactor == GoldenFormFactor.phone;
}

/// Wraps the widget the golden captures. Tests pump through [pumpGoldenApp],
/// so everything inside MaterialApp, overlays and dialogs included, is in the
/// image.
const goldenBoundaryKey = ValueKey('golden-boundary');

/// Registers one golden test per [themes] x [formFactors] cell for [screen].
///
/// [body] pumps the screen (normally through [pumpGoldenApp]) and leaves it in
/// the state to capture; the harness then compares the whole view against
/// `goldens/<screen>/<screen>_<form factor>_<theme>.png` (the screen prefix
/// keeps the names of failure images unique).
void goldenMatrix(
  String screen, {
  required List<GoldenTheme> themes,
  List<GoldenFormFactor> formFactors = GoldenFormFactor.values,
  required Future<void> Function(WidgetTester tester, GoldenCase golden) body,
}) {
  group(screen, () {
    for (final formFactor in formFactors) {
      for (final theme in themes) {
        final golden = GoldenCase(formFactor, theme);
        testWidgets('${formFactor.name} ${theme.name}', (tester) async {
          await setUpGoldenCase(tester, golden);
          try {
            await body(tester, golden);
            await expectLater(
              await _captureMasked(tester),
              matchesGoldenFile('goldens/$screen/${screen}_${formFactor.name}_${theme.name}.png'),
            );
          } finally {
            tearDownGoldenCase();
          }
        }, tags: goldenTag);
      }
    }
  });
}

/// Text showing the wall-clock time: the player's clock and its "ends at"
/// estimate. Both read `DateTime.now()`, which the test clock does not
/// control, so their text is painted over in the captured image.
final List<Finder> _wallClockFinders = [
  for (final owner in [SystemClock, FinishTimeBuilder])
    find.descendant(of: find.byType(owner), matching: find.byType(RichText)),
];

/// Colour of the box that replaces wall-clock text in the image.
const _wallClockMask = Color(0xFFFF00FF);

/// The golden boundary as an image, with all wall-clock text masked.
Future<ui.Image> _captureMasked(WidgetTester tester) async {
  final boundary = find.byKey(goldenBoundaryKey).evaluate().single;
  final masks = [
    for (final finder in _wallClockFinders)
      for (final element in finder.evaluate())
        if (element.renderObject case final RenderParagraph text when text.hasSize)
          if (_glyphBounds(text) case final bounds?) MatrixUtils.transformRect(text.getTransformTo(null), bounds),
  ];
  return (await tester.runAsync(() async {
    final image = await captureImage(boundary);
    if (masks.isEmpty) return image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
    // Whole pixels with a pixel of margin and no anti-aliasing: glyph bounds
    // move by thousandths of a pixel with the digits shown, which would
    // otherwise change the blended edge.
    final paint = Paint()
      ..color = _wallClockMask
      ..isAntiAlias = false;
    for (final rect in masks) {
      final outer = rect.inflate(1);
      canvas.drawRect(
        Rect.fromLTRB(
          outer.left.floorToDouble(),
          outer.top.floorToDouble(),
          outer.right.ceilToDouble(),
          outer.bottom.ceilToDouble(),
        ),
        paint,
      );
    }
    final masked = await recorder.endRecording().toImage(image.width, image.height);
    image.dispose();
    return masked;
  }))!;
}

/// The area [text] actually draws glyphs in, which is narrower than its box
/// when the text is aligned inside a wide slot.
Rect? _glyphBounds(RenderParagraph text) {
  final length = text.text.toPlainText().length;
  if (length == 0) return null;
  final boxes = text.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length));
  if (boxes.isEmpty) return null;
  return boxes.map((box) => box.toRect()).reduce((a, b) => a.expandToInclude(b));
}

/// Fresh preferences, English strings, the stored theme, and the view, theme
/// platform and TV mode for [golden]'s form factor.
Future<void> setUpGoldenCase(WidgetTester tester, GoldenCase golden) async {
  resetSharedPreferencesForTest();
  settings.SettingsService.resetForTesting();
  final service = await settings.SettingsService.getInstance();
  await service.write(settings.SettingsService.themeMode, golden.theme.mode);
  await service.write(settings.SettingsService.customThemePalette, goldenCustomPalette);
  LocaleSettings.setLocaleSync(AppLocale.en);

  final formFactor = golden.formFactor;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = formFactor.size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  // Meant to render wall-clock text as HH:mm, but it is set after the view
  // metrics above, and the root MediaQuery reads it only when it rebuilds its
  // data for a metrics change, so the player still shows 12-hour time (the
  // clock reads 7:19 AM). The pinned wall clock below is what keeps that text fixed.
  tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  // A pinned wall clock: the masked text, and so the mask's edge, is the same
  // on every run, whatever the font's digits.
  debugWallClock = () => DateTime(2026, 10, 28, 7, 19);
  addTearDown(() => debugWallClock = DateTime.now);
  addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);

  // Desktop player chrome asks the window plugin about the window state.
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const windowChannel = MethodChannel('window_manager');
  messenger.setMockMethodCallHandler(windowChannel, (call) async => call.method.startsWith('is') ? false : null);
  addTearDown(() => messenger.setMockMethodCallHandler(windowChannel, null));

  debugDefaultTargetPlatformOverride = formFactor.platform;
  PlatformDetector.debugSetIsDesktopOSOverride(formFactor == GoldenFormFactor.desktop);
  TvDetectionService.debugReset();
  if (golden.isTV) {
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
  }
}

/// Undoes the global overrides of [setUpGoldenCase]. Runs inside the test
/// body, because flutter_test checks foundation debug variables before
/// tear-downs run.
void tearDownGoldenCase() {
  debugDefaultTargetPlatformOverride = null;
  PlatformDetector.debugSetIsDesktopOSOverride(null);
  TvDetectionService.debugReset();
}

/// Pumps [home] inside the app's theme for [golden] and the boundary the
/// golden captures. [providers] are installed above MaterialApp, as MainApp
/// installs its own.
Future<void> pumpGoldenApp(
  WidgetTester tester,
  GoldenCase golden, {
  required Widget home,
  List<SingleChildWidget> providers = const [],
  GlobalKey<NavigatorState>? navigatorKey,
  bool settle = true,
}) async {
  Widget app = MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    theme: goldenThemeData(golden.theme.palette),
    home: home,
  );
  if (providers.isNotEmpty) app = MultiProvider(providers: providers, child: app);
  await tester.pumpWidget(
    RepaintBoundary(
      key: goldenBoundaryKey,
      child: TranslationProvider(child: InputModeTracker(child: app)),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Stands in for the device's default UI font.
///
/// The theme's text styles come from `Typography.englishLike2021`, which names
/// no font family, so a device draws them in its system font (Roboto on
/// Android). flutter_tester has no system fonts and draws any style without a
/// family in its box-glyph test font, whatever fonts are loaded.
const goldenDefaultFontFamily = 'Roboto';

/// [monoTheme] for [palette], with [goldenDefaultFontFamily] filled in on the
/// theme's text styles that name no family: the text themes and the app bar
/// title. Nothing else differs, so a change to any size, weight, spacing or
/// colour still shows in the images.
ThemeData goldenThemeData(MonoPalette palette) {
  final theme = monoTheme(palette);
  return theme.copyWith(
    textTheme: _withDefaultFamily(theme.textTheme),
    primaryTextTheme: _withDefaultFamily(theme.primaryTextTheme),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: _fillFamily(theme.appBarTheme.titleTextStyle),
      toolbarTextStyle: _fillFamily(theme.appBarTheme.toolbarTextStyle),
    ),
  );
}

TextStyle? _fillFamily(TextStyle? style) =>
    style == null || style.fontFamily != null ? style : style.copyWith(fontFamily: goldenDefaultFontFamily);

TextTheme _withDefaultFamily(TextTheme textTheme) {
  const fill = _fillFamily;
  return TextTheme(
    displayLarge: fill(textTheme.displayLarge),
    displayMedium: fill(textTheme.displayMedium),
    displaySmall: fill(textTheme.displaySmall),
    headlineLarge: fill(textTheme.headlineLarge),
    headlineMedium: fill(textTheme.headlineMedium),
    headlineSmall: fill(textTheme.headlineSmall),
    titleLarge: fill(textTheme.titleLarge),
    titleMedium: fill(textTheme.titleMedium),
    titleSmall: fill(textTheme.titleSmall),
    bodyLarge: fill(textTheme.bodyLarge),
    bodyMedium: fill(textTheme.bodyMedium),
    bodySmall: fill(textTheme.bodySmall),
    labelLarge: fill(textTheme.labelLarge),
    labelMedium: fill(textTheme.labelMedium),
    labelSmall: fill(textTheme.labelSmall),
  );
}

/// Loads the fonts the app ships (every family in the asset FontManifest,
/// which covers Material Symbols and the bundled Go Noto fallbacks) plus
/// Roboto, the Material default the theme resolves to on Android and Linux.
///
/// flutter_test otherwise renders every glyph as a box in its test font, so
/// text size and weight changes would not show in the images.
Future<void> loadGoldenFonts() async {
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }

  final files = _materialFontsDir().listSync().whereType<File>().where((file) {
    final name = file.uri.pathSegments.last;
    return name.startsWith('Roboto-') && name.endsWith('.ttf');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) throw StateError('No Roboto fonts in ${_materialFontsDir().path}');
  final roboto = FontLoader(goldenDefaultFontFamily);
  for (final file in files) {
    roboto.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await roboto.load();
}

/// The Flutter SDK's cached Material fonts. `flutter test` exports
/// FLUTTER_ROOT; the tester binary's own location is the fallback.
Directory _materialFontsDir() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    return Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  }
  // <root>/bin/cache/artifacts/engine/<platform>/flutter_tester
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  return Directory('${artifacts.path}/material_fonts');
}

/// Installs [_HostGatedGoldenComparator] over the per-file comparator
/// flutter_test set up.
void installGoldenComparator() {
  goldenFileComparator = _HostGatedGoldenComparator(goldenFileComparator);
}

/// Compares on hosts that render the committed images ([goldenHostRenders]);
/// elsewhere it accepts every image, so a plain `flutter test` on macOS,
/// Windows or Linux arm64 still runs the screens without failing on
/// rasterisation, and it refuses `--update-goldens` so images from those hosts
/// never get committed.
class _HostGatedGoldenComparator extends GoldenFileComparator {
  _HostGatedGoldenComparator(this._inner);

  final GoldenFileComparator _inner;
  static bool _warned = false;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (goldenHostRenders) return _inner.compare(imageBytes, golden);
    if (!_warned) {
      _warned = true;
      debugPrint(
        'Golden images are not compared on ${Abi.current()}: they are rendered on Linux x64. '
        'Run scripts/update_goldens.sh --check to compare them in a Linux container.',
      );
    }
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    if (!goldenHostRenders) {
      throw FlutterError(
        'Refusing to write $golden on ${Abi.current()}: committed goldens are rendered on Linux x64. '
        'Run scripts/update_goldens.sh instead.',
      );
    }
    return _inner.update(golden, imageBytes);
  }

  @override
  Uri getTestUri(Uri key, int? version) => _inner.getTestUri(key, version);
}
