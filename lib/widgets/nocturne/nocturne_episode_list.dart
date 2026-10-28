import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../media/media_item_types.dart';
import '../../media/media_server_client.dart';
import '../../services/device_performance.dart';
import '../../theme/mono_tokens.dart';
import '../../theme/surface_tokens.dart';
import '../../utils/formatters.dart';
import '../../utils/media_image_helper.dart' show ImageType;
import '../app_icon.dart';
import '../optimized_media_image.dart';
import 'nocturne_spotlight.dart';

/// Seasons and episodes on TV in the Nocturne layout: a row of season chips
/// over a vertical list of episodes, where the focused row inverts.
///
/// Up from the first episode reaches the season chips, Up from the chips the
/// action row; Down past the last episode stays put. The classic layout keeps
/// its sideways rail of episode cards.
class NocturneEpisodeList extends StatefulWidget {
  const NocturneEpisodeList({
    super.key,
    required this.seasons,
    required this.selectedSeason,
    required this.clientFor,
    required this.onSeasonSelected,
    required this.onEpisodeFocused,
    required this.onEpisodeActivated,
    required this.onNavigateUp,
    required this.onBack,
    this.initialEpisodeId,
    this.hideSpoilers = false,
    this.unwatchedCountOf,
  });

  /// One hub per season, each holding its loaded episodes; a single hub
  /// (a season, or a show listed without seasons) shows no chips.
  final List<MediaHub> seasons;
  final int selectedSeason;
  final MediaServerClient? Function(MediaItem item) clientFor;
  final void Function(MediaHub season, int index) onSeasonSelected;
  final void Function(MediaHub season, MediaItem episode) onEpisodeFocused;
  final void Function(MediaHub season, MediaItem episode) onEpisodeActivated;

  /// Up from the season chips (or the first episode without chips).
  final VoidCallback onNavigateUp;
  final VoidCallback onBack;
  final String? initialEpisodeId;
  final bool hideSpoilers;

  /// Unwatched episodes in the season at an index, shown as "N new" on its
  /// chip; null or zero shows nothing.
  final int? Function(int seasonIndex)? unwatchedCountOf;

  @override
  State<NocturneEpisodeList> createState() => NocturneEpisodeListState();
}

class NocturneEpisodeListState extends State<NocturneEpisodeList> {
  final _scroll = ScrollController();
  final List<FocusNode> _chipNodes = [];
  final List<FocusNode> _episodeNodes = [];

  /// The episode row last focused, so focus comes back to it.
  int _episodeIndex = 0;

  MediaHub? get _season =>
      widget.seasons.isEmpty ? null : widget.seasons[widget.selectedSeason.clamp(0, widget.seasons.length - 1)];

  bool get _showChips => widget.seasons.length > 1;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEpisodeId;
    final items = _season?.items ?? const <MediaItem>[];
    if (initial != null) {
      final index = items.indexWhere((item) => item.id == initial);
      if (index >= 0) _episodeIndex = index;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in [..._chipNodes, ..._episodeNodes]) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncNodes(List<FocusNode> nodes, int count, String label) {
    while (nodes.length < count) {
      nodes.add(FocusNode(debugLabel: '$label${nodes.length}'));
    }
  }

  /// Focuses the remembered episode, or the selected season chip when the
  /// season has no episodes yet.
  void requestFocus() {
    final items = _season?.items ?? const <MediaItem>[];
    if (items.isEmpty) {
      if (_showChips && widget.selectedSeason < _chipNodes.length) _chipNodes[widget.selectedSeason].requestFocus();
      return;
    }
    final index = _episodeIndex.clamp(0, items.length - 1);
    if (index < _episodeNodes.length) _episodeNodes[index].requestFocus();
  }

