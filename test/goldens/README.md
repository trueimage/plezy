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
| `shell` | all 10 | phone, desktop, TV | Navigation shell around a library grid of `MediaCard`s: the `NavigationBar` on the phone, the collapsed `SideNavigationRail` on desktop and TV |
| `detail_hero` | all 10 | phone, desktop, TV | `MediaDetailScreen` hero for a movie with full metadata (Nocturne's movie also has two versions, media info and a trailer) |
| `tv_focus` | all 10 | TV | The shell with the first card focused in keyboard (D-pad) mode: focus ring, scale and glow |
| `navigation` | Light, Dark, Nocturne | phone, desktop, TV | The rail held open with its library list (desktop, TV); the bottom bar without labels (phone) |
| `hub_section` | Light, Dark, Nocturne | phone, desktop, TV | Continue Watching and a movie `HubSection` |
| `episode_list` | Light, Dark, Nocturne | phone, desktop, TV | A season's episodes (`EpisodeCard` list; the episode row on TV, Nocturne's vertical list) |
| `settings_appearance` | Light, Dark, Nocturne | phone, desktop, TV | Settings → Appearance (with the Nocturne settings group under Nocturne) |
| `theme_picker` | Light, Dark, Nocturne | phone, desktop, TV | The theme picker with the presets and Custom available |
| `dialog` | Light, Dark, Nocturne | phone, desktop, TV | A destructive confirm dialog over the shell |
| `overlay_sheet` | Light, Dark, Nocturne | phone, desktop, TV | An `OverlaySheet` menu over the shell |
| `player_controls` | Light, Dark, Nocturne | phone, desktop, TV | The video controls raised over steady playback |
| `player_loading` | Light, Dark, Nocturne | phone, desktop, TV | The player route's loading surface, opened against the mock native channels |
| `nocturne_home` | Nocturne | phone, desktop, TV | The home screen's spotlight over the fixture server's Continue Watching and hubs |
| `nocturne_home_variants` | Nocturne True black + Ivory | TV | The home spotlight with both Nocturne settings changed |
| `nocturne_home_hc` | Nocturne | TV | The home spotlight with the platform's high-contrast flag: no scale, no glow, the 4 px ring |
| `nocturne_home_reduced` | Nocturne | TV | The home spotlight on the reduced visual-effects tier |
| `nocturne_detail_show` | Nocturne | phone, desktop, TV | A three-season show's page: the season chips with their "N new" counts over the episode list |
| `nocturne_library` | Nocturne | phone, desktop, TV | `LibrariesScreen` on a 128-title Movies library: the header, chips and A–Z jump rail |
| `nocturne_search` / `nocturne_search_none` | Nocturne | phone, desktop, TV | `SearchScreen` with results, and with none |
| `nocturne_state_loading` / `_empty` / `_offline` | Nocturne | phone, desktop, TV | The home while the server has not answered, has nothing, and cannot be reached |

The ten themes are the nine fixed ones (Light, Dark, OLED, Nocturne, Ember, Glacier, Forest, Plum, Paper) and
Custom with the fixed `goldenCustomPalette` in `golden_harness.dart`. System is not a palette of its own: it
resolves to Light or Dark.

Every theme is captured where a palette change shows up most (chrome, cards, hero, focus). Every other screen is
captured in Light and Dark, the two built-ins with opposite brightness, and in Nocturne, the one theme that draws
its own layout. That covers each screen in both brightnesses and in both layouts, and each palette everywhere it
differs, without multiplying every screen by ten. The `nocturne_*` screens are the ones only the Nocturne layout
draws, or that it changes enough to need their own fixtures.

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

- **Fonts.** `flutter_test_config.dart` loads every font in the app's `FontManifest.json` (Material Symbols,
  Nocturne's Manrope and the bundled Go Noto fallbacks) plus Roboto from the Flutter SDK's cached Material fonts. The theme's text styles
  come from `Typography.englishLike2021`, which names no font family, so a device draws them in its system font
  (Roboto on Android). The test engine draws any style without a family in its box-glyph test font, so
  `goldenThemeData` fills in Roboto on exactly those styles: the text themes and the app-bar title. Nocturne
  names Manrope on them, so it renders in its own face. Everything
  else about the theme is the production `monoTheme`, so size, weight, spacing and colour changes all show.
- **No artwork.** The fixtures in `golden_fixtures.dart` have no image paths, so cards and heroes show their
  placeholders instead of depending on image decoding.
- **Wall-clock time.** The clock and the player's "ends at" estimate read the time through `wallClockNow()`
  (`lib/utils/wall_clock.dart`), which the harness pins to 07:19 on 28 October 2026 in 24-hour format. The text is
  still painted over in magenta (`0xFFFF00FF`) in the captured image. Pinning the clock keeps the mask itself
  steady: Roboto and Manrope draw digits at different widths, so masking a live clock moved the mask's edge with
  the time of day.
- **Animations** are settled, or stepped by fixed durations of the fake test clock.

## Adding a screen

Add a `goldenMatrix(...)` to a `*_golden_test.dart` file in this directory (tag the file `@Tags(['golden'])`):

```dart
goldenMatrix(
  'my_screen',
  themes: screenGoldenThemes, // or allGoldenThemes
  body: (tester, golden) => pumpGoldenApp(tester, golden, home: const MyScreen()),
);
```

Then run `scripts/update_goldens.sh test/goldens/my_screen_golden_test.dart` and commit the new images.
