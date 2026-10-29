import 'package:flutter/material.dart';

import '../media/media_item.dart';
import '../theme/mono_tokens.dart';
import '../theme/surface_tokens.dart';

/// The accent dot an unwatched, unstarted movie carries top-right when the
/// theme's [BadgeGrammar.unwatchedDot] is on.
class UnwatchedDot extends StatelessWidget {
  const UnwatchedDot({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Container(
      key: const Key('unwatched-dot'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.accent,
        shape: BoxShape.circle,
        // A hairline of the page colour keeps the dot legible on bright art.
        border: Border.all(color: t.bg.withValues(alpha: 0.6), width: size * 0.12),
      ),
    );
  }
}

/// Why a card is in its row ("Next up"), top-left on the artwork when the
/// theme's [BadgeGrammar.reasonTag] is on.
class ReasonTag extends StatelessWidget {
  const ReasonTag({super.key, required this.label});

  final String label;
  static const double fontSize = 11;

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final surfaces = SurfaceTokens.of(context);
    return DecoratedBox(
      key: const Key('reason-tag'),
      decoration: BoxDecoration(color: surfaces.labelBadgeColor, borderRadius: BorderRadius.circular(fontSize * 0.5)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.3),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          style: TextStyle(
            color: t.accent,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: fontSize * 0.08,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Whether [item] earns the "Next up" reason tag: a Continue Watching card
/// nobody has started, under a theme that draws reason tags.
bool showsNextUpTag(BuildContext context, MediaItem item, {required bool inContinueWatching}) =>
    inContinueWatching &&
    SurfaceTokens.of(context).badgeGrammar.reasonTag &&
    !item.hasActiveProgress &&
    !item.isWatched;