  KeyEventResult _onChipKey(int index, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key.isSelectKey) {
      widget.onSeasonSelected(widget.seasons[index], index);
      return KeyEventResult.handled;
    }
    if (key.isBackKey) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onNavigateUp();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final next = index + (key == LogicalKeyboardKey.arrowLeft ? -1 : 1);
      // Short menus may not wrap here: Left always undoes Right.
      if (next >= 0 && next < _chipNodes.length) _chipNodes[next].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onEpisodeKey(int index, KeyEvent event) {
    if (!event.isActionable) return KeyEventResult.ignored;
    final season = _season;
    if (season == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key.isSelectKey) {
      widget.onEpisodeActivated(season, season.items[index]);
      return KeyEventResult.handled;
    }
    if (key.isBackKey) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        _episodeNodes[index - 1].requestFocus();
      } else if (_showChips && widget.selectedSeason < _chipNodes.length) {
        _chipNodes[widget.selectedSeason].requestFocus();
      } else {
        widget.onNavigateUp();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      // Down past the last episode stays put.
      if (index + 1 < season.items.length) _episodeNodes[index + 1].requestFocus();
      return KeyEventResult.handled;
    }
    // A list has nothing sideways; keep focus on the row.
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  void _onEpisodeFocus(int index, bool focused) {
    final season = _season;
    if (!focused || season == null || index >= season.items.length) return;
    _episodeIndex = index;
    widget.onEpisodeFocused(season, season.items[index]);
  }

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final season = _season;
    final items = season?.items ?? const <MediaItem>[];
    _syncNodes(_chipNodes, widget.seasons.length, 'nocturne_season_');
    _syncNodes(_episodeNodes, items.length, 'nocturne_episode_');
    final gap = m.pick(tv: 16, desktop: 12, phone: 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showChips)
          Padding(
            padding: EdgeInsets.only(left: m.safeX, bottom: gap),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (var i = 0; i < widget.seasons.length; i++) ...[
                    if (i > 0) SizedBox(width: m.pick(tv: 12, desktop: 8, phone: 8)),
                    _SeasonChip(
                      focusNode: _chipNodes[i],
                      label: widget.seasons[i].title,
                      newCount: widget.unwatchedCountOf?.call(i),
                      selected: i == widget.selectedSeason,
                      onKey: (event) => _onChipKey(i, event),
                      onTap: () => widget.onSeasonSelected(widget.seasons[i], i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(m.safeX, m.pick(tv: 4, desktop: 4, phone: 4), m.safeX, m.safeX),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: m.pick(tv: 12, desktop: 8, phone: 8)),
              child: _EpisodeRow(
                episode: items[index],
                client: widget.clientFor(items[index]),
                focusNode: _episodeNodes[index],
                autofocus: false,
                hideSpoilers: widget.hideSpoilers,
                onKey: (event) => _onEpisodeKey(index, event),
                onFocusChange: (focused) => _onEpisodeFocus(index, focused),
                onTap: () => widget.onEpisodeActivated(season!, items[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeasonChip extends StatelessWidget {
  const _SeasonChip({
    required this.focusNode,
    required this.label,
    required this.selected,
    required this.onKey,
    required this.onTap,
    this.newCount,
  });

  final FocusNode focusNode;
  final String label;
  final int? newCount;
  final bool selected;
  final KeyEventResult Function(KeyEvent event) onKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final tk = tokens(context);
    final surfaces = SurfaceTokens.of(context);
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, event) => onKey(event),
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final focused = focusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
          final light = focused || selected;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: FocusTheme.getAnimationDuration(context),
              height: m.pick(tv: 56, desktop: 36, phone: 36),
              padding: EdgeInsets.symmetric(horizontal: m.pick(tv: 24, desktop: 14, phone: 14)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: light ? tk.text : surfaces.raisedSurface ?? tk.surface,
                borderRadius: BorderRadius.circular(surfaces.chipRadius),
                border: focused && selected
                    ? Border.all(
                        color: FocusTheme.getFocusBorderColor(context),
                        width: FocusTheme.of(context).ringWidth,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : Border.all(color: light ? tk.text : tk.outline.withValues(alpha: 0.24)),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: label),
                    if (newCount case final count? when count > 0)
                      TextSpan(
                        text: '  ${t.nocturne.newCount(count: count)}',
                        style: TextStyle(
                          color: light ? tk.bg.withValues(alpha: 0.7) : tk.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(
                  color: light ? tk.bg : tk.text,
                  fontSize: m.label,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One episode: a 16:9 still with its number, the title, a meta line, the
/// synopsis and a watched or progress marker. Focus inverts the row.
class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.episode,
    required this.client,
    required this.focusNode,
    required this.autofocus,
    required this.hideSpoilers,
    required this.onKey,
    required this.onFocusChange,
    required this.onTap,
  });

  final MediaItem episode;
  final MediaServerClient? client;
  final FocusNode focusNode;
  final bool autofocus;
  final bool hideSpoilers;
  final KeyEventResult Function(KeyEvent event) onKey;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final tk = tokens(context);
    final surfaces = SurfaceTokens.of(context);
    final stillWidth = m.pick(tv: 300, desktop: 200, phone: 140);
    final stillHeight = stillWidth * 9 / 16;
    final pad = m.pick(tv: 14, desktop: 10, phone: 8);
    final number = episode.index;
    final title = [if (number != null) '$number.', ?episode.title].join(' ');
    final meta = [
      if (episode.durationMs != null) formatDurationTextual(episode.durationMs!),
      if (episode.originallyAvailableAt case final aired?) formatFullDate(aired),
    ].join(' · ');
    final spoiler = hideSpoilers && episode.shouldHideSpoiler;
    final summary = spoiler ? null : episode.summary;
    final progress = episode.durationMs != null && (episode.viewOffsetMs ?? 0) > 0
        ? (episode.viewOffsetMs! / episode.durationMs!).clamp(0.0, 1.0)
        : null;
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: (focused) {
        onFocusChange(focused);
        if (focused && InputModeTracker.currentMode == InputMode.keyboard) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.1,
            duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 160)),
          );
        }
      },
      onKeyEvent: (_, event) => onKey(event),
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final focused = focusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
          // Lists invert on focus, on every tier: light fill, dark text.
          final foreground = focused ? tk.bg : tk.text;
          final muted = focused ? tk.bg.withValues(alpha: 0.72) : tk.textMuted;
          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: FocusTheme.getAnimationDuration(context),
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: focused ? tk.text : tk.surface,
                borderRadius: BorderRadius.circular(surfaces.cardRadius),
                border: Border.all(color: focused ? tk.text : tk.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(surfaces.thumbnailRadius),
                    child: SizedBox(
                      width: stillWidth,
                      height: stillHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          OptimizedMediaImage(
                            client: client,
                            imagePath: episode.thumbPath,
                            width: stillWidth,
                            height: stillHeight,
                            fit: BoxFit.cover,
                            imageType: ImageType.thumb,
                            fallbackIcon: Symbols.movie_rounded,
                          ),
                          if (number != null)
                            Positioned(
                              left: pad * 0.7,
                              top: pad * 0.5,
                              child: Text(
                                '$number',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: m.label,
                                  fontWeight: FontWeight.w800,
                                  shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 6)],
                                ),
                              ),
                            ),
                          if (progress != null && progress < 1)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: surfaces.progressHeight ?? 4,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: ColoredBox(color: tk.accent),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: pad * 1.6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: m.size(m.type.shelfHeader) * 0.875,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            maxLines: 1,
                            style: TextStyle(color: muted, fontSize: m.caption, height: 1.5),
                          ),
                        if (summary != null && summary.isNotEmpty) ...[
                          SizedBox(height: pad * 0.4),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: foreground, fontSize: m.size(m.type.detailMeta), height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (episode.isWatched) ...[
                    SizedBox(width: pad),
                    AppIcon(Symbols.check_rounded, fill: 1, size: m.caption, color: muted),
                    SizedBox(width: pad * 0.4),
                    Text(
                      t.nocturne.watched,
                      style: TextStyle(color: muted, fontSize: m.caption),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
