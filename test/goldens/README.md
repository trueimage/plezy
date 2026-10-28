# Golden screenshot tests

`test/goldens/` renders the app's main surfaces in every theme and form factor and compares them pixel for pixel
with the PNGs committed under `test/goldens/goldens/`. They exist so that refactoring the theme and layout code
can prove the existing themes and layouts did not change.

## The rule

**A change that is not meant to change how the app looks must not change any existing golden image.** That
includes every refactor of theme, token, typography, spacing, focus and layout code. If a refactor makes a
golden fail, the refactor is wrong, not the image.

A change that is meant to look different (a new theme, a deliberate restyle) regenerates only the images it
means to change, and the pull request says which images changed and why. A new theme or screen adds images; it
does not modify the existing ones.

## What is captured

| Screen (`goldens/<screen>/`) | Themes | Form factors | What it shows |
|---|---|---|---|
| `shell` | all 9 | phone, desktop, TV | Navigation shell around a library grid of `MediaCard`s: the `NavigationBar` on the phone, the collapsed `SideNavigationRail` on desktop and TV |
| `detail_hero` | all 9 | phone, desktop, TV | `MediaDetailScreen` hero for a movie with full metadata |
| `tv_focus` | all 9 | TV | The shell with the first card focused in keyboard (D-pad) mode: focus ring, scale and glow |
| `navigation` | Light, Dark | phone, desktop, TV | The rail held open with its library list (desktop, TV); the bottom bar without labels (phone) |
| `hub_section` | Light, Dark | phone, desktop, TV | Continue Watching and a movie `HubSection` |
| `episode_list` | Light, Dark | phone, desktop, TV | A season's episodes (`EpisodeCard` list; the episode row on TV) |
| `settings_appearance` | Light, Dark | phone, desktop, TV | Settings → Appearance |
| `theme_picker` | Light, Dark | phone, desktop, TV | The theme picker with the presets and Custom available |
| `dialog` | Light, Dark | phone, desktop, TV | A destructive confirm dialog over the shell |
| `overlay_sheet` | Light, Dark | phone, desktop, TV | An `OverlaySheet` menu over the shell |
| `player_controls` | Light, Dark | phone, desktop, TV | The video controls raised over steady playback |
| `player_loading` | Light, Dark | phone, desktop, TV | The player route's loading surface, opened against the mock native channels |

The nine themes are the eight fixed ones (Light, Dark, OLED, Ember, Glacier, Forest, Plum, Paper) and Custom with
the fixed `goldenCustomPalette` in `golden_harness.dart`. System is not a palette of its own: it resolves to Light
or Dark.

Every theme is captured where a palette change shows up most (chrome, cards, hero, focus). Every other screen is
captured in Light and Dark, the two built-ins with opposite brightness. That covers each screen in both
brightnesses, and each palette everywhere it differs, without multiplying every screen by nine.

Form factors are logical sizes at 1x: phone 390x844, desktop 1280x800, and TV 1920x1080, the size
`TvLayoutConstants` scales against. The phone and TV render with the Android theme platform and desktop with
Linux. TV is forced the way the Force TV setting does it. Settings are the defaults for that form factor.

## Running them

```sh
flutter test test/goldens                 # just the goldens
scripts/run_tests.sh --tags golden        # same, as CI runs them
scripts/run_tests.sh --exclude-tags golden
```

The images are rendered on **Linux x64** with the Flutter version CI pins (`FLUTTER_VERSION` in
`.github/workflows/ci.yml`). Other hosts lay out identically but rasterise text, gradients and anti-aliasing a
little differently (Linux arm64 too: about a dozen images differ by up to 0.25%). So on macOS, Windows and Linux
arm64 the tests still pump every screen, and fail on any exception or overflow, but do not compare pixels. A plain
`flutter test` on a Mac therefore passes; it prints one line per test file saying the images were not compared.

CI compares them in the Unit Tests job (step "Run golden screenshot tests"). When that step fails, the
`golden-failures` artifact holds the master, test and diff images for every failing golden.

## Comparing and updating on any machine

`scripts/update_goldens.sh` runs the goldens in an Ubuntu x64 container with the CI Flutter version. It needs
Docker, and on Apple silicon it runs under amd64 emulation, so the first run builds the image and is slow.

```sh
scripts/update_goldens.sh --check                                  # compare; diffs land in test/goldens/failures/
scripts/update_goldens.sh                                          # regenerate every image
scripts/update_goldens.sh test/goldens/shell_golden_test.dart      # regenerate one file's images
```

A full update renders into an empty `goldens/` directory inside the container, so images for tests that no longer
exist are removed when the successful render replaces the committed baselines. Full and targeted updates leave
existing baselines untouched if rendering fails.
`flutter test --update-goldens` refuses to write images on a host other than Linux x64.

After updating, look at every changed image (`git status test/goldens/goldens`) before committing it.

## How the images stay deterministic

- **Fonts.** `flutter_test_config.dart` loads every font in the app's `FontManifest.json` (Material Symbols and
  the bundled Go Noto fallbacks) plus Roboto from the Flutter SDK's cached Material fonts. The theme's text styles
  come from `Typography.englishLike2021`, which names no font family, so a device draws them in its system font
  (Roboto on Android). The test engine draws any style without a family in its box-glyph test font, so
  `goldenThemeData` fills in Roboto on exactly those styles: the text themes and the app-bar title. Everything
  else about the theme is the production `monoTheme`, so size, weight, spacing and colour changes all show.
- **No artwork.** The fixtures in `golden_fixtures.dart` have no image paths, so cards and heroes show their
  placeholders instead of depending on image decoding.
- **Wall-clock time.** The clock and the player's "ends at" estimate read the time through `wallClockNow()`
  (`lib/utils/wall_clock.dart`), which the harness pins to 07:19 on 28 October 2026 in 12-hour format. The text is
  still painted over in magenta (`0xFFFF00FF`) in the captured image. Pinning the clock keeps the mask itself
  steady: Roboto draws digits at different widths, so masking a live clock moved the mask's edge with
  the time of day.
- **Animations** are settled, or stepped by fixed durations of the fake test clock.

## Adding a screen

Add a `goldenMatrix(...)` to a `*_golden_test.dart` file in this directory (tag the file `@Tags(['golden'])`):

```dart
goldenMatrix(
  'my_screen',
  themes: lightDarkGoldenThemes, // or allGoldenThemes
  body: (tester, golden) => pumpGoldenApp(tester, golden, home: const MyScreen()),
);
```

Then run `scripts/update_goldens.sh test/goldens/my_screen_golden_test.dart` and commit the new images.
