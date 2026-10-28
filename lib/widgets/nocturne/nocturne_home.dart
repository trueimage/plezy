import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../navigation/main_screen_scope.dart';
import '../../services/device_performance.dart';
import '../../theme/mono_tokens.dart';
import '../../theme/surface_tokens.dart';
import '../media_card.dart' show SkeletonLoader;
import '../tv_spotlight_scaffold.dart' show TvSpotlightClientResolver;
import 'nocturne_spotlight.dart';

/// The kicker over a spotlight: the hub the item was focused in, so the
/// spotlight says why it is showing this title.
String? nocturneKickerFor(MediaItem? item, Iterable<MediaHub> hubs) {
  if (item == null) return null;
  for (final hub in hubs) {
    for (final candidate in hub.items) {
      if (candidate.globalKey == item.globalKey) return hub.title;
    }
  }
  return null;
}

/// The Nocturne home on TV: a focus-driven spotlight band over the rows.
///
/// The spotlight follows whatever card is focused, at a fixed row density:
/// the first row sits on the layout's focus line, so Continue Watching peeks
/// into the band. Once focus moves past the first row, the rows rise and the
/// spotlight folds to a one-line title. Focus never moves on its own; Up from
/// the first row reaches the spotlight's primary action.
class NocturneTvHome extends StatefulWidget {
  const NocturneTvHome({
    super.key,
    required this.hubs,
    required this.spotlight,
    required this.resolveSpotlight,
    required this.resolveClient,
    required this.activeHubIndex,
    required this.rows,
    required this.onPlay,
    required this.onDetails,
    required this.onNavigateDown,
    required this.onNavigateUp,
    this.hideSpoilers = false,
    this.overlays = const [],
  });

  final List<MediaHub> hubs;
  final ValueListenable<MediaItem?> spotlight;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;

  /// Index of the row holding focus; past the first, the band folds.
  final ValueListenable<int> activeHubIndex;

  /// The rows (the shared TV browse rail).
  final Widget rows;
  final ValueChanged<MediaItem> onPlay;
  final ValueChanged<MediaItem> onDetails;

  /// Down from the spotlight actions: into the first row.
  final VoidCallback onNavigateDown;

  /// Up from the spotlight actions: the toolbar.
  final VoidCallback onNavigateUp;
  final bool hideSpoilers;

  /// Loading, error and empty states and the toolbar, over everything.
  final List<Widget> overlays;

  @override
  State<NocturneTvHome> createState() => NocturneTvHomeState();
}

class NocturneTvHomeState extends State<NocturneTvHome> {
  final _primaryAction = FocusNode(debugLabel: 'nocturne_spotlight_primary');

  /// Focuses the spotlight's primary action (Resume or Play).
  void focusPrimaryAction() {
    if (_primaryAction.context != null) _primaryAction.requestFocus();
  }

