import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_wrapper.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../media/media_item_types.dart';
import '../../media/media_server_client.dart';
import '../../services/device_performance.dart';
import '../../theme/mono_tokens.dart';
import '../../theme/nocturne_theme.dart';
import '../../theme/plezy_layout.dart';
import '../../theme/surface_tokens.dart';
import '../../theme/type_scale.dart';
import '../../utils/content_utils.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../app_icon.dart';
import '../cycling_media_backdrop.dart';
import '../fitted_metadata_line.dart';
import '../fitting_title_text.dart';
import '../media_rating_badge.dart';
import '../optimized_media_image.dart' show ClearLogoImage;
import '../rasterized_gradient.dart';

/// Where a Nocturne screen is drawn, which picks its type sizes and margins.
enum NocturneFormFactor {
  tv,
  desktop,
  phone;

  static NocturneFormFactor of(BuildContext context) {
    if (PlatformDetector.isTV()) return tv;
    return PlatformDetector.isMobile(context) ? phone : desktop;
  }

  bool get isTv => this == tv;
}

/// Sizes of the Nocturne screens: [TypeScale] roles and [PlezyLayout]
/// measurements at 1080p on TV, scaled to the screen, and their desktop and
/// phone values elsewhere.
@immutable
class NocturneMetrics {
  const NocturneMetrics._(this.formFactor, this.scale, this.type, this.layout);

  factory NocturneMetrics.of(BuildContext context) {
    final formFactor = NocturneFormFactor.of(context);
    return NocturneMetrics._(
      formFactor,
      formFactor.isTv ? PlezyLayout.designScaleOf(context) : 1.0,
      TypeScale.of(context),
      PlezyLayout.of(context),
    );
  }

  final NocturneFormFactor formFactor;

  /// Screen height over 1080 on TV, 1 elsewhere.
  final double scale;
  final TypeScale type;
  final PlezyLayout layout;

  bool get isTv => formFactor.isTv;
  bool get isPhone => formFactor == NocturneFormFactor.phone;

  /// [size] for this form factor, scaled on TV.
  double size(TypeSize size) => switch (formFactor) {
    NocturneFormFactor.tv => (size.tvSize ?? 14) * scale,
    NocturneFormFactor.desktop => size.regular ?? 14,
    NocturneFormFactor.phone => size.phone ?? size.regular ?? 14,
  };

  /// A length given for each form factor, the TV one at 1080p.
  double pick({required double tv, required double desktop, required double phone}) => switch (formFactor) {
    NocturneFormFactor.tv => tv * scale,
    NocturneFormFactor.desktop => desktop,
    NocturneFormFactor.phone => phone,
  };

  /// Kicker (uppercase label): 24 / 11 / 11.
  double get kicker => pick(tv: 24, desktop: 11, phone: 11);

  /// Label (buttons, chips, rail): 26 / 14 / 14.
  double get label => pick(tv: 26, desktop: 14, phone: 14);

  /// Caption (counts, sub-lines): 24 / 12.5 / 12.
  double get caption => pick(tv: 24, desktop: 12.5, phone: 12);

  /// Horizontal margin for text and focusables.
  double get safeX => pick(tv: layout.safeX, desktop: 32, phone: 16);

  /// The reserved clear-logo box.
  Size get logoBox => switch (formFactor) {
    NocturneFormFactor.tv => layout.logoBox * scale,
    NocturneFormFactor.desktop => const Size(360, 110),
    NocturneFormFactor.phone => const Size(260, 80),
  };

  double get buttonHeight => pick(tv: 70, desktop: 40, phone: 44);
}

/// The artwork behind a Nocturne spotlight or detail hero: one backdrop with
/// its subject right of the text column, faded into the page by
/// pre-rasterised scrims (never a live blur). A title with no artwork gets a
/// tonal wash in its own hue and a soft monogram instead.
class NocturneBackdrop extends StatelessWidget {
  const NocturneBackdrop({
    super.key,
    required this.item,
    required this.client,
    this.heightFactor,
    this.sideScrim = true,
    this.localArtworkPathResolver,
    this.allowNetwork = true,
  });

