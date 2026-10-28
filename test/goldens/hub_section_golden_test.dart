@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/locked_hub_controller.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/widgets/hub_section.dart';

import 'golden_fixtures.dart';
import 'golden_harness.dart';

/// Home-screen shelves: a Continue Watching hub of episodes and a movie hub,
/// stacked the way the home screen lists them.
void main() {
  goldenMatrix(
    'hub_section',
    themes: screenGoldenThemes,
    body: (tester, golden) => pumpGoldenApp(
      tester,
      golden,
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            children: [
              HubSection(
                hub: _hub('continue', 'Continue Watching', goldenEpisodes.sublist(2, 5)),
                focusMemory: HubFocusMemory(),
                icon: Symbols.play_circle_rounded,
                isInContinueWatching: true,
              ),
              HubSection(
                hub: _hub('recent_movies', 'Recently Added Movies', goldenMovies.sublist(0, 12)),
                focusMemory: HubFocusMemory(),
                icon: Symbols.movie_rounded,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

MediaHub _hub(String id, String title, List<MediaItem> items) => MediaHub(
  id: id,
  title: title,
  type: 'mixed',
  items: items,
  size: items.length,
  more: true,
  serverId: goldenServerId,
);