  @override
  void dispose() {
    _primaryAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final size = MediaQuery.sizeOf(context);
    final foregroundLeft = MainScreenFocusScope.foregroundLeftOf(context);
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    final duration = DevicePerformance.reducedDuration(const Duration(milliseconds: 220));
    final textLeft = (m.safeX - foregroundLeft).clamp(0.0, double.infinity).toDouble();
    final rowTop = m.layout.rowFocusLine * m.scale;
    final foldedRowTop = (m.layout.safeY + 96) * m.scale;
    // The band ends where the rows begin, so the rail's first header never
    // runs under the buttons whatever the screen size.
    final bandTop = (m.layout.safeY + 24) * m.scale;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          SideNavigationBleedBuilder(
            targetBleed: foregroundLeft,
            child: ValueListenableBuilder<MediaItem?>(
              valueListenable: widget.spotlight,
              builder: (context, _, _) {
                final item = widget.resolveSpotlight();
                return NocturneBackdrop(item: item, client: widget.resolveClient(item));
              },
            ),
            builder: (context, bleed, child) =>
                Positioned(top: 0, bottom: 0, left: -bleed, width: fullBleedWidth, child: child!),
          ),
          ValueListenableBuilder<int>(
            valueListenable: widget.activeHubIndex,
            builder: (context, activeHub, _) {
              final folded = activeHub > 0;
              final rowsTop = folded ? foldedRowTop : rowTop - 12 * m.scale;
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: textLeft,
                    top: bandTop,
                    width: size.width * 0.5,
                    height: rowsTop - bandTop,
                    child: ValueListenableBuilder<MediaItem?>(
                      valueListenable: widget.spotlight,
                      builder: (context, _, _) {
                        final item = widget.resolveSpotlight();
                        return AnimatedSwitcher(
                          duration: duration,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.bottomLeft,
                            fit: StackFit.expand,
                            children: [...previous, ?current],
                          ),
                          child: item == null
                              ? const SizedBox.shrink()
                              : KeyedSubtree(
                                  key: ValueKey((item.globalKey, folded)),
                                  child: folded ? _foldedTitle(context, item) : _spotlight(context, item),
                                ),
                        );
                      },
                    ),
                  ),
                  AnimatedPositioned(
                    duration: duration,
                    curve: const Cubic(0.3, 0, 0.1, 1),
                    left: 0,
                    right: 0,
                    top: rowsTop,
                    bottom: 0,
                    child: widget.rows,
                  ),
                ],
              );
            },
          ),
          ...widget.overlays,
        ],
      ),
    );
  }

  Widget _foldedTitle(BuildContext context, MediaItem item) {
    final m = NocturneMetrics.of(context);
    final t = tokens(context);
    final episode = nocturneEpisodeLine(item);
    return Align(
      alignment: Alignment.bottomLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: item.grandparentTitle ?? item.displayTitle,
              style: TextStyle(fontWeight: FontWeight.w800, color: t.text),
            ),
            if (episode != null)
              TextSpan(
                text: '  ·  $episode',
                style: TextStyle(fontWeight: FontWeight.w500, color: t.textMuted),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: m.size(m.type.shelfHeader), height: 1.2),
      ),
    );
  }

  Widget _spotlight(BuildContext context, MediaItem item) {
    final m = NocturneMetrics.of(context);
    final timeLeft = nocturneTimeLeft(item);
    // While the band folds, the outgoing spotlight is laid out in the folded
    // slot; it keeps its own height and is clipped instead of overflowing.
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NocturneTitleBlock(
              item: item,
              client: widget.resolveClient(item),
              kicker: nocturneKickerFor(item, widget.hubs),
              hideSpoilers: widget.hideSpoilers,
              extraMeta: [?timeLeft],
            ),
            SizedBox(height: m.pick(tv: 22, desktop: 16, phone: 12)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NocturneButton(
                  focusNode: _primaryAction,
                  style: NocturneButtonStyle.primary,
                  icon: Symbols.play_arrow_rounded,
                  label: item.hasActiveProgress ? t.common.resume : t.common.play,
                  detail: timeLeft,
                  onPressed: () => widget.onPlay(item),
                  onNavigateDown: widget.onNavigateDown,
                  onNavigateUp: widget.onNavigateUp,
                ),
                SizedBox(width: m.pick(tv: 16, desktop: 12, phone: 10)),
                NocturneButton(
                  icon: Symbols.info_rounded,
                  label: t.nocturne.details,
                  onPressed: () => widget.onDetails(item),
                  onNavigateDown: widget.onNavigateDown,
                  onNavigateUp: widget.onNavigateUp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Nocturne home spotlight on desktop and phone: the first Continue
/// Watching title over its backdrop, with Resume and Details. It holds still:
/// no carousel, no auto-advance.
class NocturneHomeHero extends StatelessWidget {
  const NocturneHomeHero({
    super.key,
    required this.item,
    required this.client,
    required this.height,
    required this.onPlay,
    required this.onDetails,
    this.kicker,
    this.hideSpoilers = false,
  });

  final MediaItem item;
  final MediaServerClient? client;
  final double height;
  final VoidCallback onPlay;
  final VoidCallback onDetails;
  final String? kicker;
  final bool hideSpoilers;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final timeLeft = nocturneTimeLeft(item);
    final top = MediaQuery.paddingOf(context).top + m.pick(tv: 0, desktop: 64, phone: 56);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NocturneBackdrop(item: item, client: client, heightFactor: 1, sideScrim: !m.isPhone),
          Positioned(
            left: m.safeX + (m.isPhone ? 0 : 8),
            right: m.isPhone ? m.safeX : null,
            width: m.isPhone ? null : 560,
            top: top,
            bottom: m.pick(tv: 0, desktop: 24, phone: 16),
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NocturneTitleBlock(
                        item: item,
                        client: client,
                        kicker: kicker,
                        hideSpoilers: hideSpoilers,
                        showSummary: !m.isPhone,
                        extraMeta: [?timeLeft],
                      ),
                      SizedBox(height: m.pick(tv: 22, desktop: 16, phone: 12)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NocturneButton(
                            style: NocturneButtonStyle.primary,
                            icon: Symbols.play_arrow_rounded,
                            label: item.hasActiveProgress ? t.common.resume : t.common.play,
                            detail: timeLeft,
                            onPressed: onPlay,
                          ),
                          SizedBox(width: m.pick(tv: 16, desktop: 12, phone: 10)),
                          NocturneButton(icon: Symbols.info_rounded, label: t.nocturne.details, onPressed: onDetails),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Nocturne home while the server has not answered: the spotlight's
/// title, lines and buttons, then a row of wide cards and a row of posters,
/// as static tonal blocks (no shimmer, so it costs nothing on the reduced
/// tier).
class NocturneHomeSkeleton extends StatelessWidget {
  const NocturneHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final surfaces = SurfaceTokens.of(context);
    final small = BorderRadius.circular(surfaces.skeletonTextRadius);
    final card = BorderRadius.circular(surfaces.skeletonRadius);
    final left = math.max(0.0, m.safeX - MainScreenFocusScope.foregroundLeftOf(context));
    Widget bar(double width, double height, {BorderRadius? radius}) => SkeletonLoader(
      borderRadius: radius ?? small,
      child: SizedBox(width: width, height: height),
    );
    Widget row({required double width, required double height, required double gap}) => SizedBox(
      height: height + gap + m.caption * 1.1,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 8; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(width, height, radius: card),
                    SizedBox(height: gap * 0.66),
                    bar(width * 0.7, m.caption * 0.6),
                    SizedBox(height: gap * 0.33),
                    bar(width * 0.45, m.caption * 0.5),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final gap = m.pick(tv: 24, desktop: 16, phone: 12);
    final wide = m.pick(tv: 400, desktop: 280, phone: 220);
    final poster = m.pick(tv: 220, desktop: 150, phone: 110);
    final skeleton = IgnorePointer(
      child: Padding(
        padding: EdgeInsets.only(
          left: left,
          top: m.pick(tv: m.layout.safeY + 52, desktop: 0, phone: 0),
        ),
        child: Column(
          key: const Key('nocturne_home_skeleton'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(m.pick(tv: 140, desktop: 90, phone: 80), m.kicker * 0.5),
            SizedBox(height: gap),
            bar(m.logoBox.width, m.logoBox.height * 0.75, radius: card),
            SizedBox(height: gap),
            bar(m.logoBox.width * 1.1, m.caption * 0.6),
            SizedBox(height: gap * 0.5),
            bar(m.logoBox.width * 1.7, m.caption * 0.6),
            SizedBox(height: gap * 0.5),
            bar(m.logoBox.width * 1.6, m.caption * 0.6),
            SizedBox(height: gap),
            Row(
              children: [
                bar(m.buttonHeight * 3.1, m.buttonHeight, radius: BorderRadius.circular(m.buttonHeight)),
                SizedBox(width: gap * 0.6),
                bar(m.buttonHeight * 2.1, m.buttonHeight, radius: BorderRadius.circular(m.buttonHeight)),
              ],
            ),
            SizedBox(height: gap * 2.5),
            bar(m.pick(tv: 260, desktop: 170, phone: 140), m.caption),
            SizedBox(height: gap * 0.66),
            row(width: wide, height: wide * 9 / 16, gap: gap),
            SizedBox(height: gap * 1.5),
            bar(m.pick(tv: 200, desktop: 130, phone: 110), m.caption),
            SizedBox(height: gap * 0.66),
            row(width: poster, height: poster * 1.5, gap: gap),
          ],
        ),
      ),
    );
    // Over a bounded area (the TV home) the blocks run off the bottom edge
    // the way the real rows do; in a scroll view they take their own height.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? ClipRect(
              child: OverflowBox(alignment: Alignment.topLeft, maxHeight: double.infinity, child: skeleton),
            )
          : skeleton,
    );
  }
}