  final MediaItem? item;
  final MediaServerClient? client;

  /// Downloaded artwork for offline titles.
  final String? Function(String? artworkPath)? localArtworkPathResolver;
  final bool allowNetwork;

  /// Share of the height the artwork covers before the bottom scrim has faded
  /// it into the page; the layout's backdrop height when null.
  final double? heightFactor;
  final bool sideScrim;

  @override
  Widget build(BuildContext context) {
    final media = item;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final heightFactor = this.heightFactor ?? PlezyLayout.of(context).backdropHeight;
        final artHeight = size.height * heightFactor;
        final aspect = size.width / math.max(1, artHeight);
        final paths = media?.heroArtCandidates(containerAspectRatio: aspect) ?? const <String>[];
        // Nothing in the spotlight (an empty or unreachable library): the bare
        // canvas, not a tint for no title.
        final fallback = media == null
            ? const SizedBox.shrink()
            : _MissingArtBackdrop(title: media.grandparentTitle ?? media.displayTitle);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: artHeight,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    fallback,
                    if (paths.isNotEmpty)
                      CyclingMediaBackdrop(
                        mediaKey: media?.globalKey,
                        // One image per title: Nocturne never rotates the
                        // backdrop under the user.
                        imagePaths: [paths.first],
                        client: client,
                        localArtworkPathResolver: localArtworkPathResolver == null
                            ? null
                            : (path) => localArtworkPathResolver!(path),
                        allowNetwork: allowNetwork,
                        width: size.width,
                        height: artHeight,
                        alignment: const Alignment(0.36, -0.2),
                        fallbackColor: Colors.transparent,
                        fadeDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 450)),
                      ),
                    if (sideScrim)
                      RasterizedGradient(
                        gradient: (highContrast ? NocturneTheme.sideScrimStrong : NocturneTheme.sideScrim).gradient(
                          bg,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    RasterizedGradient(
                      gradient: NocturneTheme.bottomScrim.gradient(
                        bg,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            RasterizedGradient(
              gradient: NocturneTheme.topScrim.gradient(bg, begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ],
        );
      },
    );
  }
}

