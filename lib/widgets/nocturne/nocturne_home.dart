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
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: textLeft,
                    top: m.layout.safeY * m.scale + m.pick(tv: 52, desktop: 0, phone: 0),
                    width: size.width * 0.5,
                    height: (folded ? foldedRowTop - m.layout.safeY * m.scale : rowTop) - 52 * m.scale,
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
                    top: folded ? foldedRowTop : rowTop - m.pick(tv: 12, desktop: 0, phone: 0),
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
    return Align(
      alignment: Alignment.bottomLeft,
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
