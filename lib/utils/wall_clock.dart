import 'package:flutter/foundation.dart';

/// Where time-of-day labels (the clock, "ends at") read the time.
///
/// The app never changes it. Screenshot tests pin it, so wall-clock text
/// renders the same on every run.
@visibleForTesting
DateTime Function() debugWallClock = DateTime.now;

/// The current wall-clock time.
DateTime wallClockNow() => debugWallClock();
