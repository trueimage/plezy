part of '../media_detail_screen.dart';

/// The Nocturne layout's TV detail page: the logo box, one humanised
/// metadata line, the media-info chips, the synopsis and credits, then the
/// action row; a show's seasons and episodes list below it vertically.
extension _NocturneMediaDetail on _MediaDetailScreenState {
  /// Height of the TV action row in the Nocturne layout at 1080p.
  static const double nocturneActionSize = 64;

  /// Share of the screen the vertical episode list takes on TV.
  static const double episodeListHeight = 0.46;

  /// Whether a show or season lists its episodes vertically (Nocturne on TV).
  bool _usesNocturneEpisodeList(BuildContext context, List<MediaHub> hubs) =>
      PlezyLayout.isNocturne(context) && hubs.any(_isTvDetailEpisodeHub);

  Widget _buildNocturneTvDetailForeground(
    BuildContext context,
    MediaItem metadata, {
    required bool hideSpoilers,
    required double scale,
  }) {
    final m = NocturneMetrics.of(context);
    final tk = tokens(context);
    final focusedEpisode = _tvDetailFocusedEpisode.value;
    final description = _tvDetailDescription(metadata, hideSpoilers: hideSpoilers);
    void openDetails() => _openTvDetailsSheet(context, metadata, hideSpoilers: hideSpoilers);
    final versions = metadata.mediaVersions?.length ?? 0;
    final chips = [...buildMediaQualityLabels(metadata), if (versions > 1) t.nocturne.versions(count: versions)];
    final credits = [
      if (metadata.directors case final directors? when directors.isNotEmpty)
        t.nocturne.directedBy(name: directors.first),
      ?metadata.studio,
      if (metadata.genres case final genres? when genres.isNotEmpty) genres.take(2).join(', '),
    ];
    final lineStyle = TextStyle(color: tk.textMuted, fontSize: m.caption, height: 1.4);

    return Align(
      alignment: Alignment.bottomLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                button: true,
                label: _tvDetailInformationSemanticLabel(
                  metadata,
                  description: description,
                  genres: metadata.genres ?? const [],
                ),
                hint: t.mediaMenu.viewDetails,
                onTap: openDetails,
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NocturneLogoOrTitle(
                        item: metadata,
                        client: _getArtworkMediaClient(context),
                        title: metadata.grandparentTitle ?? metadata.displayTitle,
                      ),
                      SizedBox(height: 12 * m.scale),
                      // The focusable path to the full-information sheet
                      // (#2042): background-only focus, no layout change.
                      FocusableWrapper(
                        focusNode: _tvDetailInfoFocusNode,
                        onSelect: openDetails,
                        onNavigateUp: _backButtonFocusNode.requestFocus,
                        onNavigateDown: _focusTvDetailActionRow,
                        onBack: _popMediaDetailIfBackNotSuppressed,
                        useBackgroundFocus: true,
                        disableScale: true,
                        autoScroll: false,
                        borderRadius: 10,
                        descendantsAreFocusable: false,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openDetails,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (focusedEpisode?.title case final title? when title.isNotEmpty)
                                Text(
                                  title,
                                  key: const ValueKey('tv_detail_episode_title'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tk.text,
                                    fontSize: m.size(m.type.detailSubtitle),
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              _buildTvDetailMetadataLine(context, metadata, scale),
                              if (chips.isNotEmpty) ...[
                                SizedBox(height: 14 * m.scale),
                                NocturneInfoChips(labels: chips, versionLabel: versions > 1 ? chips.last : null),
                              ],
                              if (description != null && description.isNotEmpty) ...[
                                SizedBox(height: 16 * m.scale),
                                Text(
                                  description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tk.text.withValues(alpha: 0.92),
                                    fontSize: m.size(m.type.detailSummary),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (credits.isNotEmpty && focusedEpisode == null) ...[
                                SizedBox(height: 10 * m.scale),
                                Text(
                                  credits.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: lineStyle,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20 * m.scale),
              SizedBox(height: nocturneActionSize * scale, child: _buildActionButtons(metadata)),
            ],
          ),
        ),
      ),
    );
  }

  /// Seasons as chips over a vertical list of episodes, wired to the same
  /// focus, paging and activation handlers as the classic rail.
  Widget _buildNocturneEpisodeList(BuildContext context, MediaItem metadata, List<MediaHub> hubs) {
    final seasons = hubs.where(_isTvDetailEpisodeHub).toList();
    final selected = seasons.indexWhere((hub) => hub.id == '$_tvDetailSeasonHubIdPrefix$_selectedSeasonIndex');
    return NocturneEpisodeList(
      key: _nocturneEpisodeListKey,
      seasons: seasons,
      selectedSeason: selected < 0 ? 0 : selected,
      clientFor: (_) => _getArtworkMediaClient(context),
      hideSpoilers: SettingsService.instance.read(SettingsService.hideSpoilers),
      initialEpisodeId: _tvDetailInitialItemId(metadata),
      onSeasonSelected: (hub, index) => _handleTvDetailHubChanged(hub, hubs.indexOf(hub)),
      onEpisodeFocused: (hub, episode) {
        _setTvDetailActionRowFocus(false);
        _handleTvDetailFocusedRailItemChanged(hub, episode);
      },
      onEpisodeActivated: (hub, episode) => unawaited(_handleTvDetailRailItemActivated(hub, episode)),
      onNavigateUp: _focusTvDetailActionRow,
      onBack: _popMediaDetailIfBackNotSuppressed,
    );
  }
}

/// Media-info chips: resolution, dynamic range, audio, the version count in
/// the accent's caution tint.
class NocturneInfoChips extends StatelessWidget {
  const NocturneInfoChips({super.key, required this.labels, this.versionLabel});

  final List<String> labels;
  final String? versionLabel;

  @override
  Widget build(BuildContext context) {
    final m = NocturneMetrics.of(context);
    final tk = tokens(context);
    return Wrap(
      spacing: 8 * m.scale,
      runSpacing: 8 * m.scale,
      children: [
        for (final label in labels)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * m.scale, vertical: 5 * m.scale),
            decoration: BoxDecoration(
              color: label == versionLabel ? tk.accent.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(6 * m.scale),
              border: Border.all(
                color: label == versionLabel ? Colors.transparent : tk.outline.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: label == versionLabel ? tk.accent : tk.text,
                fontSize: m.size(m.type.detailChip),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}
