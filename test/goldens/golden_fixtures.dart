import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_person.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/media/media_role.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/paged_fakes.dart';

/// Fixture content shared by the golden screens. Nothing here has artwork:
/// image loads would make the goldens depend on decode timing, so cards and
/// heroes render their placeholders.

const goldenServerId = 'server_1';
const goldenServerName = 'Home Server';

/// A movie library grid: plain, watched, in-progress and long-titled items, so
/// the card's badges, progress bar and title truncation are all captured.
final List<MediaItem> goldenMovies = [
  _movie('m1', 'The Quiet Harbor', 2024, durationMinutes: 118),
  _movie('m2', 'Northern Lights', 2023, durationMinutes: 104, viewCount: 1),
  _movie('m3', 'A Very Long Title That Has To Be Truncated On Every Card', 2021, durationMinutes: 131),
  _movie('m4', 'Glass Garden', 2022, durationMinutes: 96, viewOffsetMinutes: 40),
  _movie('m5', 'Midnight Express Line', 2019, durationMinutes: 142),
  _movie('m6', 'Paper Moons', 2020, durationMinutes: 88, viewCount: 2),
  _movie('m7', 'Saltwater', 2018, durationMinutes: 110),
  _movie('m8', 'The Last Lighthouse', 2017, durationMinutes: 125, viewOffsetMinutes: 90),
  _movie('m9', 'Ember & Ash', 2016, durationMinutes: 99),
  _movie('m10', 'Cold Open', 2015, durationMinutes: 101),
  _movie('m11', 'Field Notes', 2014, durationMinutes: 93),
  _movie('m12', 'Second Sunrise', 2013, durationMinutes: 115),
  _movie('m13', 'Undertow', 2012, durationMinutes: 107),
  _movie('m14', 'Static Bloom', 2011, durationMinutes: 120),
  _movie('m15', 'Harbor Lights II', 2010, durationMinutes: 112),
  _movie('m16', 'Open Water', 2009, durationMinutes: 98),
  _movie('m17', 'Late Summer', 2008, durationMinutes: 103),
  _movie('m18', 'The Long Way Round', 2007, durationMinutes: 140),
  _movie('m19', 'Signal Fire', 2006, durationMinutes: 97),
  _movie('m20', 'Low Tide', 2005, durationMinutes: 109),
  _movie('m21', 'Copper Sky', 2004, durationMinutes: 117),
  _movie('m22', 'Night Ferry', 2003, durationMinutes: 92),
  _movie('m23', 'Winter Orchard', 2002, durationMinutes: 124),
  _movie('m24', 'Drift', 2001, durationMinutes: 86),
];

/// Libraries the side navigation lists.
final List<MediaLibrary> goldenLibraries = [
  _library('lib_movies', 'Movies', MediaKind.movie),
  _library('lib_shows', 'TV Shows', MediaKind.show),
  _library('lib_music', 'Music', MediaKind.artist),
];

MediaItem _movie(
  String id,
  String title,
  int year, {
  required int durationMinutes,
  int? viewCount,
  int? viewOffsetMinutes,
}) {
  return testMediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: title,
    year: year,
    durationMs: durationMinutes * 60000,
    viewCount: viewCount,
    viewOffsetMs: viewOffsetMinutes == null ? null : viewOffsetMinutes * 60000,
    serverId: goldenServerId,
    serverName: goldenServerName,
  );
}

/// A Jellyfin Movies library: its A–Z bar is the local alphabet, so the
/// library screen draws it without a Plex first-character request.
final List<MediaLibrary> goldenBrowseLibraries = [
  _library('lib_movies', 'Movies', MediaKind.movie, backend: MediaBackend.jellyfin),
  ...goldenLibraries.skip(1),
];

/// The browse library's 128 fictional films, enough for the A–Z bar, sorted
/// by title.
final List<MediaItem> goldenBrowseMovies = () {
  const first = ['Amber', 'Blue', 'Cinder', 'Distant', 'Ember', 'Hollow', 'Iron', 'Lantern'];
  const second = ['Bay', 'Coast', 'Field', 'Harbor', 'Hours', 'Light', 'Ridge', 'Road'];
  const third = ['', ' II'];
  final titles = [
    for (final a in first)
      for (final b in second)
        for (final c in third) '$a $b$c',
  ]..sort();
  return [
    for (final (i, title) in titles.indexed)
      _movie(
        'b$i',
        title,
        1990 + (i * 7) % 35,
        durationMinutes: 84 + (i * 13) % 70,
        viewCount: i % 5 == 2 ? 1 : null,
        viewOffsetMinutes: i % 9 == 4 ? 30 : null,
      ),
  ];
}();