/// A backdrop for a title with no artwork: a tonal gradient from the title's
/// hue and a large, faint monogram on the right.
class _MissingArtBackdrop extends StatelessWidget {
  const _MissingArtBackdrop({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final text = title;
    final hue = nocturneTitleHue(text);
    final tint = HSLColor.fromAHSL(1, hue, 0.38, 0.2).toColor();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.45, -0.25),
                  radius: 1.05,
                  colors: [tint, Color.lerp(tint, bg, 0.55)!, bg],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            if (text.isNotEmpty)
              Align(
                alignment: const Alignment(0.62, -0.1),
                child: Text(
                  nocturneMonogram(text),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: height * 0.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A stable hue for [title], so a title without artwork keeps its colour.
double nocturneTitleHue(String title) {
  var hash = 0;
  for (final unit in title.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}

/// Up to two initials of [title].
String nocturneMonogram(String title) {
  final words = title.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return '';
  final letters = words.length == 1
      ? words.first.characters.take(1)
      : [words[0], words[1]].map((w) => w.characters.first);
  return letters.join().toUpperCase();
}

/// The text column of a Nocturne spotlight or detail hero: an optional
/// kicker, the clear logo (or the typeset title) in its reserved box, the
/// episode line, a metadata line and the synopsis.
class NocturneTitleBlock extends StatelessWidget {
  const NocturneTitleBlock({
    super.key,
    required this.item,
    required this.client,
    this.kicker,
    this.showSummary = true,
    this.extraMeta = const [],
    this.hideSpoilers = false,
  });

  final MediaItem item;
  final MediaServerClient? client;
  final String? kicker;
  final bool showSummary;

  /// Facts appended to the metadata line (time left, episode counts).
  final List<String> extraMeta;
  final bool hideSpoilers;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final t = tokens(context);
    final episodeLine = nocturneEpisodeLine(item);
    final hideSummary = hideSpoilers && item.shouldHideSpoiler;
    final summary = hideSummary ? null : item.summary;
    final gap = m.pick(tv: 12, desktop: 8, phone: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kicker case final kicker?) ...[
          Text(
            kicker.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.accent,
              fontSize: m.kicker,
              fontWeight: FontWeight.w700,
              letterSpacing: m.kicker * 0.1,
              height: 1.3,
            ),
          ),
          SizedBox(height: m.pick(tv: 28, desktop: 18, phone: 10)),
        ],
        NocturneLogoOrTitle(item: item, client: client),
        if (episodeLine != null) ...[
          SizedBox(height: gap),
          Text(
            episodeLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.text,
              fontSize: m.size(m.type.detailSubtitle),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
        SizedBox(height: gap),
        NocturneMetaLine(item: item, extra: extraMeta),
        if (showSummary && summary != null && summary.isNotEmpty) ...[
          SizedBox(height: gap * 1.5),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.text.withValues(alpha: 0.92),
              fontSize: m.size(m.type.detailSummary),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// "S2 · E4 · Signal Decay" for an episode; null for anything else.
String? nocturneEpisodeLine(MediaItem item) {
  if (!item.isEpisode) return null;
  final label = formatSeasonEpisodeLabel(item.parentIndex, item.index);
  final parts = [?label, if (item.title case final title? when title.isNotEmpty) title];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// What is left of [item]'s progress, "23 min left"; null without progress.
String? nocturneTimeLeft(MediaItem item) {
  final duration = item.durationMs;
  final offset = item.viewOffsetMs;
  if (duration == null || offset == null || offset <= 0 || offset >= duration) return null;
  return t.discover.minutesLeft(minutes: ((duration - offset) / 60000).round());
}

/// The clear logo fitted into the reserved logo box, or the title typeset in
/// Manrope 800 at display size; the box keeps its size either way, so nothing
/// moves when a logo arrives.
class NocturneLogoOrTitle extends StatelessWidget {
  const NocturneLogoOrTitle({super.key, required this.item, required this.client});

  final MediaItem item;
  final MediaServerClient? client;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final box = m.logoBox;
    final fontSize = m.size(m.type.heroTitle);
    Widget typeset(BuildContext context) => Align(
      alignment: Alignment.bottomLeft,
      child: FittingTitleText(
        item.grandparentTitle ?? item.displayTitle,
        maxLines: 2,
        alignment: Alignment.bottomLeft,
        style: TextStyle(
          color: tokens(context).text,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.04,
          letterSpacing: -0.02 * fontSize,
        ),
      ),
    );
    final logoPath = item.clearLogoPath;
    return SizedBox(
      width: box.width,
      height: box.height,
      child: logoPath == null || logoPath.isEmpty
          ? Builder(builder: typeset)
          : ClearLogoImage(
              client: client,
              logoPath: logoPath,
              width: box.width,
              height: box.height,
              fallbackWidth: box.width,
              alignment: Alignment.bottomLeft,
              fadeInDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 200)),
              fallbackBuilder: typeset,
            ),
    );
  }
}

/// One humanised metadata line: year, certification, runtime, scores, plus
/// [extra] facts, shedding the least useful part when it runs out of room.
class NocturneMetaLine extends StatelessWidget {
  const NocturneMetaLine({super.key, required this.item, this.extra = const []});

  final MediaItem item;
  final List<String> extra;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final t = tokens(context);
    final style = TextStyle(
      color: t.text,
      fontSize: m.size(m.type.detailMeta),
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
    final parts = <MetadataLinePart>[];
    if (item.isEpisode && item.originallyAvailableAt != null) {
      parts.add(MetadataLineText(formatFullDate(item.originallyAvailableAt!), dropPriority: 2));
    } else if (item.year != null) {
      parts.add(MetadataLineText(item.year.toString(), dropPriority: 0));
    }
    if (!item.isShow && item.durationMs != null && !item.hasActiveProgress) {
      parts.add(MetadataLineText(formatDurationTextual(item.durationMs!), dropPriority: 1));
    }
    if (item.contentRating case final rating? when rating.isNotEmpty) {
      parts.add(MetadataLineText(formatContentRating(rating), dropPriority: 3));
    }
    final ratings = mediaRatingsFor(item);
    if (ratings.isNotEmpty) parts.add(MetadataLineRatings(ratings, dropPriority: 4));
    for (final fact in extra) {
      parts.add(MetadataLineText(fact, dropPriority: 1));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return FittedMetadataLine(
      textStyle: style,
      parts: parts,
      ratingIconSize: style.fontSize,
      ratingSpacing: 4 * m.scale,
      ratingEntrySpacing: 12 * m.scale,
    );
  }
}

/// The style of a [NocturneButton].
enum NocturneButtonStyle {
  /// Accent fill: the one primary action of a screen.
  primary,

  /// A tonal pill with a hairline.
  secondary,
}

/// A Nocturne action: pill, inverted to a light fill with dark
/// content when D-pad focused, plus the theme's ring and glow; on the
/// reduced tier it snaps and drops the glow.
class NocturneButton extends StatelessWidget {
  const NocturneButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.detail,
    this.style = NocturneButtonStyle.secondary,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateDown,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  /// A second, lighter part after the label ("23 min left", "4K · HDR").
  final String? detail;

  final NocturneButtonStyle style;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final height = m.buttonHeight;
    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: onPressed,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
      borderRadius: height / 2,
      semanticLabel: label,
      useFocusGlow: true,
      autoScroll: false,
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus && InputModeTracker.isKeyboardMode(context);
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPressed,
              child: NocturneButtonFace(style: style, icon: icon, label: label, detail: detail, focused: focused),
            ),
          );
        },
      ),
    );
  }
}

/// How a [NocturneButton] looks, for controls that own their focus elsewhere
/// (the detail page's action row): the pill, inverted when
/// [focused].
class NocturneButtonFace extends StatelessWidget {
  const NocturneButtonFace({
    super.key,
    required this.style,
    required this.icon,
    required this.label,
    this.detail,
    this.focused = false,
    this.height,
  });

