import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Applies to every test under `test/goldens/`: loads the app's real fonts and
/// installs the host-gated comparator before any golden test runs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadGoldenFonts();
  installGoldenComparator();
  await testMain();
}