MediaLibrary _library(String id, String title, MediaKind kind, {MediaBackend backend = MediaBackend.plex}) {
  return MediaLibrary(
    id: id,
    backend: backend,
    title: title,
    kind: kind,
    serverId: ServerId(goldenServerId),
    serverName: goldenServerName,
  );
}

/// The detail hero's movie: every metadata line the hero can show.
final MediaItem goldenDetailMovie = testMediaItem(
  id: 'detail_movie',
  backend: MediaBackend.plex,
  kind: MediaKind.movie,
  title: 'The Quiet Harbor',
  tagline: 'Every light has a keeper.',
  summary:
      'When a storm cuts a fishing town off from the mainland, the lighthouse keeper\'s daughter has three '
      'nights to bring the last ferry home. A slow-burning drama about duty, weather and the people who wait.',
  year: 2024,
  contentRating: 'PG-13',
  durationMs: 118 * 60000,
  rating: 8.1,
  studio: 'Northlight Pictures',
  genres: const ['Drama', 'Mystery', 'Adventure'],
  directors: const ['Ada Lindqvist'],
  writers: const ['Ada Lindqvist', 'Tomas Reyes'],
  roles: const [
    MediaRole(tag: 'Mara Holt', role: 'Elin'),
    MediaRole(tag: 'Jonas Field', role: 'Keeper'),
    MediaRole(tag: 'Iris Okafor', role: 'Ferry Captain'),
    MediaRole(tag: 'Leo Brandt', role: 'Harbormaster'),
  ],
  serverId: goldenServerId,
  serverName: goldenServerName,
);

final MediaItem goldenShow = testMediaItem(
  id: 'show_1',
  backend: MediaBackend.plex,
  kind: MediaKind.show,
  title: 'Signal & Noise',
  summary: 'A radio station at the edge of the world picks up broadcasts from a town that should not exist.',
  year: 2022,
  contentRating: 'TV-14',
  genres: const ['Sci-Fi', 'Drama'],
  leafCount: 6,
  viewedLeafCount: 2,
  childCount: 1,
  serverId: goldenServerId,
  serverName: goldenServerName,
);

final MediaItem goldenSeason = testMediaItem(
  id: 'season_1',
  backend: MediaBackend.plex,
  kind: MediaKind.season,
  title: 'Season 1',
  index: 1,
  parentId: goldenShow.id,
  parentTitle: goldenShow.title,
  leafCount: 6,
  viewedLeafCount: 2,
  serverId: goldenServerId,
  serverName: goldenServerName,
);

/// Six episodes: watched, in progress and unwatched, with summaries of
/// different lengths.
final List<MediaItem> goldenEpisodes = [
  for (final (index, title, summary, viewCount, offsetMinutes) in const [
    (1, 'Pilot', 'A faint signal interrupts the night shift.', 1, null),
    (2, 'Dead Air', 'The station goes silent for exactly eleven minutes, and nobody can say why.', 1, null),
    (3, 'Call Sign', 'Mara traces the broadcast to a frequency that was retired forty years ago.', null, 21),
    (4, 'Interference', 'A storm brings the town closer than ever.', null, null),
    (5, 'The Long Wave', 'An old recording surfaces with a voice everyone recognises.', null, null),
    (6, 'Sign Off', 'The last transmission.', null, null),
  ])
    testMediaItem(
      id: 'episode_$index',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: title,
      summary: summary,
      index: index,
      parentId: goldenSeason.id,
      parentIndex: 1,
      parentTitle: goldenSeason.title,
      grandparentId: goldenShow.id,
      grandparentTitle: goldenShow.title,
      durationMs: 47 * 60000,
      viewCount: viewCount,
      viewOffsetMs: offsetMinutes == null ? null : offsetMinutes * 60000,
      serverId: goldenServerId,
      serverName: goldenServerName,
    ),
];