  final NocturneButtonStyle style;
  final IconData icon;
  final String label;
  final String? detail;
  final bool focused;

  /// Defaults to the form factor's button height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final height = this.height ?? m.buttonHeight;
    final t = tokens(context);
    final surfaces = SurfaceTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconSize = m.pick(tv: 30, desktop: 18, phone: 20);
    final labelStyle = TextStyle(fontSize: m.label, fontWeight: FontWeight.w700, height: 1.2);
    final detailStyle = TextStyle(fontSize: m.caption, fontWeight: FontWeight.w600, height: 1.2);
    final light = t.text;
    final dark = t.bg;

    final padX = m.pick(tv: 34, desktop: 18, phone: 18);
    final gap = m.pick(tv: 12, desktop: 8, phone: 8);
    final primary = style == NocturneButtonStyle.primary;
    final head = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, fill: 1, size: iconSize),
        SizedBox(width: gap),
        Text(label, style: labelStyle),
      ],
    );
    final detail = this.detail;
    if (primary && !focused) {
      // The accent covers the action; a light tail carries the detail.
      // Focused, the whole pill turns light like the other buttons.
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(left: padX * 0.9, right: detail == null ? padX : gap),
                color: scheme.primary,
                child: IconTheme.merge(
                  data: IconThemeData(color: scheme.onPrimary),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: scheme.onPrimary),
                    child: head,
                  ),
                ),
              ),
              if (detail != null)
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(left: gap * 0.6, right: padX * 0.9),
                  color: light,
                  child: Text(detail, style: detailStyle.copyWith(color: dark)),
                ),
            ],
          ),
        ),
      );
    }
    final foreground = focused ? dark : light;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padX),
      decoration: BoxDecoration(
        color: focused ? light : (surfaces.overlaySurface ?? t.surface).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: focused ? light : t.outline.withValues(alpha: 0.24)),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              head,
              if (detail != null) ...[
                SizedBox(width: gap),
                Text(detail, style: detailStyle.copyWith(color: foreground.withValues(alpha: 0.72))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
