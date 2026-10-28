import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import 'app_icon.dart';
import 'artwork_badges.dart';
import 'media_progress_bar.dart';
import 'unwatched_count_badge.dart';
import '../theme/surface_tokens.dart';

/// Size preset for [WatchedIndicator]: [standard] for grid/poster cards,
/// [compact] for dense surfaces (folder tree rows, episode thumbnails).
/// Add a preset here instead of hand-rolling a new overlay variant.
enum WatchedIndicatorSize {
  standard(
    checkInset: 4,
    checkPadding: 4,
    checkIconSize: 16,
    badgeSize: 24,
    badgeFontSize: 12,
    barRadius: 8,
    barMinHeight: 4,
  ),
  compact(
    checkInset: 3,
    checkPadding: 2,
    checkIconSize: 12,
    badgeSize: 20,
    badgeFontSize: 10,
    barRadius: 6,
    barMinHeight: 3,
  );

  const WatchedIndicatorSize({
    required this.checkInset,
    required this.checkPadding,
    required this.checkIconSize,
    required this.badgeSize,
    required this.badgeFontSize,
    required this.barRadius,
    required this.barMinHeight,
  });

  final double checkInset;
  final double checkPadding;
  final double checkIconSize;
  final double badgeSize;
  final double badgeFontSize;
  final double barRadius;
  final double barMinHeight;
}

/// Watched/progress overlay for media artwork: watched checkmark,
/// unwatched-count pill (shows/seasons), active-progress bar, and season
/// completion bar. The single implementation behind every surface that
/// stamps watch state onto a poster/thumbnail. Callers that must react to
/// [SettingsService.showWatchedIndicators] or [SettingsService.showUnwatchedCount]
/// flipping wrap themselves in a [SettingsBuilder] on those prefs.
class WatchedIndicator extends StatelessWidget {
  final MediaItem item;
  final WatchedIndicatorSize size;

  /// Overrides the settings read for the unwatched-count pill — pass it when
  /// the caller already watches [SettingsService.showUnwatchedCount] so pill
  /// visibility updates reactively with the caller's rebuilds.
  final bool? showUnwatchedCount;

  const WatchedIndicator({
    super.key,
    required this.item,
    this.size = WatchedIndicatorSize.standard,
    this.showUnwatchedCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool showCount = showUnwatchedCount ?? SettingsService.instance.read(SettingsService.showUnwatchedCount);
    final bool showWatched = SettingsService.instance.read(SettingsService.showWatchedIndicators);
    final hasActiveProgress = item.hasActiveProgress;
    final unwatched = item.unwatchedCount;
    final surfaces = SurfaceTokens.of(context);
    final grammar = surfaces.badgeGrammar;
    final barRadius = BorderRadius.only(
      bottomLeft: Radius.circular(size.barRadius),
      bottomRight: Radius.circular(size.barRadius),
    );

    return Stack(
      children: [
        // Watched checkmark
        if (showWatched && item.isWatched && !hasActiveProgress)
          Positioned(
            top: size.checkInset,
            right: size.checkInset,
            child: Container(
              padding: EdgeInsets.all(size.checkPadding),
              decoration: BoxDecoration(
                color: surfaces.badgeFill ?? tokens(context).text,
                shape: BoxShape.circle,
                boxShadow: surfaces.badgeShadows,
              ),
              child: AppIcon(
                Symbols.check_rounded,
                fill: 1,
                color: surfaces.badgeForeground ?? tokens(context).bg,
                size: size.checkIconSize,
              ),
            ),
          ),
        // Unwatched dot for movies nobody has started
        if (showWatched &&
            grammar.unwatchedDot &&
            item.kind == MediaKind.movie &&
            !item.isWatched &&
            !hasActiveProgress)
          Positioned(
            top: size.checkInset + size.checkPadding,
            right: size.checkInset + size.checkPadding,
            child: UnwatchedDot(size: size.checkIconSize * 0.75),
          ),
        // Unwatched count for shows/seasons
        if (showCount &&
            !item.isWatched &&
            (item.kind == MediaKind.show || item.kind == MediaKind.season) &&
            unwatched != null &&
            unwatched > 0)
          Positioned(
            top: size.checkInset,
            right: grammar.countTopLeft ? null : size.checkInset,
            left: grammar.countTopLeft ? size.checkInset : null,
            child: UnwatchedCountBadge(
              count: unwatched,
              size: size.badgeSize,
              fontSize: size.badgeFontSize,
              accent: grammar.countTopLeft,
            ),
          ),
        // Progress bar for partially watched content (episodes/movies)
        if (hasActiveProgress)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: barRadius,
              child: MediaProgressBar(
                viewOffset: item.viewOffsetMs!,
                duration: item.durationMs!,
                minHeight: surfaces.progressHeight ?? size.barMinHeight,
              ),
            ),
          ),
        // Progress bar for seasons (viewed leaves / total leaves).
        if (item.isSeason && item.isPartiallyWatched)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: barRadius,
              child: LinearProgressIndicator(
                value: item.leafWatchFraction,
                backgroundColor: tokens(context).outline,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                minHeight: surfaces.progressHeight ?? size.barMinHeight,
              ),
            ),
          ),
      ],
    );
  }
}