/// The home screen's Continue Watching: an episode and a movie in progress,
/// and an episode that is next up with no progress. Fictional titles only.
final List<MediaItem> goldenContinueWatching = [
  testMediaItem(
    id: 'cw_halcyon',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Signal Decay',
    summary:
        'Forty thousand people live on the last station in the belt. When the resupply ships stop coming, the '
        'station has to decide what it is willing to become.',
    index: 4,
    parentIndex: 2,
    grandparentTitle: 'Halcyon Station',
    year: 2024,
    contentRating: 'TV-14',
    rating: 8.3,
    durationMs: 51 * 60000,
    viewOffsetMs: 28 * 60000,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
  testMediaItem(
    id: 'cw_lighthouse',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'The Last Lighthouse',
    summary:
        'When the mainland goes dark, a retired keeper rows back to the island she swore she would never see '
        'again, and finds the light already burning.',
    year: 2024,
    contentRating: 'PG-13',
    rating: 7.9,
    durationMs: 127 * 60000,
    viewOffsetMs: 55 * 60000,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
  testMediaItem(
    id: 'cw_blue_hour',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Slack Water',
    summary: 'The tide turns twice in one night, and the harbour town learns which of its neighbours it can trust.',
    index: 7,
    parentIndex: 1,
    grandparentTitle: 'Blue Hour',
    year: 2023,
    contentRating: 'TV-MA',
    durationMs: 44 * 60000,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
  testMediaItem(
    id: 'cw_glass_ocean',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Glass Ocean',
    year: 2024,
    contentRating: 'PG',
    durationMs: 89 * 60000,
    viewOffsetMs: 49 * 60000,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
];

/// The home screen's hubs below Continue Watching.
final List<MediaHub> goldenHomeHubs = [
  MediaHub(
    id: 'recently_added_movies',
    title: 'Recently added',
    type: 'movie',
    items: goldenMovies.take(12).toList(),
    size: 12,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
  MediaHub(
    id: 'more_from_the_library',
    title: 'From your library',
    type: 'movie',
    items: goldenMovies.skip(12).toList(),
    size: 12,
    serverId: goldenServerId,
    serverName: goldenServerName,
  ),
];

/// A server that answers from the fixtures above, at once, with no artwork.
class GoldenMediaServerClient implements MediaServerClient {
  late final Map<String, List<MediaItem>> _children = {
    goldenShow.id: [goldenSeason],
    goldenSeason.id: goldenEpisodes,
  };

  late final List<MediaItem> _items = [goldenDetailMovie, goldenShow, goldenSeason, ...goldenEpisodes, ...goldenMovies];

  @override
  ServerId get serverId => ServerId(goldenServerId);

  @override
  String? get serverName => goldenServerName;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  MediaItem? _find(String id) => _items.where((item) => item.id == id).firstOrNull;

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async {
    final item = _find(id);
    if (item != null) onItemReady?.call(item);
    return (item: item, onDeckEpisode: id == goldenShow.id ? goldenEpisodes[2] : null);
  }

  @override
  Future<MediaItem?> fetchItem(String id) async => _find(id);

  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(
    String itemId, {
    int mediaIndex = 0,
    String? mediaSourceId,
    String? preferredVersionSignature,
  }) async => null;

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) async =>
      goldenContinueWatching;

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) async => goldenHomeHubs;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => goldenLibraries;

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) async => const [];

  /// Titles containing [query], films first.
  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    final needle = query.toLowerCase();
    return [
      for (final item in [...goldenMovies, goldenShow, ...goldenEpisodes])
        if ((item.title ?? '').toLowerCase().contains(needle)) item,
    ].take(limit).toList();
  }

  @override
  Future<List<MediaPerson>> searchPeople(
    String query, {
    int limit = defaultPeopleSearchLimit,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => const [];

  /// The browse library's films.
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    return fakeLibraryPage(goldenBrowseMovies, start: query.offset, size: query.limit);
  }

  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async =>
      LibraryFilterResult.empty;

  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async => const [
    MediaSort(key: 'titleSort', title: 'Title'),
    MediaSort(key: 'addedAt', descKey: 'addedAt:desc', title: 'Date added'),
  ];

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async => _children[parentId] ?? const [];

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => fakeLibraryPage(_children[parentId] ?? const <MediaItem>[], start: start, size: size);

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => fakeLibraryPage(goldenEpisodes, start: start, size: size);

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) => '';

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
